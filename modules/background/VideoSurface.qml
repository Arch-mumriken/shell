pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

Item {
    id: root
    property url path: ""
    property var onReady: function () {}

    MediaPlayer {
        id: player
        source: root.path
        loops: MediaPlayer.Infinite
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                if (root.onReady)
                    root.onReady();
                play();
            }
        }
        onErrorOccurred: function (_, msg) {
            console.warn("Media error:", msg);
        }

        videoOutput: vo
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: !!root.path
    }
}
