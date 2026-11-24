pragma Singleton
import QtQuick 2.12

// Thin wrapper so pages in separate files can navigate; Main.qml sets `stack`.
QtObject {
    property var stack: null

    function push(url, props) { return stack.push(url, props || {}); }
    function pop() { if (stack && stack.depth > 1) stack.pop(); }
    function home() { while (stack && stack.depth > 1) stack.pop(); }
}
