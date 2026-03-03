import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "sshConnections"

    readonly property string plugin_name: "sshConnections"
    readonly property string default_trigger: ";"
    readonly property string default_server: "localhost"
    readonly property string default_options: ""
    readonly property string default_terminal: Quickshell.env("TERMINAL") || "kitty"
    readonly property string default_ssh_command: "ssh"
    readonly property string default_max_history: "20"

    StyledText {
        width: parent.width
        text: "SSH Connections Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Separator Line (from command runner)
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StringSetting {
        id: triggerSetting
        settingKey: "trigger"
        label: I18n.tr("Trigger Prefix")
        description: "Type this prefix to search SSH Connection List (default: " + default_trigger + ")"
        placeholder: default_trigger
        defaultValue: default_trigger
    }

    // Separator Line (from command runner)
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
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
        description: "Terminal application to run for SSH command (e.g. kitty, alacritty, foot). '-e' will automatically be appended. Can specify options like 'kitty --hold'."
        placeholder: default_terminal
        defaultValue: default_terminal
    }

    // Separator Line (from command runner)
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StringSetting {
        settingKey: "ssh_command"
        label: "SSH Command"
        description: "Command to run for SSH (e.g. 'ssh' or 'kitten ssh')"
        placeholder: default_ssh_command
        defaultValue: default_ssh_command
    }

    // Separator Line (from command runner)
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    StyledText {
        width: parent.width
        text: "History Settings"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "A list of previously connected to servers that are not in the SSH Connection List"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "Max history items"
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

        DankTextField {
            id: historyField
            width: 80
            text: root.loadValue("max_history", default_max_history).toString()
            placeholderText: default_max_history
            onTextEdited: {
                const num = parseInt(text);
                if (!isNaN(num) && num > 0 && num <= 100) {
                    root.saveValue("max_history", num);
                }
            }
        }

        StyledText {
            text: "(1-100)"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    DankButton {
        text: "Clear Host History"
        iconName: "delete"
        backgroundColor: Theme.error
        textColor: Theme.surface
        onClicked: {
            root.saveValue("history", []);
            ToastService?.showInfo("Host history cleared");
        }
    }

    // Separator Line (from command runner)
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ServerList {
        settingKey: "server_list"
        label: "SSH Connection List"
        description: "Server List (default to '" + default_server + "')"
        defaultValue: [{"server": default_server}]
        fields: [
            {id: "server", label: "Server", placeholder: default_server, width: 130, required: true},
            {id: "options", label: "Options", placeholder: default_options, width: 195, required: false},
        ]
    }
}
