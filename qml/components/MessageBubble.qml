import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../js/text.js" as Txt

/*
 * One chat message. `msg` = {seq, ts, uid, kind, text}. `chatPage` provides member(uid), mentionNames,
 * readers(seq, uid), myUid and rev (bumped whenever members/read state change).
 */
Item {
    id: root
    property var msg
    property var chatPage

    readonly property bool system: msg.kind !== "msg"
    readonly property bool mine: !system && msg.uid === chatPage.myUid
    readonly property var author: { chatPage.rev; return chatPage.member(msg.uid); }
    readonly property var readers: { chatPage.rev; return chatPage.readers(msg.seq, msg.uid); }

    width: ListView.view ? ListView.view.width : parent.width
    height: (system ? sysLabel.height + units.gu(1.5) : bubble.height + units.gu(0.9))

    // ---- join / leave / admin notices
    Label {
        id: sysLabel
        visible: root.system
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        width: Math.min(implicitWidth, parent.width - units.gu(6))
        text: (msg.kind === "admin" ? "📢 " : "") + msg.text
        color: msg.kind === "admin" ? Style.primary : Style.subtext
        font.italic: msg.kind !== "admin"
        font.bold: msg.kind === "admin"
        fontSize: "small"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    // ---- normal message
    Rectangle {
        id: bubble
        visible: !root.system
        anchors {
            top: parent.top; topMargin: units.gu(0.45)
            left: root.mine ? undefined : parent.left; leftMargin: units.gu(1.2)
            right: root.mine ? parent.right : undefined; rightMargin: units.gu(1.2)
        }
        width: Math.min(root.width * 0.8, Math.max(body.implicitWidth, header.implicitWidth, footer.implicitWidth) + units.gu(2.4))
        height: col.height + units.gu(1.6)
        radius: units.gu(1.6)
        color: root.mine ? Style.bubbleMine : Style.bubbleOther
        border.width: root.mine ? 0 : 1
        border.color: Style.divider

        Column {
            id: col
            x: units.gu(1.2); y: units.gu(0.8)
            width: bubble.width - units.gu(2.4)
            spacing: units.gu(0.3)

            // author name in the member's own colour
            Label {
                id: header
                visible: !root.mine
                width: parent.width
                text: root.author ? root.author.n : "?"
                color: root.author ? root.author.c : Style.subtext
                font.bold: true
                fontSize: "small"
                elide: Text.ElideRight
            }

            Label {
                id: body
                width: parent.width
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                color: root.mine ? "white" : Style.text
                text: Txt.render(msg.text, chatPage.mentionNames, {
                    link: String(root.mine ? Style.linkOnMine : Style.link),
                    mention: String(root.mine ? Style.mentionOnMine : Style.mention) })
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Row {
                id: footer
                spacing: units.gu(1)
                anchors.right: parent.right
                Label {
                    text: Txt.fmtTime(msg.ts)
                    fontSize: "x-small"
                    color: root.mine ? "#DDEEFF" : Style.subtext
                }
                // tap -> popup with everyone who has read this message
                Label {
                    text: "✓ Read by " + root.readers.length
                    fontSize: "x-small"
                    font.underline: true
                    color: root.mine ? "#DDEEFF" : Style.subtext
                    MouseArea {
                        anchors { fill: parent; margins: -units.gu(1) }
                        onClicked: chatPage.showReaders(msg)
                    }
                }
            }
        }
    }
}
