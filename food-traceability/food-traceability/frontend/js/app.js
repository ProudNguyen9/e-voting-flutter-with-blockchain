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
        var n = Number(await contract.getTotalProducts());
        document.getElementById("stat-total").textContent = n;

        var forsale = 0;
        var shipped = 0;
        var rows = [];

        for (var i = 1; i <= n; i++) {
            var st = Number(await contract.getProductState(i));
            if (st === 5) forsale++;
            if (st === 3) shipped++;

            var h = await contract.getProductHistory(i);
            rows.push({ id: i, name: h[0], state: st });
        }

        document.getElementById("stat-forsale").textContent = forsale;
        document.getElementById("stat-shipped").textContent = shipped;

        var list = document.getElementById("productList");
        if (!rows.length) {
            list.innerHTML = "<p class='text-muted small'>Chưa có sản phẩm nào.</p>";
            return;
        }

        list.innerHTML = rows.map(function (r) {
            return "<div class='d-flex justify-content-between align-items-center py-2 border-bottom'>" +
                "<span><span class='text-muted me-2 font-monospace'>#" + r.id + "</span>" + r.name + "</span>" +
                "<span class='badge bg-success'>" + STATE_ICONS[r.state] + " " + STATE_LABELS[r.state] + "</span>" +
                "</div>";
        }).join("");
    } catch (e) {
        console.error(e);
        showToast("Lỗi tải dashboard: " + e.message, "danger");
    }
}

async function traceProduct() {
    if (!checkContract()) return;

    var id = document.getElementById("traceId").value;
    if (!id) {
        showToast("Nhập Product ID", "warning");
        return;
    }

    try {
        var h = await contract.getProductHistory(BigInt(id));
        var state = Number(h[1]);
        var stepDefs = ["Gieo trồng", "Thu hoạch", "Chế biến", "Vận chuyển", "Nhận hàng", "Đang bán"];

        var tl = stepDefs.map(function (s, i) {
            var cls = i < state ? "text-success" : i === state ? "text-warning" : "text-muted";
            var arrow = i < stepDefs.length - 1 ? "<div class='align-self-center text-muted px-1'>→</div>" : "";
            return "<div class='text-center px-1'><div class='fs-4'>" + STATE_ICONS[i] + "</div><div class='small fw-bold " + cls + "'>" + s + "</div></div>" + arrow;
        }).join("");

        document.getElementById("traceTimeline").innerHTML = tl;

        var rows = [
            ["Tên sản phẩm", h[0]],
            ["Trạng thái", STATE_ICONS[state] + " " + STATE_LABELS[state]],
            ["Nông dân", h[2] || "--"],
            ["Trang trại", h[3] || "--"],
            ["Ngày gieo trồng", h[4] > 0n ? new Date(Number(h[4]) * 1000).toLocaleString("vi-VN") : "--"],
            ["Nhà máy", h[5] || "--"],
            ["Nhà phân phối", h[7] || "--"],
            ["Siêu thị", h[9] || "--"],
            ["Giá bán", h[11] > 0n ? ethers.formatEther(h[11]) + " ETH" : "--"]
        ];

        document.getElementById("traceDetail").innerHTML = rows.map(function (r) {
            return "<tr><th class='text-muted fw-normal' style='width:40%'>" + r[0] + "</th><td>" + r[1] + "</td></tr>";
        }).join("");

        document.getElementById("traceResult").classList.remove("d-none");
    } catch (e) {
        showToast("Lỗi tra cứu: " + e.message, "danger");
    }
}

window.addEventListener("load", async function () {
    var saved = localStorage.getItem("ftContract");
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
    }
});
