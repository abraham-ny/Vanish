import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../lib"
import "../js/text.js" as Txt

Dialog {
    id: dlg
    property string code: ""
    property string chatName: ""

    title: i18n.tr("Invite friends")
    text: i18n.tr("Anyone with this code can join “%1” until it expires.").arg(chatName)

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Txt.formatCode(dlg.code)
        font.bold: true
        font.pixelSize: units.gu(4)
        color: Style.primary
    }
    Button {
        text: i18n.tr("Copy code")
        color: Style.primary
        onClicked: { Clipboard.push(Txt.formatCode(dlg.code)); PopupUtils.close(dlg); Store.toast(i18n.tr("Code copied")); }
    }
    Button {
        text: i18n.tr("Copy invite message")
        onClicked: {
            Clipboard.push("Join my temporary chat “" + dlg.chatName + "” on Vanish. Code: " + Txt.formatCode(dlg.code));
            PopupUtils.close(dlg);
            Store.toast(i18n.tr("Invite copied"));
        }
    }
    Button {
        text: i18n.tr("Close")
        onClicked: PopupUtils.close(dlg)
    }
}
