import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    property int size
    property bool active: false
    property bool favorite: false

    width: size
    height: size
    color: active ? "green" : "transparent"
    border.color: Theme.primaryColor
    border.width: 1
    radius: width * 0.5

    Label {
        id: character
        text: favorite ? "\u2605" : ""
        anchors.centerIn: parent
    }
}
