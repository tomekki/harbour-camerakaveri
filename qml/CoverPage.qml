import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.camerakaveri.Tomekki 1.0
import "control.js" as CTRL

CoverBackground {

    property string photoCaption : ""
    property string photoText
    property int photoId
    property string photoUrl : ""
    property var photoUpdated

    property int coverPageStatus: Enums.INIT

    Connections {
        target: photoModel
        onColumnActionChanged: {
            var previousPhoto
            var currentPhoto

            if (columnAction === FilterModel.Created) {
                currentPhoto = photoModel.getCurrentDataRaw()

                if (currentPhoto.is_favorite) {
                    updateCoverPage(currentPhoto)
                }
            } else if (columnAction === FilterModel.Updated) {
                previousPhoto = photoModel.getPreviousDataRaw()
                currentPhoto = photoModel.getCurrentDataRaw()

                if (currentPhoto.is_favorite) {
                    updateCoverPage(currentPhoto)
                }
                else if (previousPhoto.is_favorite && !currentPhoto.is_favorite){
                    updateCoverPage(undefined)
                }
            } else if (columnAction === FilterModel.Removed) {
                previousPhoto = photoModel.getPreviousDataRaw()

                if (previousPhoto.is_favorite) {
                    updateCoverPage(undefined)
                }
            } else if (columnAction === FilterModel.Cleared) {
                updateCoverPage(undefined)
            }
        }
    }

    Connections {
        target: controller
        onPreparePhoto: {
            if (photoId === id) {
                coverPageStatus = Enums.LOADING
                photoText = qsTr("Loading ...")
            }
        }
        onReloadPhoto: {
            if (photoId === id) {
                coverPageStatus = Enums.DISPLAY_IMAGE
                var temp = photoUrl
                photoUrl = ""
                photoUrl = temp
            }
        }
        onDownloadError: {
            if (photoId === id) {
                coverPageStatus = Enums.ERROR
                photoText = qsTr("Error...")
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.paddingSmall
        width: parent.width
        height: parent.height
        color: "transparent"

        Label {
            id: text
            visible: status === Enums.DISPLAY_IMAGE
            color: Theme.primaryColor
            width: parent.width
            text: photoCaption
            horizontalAlignment: contentWidth <= width ? Text.AlignHCenter : Text.AlignLeft
            truncationMode: TruncationMode.Fade
            opacity: 0.8
        }

        Label {
            id: contentText
            visible: coverPageStatus !== Enums.DISPLAY_IMAGE
            color: Theme.primaryColor
            width: parent.width
            text: photoText
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: contentWidth <= width ? Text.AlignHCenter : Text.AlignLeft
            opacity: 0.8
        }

        Image {
            id: image
            visible: coverPageStatus === Enums.DISPLAY_IMAGE
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectFit
            width: parent.width
            anchors.top: text.bottom
            source: photoUrl
        }

        Label {
            id: lastUpdate
            visible: coverPageStatus === Enums.DISPLAY_IMAGE
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: Qt.formatDateTime(new Date(photoUpdated),
                                    Qt.SystemLocaleShortDate)
            opacity: 0.8
        }
    }

    function updateCoverPage(photo) {
        if (photo === undefined) {
            coverPageStatus = Enums.INIT
            photoId = 0
            photoCaption = "";
            photoText = "Camera Caveri"
            photoUpdated = "";
        } else {
            coverPageStatus = Enums.DISPLAY_IMAGE
            photoId = photo.id
            photoCaption = photo.caption
            if (photo.image_url === undefined) {
                photoUrl = CTRL.getFallbackImageUrl()
            }
            else {
                photoUrl = photo.image_url
            }
            photoUpdated = photo.last_update
        }
    }

    Component.onCompleted: {
        updateCoverPage(CTRL.getFavoritePhoto(photoModel))
    }

    CoverActionList {
        id: coverAction
        enabled: coverPageStatus !== Enums.INIT

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"

            onTriggered: {
                coverPageStatus = Enums.LOADING
                photoText = qsTr("Loading ..")
                controller.refreshPhoto(photoId)
            }
        }
    }
}
