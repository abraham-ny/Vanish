pragma Singleton
import QtQuick 2.12

QtObject {
    // Set from Main.qml (follows Settings > Theme).
    property bool dark: false

    readonly property color primary: "#1E90FF"          // dodger blue
    readonly property color primaryDeep: "#1570CC"
    readonly property color primaryText: "#FFFFFF"
    readonly property color danger: "#E5484D"

    property color bg: dark ? "#111418" : "#F3F7FC"
    property color surface: dark ? "#1B2027" : "#FFFFFF"
    property color text: dark ? "#ECF0F5" : "#18212B"
    property color subtext: dark ? "#98A3B1" : "#5B6879"
    property color divider: dark ? "#29313B" : "#E0E7F0"
    property color bubbleOther: dark ? "#252C35" : "#FFFFFF"
    property color bubbleMine: primary
    property color chipBg: dark ? "#223244" : "#E3F1FF"

    // Rich-text colours (passed to text.js as strings)
    property color link: dark ? "#7CC0FF" : "#0A62C9"
    property color mention: dark ? "#9AD0FF" : "#0A5BBE"
    readonly property color linkOnMine: "#FFFFFF"
    readonly property color mentionOnMine: "#FFFFFF"
}
