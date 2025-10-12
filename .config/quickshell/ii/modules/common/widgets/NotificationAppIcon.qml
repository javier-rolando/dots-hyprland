import qs.modules.common
import "./notification_utils.js" as NotificationUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialCookie { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var body: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property var notificationBodies: []
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    function lowerBodies() {
	    return notificationBodies.length > 0
	    ? notificationBodies.map(b => (b || "").toLowerCase())
	    : [body?.toLowerCase() || ""]
    }

    property bool isTwitchNotification: lowerBodies().length > 0 &&
    lowerBodies().every(b => b.includes("from twitch"))

    property bool isKickNotification: lowerBodies().length > 0 &&
    lowerBodies().every(b => b.includes("from kick"))

    implicitSize: 38 * scale
    sides: isUrgent ? 12 : 0
    amplitude: implicitSize / 30

    color: isUrgent ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        active: root.appIcon == ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
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
                ? Quickshell.shellPath("assets/images/twitch.jpg")
                : root.isKickNotification
                ? Quickshell.shellPath("assets/images/kick.webp")
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
