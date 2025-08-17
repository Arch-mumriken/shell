pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

Item {
    id: root
    property url path: ""
    property string outFile: ""

    signal saved(string filePath)
    signal error(string reason)

    Component.onCompleted: {
        if (!path || !outFile) {
            error("Missing path or outFile");
            return;
        }
        player.source = path;
    }

    MediaPlayer {
        id: player
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.Buffered) {
                position = 0;
                vo.grabToImage(function (result) {
                    if (!result || result.status !== ImageCapture.Ready) {
                        root.error("grabToImage failed");
                        return;
                    }
                    if (result.saveToFile(outFile)) {
                        root.saved(outFile);
                    } else {
                        root.error("saveToFile failed");
                    }
                });
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                root.error("Invalid media");
            }
        }
        onErrorOccurred: function (_, msg) {
            root.error(msg);
        }
    }

    VideoOutput {
        id: vo
        visible: false
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }
}
