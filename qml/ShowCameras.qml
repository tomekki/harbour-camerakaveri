import QtQuick 2.1
import Sailfish.Silica 1.0
import "control.js" as CTRL

Page {
    id: mainPage

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: idFlickable
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Manage cameras")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AdministrateCameras.qml"), {
                                       parPhotoModel: photoModel
                                   })
                }
            }
            MenuItem {
                text: qsTr("Refresh all")
                enabled: photoModel.count > 0
                onClicked: {
                   controller.refreshPhotos();
                }
            }
        }

        SilicaGridView {
            id: idGrid
            width: parent.width
            height: parent.height
            cellWidth: parent.width / 2
            cellHeight: parent.height / 2
            model: photoModel
            delegate: Photo {
                id: photo
                photoId: model.id
                photoUpdated: model.last_update
                width: idGrid.cellWidth
                height: idGrid.cellHeight
                photoCaption: model.caption === undefined ? "" : model.caption
                photoUrl: model.image_url === undefined ? CTRL.getFallbackImageUrl() : model.image_url
                Connections {
                    target: controller
                    onPreparePhoto: {
                        if (model.is_active && model.id === id) {
                            photo.prepare()
                        }
                    }
                    onReloadPhoto: {
                        if (model.is_active && model.id === id) {
                            //console.log("ShowCameras::onReloadPhoto -> ")
                            //console.log("  OLD: " + photo.photoUrl)
                            //console.log("  NEW: " + model.image_url)
                            photo.photoUrl = model.image_url
                            photo.reload()
                        }
                    }
                    onAgePhoto: {
                        if (model.is_active && model.id === id) {
                            photo.age();
                        }
                    }
                    onAgePhotos: {
                        if (model.is_active) {
                            photo.age();
                        }
                    }
                    onDownloadError: {
                        if (model.is_active && model.id === id) {
                            photo.displayError(errorText)
                        }
                    }
                }
                onClicked: {
                    var image_url = model.image_url === undefined ? CTRL.getFallbackImageUrl(
                                                                        ) : model.image_url
                    var caption = model.caption === undefined ? "" : model.caption

                    pageStack.push(Qt.resolvedUrl("ShowCamera.qml"), {
                                       parCaption: caption,
                                       parUrl: image_url,
                                       parBorderColor: CTRL.getColor(
                                                           model.last_update)
                                   })
                }
            }
            onVisibleChanged: {
                if (visible) {
                    photoModel.setFilter("is_active", true)
                }
            }
            VerticalScrollDecorator {
                flickable: idGrid
            }
        }
    }
}
