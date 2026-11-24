import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../lib"
import "../components"
import "../js/api.js" as Api
import "../js/db.js" as Db
import "../js/text.js" as Txt

Page {
    id: page
    property string chatId: ""
    property var chat: null
    property int rev: 0                 // bumped whenever members / read state change
    property var memberMap: ({})
    property var mentionNames: []
    property string mentionQuery: ""
    property int mentionAt: -1
    property bool sending: false

    readonly property string myUid: chat ? chat.myUid : ""
    readonly property bool ended: { Store.tick; return chat ? Store.isExpired(chat) : true; }

    // ------------------------------------------------------------ data
    function member(uid) { return memberMap[uid] || { n: "?", c: "#888888", r: 0, l: 1 }; }

    /** Current members (not the author) that have read up to `seq`. */
    function readers(seq, authorUid) {
        var out = [];
        for (var k in memberMap) {
            var m = memberMap[k];
            if (k !== authorUid && !m.l && m.r >= seq) out.push(m);
        }
        return out;
    }

    function load() {
        var c = Store.getChat(chatId);
        if (!c) { Nav.pop(); return false; }
        chat = c;
        try { memberMap = JSON.parse(c.members || "{}"); } catch (e) { memberMap = {}; }
        var names = [];
        for (var k in memberMap) if (!memberMap[k].l) names.push(memberMap[k].n);
        mentionNames = names;
        rev++;
        return true;
    }

    function reload() {
        var rows = Db.messages(chatId, 300), diff = rows.length - msgs.count, i;
        if (diff === 0 && (rows.length === 0 || rows[0].seq === msgs.get(0).seq)) { rev++; return; }
        if (diff > 0 && msgs.count > 0 && rows[diff].seq === msgs.get(0).seq) {
            for (i = diff - 1; i >= 0; i--) msgs.insert(0, rows[i]);   // newest first (list is bottom-to-top)
        } else {
            msgs.clear();
            for (i = 0; i < rows.length; i++) msgs.append(rows[i]);
        }
        rev++;
    }

    function showReaders(msg) {
        var done = readers(msg.seq, msg.uid), entries = [], seen = {}, k;
        done.forEach(function (m) { entries.push({ name: m.n, color: m.c, note: "✓" }); });
        for (k in memberMap) {
            var m = memberMap[k];
            if (k === msg.uid || m.l || m.r >= msg.seq) continue;
            entries.push({ name: m.n, color: Style.divider, note: i18n.tr("not yet") });
        }
        PopupUtils.open(Qt.resolvedUrl("../components/ListDialog.qml"), page, {
            title: i18n.tr("Read by %1").arg(done.length), entries: entries,
            emptyText: i18n.tr("Nobody has read this yet.") });
    }

    function showMembers() {
        var entries = [];
        for (var k in memberMap) {
            var m = memberMap[k];
            if (m.l) continue;
            entries.push({ name: m.n, color: m.c, note: k === myUid ? i18n.tr("you") : "" });
        }
        PopupUtils.open(Qt.resolvedUrl("../components/ListDialog.qml"), page, {
            title: i18n.tr("Members (%1)").arg(entries.length), entries: entries });
    }

    function updateMention(text) {
        var at = text.lastIndexOf("@");
        mentionAt = -1; mentionQuery = "";
        if (at < 0 || (at > 0 && !/\s/.test(text.charAt(at - 1)))) return;
        var q = text.substring(at + 1);
        if (q.length > 24 || q.indexOf("\n") >= 0) return;
        mentionAt = at; mentionQuery = q;
    }

    readonly property var mentionMatches: {
        rev;
        var out = [];
        if (mentionAt < 0) return out;
        var q = mentionQuery.toLowerCase();
        for (var k in memberMap) {
            var m = memberMap[k];
            if (m.l || k === myUid) continue;
            var n = m.n.toLowerCase();
            if (n.indexOf(q) === 0 && n !== q) out.push(m);
        }
        return out.slice(0, 8);
    }

    function pickMention(name) {
        input.text = input.text.substring(0, mentionAt) + "@" + name + " ";
        input.cursorPosition = input.text.length;
        mentionAt = -1;
        input.forceActiveFocus();
    }

    function send() {
        var t = input.text.trim();
        if (!t || sending || ended) return;
        sending = true;
        input.text = "";
        Store.sendMessage(chatId, t, function (err) {
            sending = false;
            if (err) {
                input.text = t;
                Store.toast(Api.friendly(err));
            }
        });
    }

    function confirmLeave() {
        PopupUtils.open(leaveDialog, page);
    }

    property bool inviteOnOpen: false

    Component.onCompleted: {
        if (load()) {
            reload();
            Store.openChat(chatId);
            if (inviteOnOpen)
                PopupUtils.open(Qt.resolvedUrl("../components/InviteDialog.qml"), page,
                                { code: chat.code, chatName: chat.name });
        }
    }
    Component.onDestruction: Store.closeChat()

    Connections {
        target: Store
        onChatUpdated: { if (chatId === page.chatId) { if (page.load()) page.reload(); } }
    }

    ListModel { id: msgs }

    // ------------------------------------------------------------ header
    header: PageHeader {
        title: chat ? chat.name : ""
        subtitle: {
            Store.tick;
            if (!chat) return "";
            var n = chat.memberCount + (chat.memberCount === 1 ? " member" : " members");
            return n + " • " + (page.ended ? "read-only" : Txt.fmtLeft(chat.expiresAt));
        }
        StyleHints {
            foregroundColor: Style.primaryText
            backgroundColor: Style.primary
            dividerColor: Style.primaryDeep
        }
        trailingActionBar {
            numberOfSlots: 3
            actions: [
                Action {
                    iconName: "share"
                    text: i18n.tr("Invite")
                    visible: !!chat && !page.ended
                    onTriggered: PopupUtils.open(Qt.resolvedUrl("../components/InviteDialog.qml"), page,
                                                 { code: chat.code, chatName: chat.name })
                },
                Action {
                    iconName: "contact-group"
                    text: i18n.tr("Members")
                    onTriggered: page.showMembers()
                },
                Action {
                    iconName: chat && chat.muted ? "audio-volume-high" : "audio-volume-muted"
                    text: chat && chat.muted ? i18n.tr("Unmute") : i18n.tr("Mute")
                    onTriggered: Store.setMuted(chatId, !chat.muted)
                },
                Action {
                    iconName: chat && chat.pinned ? "unpinned" : "pinned"
                    text: chat && chat.pinned ? i18n.tr("Unpin") : i18n.tr("Pin")
                    onTriggered: Store.setPinned(chatId, !chat.pinned)
                },
                Action {
                    iconName: page.ended ? "delete" : "system-log-out"
                    text: page.ended ? i18n.tr("Delete from device") : i18n.tr("Leave chat")
                    onTriggered: page.confirmLeave()
                }
            ]
        }
    }

    // ------------------------------------------------------------ keep / expiry banner
    Rectangle {
        id: banner
        anchors { top: page.header.bottom; left: parent.left; right: parent.right }
        height: visible ? units.gu(4.6) : 0
        visible: !!chat && (page.ended || chat.expiresAt > 0)
        color: Style.chipBg

        Label {
            anchors { left: parent.left; leftMargin: units.gu(1.5); right: keepBtn.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
            fontSize: "small"
            elide: Text.ElideRight
            color: Style.text
            text: {
                Store.tick;
                if (!chat) return "";
                if (page.ended) return chat.kept ? i18n.tr("Ended • kept on this device, read-only")
                                                 : i18n.tr("Ended • removed when you leave unless kept");
                return chat.kept ? i18n.tr("Disappears %1 • will be kept on this device").arg(Txt.fmtLeft(chat.expiresAt))
                                 : i18n.tr("Disappears for everyone: %1").arg(Txt.fmtLeft(chat.expiresAt));
            }
        }
        Label {
            id: keepBtn
            anchors { right: parent.right; rightMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
            text: chat && chat.kept ? "★ " + i18n.tr("Kept") : "☆ " + i18n.tr("Keep chat")
            color: Style.primary
            font.bold: true
            fontSize: "small"
            MouseArea {
                anchors { fill: parent; margins: -units.gu(1) }
                onClicked: Store.setKept(chatId, !chat.kept)
            }
        }
    }

    // ------------------------------------------------------------ messages
    Rectangle { anchors.fill: parent; color: Style.bg; z: -1 }

    ListView {
        id: list
        anchors { top: banner.bottom; left: parent.left; right: parent.right; bottom: mentionBar.top }
        clip: true
        verticalLayoutDirection: ListView.BottomToTop   // index 0 (newest) sits at the bottom
        model: msgs
        delegate: MessageBubble {
            msg: ({ seq: model.seq, ts: model.ts, uid: model.uid, kind: model.kind, text: model.text })
            chatPage: page
        }
        header: Item { height: units.gu(1) }
        footer: Item { height: units.gu(1) }
    }

    Label {
        anchors.centerIn: list
        visible: msgs.count === 0
        text: i18n.tr("No messages yet.\nSay hi 👋")
        horizontalAlignment: Text.AlignHCenter
        color: Style.subtext
    }

    // ------------------------------------------------------------ @mention suggestions
    Rectangle {
        id: mentionBar
        anchors { left: parent.left; right: parent.right; bottom: composer.top }
        height: page.mentionMatches.length > 0 ? units.gu(5) : 0
        visible: height > 0
        color: Style.surface

        ListView {
            anchors { fill: parent; leftMargin: units.gu(1); rightMargin: units.gu(1) }
            orientation: ListView.Horizontal
            spacing: units.gu(1)
            clip: true
            model: page.mentionMatches
            delegate: Rectangle {
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                height: units.gu(3.6)
                width: nm.implicitWidth + units.gu(3.6)
                radius: height / 2
                color: Style.chipBg
                Row {
                    anchors.centerIn: parent
                    spacing: units.gu(0.8)
                    Rectangle { width: units.gu(1.4); height: width; radius: width / 2; color: modelData.c; anchors.verticalCenter: parent.verticalCenter }
                    Label { id: nm; text: "@" + modelData.n; color: Style.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: page.pickMention(modelData.n) }
            }
        }
    }

    // ------------------------------------------------------------ composer
    Rectangle {
        id: composer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: units.gu(7)
        color: Style.surface

        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Style.divider }

        Label {
            visible: page.ended
            anchors.centerIn: parent
            text: i18n.tr("This chat is read-only")
            color: Style.subtext
        }

        Row {
            visible: !page.ended
            anchors { fill: parent; margins: units.gu(1) }
            spacing: units.gu(1)

            TextField {
                id: input
                width: parent.width - sendBtn.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: i18n.tr("Message (type @ to mention)")
                maximumLength: 500
                onTextChanged: page.updateMention(text)
                onAccepted: page.send()
            }
            Rectangle {
                id: sendBtn
                width: units.gu(5); height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: input.text.trim() && !page.sending ? Style.primary : Style.divider
                Icon { anchors.centerIn: parent; width: units.gu(2.6); height: width; name: "send"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: page.send() }
            }
        }
    }

    // ------------------------------------------------------------ dialogs
    Component {
        id: leaveDialog
        Dialog {
            id: dlg
            title: page.ended ? i18n.tr("Delete from this device?") : i18n.tr("Leave this chat?")
            text: page.ended ? i18n.tr("The local copy will be removed.")
                             : i18n.tr("You will stop receiving messages. Others will see that you left.")
            Button {
                text: page.ended ? i18n.tr("Delete") : i18n.tr("Leave")
                color: Style.danger
                onClicked: {
                    PopupUtils.close(dlg);
                    if (page.ended) { Store.deleteLocal(page.chatId); return; }
                    Store.leaveChat(page.chatId, function (err) {
                        if (err) Store.toast(Api.friendly(err)); else Nav.pop();
                    });
                }
            }
            Button { text: i18n.tr("Cancel"); onClicked: PopupUtils.close(dlg) }
        }
    }
}
