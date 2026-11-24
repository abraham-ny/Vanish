import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../lib"
import "../components"
import "../js/api.js" as Api
import "../js/text.js" as Txt

Page {
    id: page
    property string query: ""
    property bool fabOpen: false
    property bool loadingPublic: false
    property string publicError: ""
    property var publicChats: []

    readonly property bool showPublic: sections.selectedIndex === 1

    // ---- open a chat
    // chatIds I am currently a member of (drives the "Joined" state in the public list)
    property var joinedIds: ({})
    function rebuildJoined() {
        var ids = {};
        for (var i = 0; i < Store.chats.count; i++) {
            var r = Store.chats.get(i);
            if (r.status === "active") ids[r.chatId] = true;
        }
        joinedIds = ids;
    }
    Component.onCompleted: rebuildJoined()
    onActiveChanged: { if (active) Store.refreshChats(); }
    Connections { target: Store; onListUpdated: page.rebuildJoined() }

    function open(id) { Nav.push(Qt.resolvedUrl("ChatPage.qml"), { chatId: id }); }

    function matches(row, q) {
        q = q.toLowerCase();
        var codeQ = q.replace(/[^a-z0-9]/g, "");
        if (row.name.toLowerCase().indexOf(q) >= 0) return true;
        if (codeQ !== "" && row.code.toLowerCase().indexOf(codeQ) >= 0) return true;
        return (row.lastText || "").toLowerCase().indexOf(q) >= 0;
    }

    function suggestions() {
        var out = [], q = query.trim();
        if (!q) return out;
        for (var i = 0; i < Store.chats.count && out.length < 6; i++) {
            var r = Store.chats.get(i);
            if (matches(r, q)) out.push({ chatId: r.chatId, name: r.name, code: r.code });
        }
        return out;
    }

    function loadPublic() {
        loadingPublic = true; publicError = "";
        Store.publicList(showPublic ? query.trim() : "", function (err, list) {
            loadingPublic = false;
            if (err) { publicError = Api.friendly(err); return; }
            publicChats = list || [];
        });
    }

    function confirmRemove(id, name, ended) {
        PopupUtils.open(removeDialog, page, { chatId: id, chatName: name, ended: ended });
    }

    // ------------------------------------------------------------ header
    header: PageHeader {
        title: "Vanish"
        StyleHints { foregroundColor: Style.primaryText; backgroundColor: Style.primary; dividerColor: Style.primaryDeep }
        trailingActionBar.actions: [
            Action { iconName: "settings"; text: i18n.tr("Settings"); onTriggered: Nav.push(Qt.resolvedUrl("SettingsPage.qml")) },
            Action { iconName: "info"; text: i18n.tr("About"); onTriggered: Nav.push(Qt.resolvedUrl("AboutPage.qml")) },
            Action {
                iconName: "message"; text: i18n.tr("Feedback chat")
                onTriggered: Nav.push(Qt.resolvedUrl("JoinPage.qml"), { code: "FEEDBACK", chatName: i18n.tr("Feedback") })
            }
        ]
        extension: Sections {
            id: sections
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: units.gu(1) }
            model: [i18n.tr("Chats"), i18n.tr("Public")]
            StyleHints { selectedSectionColor: Style.primaryText; sectionColor: "#CFE6FF" }
            onSelectedIndexChanged: { if (selectedIndex === 1) page.loadPublic(); }
        }
    }

    Rectangle { anchors.fill: parent; color: Style.bg; z: -1 }

    // ------------------------------------------------------------ search
    Rectangle {
        id: searchBar
        anchors { top: page.header.bottom; left: parent.left; right: parent.right }
        height: units.gu(6.5)
        color: Style.bg
        z: 5

        TextField {
            id: search
            anchors { fill: parent; margins: units.gu(1) }
            placeholderText: page.showPublic ? i18n.tr("Search public chats") : i18n.tr("Search chats by name, code or text")
            inputMethodHints: Qt.ImhNoPredictiveText
            onTextChanged: {
                page.query = text;
                if (page.showPublic) publicDebounce.restart();
            }
            // clear button
            primaryItem: Icon { width: units.gu(2.2); height: width; name: "find"; color: Style.subtext }
        }
        Timer { id: publicDebounce; interval: 500; onTriggered: page.loadPublic() }
    }

    // dropdown suggestions (my chats only)
    Rectangle {
        id: dropdown
        z: 20
        visible: search.activeFocus && !page.showPublic && page.query.trim() !== ""
        anchors { top: searchBar.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(1); rightMargin: units.gu(1) }
        height: visible ? Math.max(units.gu(5), sugg.count * units.gu(5.5)) : 0
        radius: units.gu(1)
        color: Style.surface
        border.color: Style.divider

        ListView {
            id: sugg
            anchors.fill: parent
            interactive: false
            model: { page.query; Store.chats.count; return page.suggestions(); }
            delegate: Item {
                width: ListView.view.width; height: units.gu(5.5)
                Row {
                    anchors { fill: parent; leftMargin: units.gu(1.5); rightMargin: units.gu(1.5) }
                    spacing: units.gu(1.2)
                    Avatar { anchors.verticalCenter: parent.verticalCenter; size: units.gu(3.6); label: modelData.name; tint: Txt.hashColor(modelData.chatId) }
                    Label { anchors.verticalCenter: parent.verticalCenter; width: parent.width - units.gu(5); text: modelData.name; elide: Text.ElideRight; color: Style.text }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { search.focus = false; search.text = ""; page.open(modelData.chatId); }
                }
            }
        }
        Label {
            visible: sugg.count === 0
            anchors.centerIn: parent
            text: i18n.tr("No matching chats")
            color: Style.subtext
        }
    }

    // ------------------------------------------------------------ my chats
    ListView {
        id: myList
        visible: !page.showPublic
        anchors { top: searchBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: Store.chats
        delegate: ChatRow {
            visible: page.query.trim() === "" || page.matches(model, page.query.trim())
            height: visible ? units.gu(9) : 0
            c: ({ chatId: model.chatId, code: model.code, name: model.name, status: model.status,
                  expiresAt: model.expiresAt, kept: model.kept, pinned: model.pinned, muted: model.muted,
                  unread: model.unread, memberCount: model.memberCount, lastText: model.lastText,
                  lastName: model.lastName, lastTs: model.lastTs, createdAt: model.createdAt })
            onOpen: page.open(model.chatId)
            onTogglePin: Store.setPinned(model.chatId, !model.pinned)
            onToggleMute: Store.setMuted(model.chatId, !model.muted)
            onRemove: page.confirmRemove(model.chatId, model.name, Store.isExpired(c))
        }
        footer: Item { height: units.gu(11) }

        Column {
            visible: Store.chats.count === 0
            anchors.centerIn: parent
            width: parent.width - units.gu(8)
            spacing: units.gu(1)
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "💨"; font.pixelSize: units.gu(6) }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: i18n.tr("No chats yet")
                font.bold: true; color: Style.text
            }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: i18n.tr("Tap + to start a temporary chat or join one with a code. No account, no trace after 24 hours.")
                color: Style.subtext; fontSize: "small"
            }
        }
    }

    // ------------------------------------------------------------ public chats
    ListView {
        id: pubList
        visible: page.showPublic
        anchors { top: searchBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: page.publicChats
        delegate: ListItem {
            height: units.gu(8.5)
            divider.colorFrom: Style.divider
            divider.colorTo: Style.divider
            readonly property bool joined: page.joinedIds[modelData.chatId] === true
            onClicked: {
                if (joined) page.open(modelData.chatId);
                else Nav.push(Qt.resolvedUrl("JoinPage.qml"), { code: modelData.code, chatName: modelData.name });
            }
            Row {
                anchors { fill: parent; leftMargin: units.gu(1.5); rightMargin: units.gu(1.5) }
                spacing: units.gu(1.5)
                Item {
                    width: units.gu(6); height: parent.height
                    Avatar { anchors.centerIn: parent; label: modelData.name; size: units.gu(5.6); tint: Txt.hashColor(modelData.chatId) }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - units.gu(6) - joinLabel.width - units.gu(3)
                    spacing: units.gu(0.4)
                    Label { width: parent.width; text: modelData.name; font.bold: true; elide: Text.ElideRight; color: Style.text }
                    Label {
                        width: parent.width; fontSize: "small"; color: Style.subtext; elide: Text.ElideRight
                        text: modelData.memberCount + " members • " + modelData.msgCount + " messages • " + Txt.fmtLeft(modelData.expiresAt)
                    }
                }
                Label {
                    id: joinLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: joined ? "\u2713 " + i18n.tr("Joined") : i18n.tr("Join")
                    color: joined ? Style.subtext : Style.primary
                    font.bold: true
                }
            }
        }
        PullToRefresh {
            refreshing: page.loadingPublic
            onRefresh: page.loadPublic()
        }
        footer: Item { height: units.gu(11) }

        Label {
            visible: !page.loadingPublic && page.publicChats.length === 0
            anchors.centerIn: parent
            width: parent.width - units.gu(8)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: page.publicError ? Style.danger : Style.subtext
            text: page.publicError || i18n.tr("No public chats right now.\nCreate one and switch on “List in Public chats”.")
        }
        ActivityIndicator { anchors.centerIn: parent; running: page.loadingPublic && page.publicChats.length === 0 }
    }

    // ------------------------------------------------------------ floating + button
    MouseArea {
        anchors.fill: parent
        visible: page.fabOpen
        z: 30
        onClicked: page.fabOpen = false
        Rectangle { anchors.fill: parent; color: "#66000000" }
    }

    Column {
        id: fabMenu
        z: 31
        visible: page.fabOpen
        anchors { right: parent.right; rightMargin: units.gu(2.5); bottom: fab.top; bottomMargin: units.gu(1.5) }
        spacing: units.gu(1.2)

        Repeater {
            model: [
                { label: i18n.tr("Join with code"), icon: "contact-new", action: "join" },
                { label: i18n.tr("New chat"), icon: "add", action: "new" }
            ]
            delegate: Item {
                anchors.right: parent.right
                width: pillRow.width; height: pillRow.height
                Row {
                    id: pillRow
                    spacing: units.gu(1.2)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: units.gu(4); width: pill.implicitWidth + units.gu(3); radius: height / 2
                        color: Style.surface
                        Label { id: pill; anchors.centerIn: parent; text: modelData.label; color: Style.text }
                    }
                    Rectangle {
                        width: units.gu(5.5); height: width; radius: width / 2
                        color: Style.surface
                        border.color: Style.primary
                        Icon { anchors.centerIn: parent; width: units.gu(2.6); height: width; name: modelData.icon; color: Style.primary }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        page.fabOpen = false;
                        Nav.push(Qt.resolvedUrl(modelData.action === "new" ? "NewChatPage.qml" : "JoinPage.qml"));
                    }
                }
            }
        }
    }

    Rectangle {
        id: fab
        z: 32
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: units.gu(2.5); bottomMargin: units.gu(2.5) }
        width: units.gu(7.5); height: width; radius: width / 2
        color: Style.primary
        rotation: page.fabOpen ? 45 : 0
        Behavior on rotation { NumberAnimation { duration: 150 } }

        Icon { anchors.centerIn: parent; width: units.gu(3.4); height: width; name: "add"; color: "white" }
        MouseArea { anchors.fill: parent; onClicked: page.fabOpen = !page.fabOpen }
    }

    // ------------------------------------------------------------ dialogs
    Component {
        id: removeDialog
        Dialog {
            id: dlg
            property string chatId
            property string chatName
            property bool ended
            title: ended ? i18n.tr("Delete “%1”?").arg(chatName) : i18n.tr("Leave “%1”?").arg(chatName)
            text: ended ? i18n.tr("The local copy will be removed from this device.")
                        : i18n.tr("You will stop receiving messages. Others will see that you left.")
            Button {
                text: dlg.ended ? i18n.tr("Delete") : i18n.tr("Leave")
                color: Style.danger
                onClicked: {
                    PopupUtils.close(dlg);
                    if (dlg.ended) Store.deleteLocal(dlg.chatId);
                    else Store.leaveChat(dlg.chatId, function (err) { if (err) Store.toast(Api.friendly(err)); });
                }
            }
            Button { text: i18n.tr("Cancel"); onClicked: PopupUtils.close(dlg) }
        }
    }
}
