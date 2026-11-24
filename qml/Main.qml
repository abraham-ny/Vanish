import QtQuick 2.12
import Lomiri.Components 1.3
import "lib"

MainView {
    id: root
    objectName: "mainView"
    applicationName: "vanish.vitalsoft"
    automaticOrientation: true
    anchorToKeyboard: true

    // Desktop (clickable desktop) window size; ignored on the phone.
    width: units.gu(45)
    height: units.gu(80)

    theme.name: Store.theme === "dark" ? "Lomiri.Components.Themes.SuruDark"
              : Store.theme === "light" ? "Lomiri.Components.Themes.Ambiance" : ""

    // "System" follows whatever palette the platform theme gives us.
    Binding {
        target: Style
        property: "dark"
        value: {
            if (Store.theme === "dark") return true;
            if (Store.theme === "light") return false;
            try {
                var c = root.theme.palette.normal.background;
                return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) < 0.5;
            } catch (e) { return false; }
        }
    }

    PageStack {
        id: stack
        Component.onCompleted: {
            Nav.stack = stack;
            push(Qt.resolvedUrl("pages/HomePage.qml"));
        }
    }

    // ---- in-app notification banner (new messages in chats you are not looking at)
    Rectangle {
        id: banner
        z: 100
        function show(t) { label.text = t; opacity = 1; hideTimer.restart(); }
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: units.gu(7) }
        width: Math.min(parent.width - units.gu(4), label.implicitWidth + units.gu(4))
        height: label.implicitHeight + units.gu(2)
        radius: units.gu(1.2)
        color: "#E6101820"
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Label {
            id: label
            anchors.centerIn: parent
            width: parent.width - units.gu(3)
            color: "white"
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
        Timer { id: hideTimer; interval: 3500; onTriggered: banner.opacity = 0 }
        MouseArea { anchors.fill: parent; onClicked: banner.opacity = 0 }
    }

    Connections {
        target: Store
        onToast: banner.show(text)
    }
}
