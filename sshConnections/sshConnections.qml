import Quickshell
import QtQuick
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    readonly property string plugin_name: "sshConnections"
    readonly property string default_trigger: ";"
    readonly property string default_server: "localhost"
    readonly property string default_options: ""
    readonly property var default_server_list: [{ "server": default_server, "options": default_options }]
    readonly property string default_terminal: "kitty"
    readonly property string default_exec_flags: "-e"
    readonly property string default_ssh_command: "ssh"
    readonly property string default_max_history: "20"

    property var pluginService: null
    property string trigger: default_trigger
    property var server_list: default_server_list
    property string terminal: default_terminal
    property string exec_flags: default_exec_flags
    property string ssh_command: default_ssh_command
    property string max_history: default_max_history
    property var history: []

    signal itemsChanged()

    Component.onCompleted: {
        if (pluginService) {
            trigger = pluginService.loadPluginData(plugin_name, "trigger", default_trigger);
            server_list = pluginService.loadPluginData(plugin_name, "server_list", default_server_list);
            terminal = pluginService.loadPluginData(plugin_name, "terminal", default_terminal);
            exec_flags = pluginService.loadPluginData(plugin_name, "exec_flags", default_exec_flags);
            ssh_command = pluginService.loadPluginData(plugin_name, "ssh_command", default_ssh_command);
            max_history = pluginService.loadPluginData(plugin_name, "max_history", default_max_history);
            history = pluginService.loadPluginData(plugin_name, "history", []);
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

    function matchQuery(query, item_list) {
        const q = query.toLowerCase();
        return item_list.some(item => item.name.toLowerCase() == q);
    }

    function filterQuery(query, item_list) {
        if (! query)
            return item_list;
        const q = query.toLowerCase();
        return item_list.filter(item => { return item.name.toLowerCase().includes(q) });
    }

    // Borrowed some ideas from https://github.com/devnullvoid/dms-command-runner/blob/main/CommandRunner.qml
    function getItems(query) {
        const item_list = [];
        let index = 0;
        for (let item of server_list) {
          let action_string = item['server'];
          if (item['options'] && item['options'].length > 0) {
              action_string = action_string + ":" + item['options']
          }
          item_list.push({
              name: titleCase(item['server']),
              icon: "material:terminal",
              comment: "SSH to " + titleCase(item['server']),
              action: "ssh:" + action_string,
              categories: ["SSH Connections"],
              _preScored: 1000 - index
          });
          index = index + 1;
        }

        if (history.length > 0) {
            const filteredHistory = query ? history.filter(host => host.toLowerCase().includes(query.toLowerCase())) : history;

            for (let i = 0; i < Math.min(10, filteredHistory.length); i++) {
                const host = filteredHistory[i];
                item_list.push({
                    name: host,
                    icon: "material:terminal",
                    comment: "SSH to " + host,
                    action: "ssh:" + host,
                    categories: ["SSH Connections"],
                    _preScored: 2000 - i
                });
            }
        }

        if (!query || query.length === 0) {
          return filterQuery(null, item_list);
        } else {
            if (! matchQuery(query, item_list)) {
                const host = query.trim();

                item_list.push({
                    name: "SSH to: " + host,
                    icon: "material:terminal",
                    comment: "SSH to " + host,
                    action: "ssh:" + host,
                    categories: ["SSH Connections"],
                    _preScored: 1
                });
            }
        }

        // Filter items based on query
        return filterQuery(query, item_list);
    }

    function executeItem(item) {
        if (!item?.action)
            return;
        const action_items = item.action.split(':');
        if (action_items.length < 2)
            return;
        const server = action_items[1];
        let options = "";
        if (action_items.length > 2) {
            options = action_items.slice(2).join(':');
        }
        const terminal_object = getTerminalCommand();
        const terminal = terminal_object.cmd;
        const exec_flags = terminal_object.exec_flags;

        // Save to history
        const s = server.toLowerCase();

        if (! server_list.some(item => item.server.toLowerCase() == s)) {
            const index = history.indexOf(server)
            if (index > -1) {
                history.splice(server, 1);
            }

            history.unshift(server);

            if (history.length > max_history) {
                history = history.slice(0, max_history);
            }

            if (pluginService) {
                pluginService.savePluginData(plugin_name, "history", history);
            }

            itemsChanged();
        }

        // Build command array
        let command = []
        if (options.length > 0) {
            command = [ terminal ].concat(exec_flags.split(' '), "sh", "-c", ssh_command + " " + options + " " + server);
        } else {
            command = [ terminal ].concat(exec_flags.split(' '), "sh", "-c", ssh_command + " " + server);
        }

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
