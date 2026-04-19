var ABI = [
    "function admin() view returns (address)",
    "function getTotalProducts() view returns (uint256)",
    "function getProductState(uint256) view returns (uint8)",
    "function getProductHistory(uint256) view returns (string,uint8,string,string,uint256,string,uint256,string,uint256,string,uint256,uint256)",
    "function participants(address) view returns (address,string,uint8,bool)",
    "function addParticipant(address,string,uint8) external",
    "function removeParticipant(address) external",
    "function createProduct(string,string) external returns (uint256)",
    "function harvestProduct(uint256) external",
    "function processProduct(uint256) external",
    "function shipProduct(uint256) external",
    "function receiveProduct(uint256,uint256) external"
];

var provider = null;
var signer = null;
var contract = null;
var userAddress = null;

var STATE_LABELS = [
    "Đã gieo trồng",
    "Đã thu hoạch",
    "Đã chế biến",
    "Đang vận chuyển",
    "Đã nhận hàng",
    "Đang bán"
];

var STATE_ICONS = ["🌱", "🌾", "🏭", "🚚", "📦", "🏪"];
var ROLE_LABELS = ["Admin", "Nông dân", "Nhà máy", "Nhà phân phối", "Siêu thị"];

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
        await contract.getTotalProducts();
        localStorage.setItem("ftContract", addr);
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
            var p = await contract.participants(userAddress);
            roleTag.textContent = p.isActive ? ROLE_LABELS[Number(p.role)] : "GUEST";
        }
        roleTag.classList.remove("d-none");
    } catch (e) {
        console.error(e);
    }
}

async function addParticipant() {
    if (!checkContract()) return;

    var address = document.getElementById("p-address").value.trim();
    var name = document.getElementById("p-name").value.trim();
    var role = document.getElementById("p-role").value;

    if (!address || !name) {
        showToast("Nhập đầy đủ địa chỉ và tên", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.addParticipant(address, name, Number(role));
        },
        "Đã thêm participant thành công!"
    );
}

async function removeParticipant() {
    if (!checkContract()) return;

    var address = document.getElementById("p-remove-address").value.trim();
    if (!address) {
        showToast("Nhập địa chỉ cần xóa", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.removeParticipant(address);
        },
        "Đã xóa participant thành công!"
    );
}

async function checkParticipant() {
    if (!contract) {
        showToast("Vui lòng kết nối contract", "warning");
        return;
    }

    var address = document.getElementById("p-check-address").value.trim();
    var info = document.getElementById("participantInfo");

    if (!address) {
        showToast("Nhập địa chỉ cần kiểm tra", "warning");
        return;
    }

    try {
        var p = await contract.participants(address);
        var isActive = Boolean(p.isActive);
        var roleIndex = Number(p.role);

        info.innerHTML = [
            '<div class="alert alert-secondary mb-0">',
            '<div><strong>Địa chỉ:</strong> <span class="font-monospace">' + address + '</span></div>',
            '<div><strong>Tên:</strong> ' + (p.name || '--') + '</div>',
            '<div><strong>Vai trò:</strong> ' + (ROLE_LABELS[roleIndex] || '--') + '</div>',
            '<div><strong>Trạng thái:</strong> ' + (isActive ? 'Đang hoạt động' : 'Không hoạt động') + '</div>',
            '</div>'
        ].join('');
    } catch (e) {
        info.innerHTML = "";
        showToast("Không thể kiểm tra participant: " + e.message, "danger");
    }
}

async function createProduct() {
    if (!checkContract()) return;

    var name = document.getElementById("f-name").value.trim();
    var location = document.getElementById("f-location").value.trim();

    if (!name || !location) {
        showToast("Nhập đầy đủ tên sản phẩm và vị trí trang trại", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.createProduct(name, location);
        },
        "Tạo sản phẩm thành công!"
    );
}

async function harvestProduct() {
    if (!checkContract()) return;

    var id = document.getElementById("f-harvest-id").value;
    if (!id) {
        showToast("Nhập Product ID cần thu hoạch", "warning");
        return;
    }

    await sendTx(
        function () {
            return contract.harvestProduct(BigInt(id));
        },
        "Thu hoạch sản phẩm thành công!"
    );
}

async function processProduct() {
    if (!checkContract()) return;
    showToast("Chức năng này đã được tách khỏi giao diện hiện tại", "info");
}

async function shipProduct() {
    if (!checkContract()) return;
    showToast("Chức năng này đã được tách khỏi giao diện hiện tại", "info");
}

async function receiveProduct() {
    if (!checkContract()) return;
    showToast("Chức năng này đã được tách khỏi giao diện hiện tại", "info");
}
