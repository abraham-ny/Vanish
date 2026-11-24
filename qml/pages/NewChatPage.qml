import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../js/api.js" as Api
import "../js/text.js" as Txt

Page {
    id: page
    property bool busy: false

    header: PageHeader {
        title: i18n.tr("New chat")
        StyleHints { foregroundColor: Style.primaryText; backgroundColor: Style.primary; dividerColor: Style.primaryDeep }
    }

    Rectangle { anchors.fill: parent; color: Style.bg; z: -1 }

    Flickable {
        anchors { top: page.header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: col.height + units.gu(4)
        clip: true

        Column {
            id: col
            x: units.gu(2); y: units.gu(2)
            width: parent.width - units.gu(4)
            spacing: units.gu(1.2)

            Label { text: i18n.tr("Chat name"); color: Style.subtext; fontSize: "small" }
            TextField {
                id: chatName
                width: parent.width
                placeholderText: i18n.tr("Untitled chat")
                maximumLength: 60
            }

            Label { text: i18n.tr("Your name in this chat"); color: Style.subtext; fontSize: "small" }
            TextField {
                id: myName
                width: parent.width
                text: Store.displayName || Txt.randomGuest()
                maximumLength: 40
            }
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                fontSize: "x-small"
                color: Style.subtext
                text: i18n.tr("Spaces and emoji are fine. Only people in this chat see it. Set a default in Settings.")
            }

            Item {
                width: parent.width; height: units.gu(6)
                Label {
                    anchors { left: parent.left; right: pub.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                    wrapMode: Text.Wrap
                    text: i18n.tr("List in Public chats\n(anyone can find and join)")
                    color: Style.text
                }
                Switch { id: pub; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                fontSize: "small"
                color: Style.subtext
                text: i18n.tr("This chat disappears for everyone 24 hours after you create it. Use ★ Keep inside the chat to save a read-only copy on your device.")
            }

            Label {
                id: error
                width: parent.width
                visible: text !== ""
                wrapMode: Text.Wrap
                color: Style.danger
            }

            Button {
                width: parent.width
                text: page.busy ? i18n.tr("Creating…") : i18n.tr("Create chat")
                color: Style.primary
                enabled: !page.busy
                onClicked: {
                    var nm = myName.text.replace(/@/g, "").trim();
                    if (!nm) { error.text = i18n.tr("Pick a name to use in this chat."); return; }
                    error.text = "";
                    page.busy = true;
                    Store.createChat(chatName.text.trim() || "Untitled chat", nm, pub.checked, function (err, id) {
                        page.busy = false;
                        if (err) { error.text = Api.friendly(err); return; }
                        Nav.pop();
                        Nav.push(Qt.resolvedUrl("ChatPage.qml"), { chatId: id, inviteOnOpen: true });
                    });
                }
            }
        }
    }
}
