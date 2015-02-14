import QtQuick 2.0
import Sailfish.Silica 1.0
import "control.js" as CTRL

Rectangle {
    // public
    property string photoCaption
    property int photoId
    property string photoUrl
    property var photoUpdated
    signal clicked

    // private
    property bool isBusy
    property bool isError

    id: photo
    radius: 6
    border.width: 6
    border.color: "#00000000"
    color: "#00000000"

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: !isError && (isBusy || image.state === Image.Loading)
        size: BusyIndicatorSize.Large
    }

    Rectangle {
        id: inner
        anchors.fill: parent
        anchors.margins: 6
        color: "transparent"

        Rectangle {
            id: header
            width: parent.width
            height: text.height
            color: Theme.rgba("dimgray", 0.8)
            Label {
                id: text
                color: Theme.primaryColor
                text: photoCaption
                width: parent.width
                horizontalAlignment: contentWidth <= width ? Text.AlignHCenter : Text.AlignLeft
                truncationMode: TruncationMode.Fade
            }
        }

        Image {
            id: image
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectFit
            source: photoUrl
            width: parent.width
            height: inner.height - header.height
            anchors.top: header.bottom
            visible: !isBusy && !isError
        }

        Text {
            id: errorLabel
            visible: isError
            color: Theme.primaryColor
            anchors.centerIn: inner
            width: parent.width
            font.family: Theme.fontFamilyHeading
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 10
        }

        MouseArea {
            anchors.fill: inner
            onClicked: photo.clicked()
        }
    }

    function prepare() {
        isError = false
        isBusy = true
    }

    function reload() {
        var oldSource = photoUrl
        photoUrl = ""
        photoUrl = oldSource
        isBusy = false
    }

    function displayError(errorText) {
        isError = true
        errorLabel.text = errorText
    }

    function age()
    {
        inner.color = CTRL.getColor(photoUpdated)
    }
}
