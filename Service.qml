import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Keeps T3 Code's "Omarchy+" theme in step with the desktop. The publisher in
// bin/ runs once when the shell starts the plugin, then after a theme switch,
// a font change, a new wallpaper or a saved edit to the plugin's config. A
// service, so exactly one of these runs per shell.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
  readonly property string currentDir: stateHome + "/omarchy/current"
  readonly property string publisher: String(Qt.resolvedUrl("bin/t3code-omarchy-theme")).replace(/^file:\/\//, "")

  property bool again: false

  // A theme switch touches several of the watched paths within a moment, so
  // changes are gathered into one run.
  function schedule() {
    settle.restart()
  }

  function publish() {
    if (run.running) {
      again = true
      return
    }
    run.running = true
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
      onStreamFinished: {
        if (text.trim() !== "") console.warn("[t3code-omarchy-theme] " + text.trim())
      }
    }
    onExited: {
      if (root.configMissing) {
        root.configMissing = false
        configWatch.active = false
        configWatch.active = true
      }
      if (root.again) {
        root.again = false
        root.publish()
      }
    }
  }

  // Written by omarchy theme set once the new theme is in place.
  FileView {
    path: root.currentDir + "/theme.generation"
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      root.schedule()
    }
  }

  // Rewritten by omarchy font set.
  FileView {
    path: root.configHome + "/fontconfig/fonts.conf"
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      root.schedule()
    }
  }

  // A watch only holds on a file that exists, and the config is written by
  // the first run. While it is missing, the watcher is rebuilt after each run.
  property bool configMissing: false

  Loader {
    id: configWatch
    sourceComponent: Item {
      FileView {
        path: root.configHome + "/omarchy-t3code-theme/config.toml"
        watchChanges: true
        printErrors: false
        onLoadFailed: root.configMissing = true
        onFileChanged: {
          reload()
          root.schedule()
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
