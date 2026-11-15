import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// The panel behind the bar button: the style, the full-alt tint and a way
// to publish again.
Panel {
  id: root
  moduleName: "io.github.jagrat7.omarchy-t3code-plus"
  ipcTarget: "io.github.jagrat7.omarchy-t3code-plus.panel"

  property var hostWidget: null
  property Item anchorItem: null
  property var service: null

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var status: service ? service.status : ({})
  readonly property string style: service ? service.style : ""
  readonly property bool autoTint: !service || service.tint === "auto"
  readonly property bool backdrop: style === "full-alt"
  // The publisher runs after every theme or wallpaper change, so its time
  // in the address makes the previews load the new picture.
  readonly property string wallpaper: "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/current/background?" + (status.time || 0)

  readonly property var styles: [
    { value: "minimal", label: "Minimal" },
    { value: "full", label: "Full" },
    { value: "max", label: "Max" },
    { value: "full-alt", label: "Full alt" }
  ]

  function ago(seconds) {
    if (!seconds) return "not yet"
    var gone = Math.max(0, Math.round(Date.now() / 1000 - seconds))
    if (gone < 60) return "just now"
    if (gone < 3600) return Math.round(gone / 60) + " min ago"
    if (gone < 86400) return Math.round(gone / 3600) + " h ago"
    return Math.round(gone / 86400) + " d ago"
  }

  function metaText() {
    if (!service) return "Starting"
    if (service.publishing) return "Publishing…"
    if (status.published === false) return "Not published: " + (status.warning || "see the log")
    return "Published " + ago(status.time)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }
      onActivateRequested: if (root.service) root.service.publish([])

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "T3 Code Thememaxed"
          meta: root.metaText()
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            DripMark {
              iconSize: Style.font.display
              color: root.foreground
            }
          }
        }

        Grid {
          id: styleGrid
          width: parent.width
          columns: 2
          spacing: Style.space(8)
          readonly property real cellWidth: (width - spacing) / 2

          Repeater {
            model: root.styles

            PanelButton {
              id: tile
              required property var modelData
              readonly property bool chosen: root.style === modelData.value
              width: styleGrid.cellWidth
              height: tileContent.implicitHeight + Style.space(8) * 2
              focusable: true
              selected: chosen
              active: chosen
              Keys.onEscapePressed: root.close()
              onClicked: root.service.setStyle(modelData.value)

              Column {
                id: tileContent
                anchors.centerIn: parent
                width: parent.width - Style.space(8) * 2
                spacing: Style.space(6)

                StylePreview {
                  width: parent.width
                  height: Math.round(width * 0.58)
                  style: tile.modelData.value
                  wallpaper: root.opened ? root.wallpaper : ""
                  foreground: root.foreground
                  background: Color.background
                  accent: Color.accent
                }

                Text {
                  width: parent.width
                  text: tile.modelData.label
                  horizontalAlignment: Text.AlignHCenter
                  color: tile.chosen ? Color.accent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: tile.chosen
                }
              }
            }
          }
        }

        PanelSeparator { width: parent.width; foreground: root.foreground; visible: root.backdrop }
        SectionHeader { text: "CHAT COLUMN TINT"; visible: root.backdrop }

        Row {
          id: tintRow
          visible: root.backdrop
          width: parent.width
          spacing: Style.space(10)

          PanelButton {
            id: autoButton
            text: "Auto"
            active: root.autoTint
            onClicked: root.service.setTint("auto")
          }

          PanelSlider {
            anchors.verticalCenter: autoButton.verticalCenter
            width: tintRow.width - autoButton.width - tintRow.spacing
            bar: root.bar
            minimum: 0
            maximum: 1
            step: 0.05
            value: root.autoTint ? (root.status.tint || 0) : Number(root.service.tint)
            enabled: !!root.service
            onReleased: function (value) { root.service.setTint(value) }
          }
        }

        PanelSeparator { width: parent.width; foreground: root.foreground }
        Row {
          id: actionRow
          width: parent.width
          spacing: Style.space(6)
          readonly property real cellWidth: (width - spacing) / 2

          PanelButton {
            width: actionRow.cellWidth
            text: root.service && root.service.publishing ? "Publishing…" : "Publish again"
            tooltipText: "Rebuild the theme now. Full and max also deal a new wallpaper."
            enabled: !!root.service && !root.service.publishing
            onClicked: root.service.publish([])
          }

          PanelButton {
            width: actionRow.cellWidth
            text: "Edit config"
            onClicked: {
              root.service.editConfig()
              root.close()
            }
          }
        }
      }
    }
  }

  // The panel's controls in the bar's colour and font.
  component PanelButton: Button {
    fontSize: Style.font.bodySmall
    bordered: true
    foreground: root.foreground
    fontFamily: root.fontFamily
    enabled: !!root.service
  }

  component SectionHeader: PanelSectionHeader {
    foreground: root.foreground
    fontFamily: root.fontFamily
  }
}
