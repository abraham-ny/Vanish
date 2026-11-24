import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../js/api.js" as Api
import "../js/text.js" as Txt

Page {
    id: page
    property string code: ""
    property string chatName: ""        // shown when joining from the public list
    property bool busy: false

    header: PageHeader {
        title: page.chatName ? i18n.tr("Join %1").arg(page.chatName) : i18n.tr("Join a chat")
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

            Label { text: i18n.tr("Invite code"); color: Style.subtext; fontSize: "small" }
            TextField {
                id: codeField
                width: parent.width
                text: Txt.formatCode(page.code)
                placeholderText: "ABCD-EFGH"
                maximumLength: 9
                inputMethodHints: Qt.ImhUppercaseOnly | Qt.ImhNoPredictiveText
                font.pixelSize: units.gu(2.6)
                font.bold: true
                onTextChanged: {
                    var f = Txt.formatCode(text);
                    if (f !== text && text.replace(/[^A-Za-z0-9]/g, "").length >= 8) { text = f; }
                }
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
                text: i18n.tr("No account needed. Others only see this name.")
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
                text: page.busy ? i18n.tr("Joining…") : i18n.tr("Join chat")
                color: Style.primary
                enabled: !page.busy
                onClicked: {
                    var nm = myName.text.replace(/@/g, "").trim();
                    var code = codeField.text.toUpperCase().replace(/[^A-Z0-9]/g, "");
                    if (code.length !== 8) { error.text = i18n.tr("Codes have 8 letters/numbers."); return; }
                    if (!nm) { error.text = i18n.tr("Pick a name to use in this chat."); return; }
                    error.text = "";
                    page.busy = true;
                    Store.joinChat(code, nm, function (err, id) {
                        page.busy = false;
                        if (err) { error.text = Api.friendly(err); return; }
                        Nav.pop();
                        Nav.push(Qt.resolvedUrl("ChatPage.qml"), { chatId: id });
                    });
                }
            }
        }
    }
}
