pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

Item {
    id: root
    property url path: ""
    signal ready

    MediaPlayer {
        id: player
        source: root.path
        loops: MediaPlayer.Infinite
        videoOutput: vo

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                root.ready();
                play();
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.warn("Invalid media:", source);
            }
        }

        onErrorOccurred: (err, msg) => {
            console.warn("Media error:", msg, "source:", source);
        }
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        visible: !!root.path
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
