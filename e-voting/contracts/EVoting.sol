// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EVoting - Hệ thống Bỏ phiếu Điện tử End-to-End Verifiable
 * @author Blockchain Programming Course
 * @notice Smart Contract bầu cử minh bạch với mã hóa và xác minh
 * @dev Quy trình: Configuration → Casting → Anonymization → Decryption → Auditing
 */

contract EVoting {
    // ========================================
    // PHẦN 1: CẤU TRÚC DỮ LIỆU
    // ========================================

    /**
     * @dev Enum trạng thái bầu cử
     */
    enum ElectionPhase {
        Configuration, // 0 - Thiết lập bầu cử
        Casting, // 1 - Đang bỏ phiếu
        Anonymization, // 2 - Xáo trộn phiếu
        Decryption, // 3 - Giải mã & đếm phiếu
        Completed // 4 - Hoàn thành
    }

    /**
     * @dev Struct thông tin bầu cử
     */
    struct Election {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        ElectionPhase phase;
        address creator;
        bool exists;
        uint256 totalVoters;
        uint256 totalVoted;
    }

    /**
     * @dev Struct ứng cử viên
     */
    struct Candidate {
        uint256 id;
        string name;
        string description;
        string imageUrl;
        uint256 voteCount;
        bool exists;
    }

    /**
     * @dev Struct phiếu bầu đã mã hóa
     */
    struct EncryptedBallot {
        uint256 electionId;
        address voter;
        bytes encryptedVote; // Phiếu đã mã hóa
        bytes32 commitment; // Commitment để xác minh
        uint256 timestamp;
        bool isShuffled; // Đã xáo trộn chưa
        bool isDecrypted; // Đã giải mã chưa
    }

    /**
     * @dev Struct proof để audit
     */
    struct AuditProof {
        bytes32 ballotHash;
        bytes32 shuffleProof;
        bytes32 decryptionProof;
        uint256 timestamp;
    }

    // ========================================
    // PHẦN 2: BIẾN TRẠNG THÁI
    // ========================================

    address public admin;
    uint256 public electionCounter = 0;
    uint256 public ballotCounter = 0;

    // Mappings
    mapping(uint256 => Election) public elections;
    mapping(uint256 => mapping(uint256 => Candidate)) public candidates; // electionId => candidateId => Candidate
    mapping(uint256 => uint256) public candidateCounters; // electionId => số lượng ứng viên
    mapping(uint256 => mapping(address => bool)) public hasVoted; // electionId => voter => đã vote chưa
    mapping(uint256 => mapping(address => bool)) public isRegisteredVoter; // electionId => voter => đã đăng ký chưa
    mapping(uint256 => EncryptedBallot[]) public encryptedBallots; // electionId => danh sách phiếu
    mapping(uint256 => AuditProof[]) public auditTrail; // electionId => audit trail

    // ========================================
    // PHẦN 3: EVENTS
    // ========================================

    event ElectionCreated(
        uint256 indexed electionId,
        string title,
        address indexed creator,
        uint256 startTime,
        uint256 endTime
    );

    event CandidateAdded(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        string name
    );

    event VoterRegistered(uint256 indexed electionId, address indexed voter);

    event PhaseChanged(
        uint256 indexed electionId,
        ElectionPhase newPhase,
        uint256 timestamp
    );

    event VoteCast(
        uint256 indexed electionId,
        address indexed voter,
        bytes32 commitment,
        uint256 timestamp
    );

    event BallotsShuffled(
        uint256 indexed electionId,
        uint256 ballotCount,
        bytes32 shuffleProof
    );

    event VoteDecrypted(
        uint256 indexed electionId,
        uint256 ballotIndex,
        uint256 candidateId
    );

    event ElectionCompleted(uint256 indexed electionId, uint256 totalVotes);

    // ========================================
    // PHẦN 4: MODIFIERS
    // ========================================

    modifier onlyAdmin() {
        require(msg.sender == admin, "Chi admin moi duoc thuc hien");
        _;
    }

    modifier electionExists(uint256 _electionId) {
        require(elections[_electionId].exists, "Bau cu khong ton tai");
        _;
    }

    modifier inPhase(uint256 _electionId, ElectionPhase _phase) {
        require(elections[_electionId].phase == _phase, "Khong dung giai doan");
        _;
    }

    modifier isRegistered(uint256 _electionId) {
        require(
            isRegisteredVoter[_electionId][msg.sender],
            "Ban chua dang ky bo phieu"
        );
        _;
    }

    modifier hasNotVoted(uint256 _electionId) {
        require(!hasVoted[_electionId][msg.sender], "Ban da bo phieu roi");
        _;
    }

    // ========================================
    // PHẦN 5: CONSTRUCTOR
    // ========================================

    constructor() {
        admin = msg.sender;
    }

    // ========================================
    // PHẦN 6: PHASE 1 - CONFIGURATION
    // ========================================

    /**
     * @dev Tạo bầu cử mới
     */
    function createElection(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyAdmin returns (uint256) {
        require(
            _startTime > block.timestamp,
            "Thoi gian bat dau phai lon hon hien tai"
        );
        require(
            _endTime > _startTime,
            "Thoi gian ket thuc phai lon hon bat dau"
        );

        electionCounter++;

        elections[electionCounter] = Election({
            id: electionCounter,
            title: _title,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            phase: ElectionPhase.Configuration,
            creator: msg.sender,
            exists: true,
            totalVoters: 0,
            totalVoted: 0
        });

        emit ElectionCreated(
            electionCounter,
            _title,
            msg.sender,
            _startTime,
            _endTime
        );

        return electionCounter;
    }

    /**
     * @dev Thêm ứng cử viên
     */
    function addCandidate(
        uint256 _electionId,
        string memory _name,
        string memory _description,
        string memory _imageUrl
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Configuration)
    {
        _addCandidate(_electionId, _name, _description, _imageUrl);
    }

    /**
     * @dev Thêm nhiều ứng cử viên cùng lúc
     */
    function addCandidatesBatch(
        uint256 _electionId,
        string[] memory _names,
        string[] memory _descriptions,
        string[] memory _imageUrls
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Configuration)
    {
        require(_names.length > 0, "Danh sach ung vien rong");
        require(
            _names.length == _descriptions.length,
            "So luong mo ta khong khop"
        );
        require(_names.length == _imageUrls.length, "So luong anh khong khop");

        for (uint256 i = 0; i < _names.length; i++) {
            _addCandidate(
                _electionId,
                _names[i],
                _descriptions[i],
                _imageUrls[i]
            );
        }
    }

    function _addCandidate(
        uint256 _electionId,
        string memory _name,
        string memory _description,
        string memory _imageUrl
    ) internal {
        uint256 candidateId = candidateCounters[_electionId] + 1;
        candidateCounters[_electionId] = candidateId;

        candidates[_electionId][candidateId] = Candidate({
            id: candidateId,
            name: _name,
            description: _description,
            imageUrl: _imageUrl,
            voteCount: 0,
            exists: true
        });

        emit CandidateAdded(_electionId, candidateId, _name);
    }

    /**
     * @dev Đăng ký cử tri
     */
    function registerVoter(
        uint256 _electionId,
        address _voter
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Configuration)
    {
        require(!isRegisteredVoter[_electionId][_voter], "Cu tri da dang ky");

        isRegisteredVoter[_electionId][_voter] = true;
        elections[_electionId].totalVoters++;

        emit VoterRegistered(_electionId, _voter);
    }

    /**
     * @dev Đăng ký nhiều cử tri cùng lúc
     */
    function registerVotersBatch(
        uint256 _electionId,
        address[] memory _voters
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Configuration)
    {
        for (uint256 i = 0; i < _voters.length; i++) {
            if (!isRegisteredVoter[_electionId][_voters[i]]) {
                isRegisteredVoter[_electionId][_voters[i]] = true;
                elections[_electionId].totalVoters++;
                emit VoterRegistered(_electionId, _voters[i]);
            }
        }
    }

    /**
     * @dev Chuyển sang giai đoạn bỏ phiếu
     */
    function startVoting(
        uint256 _electionId
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Configuration)
    {
        require(
            candidateCounters[_electionId] >= 2,
            "Phai co it nhat 2 ung vien"
        );
        require(
            elections[_electionId].totalVoters >= 3,
            "Phai co it nhat 3 cu tri"
        );
        require(
            block.timestamp >= elections[_electionId].startTime,
            "Chua den thoi gian bat dau"
        );

        elections[_electionId].phase = ElectionPhase.Casting;
        emit PhaseChanged(_electionId, ElectionPhase.Casting, block.timestamp);
    }

    // ========================================
    // PHẦN 7: PHASE 2 - CASTING (Bỏ phiếu)
    // ========================================

    /**
     * @dev Cử tri bỏ phiếu (đã mã hóa trên client)
     */
    function castVote(
        uint256 _electionId,
        bytes memory _encryptedVote,
        bytes32 _commitment
    )
        public
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Casting)
        isRegistered(_electionId)
        hasNotVoted(_electionId)
    {
        _recordVote(_electionId, msg.sender, _encryptedVote, _commitment);
    }

    /**
     * @dev Admin/server bỏ phiếu thay cho cử tri đã đăng ký
     */
    function castVoteForVoter(
        uint256 _electionId,
        address _voter,
        bytes memory _encryptedVote,
        bytes32 _commitment
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Casting)
    {
        require(
            isRegisteredVoter[_electionId][_voter],
            "Ban chua dang ky bo phieu"
        );
        require(!hasVoted[_electionId][_voter], "Ban da bo phieu roi");

        _recordVote(_electionId, _voter, _encryptedVote, _commitment);
    }

    function _recordVote(
        uint256 _electionId,
        address _voter,
        bytes memory _encryptedVote,
        bytes32 _commitment
    ) internal {
        require(
            block.timestamp <= elections[_electionId].endTime,
            "Da het thoi gian bo phieu"
        );

        encryptedBallots[_electionId].push(
            EncryptedBallot({
                electionId: _electionId,
                voter: _voter,
                encryptedVote: _encryptedVote,
                commitment: _commitment,
                timestamp: block.timestamp,
                isShuffled: false,
                isDecrypted: false
            })
        );

        hasVoted[_electionId][_voter] = true;
        elections[_electionId].totalVoted++;

        emit VoteCast(_electionId, _voter, _commitment, block.timestamp);
    }

    /**
     * @dev Kết thúc bỏ phiếu, chuyển sang xáo trộn
     */
    function endVoting(
        uint256 _electionId
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Casting)
    {
        require(
            block.timestamp > elections[_electionId].endTime,
            "Chua het thoi gian bo phieu"
        );

        elections[_electionId].phase = ElectionPhase.Anonymization;
        emit PhaseChanged(
            _electionId,
            ElectionPhase.Anonymization,
            block.timestamp
        );
    }

    // ========================================
    // PHẦN 8: PHASE 3 - ANONYMIZATION (Xáo trộn)
    // ========================================

    /**
     * @dev Xáo trộn phiếu để bảo vệ riêng tư
     * Trong thực tế, sử dụng Mix-Net hoặc Zero-Knowledge Proofs
     */
    function shuffleBallots(
        uint256 _electionId,
        bytes32 _shuffleProof
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Anonymization)
    {
        uint256 ballotCount = encryptedBallots[_electionId].length;
        require(ballotCount > 0, "Khong co phieu nao");

        // Đánh dấu tất cả phiếu đã được xáo trộn
        for (uint256 i = 0; i < ballotCount; i++) {
            encryptedBallots[_electionId][i].isShuffled = true;
        }

        // Lưu proof để audit
        auditTrail[_electionId].push(
            AuditProof({
                ballotHash: keccak256(
                    abi.encodePacked(_electionId, ballotCount)
                ),
                shuffleProof: _shuffleProof,
                decryptionProof: bytes32(0),
                timestamp: block.timestamp
            })
        );

        emit BallotsShuffled(_electionId, ballotCount, _shuffleProof);

        // Chuyển sang giai đoạn giải mã
        elections[_electionId].phase = ElectionPhase.Decryption;
        emit PhaseChanged(
            _electionId,
            ElectionPhase.Decryption,
            block.timestamp
        );
    }

    // ========================================
    // PHẦN 9: PHASE 4 - DECRYPTION & TALLYING
    // ========================================

    /**
     * @dev Giải mã và đếm phiếu
     * Trong thực tế, sử dụng Threshold Decryption
     */
    function decryptAndTally(
        uint256 _electionId,
        uint256[] memory _candidateIds
    )
        public
        onlyAdmin
        electionExists(_electionId)
        inPhase(_electionId, ElectionPhase.Decryption)
    {
        _decryptAndFinalize(_electionId, _candidateIds);
    }

    function finalizeElectionWithTally(
        uint256 _electionId,
        bytes32 _shuffleProof,
        uint256[] memory _candidateIds
    ) public onlyAdmin electionExists(_electionId) {
        ElectionPhase currentPhase = elections[_electionId].phase;

        if (currentPhase == ElectionPhase.Casting) {
            require(
                block.timestamp > elections[_electionId].endTime,
                "Chua het thoi gian bo phieu"
            );
            elections[_electionId].phase = ElectionPhase.Anonymization;
            emit PhaseChanged(
                _electionId,
                ElectionPhase.Anonymization,
                block.timestamp
            );
            currentPhase = ElectionPhase.Anonymization;
        }

        if (currentPhase == ElectionPhase.Anonymization) {
            uint256 ballotCount = encryptedBallots[_electionId].length;
            require(ballotCount > 0, "Khong co phieu nao");

            for (uint256 i = 0; i < ballotCount; i++) {
                encryptedBallots[_electionId][i].isShuffled = true;
            }

            auditTrail[_electionId].push(
                AuditProof({
                    ballotHash: keccak256(
                        abi.encodePacked(_electionId, ballotCount)
                    ),
                    shuffleProof: _shuffleProof,
                    decryptionProof: bytes32(0),
                    timestamp: block.timestamp
                })
            );

            emit BallotsShuffled(_electionId, ballotCount, _shuffleProof);

            elections[_electionId].phase = ElectionPhase.Decryption;
            emit PhaseChanged(
                _electionId,
                ElectionPhase.Decryption,
                block.timestamp
            );
            currentPhase = ElectionPhase.Decryption;
        }

        require(
            currentPhase == ElectionPhase.Decryption,
            "Khong dung giai doan"
        );

        _decryptAndFinalize(_electionId, _candidateIds);
    }

    function _decryptAndFinalize(
        uint256 _electionId,
        uint256[] memory _candidateIds
    ) internal {
        uint256 ballotCount = encryptedBallots[_electionId].length;
        require(_candidateIds.length == ballotCount, "So luong khong khop");

        // Đếm phiếu cho từng ứng viên
        for (uint256 i = 0; i < ballotCount; i++) {
            uint256 candidateId = _candidateIds[i];
            require(
                candidates[_electionId][candidateId].exists,
                "Ung vien khong ton tai"
            );

            candidates[_electionId][candidateId].voteCount++;
            encryptedBallots[_electionId][i].isDecrypted = true;

            emit VoteDecrypted(_electionId, i, candidateId);
        }

        // Hoàn thành bầu cử
        elections[_electionId].phase = ElectionPhase.Completed;
        emit PhaseChanged(
            _electionId,
            ElectionPhase.Completed,
            block.timestamp
        );
        emit ElectionCompleted(_electionId, ballotCount);
    }

    // ========================================
    // PHẦN 10: PHASE 5 - AUDITING (Xem & Kiểm tra)
    // ========================================

    /**
     * @dev Lấy kết quả bầu cử
     */
    function getResults(
        uint256 _electionId
    )
        public
        view
        electionExists(_electionId)
        returns (
            string memory title,
            ElectionPhase phase,
            uint256 totalVoters,
            uint256 totalVoted,
            uint256 candidateCount
        )
    {
        Election memory election = elections[_electionId];
        return (
            election.title,
            election.phase,
            election.totalVoters,
            election.totalVoted,
            candidateCounters[_electionId]
        );
    }

    /**
     * @dev Lấy thông tin ứng viên và số phiếu
     */
    function getCandidate(
        uint256 _electionId,
        uint256 _candidateId
    )
        public
        view
        electionExists(_electionId)
        returns (
            string memory name,
            string memory description,
            string memory imageUrl,
            uint256 voteCount
        )
    {
        Candidate memory candidate = candidates[_electionId][_candidateId];
        require(candidate.exists, "Ung vien khong ton tai");

        return (
            candidate.name,
            candidate.description,
            candidate.imageUrl,
            candidate.voteCount
        );
    }

    /**
     * @dev Lấy tất cả ứng viên
     */
    function getAllCandidates(
        uint256 _electionId
    )
        public
        view
        electionExists(_electionId)
        returns (
            uint256[] memory ids,
            string[] memory names,
            uint256[] memory votes
        )
    {
        uint256 count = candidateCounters[_electionId];
        ids = new uint256[](count);
        names = new string[](count);
        votes = new uint256[](count);

        for (uint256 i = 1; i <= count; i++) {
            ids[i - 1] = i;
            names[i - 1] = candidates[_electionId][i].name;
            votes[i - 1] = candidates[_electionId][i].voteCount;
        }

        return (ids, names, votes);
    }

    /**
     * @dev Kiểm tra cử tri đã bỏ phiếu chưa
     */
    function hasVoterVoted(
        uint256 _electionId,
        address _voter
    ) public view electionExists(_electionId) returns (bool) {
        return hasVoted[_electionId][_voter];
    }

    /**
     * @dev Lấy audit trail
     */
    function getAuditTrail(
        uint256 _electionId
    ) public view electionExists(_electionId) returns (AuditProof[] memory) {
        return auditTrail[_electionId];
    }

    /**
     * @dev Lấy số lượng phiếu đã mã hóa
     */
    function getBallotCount(
        uint256 _electionId
    ) public view electionExists(_electionId) returns (uint256) {
        return encryptedBallots[_electionId].length;
    }

    /**
     * @dev Xác minh commitment của phiếu
     */
    function verifyBallotCommitment(
        uint256 _electionId,
        uint256 _ballotIndex,
        bytes32 _commitment
    ) public view electionExists(_electionId) returns (bool) {
        require(
            _ballotIndex < encryptedBallots[_electionId].length,
            "Ballot khong ton tai"
        );
        return
            encryptedBallots[_electionId][_ballotIndex].commitment ==
            _commitment;
    }

    // ========================================
    // PHẦN 11: HELPER FUNCTIONS
    // ========================================

    /**
     * @dev Chuyển đổi phase sang string
     */
    function phaseToString(
        ElectionPhase _phase
    ) public pure returns (string memory) {
        if (_phase == ElectionPhase.Configuration) return "Thiet lap";
        if (_phase == ElectionPhase.Casting) return "Dang bo phieu";
        if (_phase == ElectionPhase.Anonymization) return "Xao tron";
        if (_phase == ElectionPhase.Decryption) return "Giai ma";
        if (_phase == ElectionPhase.Completed) return "Hoan thanh";
        return "Khong xac dinh";
    }

    /**
     * @dev Lấy thông tin bầu cử đầy đủ
     */
    function getElectionInfo(
        uint256 _electionId
    )
        public
        view
        electionExists(_electionId)
        returns (
            string memory title,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            ElectionPhase phase,
            uint256 totalVoters,
            uint256 totalVoted,
            uint256 candidateCount
        )
    {
        Election memory election = elections[_electionId];
        return (
            election.title,
            election.description,
            election.startTime,
            election.endTime,
            election.phase,
            election.totalVoters,
            election.totalVoted,
            candidateCounters[_electionId]
        );
    }
}
