pragma ComponentBehavior: Bound

import qs.components
import qs.components.wallpapers
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root

    property string source: Wallpapers.current
    property var current: null

    anchors.fill: parent

    Component.onCompleted: current = one

    onSourceChanged: {
        if (!source) {
            current = null;
            return;
        }
        const next = (current === one) ? two : one;
        if (next.path === source) {
            current = next;
        } else {
            next.path = source;
        }
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
        isCurrent: root.current === one
        onReady: if (root.source && path === root.source)
            root.current = one
    }

    WallSurface {
        id: two
        anchors.fill: parent
        isCurrent: root.current === two
        onReady: if (root.source && path === root.source)
            root.current = two
    }
}
