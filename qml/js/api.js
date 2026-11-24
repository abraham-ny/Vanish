.pragma library

var MESSAGES = {
    not_found: "No chat with that code.",
    expired: "This chat has expired.",
    full: "This chat is full.",
    banned: "This device is blocked.",
    slow_down: "Slow down a little.",
    not_member: "You are no longer in this chat.",
    bad_input: "Please check the name and code.",
    network: "Can't reach the server. Check your connection and backend URL.",
    no_backend: "Backend URL is not set. Add it in Settings.",
    forbidden: "Not allowed."
};

function friendly(code) {
    return MESSAGES[code] || ("Something went wrong (" + code + ").");
}

/**
 * Call the Apps Script web app. GET with the JSON in ?p= (see doGet in Code.gs for why not POST).
 * cb(errCode|null, data).
 */
function call(url, body, cb) {
    if (!url) { cb("no_backend", null); return; }
    var q = "p=" + encodeURIComponent(JSON.stringify(body)) + "&_=" + Date.now();   // _ defeats any HTTP cache
    var full = url + (url.indexOf("?") >= 0 ? "&" : "?") + q;
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        if (xhr.status < 200 || xhr.status >= 300) { cb("network", null); return; }
        var res;
        try { res = JSON.parse(xhr.responseText); } catch (e) { cb("network", null); return; }
        if (res.ok) cb(null, res.data); else cb(res.error || "unknown", null);
    };
    xhr.open("GET", full);
    xhr.send();
}

/** RFC4122-style v4 id. Qt.uuid() is missing on older Qt, and QML has no crypto API. */
function uuid() {
    var b = [], i;
    for (i = 0; i < 16; i++) b.push(Math.floor(Math.random() * 256));
    var t = Date.now();
    for (i = 0; i < 6; i++) { b[i] ^= t & 255; t = Math.floor(t / 256); }   // mix in the clock
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    var h = b.map(function (x) { return (x < 16 ? "0" : "") + x.toString(16); }).join("");
    return h.substr(0, 8) + "-" + h.substr(8, 4) + "-" + h.substr(12, 4) + "-" + h.substr(16, 4) + "-" + h.substr(20, 12);
}
