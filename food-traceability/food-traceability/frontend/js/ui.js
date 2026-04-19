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

    if (!container) return;

    container.insertAdjacentHTML(
        "beforeend",
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
