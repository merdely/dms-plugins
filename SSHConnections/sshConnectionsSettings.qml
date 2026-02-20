import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "sshConnections"


    Component.onCompleted: {
        const currentTrigger = root.loadValue("trigger", ">");
        if (!currentTrigger || currentTrigger.trim().length === 0)
            root.saveValue("trigger", ">");
    }

    StyledText {
        width: parent.width
        text: "SSH Connections Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "trigger"
        label: "Trigger Prefix"
        description: "Type this prefix to search SSH Connection List (default: >)"
        placeholder: ">"
        defaultValue: ">"
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    StyledText {
        width: parent.width
        text: "Configure Terminal Settings"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Column {
            width: (parent.width - Theme.spacingM) / 2
            spacing: Theme.spacingXS

            StringSetting {
                settingKey: "terminal"
                label: "Application"
                description: "Terminal application to run for SSH command (e.g. kitty, foot)"
                placeholder: "kitty"
                defaultValue: "kitty"
            }
        }

        Column {
            width: (parent.width - Theme.spacingM) / 2
            spacing: Theme.spacingXS

            StringSetting {
                settingKey: "execFlag"
                label: "Exec Flag"
                description: "Flag for Terminal Application to execute programs (e.g. -e)"
                placeholder: "-e"
                defaultValue: "-e"
            }
        }
    }

    ListSettingWithInput {
        settingKey: "server_list"
        label: "SSH Connection List"
        description: "Server List (default to 'localhost')"
        defaultValue: ["localhost"]
        fields: [
            {id: "server", label: "Server", placeholder: "localhost", width: 150, required: true},
        ]
    }
}
