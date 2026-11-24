import QtQuick 2.12
import Lomiri.Components 1.3
import "../lib"
import "../components"
import "../js/config.js" as Config

Page {
    id: page

    header: PageHeader {
        title: i18n.tr("About")
        StyleHints { foregroundColor: Style.primaryText; backgroundColor: Style.primary; dividerColor: Style.primaryDeep }
    }

    Rectangle { anchors.fill: parent; color: Style.bg; z: -1 }

    Flickable {
        anchors { top: page.header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: col.height + units.gu(3)
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: units.gu(1.5)

            Item { width: 1; height: units.gu(1) }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(12); height: width
                source: Qt.resolvedUrl("../../assets/logo.svg")
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Config.APP_NAME
                font.bold: true
                font.pixelSize: units.gu(3.4)
                color: Style.text
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n.tr("Version %1").arg(Config.APP_VERSION)
                color: Style.subtext
                fontSize: "small"
            }
            Label {
                x: units.gu(3); width: parent.width - units.gu(6)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Style.text
                text: i18n.tr("Temporary, anonymous, text-only group chats. No accounts, no phone numbers. Every chat vanishes 24 hours after it starts unless you keep a read-only copy on your own device.")
            }

            Rectangle { width: parent.width; height: units.gu(4); color: "transparent"
                Label { x: units.gu(2); anchors.verticalCenter: parent.verticalCenter; text: i18n.tr("DEVELOPER"); color: Style.subtext; fontSize: "x-small"; font.bold: true }
            }
            Label { x: units.gu(2); width: parent.width - units.gu(4); text: Config.DEV_NAME; color: Style.text; font.bold: true }

            LinkRow { width: parent.width; title: i18n.tr("Developer website"); url: Config.DEV_WEBSITE }
            LinkRow { width: parent.width; title: i18n.tr("Source code (GitHub)"); url: Config.SOURCE_URL }
            LinkRow { width: parent.width; title: i18n.tr("Developer on GitHub"); url: Config.DEV_GITHUB }
            LinkRow { width: parent.width; title: i18n.tr("Send feedback (website)"); url: Config.FEEDBACK_URL }
            LinkRow {
                width: parent.width
                title: i18n.tr("Feedback chat")
                sub: i18n.tr("Talk to the developer anonymously, inside the app")
                onClicked: Nav.push(Qt.resolvedUrl("JoinPage.qml"), { code: Config.FEEDBACK_CODE, chatName: i18n.tr("Feedback") })
            }
            LinkRow {
                width: parent.width
                title: i18n.tr("Support the project")
                sub: i18n.tr("Donate")
                onClicked: Nav.push(Qt.resolvedUrl("DonatePage.qml"))
            }

            Label {
                x: units.gu(3); width: parent.width - units.gu(6)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                fontSize: "x-small"
                color: Style.subtext
                text: i18n.tr("Privacy: each chat uses a fresh random ID, so your chats can't be linked to each other. The server only counts devices for statistics and deletes message content when a chat expires.")
            }
        }
    }
}
