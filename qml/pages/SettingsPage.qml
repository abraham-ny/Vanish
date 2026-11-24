import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../lib"

Page {
    id: page

    // Hidden developer mode: tap the "Dark" theme row 5 times. Lives only as long as this page instance,
    // so leaving Settings forgets it; nothing is saved.
    property bool devMode: false
    property int devTaps: 0
    function registerTap() {
        devTaps++;
        tapReset.restart();
        if (devTaps >= 5 && !devMode) {
            devMode = true;
            Store.toast(i18n.tr("Developer mode enabled"));
        }
    }
    Timer { id: tapReset; interval: 3000; onTriggered: page.devTaps = 0 }

    header: PageHeader {
        title: i18n.tr("Settings")
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
            spacing: units.gu(1.4)

            Label { text: i18n.tr("Default name"); color: Style.subtext; fontSize: "small" }
            TextField {
                width: parent.width
                text: Store.displayName
                placeholderText: i18n.tr("Random guest name")
                maximumLength: 40
                onAccepted: Store.setDisplayName(text)
                onActiveFocusChanged: { if (!activeFocus) Store.setDisplayName(text); }
            }
            Label {
                width: parent.width; wrapMode: Text.Wrap; fontSize: "x-small"; color: Style.subtext
                text: i18n.tr("Pre-filled when you create or join a chat. You can still pick a different name every time.")
            }

            Label { text: i18n.tr("Theme"); color: Style.subtext; fontSize: "small" }
            Repeater {
                model: [
                    { key: "system", label: i18n.tr("Follow system") },
                    { key: "light", label: i18n.tr("Light") },
                    { key: "dark", label: i18n.tr("Dark") }
                ]
                delegate: Rectangle {
                    width: col.width
                    height: units.gu(5.5)
                    radius: units.gu(1)
                    color: Style.surface
                    border.width: Store.theme === modelData.key ? 2 : 1
                    border.color: Store.theme === modelData.key ? Style.primary : Style.divider

                    Label {
                        anchors { left: parent.left; leftMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
                        text: modelData.label
                        color: Style.text
                    }
                    Label {
                        anchors { right: parent.right; rightMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
                        visible: Store.theme === modelData.key
                        text: "✓"
                        color: Style.primary
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Store.setTheme(modelData.key);
                            if (modelData.key === "dark") page.registerTap(); else page.devTaps = 0;
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: units.gu(7)
                Label {
                    anchors { left: parent.left; right: alertSwitch.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                    wrapMode: Text.Wrap
                    text: i18n.tr("In-app message alerts (muted chats are always silent)")
                    color: Style.text
                }
                Switch {
                    id: alertSwitch
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    checked: Store.alerts
                    onClicked: Store.setAlerts(checked)
                }
            }
            Label {
                width: parent.width; wrapMode: Text.Wrap; fontSize: "x-small"; color: Style.subtext
                text: i18n.tr("Alerts appear while Vanish is open. Without accounts there is no server that can wake a closed app.")
            }

            Rectangle { visible: page.devMode; width: parent.width; height: 1; color: Style.divider }

            Label { visible: page.devMode; text: i18n.tr("Developer: backend URL"); color: Style.subtext; fontSize: "small" }
            TextField {
                visible: page.devMode
                width: parent.width
                text: Store.apiUrl
                placeholderText: "https://script.google.com/macros/s/.../exec"
                inputMethodHints: Qt.ImhNoPredictiveText
                onAccepted: Store.setApiUrl(text)
                onActiveFocusChanged: { if (!activeFocus) Store.setApiUrl(text); }
            }

            Rectangle { width: parent.width; height: 1; color: Style.divider }

            Button {
                width: parent.width
                text: i18n.tr("Delete all local chats")
                color: Style.danger
                onClicked: PopupUtils.open(wipeDialog, page)
            }
        }
    }

    Component {
        id: wipeDialog
        Dialog {
            id: dlg
            title: i18n.tr("Delete all local chats?")
            text: i18n.tr("Kept chats on this device are removed for good. Chats stay open for others until they expire.")
            Button {
                text: i18n.tr("Delete everything")
                color: Style.danger
                onClicked: { Store.clearAll(); PopupUtils.close(dlg); Store.toast(i18n.tr("Local data deleted")); }
            }
            Button { text: i18n.tr("Cancel"); onClicked: PopupUtils.close(dlg) }
        }
    }
}
