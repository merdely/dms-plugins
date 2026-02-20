import Quickshell
import QtQuick
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string trigger: ";"

    property var server_list: [ { "server": "localhost" } ]
    property string terminal: "kitty"
    property string execFlag: "-e"

    signal itemsChanged()

    Component.onCompleted: {
        console.info("sshConnections: Plugin loaded")

        if (pluginService) {
            trigger = pluginService.loadPluginData("sshConnections", "trigger", ";");
            server_list = pluginService.loadPluginData("sshConnections", "server_list", [{"server":"localhost"}]);
            terminal = pluginService.loadPluginData("sshConnections", "terminal", "kitty");
            execFlag = pluginService.loadPluginData("sshConnections", "execFlag", "-e");
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
        console.info("sshConnections: Running '" + terminal.cmd + " " + terminal.execFlag + " ssh " + host + "'");
        Quickshell.execDetached([terminal.cmd, terminal.execFlag, "ssh", host]);
    }

    // Borrowed from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    function getTerminalCommand() {
        if (pluginService) {
            const terminal = pluginService.loadPluginData("sshConnections", "terminal", "kitty");
            const execFlag = pluginService.loadPluginData("sshConnections", "execFlag", "-e");
            if (terminal && execFlag) {
                return {
                    cmd: terminal,
                    execFlag: execFlag
                };
            }
        }
        return {
            cmd: "kitty",
            execFlag: "-e"
        };
    }

    onTriggerChanged: {
        if (pluginService) {
            pluginService.savePluginData("sshConnections", "trigger", trigger);
            pluginService.savePluginData("sshConnections", "server_list", server_list);
            pluginService.savePluginData("sshConnections", "terminal", terminal);
            pluginService.savePluginData("sshConnections", "execFlag", execFlag);
        }
    }
}
