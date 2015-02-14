import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    property int parBorderWidth
    property color parBorderColor
    property string parUrl

    id: border
    color: "#00000000"
    radius: 10
    border.color: parBorderColor
    border.width: parBorderWidth

    Rectangle {
        id: inner
        anchors.fill: parent
        anchors.margins: parBorderWidth
        color: "#00000000"

        SilicaFlickable {
            id: flick
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: parent.height

            PinchArea {
                width: Math.max(flick.contentWidth, flick.width)
                height: Math.max(flick.contentHeight, flick.height)

                property real initialWidth
                property real initialHeight
                onPinchStarted: {
                    initialWidth = flick.contentWidth
                    initialHeight = flick.contentHeight
                }

                onPinchUpdated: {
                    // adjust content pos due to drag
                    flick.contentX += pinch.previousCenter.x - pinch.center.x
                    flick.contentY += pinch.previousCenter.y - pinch.center.y

                    // resize content
                    flick.resizeContent(initialWidth * pinch.scale,
                                        initialHeight * pinch.scale,
                                        pinch.center)
                }

                onPinchFinished: {
                    // Move its content within bounds.
                    flick.returnToBounds()
                }

                Rectangle {
                    width: flick.contentWidth
                    height: flick.contentHeight
                    color: "#99999999"
                    Image {
                        anchors.fill: parent
                        source: parUrl
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked: {
                                console.log("double clicked")
                                flick.contentWidth = inner.implicitWidth
                                flick.contentHeight = inner.implicitHeight
                            }
                        }
                    }
                }
            }
        }
    }
}
