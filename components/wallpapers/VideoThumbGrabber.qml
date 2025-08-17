pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

Item {
    id: root
    property url path: ""
    property string outFile: ""

    signal saved(string filePath)
    signal failed(string reason)

    Component.onCompleted: {
        if (!path || !outFile) {
            failed("Missing path or outFile");
            return;
        }
        player.source = root.path;
    }

    MediaPlayer {
        id: player
        videoOutput: vo

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                player.position = 0;
                vo.grabToImage(function (result) {
                    if (!result) {
                        root.failed("grabToImage returned null");
                        return;
                    }
                    if (result.saveToFile(root.outFile))
                        root.saved(root.outFile);
                    else
                        root.failed("saveToFile failed");
                });
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                root.failed("Invalid media");
            }
        }

        onErrorOccurred: (err, msg) => {
            root.failed(msg || "Unknown media error");
        }
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        visible: false
        fillMode: VideoOutput.PreserveAspectFit
    }
}
