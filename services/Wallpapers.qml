pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    readonly property string currentNamePath: Paths.strip(`${Paths.state}/wallpaper/path.txt`)
    readonly property list<string> smartArg: Config.services.smartScheme ? [] : ["--no-smart"]

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    readonly property var _videoExts: [".mp4", ".webm", ".mov", ".mkv", ".avi"]
    function isVideoByName(p) {
        if (!p)
            return false;
        const s = p.toLowerCase();
        return _videoExts.some(ext => s.endsWith(ext));
    }
    function isMediaByName(p) {
        return Images.isValidImageByName(p) || isVideoByName(p);
    }

    readonly property string thumbsDir: Paths.strip(`${Paths.state}/wallpaper/thumbs`)

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic") {
            if (isVideoByName(previewPath)) {
                ensureThumbsDir();
                videoThumbber.request(previewPath);
            } else {
                getPreviewColoursProc.running = true;
            }
        }
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    function ensureThumbsDir() {
        Quickshell.execDetached(["mkdir", "-p", thumbsDir]);
    }

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.actualCurrent = text().trim();
            root.previewColourLock = false;
        }
    }

    Process {
        id: getPreviewColoursProc
        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: getPreviewColoursFromThumbProc
        property string thumbPath: ""
        command: ["caelestia", "wallpaper", "-p", () => getPreviewColoursFromThumbProc.thumbPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    QtObject {
        id: videoThumbber

        function _hash(s) {
            var h = 2166136261; // simple FNV-1a-ish
            for (var i = 0; i < s.length; ++i) {
                h ^= s.charCodeAt(i);
                h = (h * 16777619) >>> 0;
            }
            return h.toString(16);
        }

        function request(videoPath) {
            var comp = Qt.createComponent("VideoThumbGrabber.qml");
            if (comp.status === Component.Error) {
                console.warn("VideoThumbGrabber component error:", comp.errorString());
                return;
            }
            var out = `${root.thumbsDir}/${_hash(videoPath)}.png`;
            var obj = comp.createObject(null, {
                path: videoPath,
                outFile: out
            });
            if (!obj) {
                console.warn("Failed to create VideoThumbGrabber");
                return;
            }

            obj.saved.connect(function (filePath) {
                getPreviewColoursFromThumbProc.thumbPath = filePath;
                getPreviewColoursFromThumbProc.running = true;
                obj.destroy();
            });
            obj.failed.connect(function (reason) {
                console.warn("Video thumbnail failed:", reason);
                obj.destroy();
            });
        }
    }

    Variants {
        id: wallpapers
        Wallpaper {}
    }

    list: wallpapers.instances
    useFuzzy: Config.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    Process {
        id: getWallsProc

        running: true
        command: ["find", "-L", Paths.expandTilde(Config.paths.wallpaperDir), "-type", "d", "-path", '*/.*', "-prune", "-o", "-not", "-name", '.*', "-type", "f", "-print"]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpapers.model = text.trim().split("\n").filter(w => root.isMediaByName(w)).sort();
            }
        }
    }

    Process {
        id: watchWallsProc

        running: true
        command: ["inotifywait", "-r", "-e", "close_write,moved_to,create", "-m", Paths.expandTilde(Config.paths.wallpaperDir)]
        stdout: SplitParser {
            onRead: data => {
                if (root.isMediaByName(data))
                    getWallsProc.running = true;
            }
        }
    }

    Connections {
        target: Config.paths

        function onWallpaperDirChanged(): void {
            getWallsProc.running = true;
            watchWallsProc.running = false;
            watchWallsProc.running = true;
        }
    }

    component Wallpaper: QtObject {
        required property string modelData
        readonly property string path: modelData
        readonly property string name: path.slice(Paths.expandTilde(Config.paths.wallpaperDir).length + 1, path.lastIndexOf("."))
    }
}
