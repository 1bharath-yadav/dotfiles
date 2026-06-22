import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// DictationHud.qml — floating real-time transcription overlay
// Driven by ~/.local/bin/transcribe, which writes state to
// ~/.cache/qs-dictation/{status,text} during a dictation session.
// Also reachable manually via: quickshell -c ii ipc call dictation show/hide/toggle

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    readonly property string stateDir: Quickshell.env("HOME") + "/.cache/qs-dictation"

    // Poll state files with a Timer (FileView needs files to exist at startup)
    Timer {
        id: pollTimer
        interval: 300
        repeat: true
        running: true
        onTriggered: statusReader.running = true
    }

    Process {
        id: statusReader
        command: ["cat", root.stateDir + "/status"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const s = data.trim()
                if (s === "recording" || s === "transcribing") {
                    GlobalStates.dictationActive = true
                    GlobalStates.dictationStatus = s
                } else if (s === "idle") {
                    GlobalStates.dictationActive = false
                    GlobalStates.dictationStatus = "idle"
                    GlobalStates.dictationText = ""
                }
            }
        }
    }

    // IPC for manual trigger from scripts
    IpcHandler {
        target: "dictation"

        function show() {
            GlobalStates.dictationActive = true
            GlobalStates.dictationStatus = "recording"
        }

        function hide() {
            GlobalStates.dictationActive = false
            GlobalStates.dictationStatus = "idle"
            GlobalStates.dictationText = ""
        }

        function toggle() {
            if (GlobalStates.dictationActive) hide()
            else show()
        }
    }

    // ── HUD Window ────────────────────────────────────────────────────────

    Loader {
        id: hudLoader
        active: GlobalStates.dictationActive

        sourceComponent: PanelWindow {
            id: hudRoot
            color: "transparent"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    hudRoot.screen = root.focusedScreen
                }
            }

            WlrLayershell.namespace: "quickshell:dictationHud"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                bottom: true
            }
            mask: Region {
                item: hudBg
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            margins {
                bottom: Appearance.sizes.barHeight
            }

            implicitWidth: hudBg.implicitWidth + 2 * Appearance.sizes.elevationMargin
            implicitHeight: hudBg.implicitHeight + 2 * Appearance.sizes.elevationMargin
            visible: hudLoader.active

            StyledRectangularShadow {
                target: hudBg
            }

            Rectangle {
                id: hudBg
                anchors {
                    fill: parent
                    margins: Appearance.sizes.elevationMargin
                }
                radius: Appearance.rounding.full
                color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.75)

                implicitWidth: hudRow.implicitWidth
                implicitHeight: hudRow.implicitHeight

                RowLayout {
                    id: hudRow
                    anchors.fill: parent
                    spacing: 10

                    Item {
                        implicitWidth: 30
                        implicitHeight: 30
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.topMargin: 9
                        Layout.bottomMargin: 9

                        MaterialSymbol {
                            anchors.centerIn: parent
                            color: GlobalStates.dictationStatus === "recording"
                                ? Appearance.m3colors.m3error
                                : Appearance.colors.colOnLayer0
                            text: "mic"
                            iconSize: 24

                            SequentialAnimation on opacity {
                                running: GlobalStates.dictationStatus === "recording"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 20
                        spacing: 2

                        StyledText {
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: Appearance.font.pixelSize.small
                            text: GlobalStates.dictationStatus === "recording"
                                ? Translation.tr("Recording…")
                                : Translation.tr("Transcribing…")
                        }
                    }
                }
            }
        }
    }
}
