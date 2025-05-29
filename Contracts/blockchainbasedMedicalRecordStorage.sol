// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Project - Blockchain Medical Record Storage
 * @dev Core smart contract for managing medical records on blockchain
 * @notice This contract provides essential functions for medical record management
 */
contract Project {
    
    // ============ STATE VARIABLES ============
    
    struct MedicalRecord {
        uint256 recordId;
        address patient;
        address provider;
        string ipfsHash;
        string recordType;
        uint256 timestamp;
        bool isActive;
    }
    
    struct Patient {
        address patientAddress;
        string name;
        bool isRegistered;
        uint256[] recordIds;
    }
    
    uint256 private recordCounter;
    
    mapping(uint256 => MedicalRecord) public medicalRecords;
    mapping(address => Patient) public patients;
    mapping(address => bool) public verifiedProviders;
    mapping(address => mapping(address => bool)) public patientProviderAccess;
    
    // ============ EVENTS ============
    
    event RecordCreated(uint256 indexed recordId, address indexed patient, address indexed provider);
    event AccessGranted(address indexed patient, address indexed provider);
    event PatientRegistered(address indexed patient, string name);
    
    // ============ CORE FUNCTIONS ============
    
    /**
     * @dev Core Function 1: Register Patient
     * @param _name Patient's name
     * @notice Allows patients to register themselves in the system
     */
    function registerPatient(string memory _name) external {
        require(!patients[msg.sender].isRegistered, "Patient already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        patients[msg.sender] = Patient({
            patientAddress: msg.sender,
            name: _name,
            isRegistered: true,
            recordIds: new uint256[](0)
        });
        
        emit PatientRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Core Function 2: Create Medical Record
     * @param _patient Patient's address
     * @param _ipfsHash IPFS hash of encrypted medical data
     * @param _recordType Type of medical record (e.g., "diagnosis", "prescription")
     * @notice Allows verified healthcare providers to create medical records
     */
    function createMedicalRecord(
        address _patient,
        string memory _ipfsHash,
        string memory _recordType
    ) external returns (uint256) {
        require(verifiedProviders[msg.sender], "Provider not verified");
        require(patients[_patient].isRegistered, "Patient not registered");
        require(patientProviderAccess[_patient][msg.sender], "No access granted");
        require(bytes(_ipfsHash).length > 0, "IPFS hash required");
        
        recordCounter++;
        
        medicalRecords[recordCounter] = MedicalRecord({
            recordId: recordCounter,
            patient: _patient,
            provider: msg.sender,
            ipfsHash: _ipfsHash,
            recordType: _recordType,
            timestamp: block.timestamp,
            isActive: true
        });
        
        patients[_patient].recordIds.push(recordCounter);
        
        emit RecordCreated(recordCounter, _patient, msg.sender);
        return recordCounter;
    }
    
    /**
     * @dev Core Function 3: Grant Provider Access
     * @param _provider Healthcare provider's address
     * @notice Allows patients to grant access to healthcare providers
     */
    function grantProviderAccess(address _provider) external {
        require(patients[msg.sender].isRegistered, "Patient not registered");
        require(verifiedProviders[_provider], "Provider not verified");
        require(!patientProviderAccess[msg.sender][_provider], "Access already granted");
        
        patientProviderAccess[msg.sender][_provider] = true;
        
        emit AccessGranted(msg.sender, _provider);
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    /**
     * @dev Verify healthcare provider (admin function)
     * @param _provider Provider's address to verify
     */
    function verifyProvider(address _provider) external {
        // In production, add proper admin access control
        verifiedProviders[_provider] = true;
    }
    
    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Get patient's record IDs
     * @param _patient Patient's address
     */
    function getPatientRecords(address _patient) external view returns (uint256[] memory) {
        require(
            msg.sender == _patient || patientProviderAccess[_patient][msg.sender],
            "No access to records"
        );
        return patients[_patient].recordIds;
    }
    
    /**
     * @dev Get medical record details
     * @param _recordId Record ID to retrieve
     */
    function getMedicalRecord(uint256 _recordId) external view returns (MedicalRecord memory) {
        MedicalRecord memory record = medicalRecords[_recordId];
        require(
            msg.sender == record.patient || patientProviderAccess[record.patient][msg.sender],
            "No access to this record"
        );
        return record;
    }
    
    /**
     * @dev Get total number of records
     */
    function getTotalRecords() external view returns (uint256) {
        return recordCounter;
    }
}
