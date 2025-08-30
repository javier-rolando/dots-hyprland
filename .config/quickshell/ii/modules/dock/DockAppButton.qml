import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    property bool isSeparator: appToplevel.appId === "SEPARATOR"

    property var iconOverrides: {
        // "kitty-special": "term",
        // "kitty-update": "update",
        // "kitty-install": "install",
        // "kitty-uninstall": "uninstall",
        // "kitty-english": "english",
        "chrome-chat.openai.com__-default": { type: "path", value: "/home/javier/.config/quickshell/ii/assets/dock/ChatGPT.svg" },
        "chrome-translate.google.com__-default": { type: "path", value: "/home/javier/.config/quickshell/ii/assets/dock/translate.svg" },
    }

    property var desktopEntry: DesktopEntries.byId(appToplevel.appId)
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    onClicked: {
        const specialWorkspaces = {
            "kitty-special": "term",
            "kitty-yazi": "yazi",
            "kitty-update": "update",
            "kitty-install": "install",
            "kitty-uninstall": "uninstall",
            "kitty-btop": "btop",
            "kitty-english": "english",
            "eu.betterbird.betterbird": "betterbird",
            "ferdium": "ferdium",
            "vesktop": "vesktop",
            "spotify": "spotify",
            "chrome-chat.openai.com__-default": "openai",
            "chrome-translate.google.com__-default": "translate"
        };

        const workspaceName = specialWorkspaces[appToplevel.appId];

        if (workspaceName) {
            if (appToplevel.toplevels.length > 0) {
                Hyprland.dispatch(`togglespecialworkspace ${workspaceName}`);
            }
            // NOTE: Launch logic is removed as per your implementation.
            // If you want to launch the app when it's closed, add an 'else' block here.
            return;
        }

        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    altAction: () => {
        if (Config.options.dock.pinnedApps.indexOf(appToplevel.appId) !== -1) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appToplevel.appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appToplevel.appId])
        }
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: IconImage {
                    source: {
                        const override = root.iconOverrides[appToplevel.appId];
                        if (override) {
                            if (override.type === "path") {
                                return "file://" + override.value; // Format as a local file URL
                            }
                            // If type is "name", use it as an icon name
                            return Quickshell.iconPath(override.value, "image-missing");
                        }
                        // Fallback to original behavior if no override exists
                        return Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing");
                    }
                    implicitSize: root.iconSize
                }
            }

            Loader {
                active: Config.options.dock.monochromeIcons
                anchors.fill: iconImageLoader
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false // There's already color overlay
                        anchors.fill: parent
                        source: iconImageLoader
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                    }
                }
            }

            RowLayout {
                spacing: 3
                anchors {
                    top: iconImageLoader.bottom
                    topMargin: 2
                    horizontalCenter: parent.horizontalCenter
                }
                Repeater {
                    model: Math.min(appToplevel.toplevels.length, 3)
                    delegate: Rectangle {
                        required property int index
                        radius: Appearance.rounding.full
                        implicitWidth: (appToplevel.toplevels.length <= 3) ? 
                            root.countDotWidth : root.countDotHeight // Circles when too many
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                    }
                }
            }
        }
    }
}
