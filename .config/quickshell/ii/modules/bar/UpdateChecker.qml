
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    property int updatesCount: 0

    implicitWidth: 40
    implicitHeight: 32

    Timer {
        id: pollTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkUpdates.running = true
        }
    }

    Process {
        id: checkUpdates
        command: ["sh", "-c", `
        if ! updates_arch=$(checkupdates 2>/dev/null | wc -l); then
        updates_arch=0; fi;
        if ! updates_aur=$(paru -Qua 2>/dev/null | wc -l); then
        updates_aur=0; fi;
        echo $((updates_arch + updates_aur))
        `]
        stdout: SplitParser {
            onRead: data => {
                root.updatesCount = parseInt(data.trim()) || 0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Hyprland.dispatch("togglespecialworkspace update");
        }

        RowLayout {
            spacing: 4
            anchors.centerIn: parent

            MaterialSymbol {
                text: "update"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                text: root.updatesCount > 0 ? `${root.updatesCount}` : "-"
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
            }
        }
    }
}
