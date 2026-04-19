function showPanel(name) {
    document.querySelectorAll(".panel").forEach(function (panel) {
        panel.classList.remove("active");
    });

    document.querySelectorAll(".nav-item-custom").forEach(function (nav) {
        nav.classList.remove("active");
        var target = nav.getAttribute("data-panel");
        if (target === name) {
            nav.classList.add("active");
        }
    });

    var panel = document.getElementById("panel-" + name);
    if (panel) {
        panel.classList.add("active");
    }

    if (name === "dashboard" && typeof loadDashboard === "function" && contract) {
        loadDashboard();
    }
}

async function loadDashboard() {
    if (!contract) return;

    try {
        var totalElections = Number(await contract.electionCounter());
        document.getElementById("stat-total-elections").textContent = totalElections;

        var totalVoters = 0;
        var totalVoted = 0;
        var totalCandidates = 0;
        var rows = [];

        for (var i = 1; i <= totalElections; i++) {
            try {
                var info = await contract.getElectionInfo(BigInt(i));
                var title = info[0];
                var phase = Number(info[4]);
                var voters = Number(info[5]);
                var voted = Number(info[6]);
                var candidates = Number(info[7]);

                totalVoters += voters;
                totalVoted += voted;
                totalCandidates += candidates;

                rows.push({
                    id: i,
                    title: title,
                    phase: phase,
                    voters: voters,
                    voted: voted
                });
            } catch (e) {
                console.error("Error loading election " + i, e);
            }
        }

        document.getElementById("stat-total-voters").textContent = totalVoters;
        document.getElementById("stat-total-voted").textContent = totalVoted;
        document.getElementById("stat-total-candidates").textContent = totalCandidates;

        var list = document.getElementById("electionList");
        if (!rows.length) {
            list.innerHTML = "<p class='text-muted small'>Chưa có bầu cử nào.</p>";
            return;
        }

        list.innerHTML = rows.map(function (r) {
            return "<div class='d-flex justify-content-between align-items-center py-2 border-bottom'>" +
                "<div>" +
                "<span class='text-muted me-2 font-monospace'>#" + r.id + "</span>" +
                "<span class='fw-bold'>" + r.title + "</span>" +
                "</div>" +
                "<div class='d-flex gap-2 align-items-center'>" +
                "<span class='badge bg-primary'>" + PHASE_ICONS[r.phase] + " " + PHASE_LABELS[r.phase] + "</span>" +
                "<span class='small text-muted'>" + r.voted + "/" + r.voters + " phiếu</span>" +
                "</div>" +
                "</div>";
        }).join("");
    } catch (e) {
        console.error(e);
        showToast("Lỗi tải dashboard: " + e.message, "danger");
    }
}

function showToast(msg, type) {
    var colorMap = {
        success: "bg-success",
        danger: "bg-danger",
        warning: "bg-warning text-dark",
        info: "bg-info text-dark"
    };
    var cls = colorMap[type] || "bg-secondary";
    var id = "toast-" + Date.now();
    var container = document.getElementById("toastContainer");

    container.insertAdjacentHTML("beforeend",
        '<div id="' + id + '" class="toast align-items-center text-white border-0 ' + cls + '" role="alert">' +
        '<div class="d-flex">' +
        '<div class="toast-body">' + msg + '</div>' +
        '<button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>' +
        '</div>' +
        '</div>'
    );

    var el = document.getElementById(id);
    var toast = new bootstrap.Toast(el, { delay: 4000 });
    toast.show();
    el.addEventListener("hidden.bs.toast", function () {
        el.remove();
    });
}

function showDecryptModal() {
    if (!checkContract()) return;

    var electionId = document.getElementById("phase-election-id").value;
    if (!electionId) {
        showToast("Nhập Election ID", "warning");
        return;
    }

    // Hiển thị prompt để nhập danh sách candidate IDs
    var input = prompt(
        "Nhập danh sách Candidate IDs theo thứ tự phiếu (cách nhau bởi dấu phẩy).\n" +
        "VD: 1,2,1,3,2,1\n\n" +
        "Lưu ý: Số lượng phải khớp với số phiếu đã bỏ."
    );

    if (!input) return;

    var candidateIds = input.split(",").map(function (id) {
        return BigInt(id.trim());
    });

    sendTx(
        function () {
            return contract.decryptAndTally(BigInt(electionId), candidateIds);
        },
        "Đã giải mã và đếm phiếu thành công!"
    );
}

// Helper function để format timestamp
function formatTimestamp(timestamp) {
    if (!timestamp || timestamp === 0) return "--";
    var date = new Date(Number(timestamp) * 1000);
    return date.toLocaleString("vi-VN");
}

// Helper function để tạo timestamp từ date input
function createTimestamp(dateString) {
    var date = new Date(dateString);
    return Math.floor(date.getTime() / 1000);
}

// Auto-load dashboard when contract is connected
window.addEventListener("contractConnected", function () {
    if (typeof loadDashboard === "function") {
        loadDashboard();
    }
});
