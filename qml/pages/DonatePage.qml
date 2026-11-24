import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../js/config.js" as Config

Page {
    id: page

    header: PageHeader {
        title: i18n.tr("Support Vanish")
        StyleHints { foregroundColor: Style.primaryText; backgroundColor: Style.primary; dividerColor: Style.primaryDeep }
    }

    Rectangle { anchors.fill: parent; color: Style.bg; z: -1 }

    Flickable {
        anchors { top: page.header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: col.height + units.gu(4)
        clip: true

        Column {
            id: col
            x: units.gu(2); y: units.gu(3)
            width: parent.width - units.gu(4)
            spacing: units.gu(2)

            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "❤️"; font.pixelSize: units.gu(7) }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Style.text
                text: i18n.tr("Vanish is free, open source and has no ads or tracking. It runs on a shoestring backend, so every coffee keeps it alive and helps me build more apps for Ubuntu Touch.")
            }

            Repeater {
                model: Config.DONATE_LINKS
                delegate: Button {
                    width: col.width
                    text: modelData.label
                    color: index === 0 ? Style.primary : theme.palette.normal.base
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                fontSize: "small"
                color: Style.subtext
                text: i18n.tr("Not able to donate? Starring the project on GitHub, sharing the app and reporting bugs all help just as much.")
            }
        }
    }
}
