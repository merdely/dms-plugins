import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "flatpakUpdates"

    readonly property string plugin_name: "flatpakUpdates"
    readonly property string default_terminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property int default_check_interval: 30

    StyledText {
        width: parent.width
        text: "Flatpak Updates Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Terminal Settings"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "terminal"
        label: "Application"
        description: "Terminal application to run Flatpak command (e.g. kitty, alacritty, foot)"
        placeholder: default_terminal
        defaultValue: default_terminal
    }

    StringSetting {
        settingKey: "check_interval"
        label: "Check Interval"
        description: "Number of minutes between checks for Flatpak updates"
        placeholder: default_check_interval
        defaultValue: default_check_interval
    }
}
