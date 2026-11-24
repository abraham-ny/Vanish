import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../js/text.js" as Txt

/* One entry of the home list. `c` is a row of the chats table. */
ListItem {
    id: root
    property var c
    signal open()
    signal togglePin()
    signal toggleMute()
    signal remove()

    readonly property bool ended: { Store.tick; return Store.isExpired(c); }
    readonly property string lastLine: c.lastText ? (c.lastName ? c.lastName + ": " : "") + c.lastText : "No messages yet"

    height: units.gu(9)
    color: "transparent"
    divider.colorFrom: Style.divider
    divider.colorTo: Style.divider
    onClicked: open()

    leadingActions: ListItemActions {
        actions: [ Action {
            iconName: c.pinned ? "unpinned" : "pinned"
            text: c.pinned ? i18n.tr("Unpin") : i18n.tr("Pin")
            onTriggered: root.togglePin()
        } ]
    }
    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: c.muted ? "audio-volume-high" : "audio-volume-muted"
                text: c.muted ? i18n.tr("Unmute") : i18n.tr("Mute")
                onTriggered: root.toggleMute()
            },
            Action {
                iconName: root.ended ? "delete" : "system-log-out"
                text: root.ended ? i18n.tr("Delete") : i18n.tr("Leave")
                onTriggered: root.remove()
            }
        ]
    }

    Row {
        anchors { fill: parent; leftMargin: units.gu(1.5); rightMargin: units.gu(1.5) }
        spacing: units.gu(1.5)

        Item {
            width: units.gu(6); height: parent.height
            Avatar { anchors.centerIn: parent; label: c.name; size: units.gu(5.6); tint: Txt.hashColor(c.chatId) }
        }

        Column {
            width: parent.width - units.gu(6) - units.gu(1.5) - badges.width - units.gu(1.5)
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(0.4)

            Label {
                width: parent.width
                text: c.name
                font.bold: true
                color: Style.text
                elide: Text.ElideRight
            }
            Label {
                width: parent.width
                text: root.lastLine
                color: Style.subtext
                fontSize: "small"
                maximumLineCount: 1
                elide: Text.ElideRight
            }
            Label {
                width: parent.width
                fontSize: "x-small"
                elide: Text.ElideRight
                color: root.ended ? Style.subtext : Style.primary
                text: {
                    Store.tick;
                    if (c.status === "left") return "Left • read-only";
                    if (root.ended) return "Kept • read-only";
                    return (c.expiresAt ? "Active • " + Txt.fmtLeft(c.expiresAt) : "Always open") +
                           " • " + c.memberCount + (c.memberCount === 1 ? " member" : " members");
                }
            }
        }

        Column {
            id: badges
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(0.6)
            width: units.gu(5)

            Label {
                anchors.right: parent.right
                text: Txt.fmtTime(c.lastTs || c.createdAt)
                fontSize: "x-small"
                color: Style.subtext
            }
            Row {
                anchors.right: parent.right
                spacing: units.gu(0.5)
                Icon { visible: c.pinned; width: units.gu(1.8); height: width; name: "pinned"; color: Style.subtext }
                Icon { visible: c.muted; width: units.gu(1.8); height: width; name: "audio-volume-muted"; color: Style.subtext }
                Icon { visible: c.kept; width: units.gu(1.8); height: width; name: "starred"; color: Style.primary }
                Rectangle {
                    visible: c.unread > 0
                    width: Math.max(units.gu(2.4), cnt.implicitWidth + units.gu(1)); height: units.gu(2.4)
                    radius: height / 2
                    color: c.muted ? Style.subtext : Style.primary
                    Label {
                        id: cnt
                        anchors.centerIn: parent
                        text: c.unread > 99 ? "99+" : c.unread
                        color: "white"; fontSize: "x-small"; font.bold: true
                    }
                }
            }
        }
    }
}
