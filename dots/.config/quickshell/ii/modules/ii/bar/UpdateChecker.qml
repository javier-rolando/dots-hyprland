import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

MouseArea {
    id: root
    property int updatesCount: 0

    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight
    // anchors.fill: parent
    onClicked: {
        Hyprland.dispatch("togglespecialworkspace update");
    }

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

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        MaterialSymbol {
            text: "update"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: root.updatesCount > 0 ? `${root.updatesCount}` : "-"
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
