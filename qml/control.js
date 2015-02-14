.pragma library
.import "storage.js" as DB
.import harbour.camerakaveri.Tomekki 1.0 as Tomekki
.import Sailfish.Silica 1.0 as Silica

function initialize(photoModel) {
    DB.initialize();

    var cameraList = DB.getCameras();
    for (var i = 0; i < cameraList.length; i++) {
        photoModel.append(cameraList[i]);
    }
}

function createExampleEntries(photoModel)
{
    var captions = [
                     "Tikkurila/FI"
                    ,"Korso/FI "
                    ,"Mäntsälä/FI"
                    ,"Lüneburg/DE"
                    ];

    var remote_urls =
            [
              "http://liikennetilanne.liikennevirasto.fi/?cameraPanId=C0158000"
             ,"http://liikennetilanne.liikennevirasto.fi/?cameraPanId=C0153201"
             ,"http://liikennetilanne.liikennevirasto.fi/?cameraPanId=C0150802"
             ,"http://www.ihk-lueneburg.de/service/Ueber_uns/861064/Webcam_artikel.html"
            ];

    var query_selectors =
            [
              "#mainPicture"
             ,"#mainPicture"
             ,"#mainPicture"
             ,".list > div:nth-child(1) > div:nth-child(3) > p:nth-child(2) > a:nth-child(1) > img:nth-child(1)"
            ];

    for (var i = 0; i < captions.length; i++) {
        var is_active = true;
        var is_favorite = i === 0 ? true : false;
        var caption = captions[i];
        var remote_url = remote_urls[i];
        var query_selector = query_selectors[i];
        var is_expect_async_change = i === captions.length - 1 ? false : true;
        var timeout = 30 * 1000;

        var camera = DB.addCamera(
                        is_active,
                        is_favorite,
                        caption,
                        remote_url,
                        query_selector,
                        is_expect_async_change,
                        timeout);
         photoModel.append(camera);
     }
}

function deletePhotos(photoModel) {
    DB.deleteCameras();
    photoModel.clear();
}

function deletePhoto(photoModel, id, index) {
    DB.deleteCamera(id);
    photoModel.remove(index);
}

function addPhotoFromDialog(photoModel, dialog) {
    var camera = DB.addCamera(
                    dialog.parIsActive,
                    dialog.parIsFavorite,
                    dialog.parCaption,
                    dialog.parUrl,
                    dialog.parImageCount,
                    dialog.parImageRegex);

    if (camera.is_favorite) {
        _resetIsFavorite (photoModel, camera.id);
    }
    photoModel.append(camera);
}

function editPhotoFromDialog(photoModel, dialog, index) {
    var photo = photoModel.get(index);

    photo.id = dialog.parId;
    photo.is_active = dialog.parIsActive;
    photo.is_favorite = dialog.parIsFavorite;
    photo.caption = dialog.parCaption;
    photo.remote_url = dialog.parUrl;
    photo.query_selector = dialog.parQuerySelector;
    photo.is_expect_async_change = dialog.parIsExpectAsyncChange;

    DB.editCamera(
        photo.id,
        photo.is_active,
        photo.is_favorite,
        photo.caption,
        photo.remote_url,
        photo.query_selector,
        photo.is_expect_async_change);

    if (photo.is_favorite === true) {
        _resetIsFavorite (photoModel, photo.id);
    }

    photoModel.set(index, photo);
}

function _resetIsFavorite(photoModel, id) {
    for (var i = 0; i < photoModel.count; i++) {
        var camera = photoModel.get(i);
        if (camera.id !== id && camera.is_favorite === true) {
            photoModel.setProperty(i, "is_favorite", false);
        }
    }
}

function getPhoto(photoModel, id) {
    for (var index = 0; index < photoModel.count; index++) {
        var camera = photoModel.get(index);

        if (camera.id === id) {
            return camera;
        }
    }
    return undefined;
}

function getNextPhoto(photoModel, id) {

    for (var index = 0; index < photoModel.count; index++) {
        var camera = photoModel.get(index);

        if (camera.id > id && camera.is_active) {
            return camera;
        }
    }
    return undefined;
}

function updatePhotoImageUrl(photoModel, id, image_url) {
    var _now = new Date();

    DB.editCameraImageUrl(id, image_url, _now.getTime());

    for (var index = 0; index < photoModel.count; index++) {
        var camera = photoModel.get(index);

        if (camera.id === id) {
            photoModel.setProperty(index, "image_url", image_url);
            photoModel.setProperty(index, "last_update", _now);
            break;
        }
    }
}

function getFavoritePhoto(photoModel) {
    var camera;
    for (var i = 0; i < photoModel.count; i++) {
        var _camera = photoModel.get(i);

        if (_camera.is_favorite) {
            camera = _camera;
            break;
        }
    }
    return camera;
}

function getPhotoString(photo) {
    return "id: '"                      + photo.id + "', " +
           "is_active: '"               + photo.is_active + "', " +
           "is_favorite: '"             + photo.is_favorite + "', " +
           "caption: '"                 + photo.caption + "'," +
           "remote_url: '"              + photo.remote_url + "', " +
           "query_selector: '"          + photo.query_selector + "', " +
           "is_expect_async_change: '"  + photo.is_expect_async_change + "', " +
           "image_url: '"               + photo.image_url + "', " +
           "timeout: '"                 + photo.timeout + "', " +
           "last_update: '"             + Qt.formatDateTime(new Date(photo.last_update), Qt.SystemLocaleShortDate) + "'";
}

function getColumnActionString(columnAction) {
    if (columnAction === Tomekki.FilterModel.Created) {
        return "Created";
    }
    else if (columnAction === Tomekki.FilterModel.Removed) {
        return "Removed";
    }
    else if (columnAction === Tomekki.FilterModel.Updated) {
        return "Updated";
    }
    else if (columnAction === Tomekki.FilterModel.Deleted) {
        return "Deleted";
    }
    else if (columnAction === Tomekki.FilterModel.Cleared) {
        return "Cleared";
    } 
}

function getFallbackImageUrl() {
    return "../res/Fallback.png";
}

function getColor(updateDate) {
    var duration = 60 * 10; // in seconds (10 min)
    var percent = 1;
    var now;

    if (updateDate === undefined) {
        percent = 0;
    }
    else {
        now = new Date();
        var seconds = (now - updateDate.getTime()) / 1000
        // console.log("Picture is " + seconds + " sec. old ");

        var delta = duration - seconds;

        if (delta < 0) {
            percent = 0;
        }
        else {
            percent = delta * (1/duration);
        }
    }

    var colorLeft = Silica.Theme.rgba("lightgray", 1);
    var colorRight = Silica.Theme.rgba("lime", 1);

    var resultRed = colorLeft.r + percent * (colorRight.r - colorLeft.r);
    var resultGreen = colorLeft.g + percent * (colorRight.g - colorLeft.g);
    var resultBlue = colorLeft.b + percent * (colorRight.b - colorLeft.b);


    return Qt.rgba(resultRed,resultGreen,resultBlue, 0.4);
}

function getRandomColor() {
    var letters = '0123456789ABCDEF'.split('');
    var color = '#';
    for (var i = 0; i < 6; i++ ) {
        color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
}

function sleep(milliseconds) {
  var start = new Date().getTime();
  for (var i = 0; i < 1e7; i++) {
    if ((new Date().getTime() - start) > milliseconds) {
      break;
    }
  }
}

function getGETValue(urlStr, name) {
    var query = {};
    var pair;
    var search = urlStr.split("&");
    var i = search.length;

    while (i--) {
        pair = search[i].split("=");
        query[pair[0]] = decodeURIComponent(pair[1]);
    }
    return query[name];
}

function appendGETParam(urlStr, key, value) {
    var seperator = (urlStr.indexOf("?") > -1) ? "&" : "?";
    return urlStr + seperator + encodeURI(key) + "=" + encodeURI(value);
}

