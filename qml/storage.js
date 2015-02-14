.pragma library
.import QtQuick.LocalStorage 2.0 as LS

/*
table camera
   - id (INTEGER)
   - is_active (INTEGER)
   - is_favorite (INTEGER)
   - caption (TEXT)
   - remote_url (TEXT)
   - query_selector (TEXT)
   - is_expect_async_change (INTEGER)
   - image_url (TEXT)
   - last_update (INTEGER)
   - timeout (INTEGER)
*/

function getDatabase() {
    try {
        var db = LS.LocalStorage.openDatabaseSync("Tomekki", "1.0","TomekkiDB", 1000000);
    } catch (e) {
        console.log("Could not open DB: " + e);
    }
    return db;
}

function initialize() {
    var db = getDatabase();
    db.transaction(function (tx) {
        try{
            // tx.executeSql("DROP TABLE camera");

            tx.executeSql("CREATE TABLE IF NOT EXISTS setting(key TEXT UNIQUE, value TEXT);");
            tx.executeSql("CREATE TABLE IF NOT EXISTS camera(" +
                          "id INTEGER UNIQUE PRIMARY KEY, " +
                          "is_active INTEGER, " +
                          "is_favorite INTEGER, " +
                          "caption TEXT, " +
                          "remote_url TEXT, " +
                          "query_selector TEXT, " +
                          "is_expect_async_change INTEGER, " +
                          "image_url TEXT, " +
                          "last_update INTEGER, " +
                          "timeout INTEGER" +
                          ");");
        } catch (e) {
            console.log("Could not initialize DB: " + e);
        }
    });
}

function addCamera(is_active, is_favorite, caption, remote_url, query_selector, is_expect_async_change, timeout) {
    var db = getDatabase();
    var res = "";

    if (is_favorite) {
        _resetIsFavorite();
    }

    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql(
                        "INSERT OR REPLACE INTO camera " +
                        "(is_active, is_favorite, caption, remote_url, query_selector, is_expect_async_change, timeout) " +
                        "VALUES (?,?,?,?,?,?,?);",
                        [is_active ? 1 : 0,
                         is_favorite ? 1 : 0,
                         caption,
                         remote_url,
                         query_selector,
                         is_expect_async_change ? 1 : 0,
                         timeout
                        ]);

            if (rs.rowsAffected === 1) {
                var id = parseInt(rs.insertId, 10);
                res = {"id": id,
                       "is_active": is_active,
                       "is_favorite": is_favorite,
                       "caption": caption,
                       "remote_url": remote_url,
                       "query_selector": query_selector,
                       "is_expect_async_change": is_expect_async_change,
                       "image_url": undefined,
                       "timeout": timeout
                };
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not add camera to DB: " + e);
        }
    });
    return res;
}

function editCamera(id, is_active, is_favorite, caption, remote_url, query_selector, is_expect_async_change, timeout) {
    var db = getDatabase();
    var res = "";

    if (is_favorite) {
        _resetIsFavorite();
    }

    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql(
                        "UPDATE camera SET " +
                        "is_active = ?, " +
                        "is_favorite = ?, " +
                        "caption = ?, " +
                        "remote_url = ?, " +
                        "query_selector = ?, " +
                        "is_expect_async_change = ?, " +
                        "timeout = ? " +
                        "WHERE id = ?;",[
                            is_active ? 1 : 0,
                            is_favorite ? 1 : 0,
                            caption,
                            remote_url,
                            query_selector,
                            is_expect_async_change ? 1 : 0,
                            id,
                            timeout
                        ]);
            //console.log(rs.rowsAffected)

            if (rs.rowsAffected === 1) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not edit camera in DB: " + e);
        }
    });
    return res;
}

function editCameraImageUrl(id, image_url, last_update) {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql(
                        "UPDATE camera SET " +
                        "image_url = ?, " +
                        "last_update = ? " +
                        " WHERE id = ?;",
                        [image_url, last_update, id]);
            //console.log(rs.rowsAffected)

            if (rs.rowsAffected === 1) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not update camera.image_url in DB: " + e);
        }
    });
    return res;
}

function _resetIsFavorite() {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql(
                        "UPDATE camera SET is_favorite = 0");
            //console.log(rs.rowsAffected)

            if (rs.rowsAffected === 1) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not update camera.is_favorite in DB: " + e);
        }
    });
    return res;
}

function deleteCamera(id) {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql('DELETE FROM camera WHERE id = ?;', [id])
            //console.log(rs.rowsAffected)
            if (rs.rowsAffected === 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not delete camera from DB: " + e);
        }
    });
    return res;
}

function deleteCameras() {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql('DELETE FROM camera;');
            //console.log(rs.rowsAffected)
            if (rs.rowsAffected > 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not delete cameras fom DB: " + e);
        }
    });

    return res;
}

function getCameras() {
    var db = getDatabase();
    var cameraList = [];

    db.transaction(function (tx) {
        try {
            var res = tx.executeSql("select * from camera;")

            for (var i = 0; i < res.rows.length; i++) {
                var _lastUpdate = new Date(res.rows.item(i).last_update);
                var _imageUrl = res.rows.item(i).image_url;

                // https://bugreports.qt-project.org/browse/QTBUG-40880
                if (_imageUrl === null)
                {
                    _imageUrl = undefined;
                }

                cameraList.push({id: res.rows.item(i).id,
                                 is_active: res.rows.item(i).is_active === 0 ? false : true,
                                 is_favorite: res.rows.item(i).is_favorite === 0 ? false : true,
                                 caption: res.rows.item(i).caption,
                                 remote_url: res.rows.item(i).remote_url,
                                 query_selector: res.rows.item(i).query_selector,
                                 is_expect_async_change: res.rows.item(i).is_expect_async_change === 0 ? false : true,
                                 image_url: _imageUrl,
                                 last_update: _lastUpdate,
                                 timeout: res.rows.item(i).timeout
                                });
            }
        } catch (e) {
            console.log("Could not get cameras from DB: " + e);
        }
    });

    return cameraList;
}

function setSetting(key, value) {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql('INSERT OR REPLACE INTO setting VALUES (?,?);',
                                   [key, value]);
            //console.log(rs.rowsAffected)
            if (rs.rowsAffected > 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        } catch (e) {
            console.log("Could not add or update setting in DB: " + e);
        }
    });
    return res;
}

function getSetting(key) {
    var db = getDatabase();
    var res = "";
    db.transaction(function (tx) {
        try {
            var rs = tx.executeSql('SELECT value FROM setting WHERE key=?;', [key])
            if (rs.rows.length > 0) {
                res = rs.rows.item(0).value;
            } else {
                res = "Unknown";
            }
        } catch (e) {
            console.log("Could not get setting from DB: " + e);
        }
    });
    return res;
}
