import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "sshConnections"

    readonly property string plugin_name: "sshConnections"
    readonly property string default_trigger: ";"
    readonly property string default_server: "localhost"
    readonly property string default_terminal: "kitty"
    readonly property string default_exec_flag: "-e"

    StyledText {
        width: parent.width
        text: "SSH Connections Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: triggerColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: triggerColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: I18n.tr("Activation")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            ToggleSetting {
                id: noTriggerToggle
                settingKey: "noTrigger"
                label: I18n.tr("Always Active")
                description: value ? I18n.tr("Keybinds shown alongside regular search results") : I18n.tr("Use trigger prefix to activate")
                defaultValue: false
                onValueChanged: {
                    if (!isInitialized)
                        return;
                    if (value)
                        root.saveValue("trigger", "");
                    else
                        root.saveValue("trigger", triggerSetting.value || default_trigger);
                }
            }

            StringSetting {
                id: triggerSetting
                visible: !noTriggerToggle.value
                settingKey: "trigger"
                label: I18n.tr("Trigger Prefix")
                description: "Type this prefix to search SSH Connection List (default: " + default_trigger + ")"
                placeholder: default_trigger
                defaultValue: default_trigger
            }
        }
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
                description: "Terminal application to run for SSH command (e.g. " + default_terminal + ", alacritty, foot)"
                placeholder: default_terminal
                defaultValue: default_terminal
            }
        }

        Column {
            width: (parent.width - Theme.spacingM) / 2
            spacing: Theme.spacingXS

            StringSetting {
                settingKey: "exec_flag"
                label: "Exec Flag"
                description: "Flag for Terminal Application to execute programs (e.g. " + default_exec_flag + ")"
                placeholder: default_exec_flag
                defaultValue: default_exec_flag
            }
        }
    }

    ListSettingWithInput {
        settingKey: "server_list"
        label: "SSH Connection List"
        description: "Server List (default to '" + default_server + "')"
        defaultValue: [{"server": default_server}]
        fields: [
            {id: "server", label: "Server", placeholder: default_server, width: 150, required: true},
        ]
    }
}
