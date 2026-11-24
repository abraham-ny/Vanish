pragma Singleton
import QtQuick 2.12
import "../js/api.js" as Api
import "../js/db.js" as Db
import "../js/config.js" as Config

/*
 * Single source of truth: settings, local chat cache (SQLite), sync loop against the Apps Script backend.
 * Every chat has its own member uuid (myUid) so nothing links your chats together except this device's local DB.
 */
Item {
    id: store

    // ---- settings
    property string deviceId: ""
    property string displayName: ""
    property string theme: "system"       // system | light | dark
    property string apiUrl: ""
    property bool alerts: true

    // ---- state
    property bool ready: false
    property string openChatId: ""
    property int totalUnread: 0
    property int tick: 0                  // bumps every 30 s so countdown bindings refresh
    property alias chats: chatModel

    ListModel { id: chatModel }

    signal chatUpdated(string chatId)
    signal listUpdated()
    signal toast(string text)

    property bool _slowBusy: false
    property bool _fastBusy: false

    Timer {
        id: fastTimer
        interval: 2500; repeat: true
        running: store.openChatId !== "" && Qt.application.state === Qt.ApplicationActive
        onTriggered: store.syncOpen()
    }
    Timer {
        id: slowTimer
        interval: 15000; repeat: true
        running: store.ready && Qt.application.state === Qt.ApplicationActive
        onTriggered: store.syncAll()
    }
    Timer {
        interval: 30000; repeat: true; running: true
        onTriggered: store.tick++
    }

    Component.onCompleted: init()

    // ------------------------------------------------------------------ setup

    function newId() { return Api.uuid(); }

    /** Api.call with a 25 s watchdog so a stalled request can never leave a page stuck on "Creating...". */
    function request(body, cb) {
        var finished = false;
        var timer = Qt.createQmlObject('import QtQuick 2.12; Timer { interval: 25000 }', store, "reqTimeout");
        var finish = function (err, data) {
            if (finished) return;
            finished = true;
            timer.stop();
            timer.destroy();
            try { cb(err, data); } catch (e) { console.log("Vanish callback error: " + e); }
        };
        timer.triggered.connect(function () { finish("network", null); });
        timer.start();
        try { Api.call(apiUrl, body, finish); } catch (e) { finish("network", null); }
    }

    function init() {
        deviceId = Db.getSetting("deviceId", "");
        if (!deviceId) { deviceId = newId(); Db.setSetting("deviceId", deviceId); }
        displayName = Db.getSetting("displayName", "");
        theme = Db.getSetting("theme", "system");
        apiUrl = Db.getSetting("apiUrl", Config.API_URL);
        alerts = Db.getSetting("alerts", "1") === "1";

        // Drop expired chats that were not kept (e.g. they expired while the app was closed).
        Db.chats().forEach(function (c) {
            if (c.status !== "active" && !c.kept) Db.deleteChat(c.chatId);
        });
        refreshChats();
        ready = true;

        request({ action: "register", deviceId: deviceId, platform: "ubuntu-touch",
                           version: Config.APP_VERSION }, function () {});
        syncAll();
    }

    function setTheme(v) { theme = v; Db.setSetting("theme", v); }
    function setDisplayName(v) { displayName = v.trim(); Db.setSetting("displayName", displayName); }
    function setApiUrl(v) { apiUrl = v.trim(); Db.setSetting("apiUrl", apiUrl); }
    function setAlerts(v) { alerts = v; Db.setSetting("alerts", v ? "1" : "0"); }

    // ------------------------------------------------------------------ local model

    /** Row for the home list: fills lastText / lastName / lastTs from the newest stored message. */
    function _withPreview(r) {
        var text = r.pvText, name = "";
        if (text === null || text === undefined) {
            text = "";
        } else if (r.pvKind === "msg") {
            if (r.pvUid === r.myUid) name = "You";
            else {
                try { var m = JSON.parse(r.members || "{}")[r.pvUid]; name = m ? m.n : ""; } catch (e) {}
            }
        } else if (r.myName && text.indexOf(r.myName + " ") === 0) {
            text = "You" + text.substring(r.myName.length);       // "Sam joined" -> "You joined"
        }
        r.lastText = text;
        r.lastName = name;
        r.lastTs = r.pvTs || 0;
        delete r.pvText; delete r.pvKind; delete r.pvUid; delete r.pvTs;
        return r;
    }

    function refreshChats() {
        var rows = Db.chats(), unread = 0;
        chatModel.clear();
        for (var i = 0; i < rows.length; i++) {
            chatModel.append(_withPreview(rows[i]));
            unread += rows[i].unread;
        }
        totalUnread = unread;
        listUpdated();
    }

    function getChat(id) { return Db.chat(id); }

    /** [{uid, n, c, r, l}] */
    function membersOf(id) {
        var c = Db.chat(id), out = [];
        if (!c) return out;
        var m = {};
        try { m = JSON.parse(c.members || "{}"); } catch (e) {}
        for (var k in m) out.push({ uid: k, n: m[k].n, c: m[k].c, r: m[k].r, l: m[k].l });
        return out;
    }

    function isExpired(c) {
        return c.status !== "active" || (c.expiresAt > 0 && c.expiresAt <= Date.now());
    }

    function setKept(id, v)   { Db.updateChat(id, { kept: v ? 1 : 0 });   refreshChats(); chatUpdated(id); }
    function setMuted(id, v)  { Db.updateChat(id, { muted: v ? 1 : 0 });  refreshChats(); chatUpdated(id); }
    function setPinned(id, v) { Db.updateChat(id, { pinned: v ? 1 : 0 }); refreshChats(); chatUpdated(id); }

    function deleteLocal(id) { Db.deleteChat(id); refreshChats(); chatUpdated(id); }

    function clearAll() { Db.wipe(); openChatId = ""; refreshChats(); }

    function findByCode(code) {
        var norm = String(code).toUpperCase().replace(/[^A-Z0-9]/g, "");
        var r = Db.all("SELECT chatId FROM chats WHERE code=? AND status='active'", [norm]);
        return r.length ? r[0].chatId : "";
    }

    // ------------------------------------------------------------------ open / close

    function openChat(id) {
        openChatId = id;
        var c = Db.chat(id);
        if (c) { Db.updateChat(id, { readSeq: c.lastSeq, unread: 0 }); refreshChats(); }
        syncOpen();
    }

    function closeChat() {
        var id = openChatId;
        openChatId = "";
        var c = id ? Db.chat(id) : null;
        if (c && c.status !== "active" && !c.kept) Db.deleteChat(id);
        refreshChats();
    }

    // ------------------------------------------------------------------ server actions

    function _saveFromView(v, uid, display) {
        var mine = v.members && v.members[uid] ? v.members[uid].n : display;
        var existing = Db.chat(v.chatId);
        var fields = { name: v.name, code: v.code, expiresAt: v.expiresAt, memberCount: v.memberCount,
                       members: JSON.stringify(v.members), isPublic: v.isPublic ? 1 : 0, status: "active" };
        if (existing) { Db.updateChat(v.chatId, fields); return; }
        Db.insertChat({ chatId: v.chatId, code: v.code, name: v.name, myUid: uid, myName: mine,
                        createdAt: v.createdAt, expiresAt: v.expiresAt, status: "active",
                        memberCount: v.memberCount, members: fields.members, isPublic: v.isPublic });
    }

    function createChat(name, display, isPublic, cb) {
        var uid = newId();
        request({ action: "createChat", deviceId: deviceId, uid: uid, display: display,
                           name: name, isPublic: isPublic }, function (err, v) {
            if (err) { cb(err, ""); return; }
            _saveFromView(v, uid, display);
            refreshChats();
            syncItems([{ chatId: v.chatId, uid: uid, after: 0, read: 0 }], function () { cb(null, v.chatId); });
        });
    }

    function joinChat(code, display, cb) {
        var have = findByCode(code);
        if (have) { cb(null, have); return; }
        var uid = newId();
        request({ action: "joinChat", deviceId: deviceId, uid: uid, display: display,
                           code: code }, function (err, v) {
            if (err) { cb(err, ""); return; }
            _saveFromView(v, uid, display);
            refreshChats();
            syncItems([{ chatId: v.chatId, uid: uid, after: 0, read: 0 }], function () { cb(null, v.chatId); });
        });
    }

    function sendMessage(chatId, text, cb) {
        var c = Db.chat(chatId);
        if (!c) { cb("not_found"); return; }
        request({ action: "send", uid: c.myUid, chatId: chatId, text: text }, function (err, m) {
            if (err) { cb(err); return; }
            // Stored without touching lastSeq so the next sync still fetches anything older from others.
            Db.insertMessages(chatId, [{ s: m.s, t: m.t, u: m.u, k: m.k, x: m.x }]);
            Db.updateChat(chatId, { lastText: m.x, lastName: c.myName, lastTs: m.t });
            refreshChats();
            chatUpdated(chatId);
            cb(null);
        });
    }

    function leaveChat(id, cb) {
        var c = Db.chat(id);
        if (!c) { cb(null); return; }
        var finish = function () {
            if (c.kept) Db.updateChat(id, { status: "left", unread: 0 }); else Db.deleteChat(id);
            if (openChatId === id) openChatId = "";
            refreshChats(); chatUpdated(id); cb(null);
        };
        if (isExpired(c)) { finish(); return; }
        request({ action: "leave", uid: c.myUid, chatId: id }, function (err) {
            if (err && err !== "not_found") { cb(err); return; }
            finish();
        });
    }

    function publicList(q, cb) {
        request({ action: "publicList", q: q || "" }, cb);
    }

    // ------------------------------------------------------------------ sync

    function _item(c) {
        return { chatId: c.chatId, uid: c.myUid, after: c.lastSeq,
                 read: c.chatId === openChatId ? c.lastSeq : c.readSeq };
    }

    function syncOpen() {
        if (!openChatId || _fastBusy) return;
        var c = Db.chat(openChatId);
        if (!c || c.status !== "active") return;
        _fastBusy = true;
        syncItems([_item(c)], function () { _fastBusy = false; });
    }

    function syncAll() {
        if (_slowBusy) return;
        var items = [];
        Db.chats().forEach(function (c) {
            if (c.status === "active" && c.chatId !== openChatId) items.push(_item(c));
        });
        if (!items.length) return;
        _slowBusy = true;
        var batches = [];
        while (items.length) batches.push(items.splice(0, 12));
        var next = function () {
            if (!batches.length) { _slowBusy = false; return; }
            syncItems(batches.shift(), next);
        };
        next();
    }

    function syncItems(items, done) {
        if (!items.length) { if (done) done(null); return; }
        request({ action: "sync", items: items }, function (err, res) {
            if (!err && res) for (var i = 0; i < res.length; i++) _apply(res[i]);
            if (done) done(err);
        });
    }

    function _markEnded(c, status) {
        if (c.kept || c.chatId === openChatId) {
            Db.updateChat(c.chatId, { status: status, unread: 0 });
        } else {
            Db.deleteChat(c.chatId);
            if (alerts) toast("“" + c.name + "” expired and was removed");
        }
        refreshChats();
        chatUpdated(c.chatId);
    }

    function _apply(r) {
        if (!r || !r.chatId) return;
        var c = Db.chat(r.chatId);
        if (!c) return;
        if (r.status === "expired" || r.status === "gone") { _markEnded(c, "expired"); return; }
        if (r.status === "left") { _markEnded(c, "left"); return; }
        if (r.status !== "active") return;

        var msgs = r.messages || [], open = c.chatId === openChatId;
        Db.insertMessages(c.chatId, msgs);

        var membersJson = JSON.stringify(r.members);
        var f = { name: r.name, expiresAt: r.expiresAt, memberCount: r.memberCount, members: membersJson,
                  isPublic: r.isPublic ? 1 : 0 };
        var lastSeq = c.lastSeq, add = 0, last = null;
        for (var i = 0; i < msgs.length; i++) {
            var m = msgs[i];
            if (m.s > lastSeq) lastSeq = m.s;
            if (m.k === "msg") {
                last = m;
                if (m.u !== c.myUid) add++;
            }
        }
        f.lastSeq = lastSeq;
        if (last) {
            var who = r.members[last.u];
            f.lastText = last.x; f.lastName = who ? who.n : "?"; f.lastTs = last.t;
        }
        if (open) { f.readSeq = lastSeq; f.unread = 0; }
        else if (add) f.unread = c.unread + add;
        Db.updateChat(c.chatId, f);

        if (add && !open && !c.muted && alerts && last)
            toast(c.name + " • " + f.lastName + ": " + last.x.substring(0, 80));

        if (msgs.length || membersJson !== c.members || r.name !== c.name) {
            if (msgs.length || r.name !== c.name || r.memberCount !== c.memberCount) refreshChats();
            chatUpdated(c.chatId);
        }
    }
}
