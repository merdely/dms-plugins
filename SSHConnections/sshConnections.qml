import Quickshell
import QtQuick
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    readonly property string default_trigger: ";"
    readonly property var default_server_list: [{ "server": "localhost" }]
    readonly property string default_terminal: "kitty"
    readonly property string default_exec_flag: "-e"


    property var pluginService: null
    property string trigger: default_trigger
    property var server_list: default_server_list
    property string terminal: default_terminal
    property string exec_flag: default_exec_flag

    signal itemsChanged()

    Component.onCompleted: {
        console.info("sshConnections: Plugin loaded")

        if (pluginService) {
            trigger = pluginService.loadPluginData("sshConnections", "trigger", default_trigger);
            server_list = pluginService.loadPluginData("sshConnections", "server_list", default_server_list);
            terminal = pluginService.loadPluginData("sshConnections", "terminal", default_terminal);
            exec_flag = pluginService.loadPluginData("sshConnections", "exec_flag", default_exec_flag);
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
              // _preScored: 1000 - i

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
        const host = item.action.substring(4); // Remove "sshConnections:" prefix
        const terminal = getTerminalCommand();
        console.info("sshConnections: Running '" + terminal.cmd + " " + terminal.exec_flag + " ssh " + host + "'");
        Quickshell.execDetached([terminal.cmd, terminal.exec_flag, "ssh", host]);
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    function getTerminalCommand() {
        if (pluginService) {
            const terminal = pluginService.loadPluginData("sshConnections", "terminal", default_terminal);
            const exec_flag = pluginService.loadPluginData("sshConnections", "exec_flag", default_exec_flag);
            if (terminal && exec_flag) {
                return {
                    cmd: terminal,
                    exec_flag: exec_flag
                };
            }
        }
        return {
            cmd: default_terminal,
            exec_flag: default_exec_flag
        };
    }
}
