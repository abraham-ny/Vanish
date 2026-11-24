.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

var _db = null;

function db() {
    if (!_db) {
        _db = Sql.LocalStorage.openDatabaseSync("vanish", "", "Vanish local data", 5 * 1024 * 1024);
        _db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS settings(k TEXT PRIMARY KEY, v TEXT)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS chats(" +
                "chatId TEXT PRIMARY KEY, code TEXT, name TEXT, myUid TEXT, myName TEXT, " +
                "createdAt INTEGER, expiresAt INTEGER, status TEXT, " +
                "kept INTEGER DEFAULT 0, pinned INTEGER DEFAULT 0, muted INTEGER DEFAULT 0, " +
                "lastSeq INTEGER DEFAULT 0, readSeq INTEGER DEFAULT 0, unread INTEGER DEFAULT 0, " +
                "memberCount INTEGER DEFAULT 0, members TEXT DEFAULT '{}', " +
                "lastText TEXT DEFAULT '', lastName TEXT DEFAULT '', lastTs INTEGER DEFAULT 0, " +
                "isPublic INTEGER DEFAULT 0)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS messages(" +
                "chatId TEXT, seq INTEGER, ts INTEGER, uid TEXT, kind TEXT, text TEXT, " +
                "PRIMARY KEY(chatId, seq))");
        });
    }
    return _db;
}

function all(sql, args) {
    var out = [];
    db().readTransaction(function (tx) {
        var rs = tx.executeSql(sql, args || []);
        for (var i = 0; i < rs.rows.length; i++) {
            var r = rs.rows.item(i), o = {};
            for (var k in r) o[k] = r[k];
            out.push(o);
        }
    });
    return out;
}

function run(sql, args) {
    db().transaction(function (tx) { tx.executeSql(sql, args || []); });
}

/* ---- settings */

function getSetting(key, def) {
    var r = all("SELECT v FROM settings WHERE k=?", [key]);
    return r.length ? r[0].v : def;
}

function setSetting(key, value) {
    run("INSERT OR REPLACE INTO settings(k, v) VALUES(?, ?)", [key, String(value)]);
}

/* ---- chats */

/**
 * Chats for the home list. The preview (last message of ANY kind, incl. "x joined") is read straight from the
 * messages table, so it always matches what the chat screen shows.
 */
function chats() {
    return all("SELECT c.*, " +
        "(SELECT text FROM messages m WHERE m.chatId = c.chatId ORDER BY m.seq DESC LIMIT 1) AS pvText, " +
        "(SELECT kind FROM messages m WHERE m.chatId = c.chatId ORDER BY m.seq DESC LIMIT 1) AS pvKind, " +
        "(SELECT uid  FROM messages m WHERE m.chatId = c.chatId ORDER BY m.seq DESC LIMIT 1) AS pvUid, " +
        "(SELECT ts   FROM messages m WHERE m.chatId = c.chatId ORDER BY m.seq DESC LIMIT 1) AS pvTs " +
        "FROM chats c ORDER BY c.pinned DESC, " +
        "CASE WHEN COALESCE(pvTs, 0) > c.createdAt THEN pvTs ELSE c.createdAt END DESC");
}

function chat(id) {
    var r = all("SELECT * FROM chats WHERE chatId=?", [id]);
    return r.length ? r[0] : null;
}

function insertChat(c) {
    run("INSERT OR REPLACE INTO chats(chatId, code, name, myUid, myName, createdAt, expiresAt, status, " +
        "kept, pinned, muted, lastSeq, readSeq, unread, memberCount, members, lastText, lastName, lastTs, isPublic) " +
        "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        [c.chatId, c.code, c.name, c.myUid, c.myName, c.createdAt, c.expiresAt, c.status || "active",
         c.kept || 0, c.pinned || 0, c.muted || 0, c.lastSeq || 0, c.readSeq || 0, c.unread || 0,
         c.memberCount || 0, c.members || "{}", c.lastText || "", c.lastName || "", c.lastTs || 0, c.isPublic ? 1 : 0]);
}

/** fields: {column: value}; column names come from code, never from user input. */
function updateChat(id, fields) {
    var cols = [], vals = [];
    for (var k in fields) { cols.push(k + "=?"); vals.push(fields[k]); }
    if (!cols.length) return;
    vals.push(id);
    run("UPDATE chats SET " + cols.join(", ") + " WHERE chatId=?", vals);
}

function deleteChat(id) {
    db().transaction(function (tx) {
        tx.executeSql("DELETE FROM messages WHERE chatId=?", [id]);
        tx.executeSql("DELETE FROM chats WHERE chatId=?", [id]);
    });
}

/* ---- messages */

function insertMessages(chatId, list) {
    if (!list.length) return;
    db().transaction(function (tx) {
        for (var i = 0; i < list.length; i++) {
            var m = list[i];
            tx.executeSql("INSERT OR IGNORE INTO messages(chatId, seq, ts, uid, kind, text) VALUES(?,?,?,?,?,?)",
                [chatId, m.s, m.t, m.u, m.k, m.x]);
        }
    });
}

/** Newest first. */
function messages(chatId, limit) {
    return all("SELECT seq, ts, uid, kind, text FROM messages WHERE chatId=? ORDER BY seq DESC LIMIT ?",
        [chatId, limit || 300]);
}

function messagesAfter(chatId, seq) {
    return all("SELECT seq, ts, uid, kind, text FROM messages WHERE chatId=? AND seq>? ORDER BY seq DESC",
        [chatId, seq]);
}

function wipe() {
    db().transaction(function (tx) {
        tx.executeSql("DELETE FROM messages");
        tx.executeSql("DELETE FROM chats");
    });
}
