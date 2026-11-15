import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Keeps T3 Code's "Omarchy+" theme in step with the desktop. The publisher in
// bin/ runs once when the shell starts the plugin, then after a theme switch,
// a font change, a new wallpaper or a saved edit to the plugin's config. A
// service, so exactly one of these runs per shell. The bar widget reads its
// state and changes settings through it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
  readonly property string currentDir: stateHome + "/omarchy/current"
  readonly property string publisher: String(Qt.resolvedUrl("bin/t3code-omarchy-plus")).replace(/^file:\/\//, "")

  readonly property string configPath: configHome + "/omarchy-t3code-plus/config.toml"
  readonly property string statusPath: stateHome + "/omarchy-t3code-plus/status.json"

  property bool again: false
  property var queued: []
  // Set while the publisher saves a setting itself, so the config watcher
  // does not publish a second time for the same change.
  property bool savingSetting: false

  // What the widget shows. status is what the publisher last wrote.
  readonly property bool publishing: run.running
  property var status: ({})
  property string style: "full"
  property string tint: "auto"
  // A watch only holds on a file that exists, and the config is written by
  // the first run. While it is missing, the watcher is rebuilt after each run.
  property bool configMissing: false

  // A theme switch touches several of the watched paths within a moment, so
  // changes are gathered into one run.
  function schedule() {
    settle.restart()
  }

  function publish(args) {
    if (run.running) {
      again = true
      if (args && args.length) queued = args
      return
    }
    run.command = [root.publisher].concat(args || [])
    run.running = true
  }

  function setStyle(name) {
    if (name === style) return
    style = name
    savingSetting = true
    publish(["--style", name])
  }

  // "auto", or a number from 0 to 1.
  function setTint(value) {
    var text = value === "auto" ? "auto" : String(Math.round(Number(value) * 100) / 100)
    if (text === tint) return
    tint = text
    savingSetting = true
    publish(["--tint", text])
  }

  function editConfig() {
    editor.running = true
  }

  function readConfig(text) {
    var styleMatch = /^\s*style\s*=\s*"([^"]*)"/m.exec(text)
    if (styleMatch) style = styleMatch[1]
    var tintMatch = /^\s*backdrop_tint\s*=\s*"?([^"\s#]*)"?/m.exec(text)
    tint = tintMatch ? tintMatch[1] : "auto"
  }

  Process {
    id: editor
    command: ["omarchy-launch-editor", root.configPath]
  }

  FileView {
    path: root.statusPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.status = JSON.parse(text())
      } catch (error) {
        root.status = ({})
      }
    }
  }

  Timer {
    id: settle
    interval: 400
    onTriggered: root.publish()
  }

  Process {
    id: run
    command: [root.publisher]
    stderr: StdioCollector {
      onStreamFinished: if (text.trim() !== "") console.warn("[t3code-omarchy-plus] " + text.trim())
    }
    onExited: {
      root.savingSetting = false
      if (root.configMissing) {
        root.configMissing = false
        configWatch.active = false
        configWatch.active = true
      }
      if (root.again) {
        root.again = false
        var args = root.queued
        root.queued = []
        root.publish(args)
      }
    }
  }

  // A file whose every change means publishing again.
  component Trigger: FileView {
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      root.schedule()
    }
  }

  // Written by omarchy theme set once the new theme is in place.
  Trigger { path: root.currentDir + "/theme.generation" }
  // Rewritten by omarchy font set.
  Trigger { path: root.configHome + "/fontconfig/fonts.conf" }

  Loader {
    id: configWatch
    sourceComponent: Item {
      FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoadFailed: root.configMissing = true
        onLoaded: root.readConfig(text())
        onFileChanged: {
          reload()
          if (!root.savingSetting) root.schedule()
        }
      }
    }
  }

  // The wallpaper is the "background" symlink in this folder. Nothing announces
  // a new one, but replacing the link changes the folder, which the model sees.
  FolderListModel {
    folder: "file://" + root.currentDir
    showDirs: true
    showHidden: true
    showDotAndDotDot: false
    showOnlyReadable: false
    onStatusChanged: {
      if (status === FolderListModel.Ready) root.schedule()
    }
  }

  Component.onCompleted: schedule()
}
