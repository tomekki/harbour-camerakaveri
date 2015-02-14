import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {

    property string parTitle: ""
    property int parId: -1
    property bool parIsActive: true
    property bool parIsFavorite: false
    property string parCaption: "My camera"
    property string parUrl: ""
    property string parQuerySelector: ""
    property bool parIsExpectAsyncChange: false
    property int parTimeout: -1
    property string parLastUpdate: ""

    property alias isActive: idIsActive.checked

    Column {
        id: idColumn
        anchors.fill: parent;
        anchors.leftMargin: Theme.paddingLarge;
        anchors.rightMargin: Theme.paddingLarge;
        DialogHeader {
            title: parTitle
        }

        TextSwitch {
            id: idIsActive
            text: qsTr("Active")
            checked: parIsActive
            onCheckedChanged: {
                if (!checked) {
                    idIsFavorite.enabled = false;
                    idIsFavorite.checked = false;
                }
                else {
                    idIsFavorite.enabled = true;
                }
            }
        }

        // IsFavorite
        TextSwitch {
            id: idIsFavorite
            text: qsTr("Favorite camera")
            checked: parIsFavorite
            enabled: parIsActive
            description: qsTr("Used for cover page")
        }

        // Caption
        TextField {
            id: idCaption
            enabled: isActive
            width: idColumn.width
            text: parCaption
            color: isActive ? Theme.primaryColor : Theme.secondaryColor
            placeholderText: qsTr("Enter caption for camera")
            validator: RegExpValidator { regExp: /^.{1,30}$/ }
            inputMethodHints: Qt.ImhLatinOnly | Qt.ImhNoPrediction
        }

        // Url
        TextField {
            id: idUrl
            enabled: isActive
            width: idColumn.width
            text: parUrl
            color: isActive ? Theme.primaryColor : Theme.secondaryColor
            placeholderText: qsTr("Enter URL (http://ab.com/c.html) containing the photo")
            validator: RegExpValidator { regExp: /^(https?|ftp|file):\/\/.+$/ }
            inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPrediction
        }

        // QuerySelector
        TextField {
            id: idQuerySelector
            enabled: isActive
            width: idColumn.width
            text: parQuerySelector
            color: isActive ? Theme.primaryColor : Theme.secondaryColor
            placeholderText: qsTr("Enter selector")
            validator: RegExpValidator { regExp: /^.{1,300}$/ }
            inputMethodHints: Qt.ImhLatinOnly | Qt.ImhNoPrediction
        }

        // IsExpectAsyncChange
        TextSwitch {
            id: idIsExpectAsyncChange
            enabled: isActive
            text: qsTr("Camera is updated later")
            checked: parIsExpectAsyncChange
            description: qsTr("Camera is updated later")
        }

        // Timeout
        TextField {
            id: idTimeout
            enabled: isActive
            width: idColumn.width
            text: parTimeout
            color: isActive ? Theme.primaryColor : Theme.secondaryColor
            placeholderText: qsTr("Timeout in seconds")
            inputMethodHints: Qt.ImhDigitsOnly
        }

        // LastUpdate
        TextField {
            width: idColumn.width
            text: qsTr("Last update: ") + parLastUpdate
            readOnly: true
        }
    }

    canAccept: {
        return (idUrl.text.length > 0  && idUrl.acceptableInput &&
                idCaption.text.length > 0 && idCaption.acceptableInput &&
                idQuerySelector.text.length > 0 && idQuerySelector.acceptableInput &&
                idTimeout.text.length > 0 && idTimeout.acceptableInput
                ) ? true : false
    }

    onDone: {
        if (result === DialogResult.Accepted)
        {
            parIsActive = isActive;
            parIsFavorite = idIsFavorite.checked;
            parCaption = idCaption.text;
            parUrl = idUrl.text;
            parQuerySelector = idQuerySelector.text;
            parIsExpectAsyncChange = idIsExpectAsyncChange.checked;
            parTimeout = parseInt(idTimeout.text, 10);
        }
    }
}
