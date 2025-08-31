import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import "../bar" as Bar
import Quickshell.Hyprland
import Quickshell.Io

Item { // Full hitbox
    id: root
    implicitHeight: content.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth
    property int updatesCount: 0

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

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: 0

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: "update"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: root.updatesCount > 0 ? `${root.updatesCount}` : "-"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Hyprland.dispatch("togglespecialworkspace update");
        }
    }
}
