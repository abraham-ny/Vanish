import QtQuick 2.12
import Lomiri.Components 1.3
import "../js/text.js" as Txt

Rectangle {
    id: root
    property string label: "?"
    property color tint: Txt.hashColor(label)
    property int size: units.gu(5.5)

    width: size; height: size; radius: size / 2
    color: tint

    Text {
        anchors.centerIn: parent
        text: Txt.initial(root.label)
        color: "white"
        font.pixelSize: root.size * 0.46
        font.bold: true
    }
}
