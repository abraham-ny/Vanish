.pragma library

function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function reEsc(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function isWordChar(ch) {
    return !!ch && /[A-Za-z0-9_]/.test(ch);
}

/** Escapes a plain segment and wraps @mentions of current members. */
function mentions(seg, names, style) {
    if (!names || names.length === 0) return esc(seg).replace(/\n/g, "<br/>");
    var sorted = names.slice().sort(function (a, b) { return b.length - a.length; });
    var re = new RegExp("@(" + sorted.map(reEsc).join("|") + ")(?![A-Za-z0-9_])", "gi");
    var out = "", last = 0, m;
    while ((m = re.exec(seg)) !== null) {
        if (m.index > 0 && isWordChar(seg.charAt(m.index - 1))) continue; // e.g. an e-mail address
        out += esc(seg.substring(last, m.index));
        out += "<b><font color=\"" + style.mention + "\">@" + esc(m[1]) + "</font></b>";
        last = m.index + m[0].length;
    }
    out += esc(seg.substring(last));
    return out.replace(/\n/g, "<br/>");
}

/**
 * Converts message text to StyledText: links become underlined+coloured, @mentions bold+coloured.
 * style: { link: "#hex", mention: "#hex" }
 */
function render(text, names, style) {
    var re = /(https?:\/\/[^\s<>]+|www\.[^\s<>]+)/gi, out = "", last = 0, m;
    while ((m = re.exec(text)) !== null) {
        var url = m[0], trail = "";
        var t = /[.,;:!?)\]}'"]+$/.exec(url);
        if (t) { trail = t[0]; url = url.substring(0, url.length - trail.length); }
        out += mentions(text.substring(last, m.index), names, style);
        var href = /^www\./i.test(url) ? "http://" + url : url;
        out += "<a href=\"" + esc(href).replace(/"/g, "%22") + "\"><font color=\"" + style.link + "\"><u>" + esc(url) + "</u></font></a>" + esc(trail);
        last = m.index + m[0].length;
    }
    out += mentions(text.substring(last), names, style);
    return out;
}

function pad(n) { return n < 10 ? "0" + n : "" + n; }

var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** "14:05" for today, "3 Nov 14:05" otherwise. */
function fmtTime(ts) {
    if (!ts) return "";
    var d = new Date(ts), n = new Date();
    var hm = pad(d.getHours()) + ":" + pad(d.getMinutes());
    if (d.toDateString() === n.toDateString()) return hm;
    return d.getDate() + " " + MONTHS[d.getMonth()] + " " + hm;
}

/** "5h 12m left" / "12m left" / "expired". expiresAt 0 = never. */
function fmtLeft(expiresAt) {
    if (!expiresAt) return "no expiry";
    var ms = expiresAt - Date.now();
    if (ms <= 0) return "expired";
    var m = Math.floor(ms / 60000), h = Math.floor(m / 60);
    return (h > 0 ? h + "h " + (m % 60) + "m" : Math.max(1, m) + "m") + " left";
}

function formatCode(code) {
    code = String(code || "").toUpperCase().replace(/[^A-Z0-9]/g, "");
    return code.length === 8 ? code.substring(0, 4) + "-" + code.substring(4) : code;
}

function randomGuest() {
    return "Guest " + (1000 + Math.floor(Math.random() * 9000));
}

/** First visible character (emoji-safe enough for surrogate pairs). */
function initial(name) {
    var s = String(name || "?").trim();
    if (!s) return "?";
    var c = s.charCodeAt(0);
    if (c >= 0xD800 && c <= 0xDBFF && s.length > 1) return s.substring(0, 2);
    return s.charAt(0).toUpperCase();
}

function hashColor(s) {
    var h = 0;
    for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
    return Qt.hsla(h / 360, 0.6, 0.45, 1);
}
