import QtQuick 2.0
import QtWebKit 3.0
import Sailfish.Silica 1.0
import "control.js" as CTRL

Item {
    signal refreshPhotos
    signal refreshPhoto(int id)

    signal preparePhoto(int id)

    signal reloadPhoto(int id)
    signal downloadError(int id, string errorText)

    signal agePhotos
    signal agePhoto(int id)

    property bool debug: true

    property int photoId: -1
    property bool isLoadAll: false

    Component.onCompleted: {
        CTRL.initialize(photoModel)
    }

    Connections {
        target: photoModel
        onColumnActionChanged: {
            if (debug) {
                console.log("DEBUG::Controller -> Column '" +  CTRL.getColumnActionString(columnAction) + "'.")
            }
        }
    }

    Connections {
        onRefreshPhoto: {
            isLoadAll = false
            assigPhotoUrl(id)
        }
        onRefreshPhotos: {
            isLoadAll = true
            findNextPhotoAndRefresh(-1)
        }
    }

    Timer {
        id: ager
        interval: 1000
        running: Qt.application.active
        repeat: true
        onTriggered: {
            agePhotos()
        }
    }

    Timer {
        id: timeout
        repeat: false
        onTriggered: {
            var photo = CTRL.getPhoto(photoModel, photoId)
            downloadError(photoId, qsTr("Timeout error. Waited ") + timeout.interval / 1000 + " sec.")
        }
    }

    function findNextPhotoAndRefresh(id) {
        if (debug) {
            console.log("DEBUG::Controller -> Determine next photo afer id '" + id + "' ...")
        }
        var photo = CTRL.getNextPhoto(photoModel, id)

        if (photo === undefined) {
            if (debug) {
                console.log("DEBUG::Controller -> No more photos!")
            }
        }
        else{
            if (debug) {
                console.log("DEBUG::Controller -> Refreshing photo with id '" +  photo.id + "' ...")
            }
            assigPhotoUrl(photo.id)
        }
    }

    SilicaWebView {
        id: webview
        visible: false

        // Enable communication between QML and WebKit
        experimental.preferences.navigatorQtObjectEnabled: true

        onLoadingChanged: {
            if (loadRequest.status === WebView.LoadSucceededStatus) {
                if (debug) {
                    console.log("DEBUG::Controller -> Loaded succesfully '" + loadRequest.url + "'")
                }
                var photo = CTRL.getPhoto(photoModel, photoId)
                extractPhotoBySelector(photo.query_selector, photo.is_expect_async_change)
            }
            else if (loadRequest.status === WebView.LoadFailedStatus) {
                var errorMessage = "Error " +  loadRequest.errorCode + ": " + loadRequest.errorString
                downloadError(photoId, errorMessage)
                console.log("ERROR::Controller: Loading failed with error '" + errorMessage + "'.")
                if (isLoadAll) {
                    findNextPhotoAndRefresh(photoId)
                }
            }

        }
        experimental.onMessageReceived: {
            var dataArray = message.data.split("@");

            if (dataArray[0] === "LOG") {
                console.log("INFO LOG: <" + dataArray[1] + ">")
            }
            else if (dataArray[0] === "ERROR") {
                console.log("ERROR LOG: " + dataArray[1] + ">")
                timeout.stop()
                downloadError(photoId, dataArray[1])
            }
            else if (dataArray[0] === "IMG") {
                var id = photoId
                var url = dataArray[1]
                timeout.stop()
                loadPhoto(id, url)
            }
            else {
                console.log("ERROR: " + message.data)
            }
        }
    }

    function extractPhotoBySelector(querySelector, isExpectAsyncChange) {
        if (debug) {
            console.log("DEBUG::Controller -> Query for selector '" + querySelector + "' " + (isExpectAsyncChange ? "asynchronously" : "synchronously") + " ...");
        }
        var script =
                "(function() { \
                    var pic = document.querySelector('" + querySelector + "'); \
                    if (pic === undefined) { \
                        var message = 'Could not select photo with selector: " + querySelector + "'; \
                        navigator.qt.postMessage('ERROR@' + message); \
                    } \
                    else { \
                        if(" + isExpectAsyncChange + " || pic.src === undefined || pic.src.length === 0) { \
                            pic.addEventListener('load', function() { \
                                navigator.qt.postMessage('IMG@' + pic.src); \
                            }, false); \
                            return 'ASYNC'; \
                        } \
                        else { \
                            navigator.qt.postMessage('IMG@' + pic.src); \
                            return 'SYNC'; \
                        } \
                    } \
                    return 'ERROR'; \
                 })()";

        evaluateJavaScriptOnWebPage(script,  function(result) {
          // console.log("RES: " + result);
        });
    }

    function assigPhotoUrl(id) {
        var photo = CTRL.getPhoto(photoModel,id)
        if (photo !== undefined) {
           preparePhoto(id)
           photoId = id
           webview.url = photo.remote_url
           timeout.interval = photo.timeout
           timeout.start()

            if (debug) {
                console.log("DEBUG::Controller -> Assigned url '" + photo.remote_url + "'.")
            }
        }
    }

    function loadPhoto(id, url) {
        if (debug) {
            console.log("DEBUG::Controller -> Loading '" + url + "' with id '" + id + "' ...")
        }
        CTRL.updatePhotoImageUrl(photoModel, id, url)
        reloadPhoto(id)
        agePhoto(id)
        if (isLoadAll) {
            findNextPhotoAndRefresh(id)
        }
    }

    function evaluateJavaScriptOnWebPage(script, onReadyCallback) {
        // console.log("Running script in webview:  " + script)
        webview.experimental.evaluateJavaScript(script, onReadyCallback)
    }
}
