pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root

    property string source: Wallpapers.current
    property WallSurface current: one

    anchors.fill: parent

    onSourceChanged: {
        if (!source)
            current = null;
        else if (current === one)
            two.update();
        else
            one.update();
    }

    Loader {
        anchors.fill: parent

        active: !root.source
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge * 5
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: selectWallText.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary

                            function onClicked(): void {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }
            }
        }
    }

    WallSurface {
        id: one
        anchors.fill: parent
    }

    WallSurface {
        id: two
        anchors.fill: parent
    }

    component WallSurface: Item {
        id: surface
        property string path: ""
        property bool isVideo: {
            if (!path)
                return false;
            var p = path.toLowerCase();
            return p.endsWith(".mp4") || p.endsWith(".webm") || p.endsWith(".mov") || p.endsWith(".mkv") || p.endsWith(".avi");
        }

        CachingImage {
            id: img
            anchors.fill: parent
            visible: !surface.isVideo
            path: surface.isVideo ? "" : surface.path

            onStatusChanged: {
                if (status === Image.Ready)
                    surface._markReady();
            }
        }

        Loader {
            id: videoLoader
            anchors.fill: parent
            visible: surface.isVideo
            active: surface.isVideo && !!surface.path
            source: "VideoSurface.qml"
            onLoaded: {
                item.path = surface.path;
                item.onReady = function () {
                    surface._markReady();
                };
            }
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.warn("Video load failed, falling back to image");
                    img.path = surface.path;
                    surface.isVideo = false;
                }
            }
        }

        function update(): void {
            if (surface.path === root.source) {
                root.current = surface;
            } else {
                surface.path = root.source;
            }
        }

        function _markReady(): void {
            root.current = surface;
        }

        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        states: State {
            name: "visible"
            when: root.current === surface
            PropertyChanges {
                surface.opacity: 1
                surface.scale: 1
            }
        }

        transitions: Transition {
            NumberAnimation {
                target: surface
                properties: "opacity,scale"
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
}
