import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../lib"

/* Generic popup: coloured dot + name (+ note) per entry. entries = [{name, color, note}] */
Dialog {
    id: dlg
    property var entries: []
    property string emptyText: ""

    Label {
        visible: dlg.entries.length === 0 && dlg.emptyText !== ""
        text: dlg.emptyText
        color: Style.subtext
        wrapMode: Text.Wrap
    }

    Repeater {
        model: dlg.entries
        delegate: Row {
            spacing: units.gu(1.2)
            width: parent.width
            Rectangle {
                width: units.gu(1.6); height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: modelData.color
            }
            Label {
                width: parent.width - units.gu(2.8) - noteLabel.width
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                elide: Text.ElideRight
            }
            Label {
                id: noteLabel
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.note || ""
                fontSize: "small"
                color: Style.subtext
            }
        }
    }

    Button {
        text: i18n.tr("Close")
        onClicked: PopupUtils.close(dlg)
    }
}
