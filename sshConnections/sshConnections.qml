import Quickshell
import QtQuick
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    readonly property string plugin_name: "sshConnections"
    readonly property string default_trigger: ";"
    readonly property string default_server: "localhost"
    readonly property var default_server_list: [{ "server": default_server }]
    readonly property string default_terminal: "kitty"
    readonly property string default_exec_flags: "-e"
    readonly property string default_ssh_command: "ssh"

    property var pluginService: null
    property string trigger: default_trigger
    property var server_list: default_server_list
    property string terminal: default_terminal
    property string exec_flags: default_exec_flags
    property string ssh_command: default_ssh_command

    signal itemsChanged()

    Component.onCompleted: {
        console.info(plugin_name + ": Plugin loaded")

        if (pluginService) {
            trigger = pluginService.loadPluginData(plugin_name, "trigger", default_trigger);
            server_list = pluginService.loadPluginData(plugin_name, "server_list", default_server_list);
            terminal = pluginService.loadPluginData(plugin_name, "terminal", default_terminal);
            exec_flags = pluginService.loadPluginData(plugin_name, "exec_flags", default_exec_flags);
            ssh_command = pluginService.loadPluginData(plugin_name, "ssh_command", default_ssh_command);
        }
    }

    function titleCase(str) {
        return str
            .toLowerCase()
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ')
            .charAt(0).toUpperCase() + str.slice(1);
    }

    function getItems(query) {
        const item_list = [];
        for (let item of server_list) {
          item_list.push({
              name: titleCase(item['server']),
              icon: "material:terminal",
              comment: "SSH to " + titleCase(item['server']),
              action: "ssh:" + item['server'],
              categories: ["SSH Connections"],
          });
        }

        if (!query || query.length === 0) {
          return item_list
        }

        // Filter items based on query
        const lowerQuery = query.toLowerCase()
        return item_list.filter(item => {
            return item.name.toLowerCase().includes(lowerQuery) ||
                   item.comment.toLowerCase().includes(lowerQuery)
        })
    }

    function executeItem(item) {
        if (!item?.action)
            return;
        const server = item.action.substring(4); // Remove "ssh:" prefix
        const terminal_object = getTerminalCommand();
        const terminal = terminal_object.cmd;
        const exec_flags = terminal_object.exec_flags;

        // Build command array
        const command = [ terminal ].concat(exec_flags.split(' '), ssh_command.split(' '), server.split(' '));

        console.info(plugin_name + ": Running '" + command.join(' ') + "'");
        Quickshell.execDetached(command);
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    function getTerminalCommand() {
        if (pluginService) {
            const terminal = pluginService.loadPluginData(plugin_name, "terminal", default_terminal);
            const exec_flags = pluginService.loadPluginData(plugin_name, "exec_flags", default_exec_flags);
            if (terminal && exec_flags) {
                return {
                    cmd: terminal,
                    exec_flags: exec_flags
                };
            }
        }
        return {
            cmd: default_terminal,
            exec_flags: default_exec_flags
        };
    }
}
