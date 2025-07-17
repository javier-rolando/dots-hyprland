import qs.modules.common
import "./notification_utils.js" as NotificationUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var body: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property var notificationBodies: []
    property real scale: 1
    property real size: 45 * scale
    property real materialIconScale: 0.57
    property real appIconScale: 0.7
    property real smallAppIconScale: 0.49
    property real materialIconSize: size * materialIconScale
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale

    function lowerBodies() {
	    return notificationBodies.length > 0
	    ? notificationBodies.map(b => (b || "").toLowerCase())
	    : [body?.toLowerCase() || ""]
    }

    property bool isTwitchNotification: lowerBodies().length > 0 &&
    lowerBodies().every(b => b.includes("from twitch"))

    property bool isKickNotification: lowerBodies().length > 0 &&
    lowerBodies().every(b => b.includes("from kick"))

    implicitWidth: size
    implicitHeight: size
    radius: Appearance.rounding.full
    color: Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        active: root.appIcon == ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "release_alert" : guessedIcon
            }
            anchors.fill: parent
            color: (root.urgency == NotificationUrgency.Critical) ? 
                ColorUtils.mix(Appearance.m3colors.m3onSecondary, Appearance.m3colors.m3onSecondaryContainer, 0.1) :
                Appearance.m3colors.m3onSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        active: root.image == "" && root.appIcon != ""
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: true
            source: Quickshell.iconPath(root.appIcon, "image-missing")
        }
    }
    Loader {
        id: notifImageLoader
        active: root.image != "" || root.isTwitchNotification || root.isKickNotification
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Image {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.isTwitchNotification
                ? Quickshell.configPath("assets/images/twitch.jpg")
                : root.isKickNotification
                ? Quickshell.configPath("assets/images/kick.webp")
                : root.image
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                width: size
                height: size
                sourceSize.width: size
                sourceSize.height: size

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != "" && !root.isTwitchNotification && !root.isKickNotification
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: true
                    source: Quickshell.iconPath(root.appIcon, "image-missing")
                }
            }
        }
    }
}
