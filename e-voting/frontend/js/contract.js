// ABI của smart contract EVoting
var ABI = [
    "function admin() view returns (address)",
    "function electionCounter() view returns (uint256)",
    "function elections(uint256) view returns (uint256,string,string,uint256,uint256,uint8,address,bool,uint256,uint256)",
    "function candidates(uint256,uint256) view returns (uint256,string,string,string,uint256,bool)",
    "function candidateCounters(uint256) view returns (uint256)",
    "function hasVoted(uint256,address) view returns (bool)",
    "function isRegisteredVoter(uint256,address) view returns (bool)",
    "function createElection(string,string,uint256,uint256) external returns (uint256)",
    "function addCandidate(uint256,string,string,string) external",
    "function registerVoter(uint256,address) external",
    "function registerVotersBatch(uint256,address[]) external",
    "function startVoting(uint256) external",
    "function castVote(uint256,bytes,bytes32) external",
    "function endVoting(uint256) external",
    "function shuffleBallots(uint256,bytes32) external",
    "function decryptAndTally(uint256,uint256[]) external",
    "function getResults(uint256) view returns (string,uint8,uint256,uint256,uint256)",
    "function getCandidate(uint256,uint256) view returns (string,string,string,uint256)",
    "function getAllCandidates(uint256) view returns (uint256[],string[],uint256[])",
    "function hasVoterVoted(uint256,address) view returns (bool)",
    "function getBallotCount(uint256) view returns (uint256)",
    "function getElectionInfo(uint256) view returns (string,string,uint256,uint256,uint8,uint256,uint256,uint256)",
    "function phaseToString(uint8) pure returns (string)"
];

var provider = null;
var signer = null;
var contract = null;
var userAddress = null;

// Enum ElectionPhase
var PHASE_LABELS = [
    "Thiết lập",
    "Đang bỏ phiếu",
    "Xáo trộn",
    "Giải mã",
    "Hoàn thành"
];

var PHASE_ICONS = ["⚙️", "🗳️", "🔀", "🔓", "✅"];

function checkContract() {
    if (!contract) {
        showToast("Vui lòng kết nối contract trong Cài đặt", "warning");
        return false;
    }
    if (!signer) {
        showToast("Vui lòng kết nối MetaMask", "warning");
        return false;
    }
    return true;
}

async function sendTx(fn, successMsg) {
    try {
        showToast("Đang xử lý giao dịch...", "info");
        var tx = await fn();
        await tx.wait();
        showToast(successMsg, "success");
        if (typeof loadDashboard === "function") {
            await loadDashboard();
        }
    } catch (e) {
        showToast("Lỗi: " + (e.reason || e.message || "Thất bại"), "danger");
    }
}

async function connectWallet() {
    if (!window.ethereum) {
        showToast("Cần cài đặt MetaMask!", "danger");
        return;
    }

    try {
        provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();

        var tag = document.getElementById("walletTag");
        if (tag) {
            tag.textContent = userAddress.slice(0, 6) + "..." + userAddress.slice(-4);
            tag.classList.remove("d-none");
        }

        var btn = document.getElementById("connectBtn");
        if (btn) {
            btn.innerHTML = '<i class="bi bi-check-circle me-1"></i>Đã kết nối';
            btn.disabled = true;
            btn.classList.replace("btn-outline-light", "btn-light");
        }

        showToast("Kết nối MetaMask thành công!", "success");
        if (contract && typeof refreshRole === "function") {
            await refreshRole();
        }
    } catch (e) {
        showToast("Lỗi: " + e.message, "danger");
    }
}

async function disconnectWallet() {
    provider = null;
    signer = null;
    userAddress = null;
    contract = null;

    var tag = document.getElementById("walletTag");
    var roleTag = document.getElementById("roleTag");
    if (tag) {
        tag.textContent = "";
        tag.classList.add("d-none");
    }
    if (roleTag) {
        roleTag.textContent = "";
        roleTag.classList.add("d-none");
    }

    var btn = document.getElementById("connectBtn");
    if (btn) {
        btn.innerHTML = '<i class="bi bi-wallet2 me-1"></i>Kết nối MetaMask';
        btn.disabled = false;
        btn.classList.replace("btn-light", "btn-outline-light");
    }

    showToast("Đã ngắt kết nối ví", "info");
}

async function loadContract() {
    var input = document.getElementById("contractAddress");
    var addr = input ? input.value.trim() : "";

    if (!addr) {
        showToast("Nhập địa chỉ contract", "warning");
        return;
    }
    if (!provider) {
        showToast("Kết nối MetaMask trước", "warning");
        return;
    }

    try {
        contract = new ethers.Contract(addr, ABI, signer);
        await contract.electionCounter();
        localStorage.setItem("evContract", addr);
        showToast("Kết nối contract thành công!", "success");

        if (typeof refreshRole === "function") {
            await refreshRole();
        }
        if (typeof loadDashboard === "function") {
            await loadDashboard();
        }
        if (typeof showPanel === "function") {
            showPanel("dashboard");
        }
    } catch (e) {
        showToast("Không thể kết nối: " + e.message, "danger");
    }
}

async function refreshRole() {
    if (!contract || !userAddress) return;

    try {
        var adminAddr = await contract.admin();
        var roleTag = document.getElementById("roleTag");
        if (!roleTag) return;

        if (userAddress.toLowerCase() === adminAddr.toLowerCase()) {
            roleTag.textContent = "ADMIN";
        } else {
            roleTag.textContent = "CỬ TRI";
        }
        roleTag.classList.remove("d-none");
    } catch (e) {
        console.error(e);
    }
}

// ========== ADMIN FUNCTIONS ==========

async function createElection() {
    if (!checkContract()) return;

    var title = document.getElementById("e-title").value.trim();
    var desc = document.getElementById("e-desc").value.trim();
    var startDatetime = document.getElementById("e-start").value;
    var endDatetime = document.getElementById("e-end").value;

    if (!title || !desc || !startDatetime || !endDatetime) {
        showToast("Nhập đầy đủ thông tin bầu cử", "warning");
        return;
    }

    // Chuyển đổi datetime-local sang Unix timestamp
    var startTimestamp = Math.floor(new Date(startDatetime).getTime() / 1000);
    var endTimestamp = Math.floor(new Date(endDatetime).getTime() / 1000);

    // Kiểm tra thời gian hợp lệ (cho phép sai số 60 giây)
    var now = Math.floor(Date.now() / 1000);
    if (startTimestamp < (now - 60)) {
        showToast("Thời gian bắt đầu phải sau thời điểm hiện tại", "warning");
        return;
    }
    if (endTimestamp <= startTimestamp) {
        showToast("Thời gian kết thúc phải sau thời gian bắt đầu (ít nhất 1 phút)", "warning");
        return;
    }
    if ((endTimestamp - startTimestamp) < 60) {
        showToast("Khoảng thời gian bầu cử phải ít nhất 1 phút", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.createElection(title, desc, BigInt(startTimestamp), BigInt(endTimestamp));
        },
        "Đã tạo bầu cử thành công!"
    );
}

async function addCandidate() {
    if (!checkContract()) return;

    var electionId = document.getElementById("c-election-id").value;
    var name = document.getElementById("c-name").value.trim();
    var desc = document.getElementById("c-desc").value.trim();
    var image = document.getElementById("c-image").value.trim();

    if (!electionId || !name || !desc) {
        showToast("Nhập đầy đủ thông tin ứng viên", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.addCandidate(BigInt(electionId), name, desc, image || "");
        },
        "Đã thêm ứng viên thành công!"
    );
}

async function registerVoter() {
    if (!checkContract()) return;

    var electionId = document.getElementById("v-election-id").value;
    var address = document.getElementById("v-address").value.trim();

    if (!electionId || !address) {
        showToast("Nhập đầy đủ Election ID và địa chỉ cử tri", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.registerVoter(BigInt(electionId), address);
        },
        "Đã đăng ký cử tri thành công!"
    );
}

async function startVoting() {
    if (!checkContract()) return;

    var electionId = document.getElementById("phase-election-id").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.startVoting(BigInt(electionId));
        },
        "Đã bắt đầu bỏ phiếu!"
    );
}

async function endVoting() {
    if (!checkContract()) return;

    var electionId = document.getElementById("phase-election-id").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.endVoting(BigInt(electionId));
        },
        "Đã kết thúc bỏ phiếu!"
    );
}

async function shuffleBallots() {
    if (!checkContract()) return;

    var electionId = document.getElementById("phase-election-id").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    // Tạo shuffle proof giả (trong thực tế cần ZK-SNARK)
    var shuffleProof = ethers.keccak256(ethers.toUtf8Bytes("shuffle_" + Date.now()));

    await sendTx(
        function () {
            return contract.shuffleBallots(BigInt(electionId), shuffleProof);
        },
        "Đã xáo trộn phiếu thành công!"
    );
}

// ========== VOTER FUNCTIONS ==========

var selectedCandidateId = null;

async function loadCandidates() {
    if (!checkContract()) return;

    var electionId = document.getElementById("vote-election-id").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    try {
        // Kiểm tra đã bỏ phiếu chưa
        var voted = await contract.hasVoterVoted(BigInt(electionId), userAddress);
        if (voted) {
            showToast("Bạn đã bỏ phiếu cho bầu cử này rồi!", "warning");
            return;
        }

        // Kiểm tra đã đăng ký chưa
        var registered = await contract.isRegisteredVoter(BigInt(electionId), userAddress);
        if (!registered) {
            showToast("Bạn chưa được đăng ký cho bầu cử này!", "warning");
            return;
        }

        var result = await contract.getAllCandidates(BigInt(electionId));
        var ids = result[0];
        var names = result[1];

        var list = document.getElementById("candidateList");
        list.innerHTML = "";

        for (var i = 0; i < ids.length; i++) {
            var candidateData = await contract.getCandidate(BigInt(electionId), ids[i]);
            var card = document.createElement("div");
            card.className = "col-md-4";
            card.innerHTML = `
                <div class="card candidate-card h-100" onclick="selectCandidate(${ids[i]}, '${names[i]}')">
                    <div class="card-body text-center">
                        <div class="fs-1 mb-2">👤</div>
                        <h6 class="fw-bold">${names[i]}</h6>
                        <p class="small text-muted mb-0">${candidateData[1]}</p>
                    </div>
                </div>
            `;
            list.appendChild(card);
        }

        document.getElementById("votingContainer").classList.remove("d-none");
    } catch (e) {
        showToast("Lỗi tải ứng viên: " + e.message, "danger");
    }
}

function selectCandidate(id, name) {
    selectedCandidateId = id;
    document.getElementById("selectedCandidate").textContent = name;
    document.getElementById("castVoteBtn").disabled = false;

    // Highlight selected card
    document.querySelectorAll(".candidate-card").forEach(function (card) {
        card.classList.remove("selected");
    });
    event.currentTarget.classList.add("selected");
}

async function castVote() {
    if (!checkContract()) return;
    if (!selectedCandidateId) {
        showToast("Vui lòng chọn ứng viên", "warning");
        return;
    }

    var electionId = document.getElementById("vote-election-id").value;

    // Mã hóa phiếu (giả lập - trong thực tế dùng encryption thật)
    var voteData = ethers.toUtf8Bytes(selectedCandidateId.toString());
    var encryptedVote = ethers.hexlify(voteData);
    var commitment = ethers.keccak256(ethers.toUtf8Bytes(userAddress + selectedCandidateId + Date.now()));

    await sendTx(
        function () {
            return contract.castVote(BigInt(electionId), encryptedVote, commitment);
        },
        "Đã bỏ phiếu thành công!"
    );

    // Reset
    selectedCandidateId = null;
    document.getElementById("votingContainer").classList.add("d-none");
}

// ========== RESULTS FUNCTIONS ==========

async function loadResults() {
    if (!checkContract()) return;

    var electionId = document.getElementById("resultElectionId").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    try {
        var info = await contract.getElectionInfo(BigInt(electionId));
        var title = info[0];
        var desc = info[1];
        var startTime = Number(info[2]);
        var endTime = Number(info[3]);
        var phase = Number(info[4]);
        var totalVoters = Number(info[5]);
        var totalVoted = Number(info[6]);
        var candidateCount = Number(info[7]);

        var infoDiv = document.getElementById("electionInfo");
        infoDiv.innerHTML = `
            <table class="table table-sm table-bordered">
                <tr><th class="text-muted" style="width:30%">Tiêu đề</th><td>${title}</td></tr>
                <tr><th class="text-muted">Mô tả</th><td>${desc}</td></tr>
                <tr><th class="text-muted">Trạng thái</th><td>${PHASE_ICONS[phase]} ${PHASE_LABELS[phase]}</td></tr>
                <tr><th class="text-muted">Cử tri đăng ký</th><td>${totalVoters}</td></tr>
                <tr><th class="text-muted">Đã bỏ phiếu</th><td>${totalVoted}</td></tr>
                <tr><th class="text-muted">Số ứng viên</th><td>${candidateCount}</td></tr>
            </table>
        `;

        // Load candidates results
        var result = await contract.getAllCandidates(BigInt(electionId));
        var ids = result[0];
        var names = result[1];
        var votes = result[2];

        var maxVotes = 0;
        for (var i = 0; i < votes.length; i++) {
            if (Number(votes[i]) > maxVotes) maxVotes = Number(votes[i]);
        }

        var resultsDiv = document.getElementById("candidateResults");
        resultsDiv.innerHTML = "";

        for (var i = 0; i < ids.length; i++) {
            var voteCount = Number(votes[i]);
            var percentage = totalVoted > 0 ? (voteCount / totalVoted * 100).toFixed(1) : 0;
            var isWinner = voteCount === maxVotes && maxVotes > 0;

            var row = document.createElement("div");
            row.className = "mb-3";
            row.innerHTML = `
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <span class="fw-bold">${names[i]} ${isWinner ? '🏆' : ''}</span>
                    <span class="badge bg-primary">${voteCount} phiếu (${percentage}%)</span>
                </div>
                <div class="progress" style="height: 25px;">
                    <div class="progress-bar ${isWinner ? 'bg-success' : 'bg-primary'}" 
                         style="width: ${percentage}%">${percentage}%</div>
                </div>
            `;
            resultsDiv.appendChild(row);
        }

        document.getElementById("resultsContainer").classList.remove("d-none");
    } catch (e) {
        showToast("Lỗi tải kết quả: " + e.message, "danger");
    }
}

// ========== EVENT LISTENERS ==========

window.addEventListener("load", async function () {
    var saved = localStorage.getItem("evContract");
    if (saved) {
        var input = document.getElementById("contractAddress");
        if (input) {
            input.value = saved;
        }
    }

    if (window.ethereum) {
        var accounts = await window.ethereum.request({ method: "eth_accounts" });
        if (accounts.length > 0) {
            connectWallet();
        }

        // Listen for account changes
        window.ethereum.on("accountsChanged", async function (accounts) {
            if (accounts.length === 0) {
                disconnectWallet();
            } else {
                if (provider) {
                    signer = await provider.getSigner();
                    userAddress = await signer.getAddress();
                    var tag = document.getElementById("walletTag");
                    if (tag) {
                        tag.textContent = userAddress.slice(0, 6) + "..." + userAddress.slice(-4);
                    }
                    if (contract) refreshRole();
                }
            }
        });

        // Listen for chain changes
        window.ethereum.on("chainChanged", function () {
            disconnectWallet();
            showToast("Đã đổi mạng. Vui lòng kết nối lại ví.", "warning");
        });
    }
});
