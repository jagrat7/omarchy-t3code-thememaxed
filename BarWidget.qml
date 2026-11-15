pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui

// The bar button. Click opens the panel; middle click republishes.
BarWidget {
  id: root
  moduleName: "io.github.jagrat7.omarchy-t3code-plus"

  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor("io.github.jagrat7.omarchy-t3code-plus") : null
  readonly property Item button: buttonItem
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property color barTint: bar ? bar.barForeground : Color.foreground

  readonly property string tooltip: {
    if (!service) return "Omarchy+ for T3 Code"
    if (service.publishing) return "Omarchy+ for T3 Code — publishing"
    return "Omarchy+ for T3 Code — " + service.style
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("hostWidget" in target) target.hostWidget = root
    if ("anchorItem" in target) target.anchorItem = buttonItem
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("service" in target) target.service = root.service
  }

  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: buttonItem.implicitWidth
  implicitHeight: barSize

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onServiceChanged: injectPanel()

  BarIconButton {
    id: buttonItem
    anchors.fill: parent
    bar: root.bar
    foreground: root.barTint
    text: "󰏘"
    tooltipText: root.tooltip
    opacity: root.service && root.service.publishing ? 0.5 : 1

    onPressed: function (buttonCode) {
      if (buttonCode === Qt.MiddleButton && root.service) root.service.publish([])
      else root.toggle()
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }
}
