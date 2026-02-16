import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string get_updates_available: Qt.resolvedUrl("scripts/get_updates_available.py")
    property var availableUpdates: []
    property bool isChecking: false
    property bool hasError: false
    property string errorMessage: ""
    readonly property int updateCount: availableUpdates.length

    function refresh() {
        if (isChecking)
            return;
        updateChecker.running = false;
        isChecking = true;
        availableUpdates = [];
        updateChecker.command = ["python3", get_updates_available.replace(/^file:\/\//, "")];
        updateChecker.running = true;
    }

    function parseUpdates(output) {
        const lines = output.trim().split('\n').filter(line => line.trim());
        const updates = [];
        for (const line of lines) {
            const match = line.match(/^{ "name": "[^"]+", "id": "[^"]+", "currentVersion": "[^"]+", "newVersion": "[^"]+" }$/)
            if (match) {
                const obj = JSON.parse(line)
                updates.push({ name: obj.name, id: obj.id, currentVersion: obj.currentVersion, newVersion: obj.newVersion })
            }
        }
        availableUpdates = updates;
    }

    function runUpdates() {
      if (updateCount === 0 || updateInstaller.running)
          return;
      const terminal = Quickshell.env("TERMINAL") || "xterm";
      const command_string = "flatpak update -y ; echo Press Enter to close window; read"
      updateInstaller.command = [terminal, "-e", "sh", "-c", command_string]
      updateInstaller.running = true;
    }

    Timer {
        interval: 1000 * 30 * 60  // 30 minutes
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    Process {
      id: updateChecker

      onExited: exitCode => {
          isChecking = false;
      }

      stdout: StdioCollector {
          id: out
          onStreamFinished: () => {
              try {
                  parseUpdates(text);
                  hasError = false;
              } catch(e) {
                  hasError = true;
                  errorMessage = String(e);
                  availableUpdates = [];
              }
          }
      }
      stderr: StdioCollector {
          id: outErr
          onStreamFinished: () => {
              if (text && text.trim().length > 0) {
                  hasError = true;
                  errorMessage = String(text);
                  availableUpdates = [];
              }
          }
      }
    }

    Process {
      id: updateInstaller

      onExited: exitCode => {
          refresh();
      }
    }

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: DankTooltip {}
    }

    horizontalBarPill: Component {
        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            DankIcon {
                id: dankIcon
                anchors.verticalCenter: parent.verticalCenter
                name: {
                    if (root.isChecking)
                        return "refresh";
                    if (root.hasError)
                        return "error";
                    if (root.updateCount > 0)
                        return "file_download";
                    return "check_box";
                }
                size: Theme.barIconSize(root.barThickness, -4, root.barConfig?.noBackground)
                color: {
                    if (root.hasError)
                        return Theme.error;
                    if (root.updateCount > 0)
                        return Theme.primary;
                    return root.isActive ? Theme.primary : Theme.surfaceText;
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        if (root.parentScreen) {
                            tooltipLoader.active = true;
                            if (tooltipLoader.item) {
                                const tooltipText = `Flatpak Updates: ${root.updateCount}`
                                const isLeft = root.axis?.edge === "left";
                                tooltipLoader.item.show(tooltipText, tooltipLoader.item.width / 2 + dankIcon.width + dankIcon.mapToGlobal(0, 0).x, Theme.barHeight, root.parentScreen, isLeft, !isLeft);
                            }
                        }
                    }
                    onExited: {
                        if (tooltipLoader.item) {
                            tooltipLoader.item.hide();
                        }
                        tooltipLoader.active = false;
                    }
                }
            }

            StyledText {
                text: root.updateCount
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
                visible: root.updateCount > 0 && !root.isChecking
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            showCloseButton: false

            Component.onCompleted: {
              refresh();
            }

            Column {
                id: popoutContentColumn
                width: parent.width - Theme.spacingL * 2
                x: Theme.spacingL
                y: Theme.spacingL
                spacing: Theme.spacingL

                Item {
                    width: parent.width
                    height: 40

                    StyledText {
                        text: I18n.tr("Flatpak Updates")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (root.isChecking)
                                    return "Checking...";
                                if (root.hasError)
                                    return "Error";
                                if (root.updateCount === 0)
                                    return "Up to date";
                                if (root.updateCount === 1)
                                    return "1 update";
                                return root.updateCount + " updates";
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            color: {
                                if (root.hasError)
                                    return Theme.error;
                                return Theme.surfaceText;
                            }
                        }

                        DankActionButton {
                            id: checkForUpdatesButton
                            buttonSize: 28
                            iconName: "refresh"
                            iconSize: 18
                            z: 15
                            iconColor: Theme.surfaceText
                            enabled: !SystemUpdateService.isChecking
                            opacity: enabled ? 1.0 : 0.5
                            onClicked: {
                                refresh();
                            }

                            RotationAnimation {
                                target: checkForUpdatesButton
                                property: "rotation"
                                from: 0
                                to: 360
                                duration: 1000
                                running: root.isChecking
                                loops: Animation.Infinite

                                onRunningChanged: {
                                    if (!running) {
                                        checkForUpdatesButton.rotation = 0;
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 365
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                    border.width: 0

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        anchors.rightMargin: 0

                        StyledText {
                            id: statusText
                            width: parent.width
                            text: {
                                if (root.hasError) {
                                    return "Failed to check for updates:\n" + root.errorMessage;
                                }
                                if (root.isChecking) {
                                    return "Checking for updates...";
                                }
                                if (root.updateCount === 0) {
                                    return "Your system is up to date!";
                                }
                                return `Found ${root.updateCount} packages to update:`;
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            color: {
                                if (root.hasError)
                                    return Theme.errorText;
                                return Theme.surfaceText;
                            }
                            wrapMode: Text.WordWrap
                            visible: root.updateCount === 0 || root.hasError || root.isChecking
                        }

                        DankListView {
                            id: packagesList

                            width: parent.width
                            height: parent.height - (root.updateCount === 0 || root.hasError || root.isChecking ? statusText.height + Theme.spacingM : 0)
                            visible: root.updateCount > 0 && !root.isChecking && !root.hasError
                            clip: true
                            spacing: Theme.spacingXS

                            model: root.availableUpdates

                            delegate: Rectangle {
                                width: ListView.view.width - Theme.spacingM
                                height: 48
                                radius: Theme.cornerRadius
                                color: packageMouseArea.containsMouse ? Theme.primaryHoverLight : "transparent"
                                border.color: Theme.outlineLight
                                border.width: 0

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingM

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - Theme.spacingM
                                        spacing: 2

                                        StyledText {
                                            width: parent.width
                                            text: modelData.name || "Error: Cannot find name"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: `${modelData.currentVersion} → ${modelData.newVersion}`
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                    }
                                }

                                MouseArea {
                                    id: packageMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 48
                    spacing: Theme.spacingM

                    Rectangle {
                        width: (parent.width - Theme.spacingM) / 2
                        height: parent.height
                        radius: Theme.cornerRadius
                        color: updateMouseArea.containsMouse ? Theme.primaryHover : Theme.secondaryHover
                        opacity: root.updateCount > 0 ? 1.0 : 0.5

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "file_download"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Update")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: updateMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.updateCount > 0
                            onClicked: {
                                runUpdates();
                                popout.closePopout();
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - Theme.spacingM) / 2
                        height: parent.height
                        radius: Theme.cornerRadius
                        color: closeMouseArea.containsMouse ? Theme.errorPressed : Theme.secondaryHover

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "close"
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Close")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popout.closePopout();
                            }
                        }
                    }
                }
            }
        }
    }
}
