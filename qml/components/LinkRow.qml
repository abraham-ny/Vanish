import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"

ListItem {
    property alias title: lbl.text
    property string url: ""
    property string sub: ""

    height: units.gu(7)
    divider.colorFrom: Style.divider
    divider.colorTo: Style.divider
    onClicked: { if (url) Qt.openUrlExternally(url); }

    Column {
        anchors { left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2); verticalCenter: parent.verticalCenter }
        Label { id: lbl; width: parent.width; color: Style.primary; font.bold: true; elide: Text.ElideRight }
        Label { width: parent.width; text: sub || url; fontSize: "x-small"; color: Style.subtext; elide: Text.ElideRight }
    }
}
