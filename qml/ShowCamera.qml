import QtQuick 2.1
import Sailfish.Silica 1.0
import "control.js" as CTRL

Page {

    property string parCaption
    property color parBorderColor
    property int borderWidth: 10
    property string parUrl

    id: showCamera
    allowedOrientations: Orientation.All

    PageHeader {
        id: header
        title: parCaption
    }

    Flickresize {
        id: flickresize
        width: parent.width
        height: parent.height - header.height
        anchors.top: header.bottom
        parBorderWidth: showCamera.borderWidth
        parBorderColor: showCamera.parBorderColor
        parUrl: showCamera.parUrl
    }
}
