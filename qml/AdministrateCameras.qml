import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.camerakaveri.Tomekki 1.0
import "control.js" as CTRL

Page {
    id: showCamerasPage

    property FilterModel parPhotoModel

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        RemorsePopup { id: remorse }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add example entries")
                onClicked: {
                    CTRL.createExampleEntries(parPhotoModel);
                }
            }
            MenuItem {
                text: qsTr("Delete all cameras")
                enabled: cameraView.count > 0
                onClicked: {
                    remorse.execute(qsTr("Deleting all cameras"), function() {
                        CTRL.deletePhotos(parPhotoModel);
                    });
                }
            }
            MenuItem {
                property string title: qsTr("Add camera")
                text: title
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("EditCamera.qml"), {"parTitle": title});
                    dialog.accepted.connect(function() {
                        CTRL.addPhotoFromDialog(parPhotoModel, dialog);
                    });
                }
            }
        }

        SilicaListView {
            id: cameraView
            property Item contextMenu

            model: parPhotoModel
            anchors.fill: parent

            header: Column {
               width: parent.width

                PageHeader {
                    id: header
                    title: qsTr("Cameras")
                }
            }
            delegate: ListItem {
                id: listItem

                property bool isMenuOpen: cameraView.contextMenu != null && cameraView.contextMenu.parent === listItem

                width: cameraView.width
                height: isMenuOpen ? cameraView.contextMenu.height + contentItem.height : contentItem.height

                function deleteCamera()
                {
                    remorseAction(qsTr("Deleting"), function() {
                        CTRL.deletePhoto(parPhotoModel, id, index);
                    });
                }

                function editCamera()
                {
                    var _lastUpdate;
                    if (last_update === undefined) {
                        _lastUpdate = qsTr("never");
                    }
                    else {
                        _lastUpdate = Qt.formatDateTime(new Date(last_update), Qt.SystemLocaleShortDate);
                    }

                    var dialog = pageStack.push(Qt.resolvedUrl("EditCamera.qml"),
                                                {"parTitle": qsTr("Edit camera"),
                                                 "parId": id,
                                                 "parIsActive": is_active,
                                                 "parIsFavorite": is_favorite,
                                                 "parCaption": caption,
                                                 "parUrl": remote_url,
                                                 "parQuerySelector": query_selector,
                                                 "parIsExpectAsyncChange": is_expect_async_change,
                                                 "parTimeout": timeout / 1000,
                                                 "parLastUpdate": _lastUpdate});

                    dialog.accepted.connect(function() {
                        CTRL.editPhotoFromDialog(parPhotoModel, dialog, index);
                    });
                }

                BackgroundItem {
                    id: contentItem
                    Rectangle{
                        color: "transparent"
                        anchors.fill: parent
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.rightMargin: Theme.paddingLarge
                        Circle {
                            id: circle
                            size: label.height / 1.1
                            active: is_active === true
                            favorite: is_favorite === true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            id: label
                            text: caption
                            width: parent.width - Theme.paddingLarge * 2
                            horizontalAlignment: Text.AlignLeft
                            truncationMode: TruncationMode.Fade
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: circle.right
                                leftMargin: 10
                            }
                            color: contentItem.highlighted ? Theme.highlightColor
                                                                : Theme.primaryColor
                        }
                    }
                    onPressAndHold: {
                        if (!isMenuOpen)
                        {
                            cameraView.contextMenu = contextMenuComponent.createObject(cameraView);
                        }
                        cameraView.contextMenu.show(listItem)
                    }
                    onClicked: {
                       editCamera();
                    }
                }

                ListView.onAdd: AddAnimation {
                    target: listItem
                    duration: 2000
                }
                ListView.onRemove: RemoveAnimation {
                    target: listItem
                    duration: 500
                }

                Component {
                    id: contextMenuComponent
                    ContextMenu {
                        MenuItem {
                            text: qsTr("Delete")
                            onClicked:{
                                deleteCamera();
                            }
                        }
                    }
                }
            }

            ViewPlaceholder {
                enabled: cameraView.count === 0
                text:  qsTr("Pull down and add camera")
            }

            VerticalScrollDecorator { }

            onVisibleChanged:
            {
                if (visible)
                {
                    parPhotoModel.clearFilter();
                }
            }
        }
    }
}

