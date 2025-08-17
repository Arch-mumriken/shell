pragma ComponentBehavior: Bound

import QtQuick
import qs.components.images
import qs.services
import qs.config

Item {
    id: surface

    property string path: ""
    property bool isCurrent: false
    signal ready

    readonly property bool isVideo: (function (p) {
            if (!p)
                return false;
            p = p.toLowerCase();
            return p.endsWith(".mp4") || p.endsWith(".webm") || p.endsWith(".mov") || p.endsWith(".mkv") || p.endsWith(".avi");
        })(path)

    opacity: isCurrent ? 1 : 0
    scale: isCurrent ? 1 : (Wallpapers.showPreview ? 1 : 0.8)

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    // IMAGE branch
    CachingImage {
        id: img
        anchors.fill: parent
        visible: !surface.isVideo
        path: surface.isVideo ? "" : surface.path
        onStatusChanged: {
            if (status === Image.Ready)
                surface.ready();
        }
    }

    Loader {
        id: videoLoader
        anchors.fill: parent
        visible: surface.isVideo
        active: surface.isVideo && !!surface.path
        source: Qt.resolvedUrl("VideoSurface.qml")

        onLoaded: {
            if (item) {
                item.path = surface.path;
            }
        }

        Connections {
            target: videoLoader.item
            function onReady() {
                surface.ready();
            }
        }
    }
}
