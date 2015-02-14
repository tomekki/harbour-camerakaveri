# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-camerakaveri

CONFIG += sailfishapp \
    sailfishapp_no_deploy_qml

SOURCES += \
    src/$${TARGET}.cpp \
    src/filtermodel.cpp \
    src/enums.cpp

OTHER_FILES += \
    qml/$${TARGET}.qml \
    qml/CoverPage.qml \
    qml/Photo.qml \
    qml/EditCamera.qml \
    qml/Flickresize.qml \
    qml/Controller.qml \
    qml/Circle.qml \
    qml/AdministrateCameras.qml \
    qml/ShowCameras.qml \
    qml/ShowCamera.qml \
    qml/storage.js \
    qml/control.js \
    rpm/$${TARGET}.spec \
    rpm/$${TARGET}.yaml \
    translations/*.ts \
    $${TARGET}.desktop \
    res/Fallback.png \
    res/LICENSE


# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/$${TARGET}-de.ts


HEADERS += \
    src/filtermodel.h \
    src/filtermodel.h \
    src/enums.h

# add qml folder
qml.files += qml
unix:qml.extra = rm -Rf $$_PRO_FILE_PWD_/qml/.DS_Store
qml.path = /usr/share/$${TARGET}
INSTALLS += qml

#message($$_PRO_FILE_PWD_/qml/.DS_Store)


# add PNGs
pngs.files = res/*png
pngs.path = /usr/share/$${TARGET}/res
INSTALLS += pngs

