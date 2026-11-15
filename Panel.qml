import QtQuick
import qs.Commons
import qs.Ui

// The panel behind the bar button: the style, the backdrop's tint, what was
// last published and a way to publish again.
Panel {
  id: root
  moduleName: "io.github.jagrat7.omarchy-t3code-plus"
  ipcTarget: "io.github.jagrat7.omarchy-t3code-plus.panel"

  property var hostWidget: null
  property Item anchorItem: null
  property var service: null

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var status: service ? service.status : ({})
  readonly property string style: service ? service.style : ""
  readonly property bool autoTint: !service || service.tint === "auto"
  readonly property bool backdrop: style === "backdrop"

  readonly property var styles: [
    { value: "minimal", label: "Minimal", about: "The theme's first wallpaper behind the sidebar's header." },
    { value: "full", label: "Full", about: "The header, plus a random theme wallpaper behind the conversation, blurred." },
    { value: "too-much", label: "Too much", about: "Full, plus the wallpaper down the whole sidebar." },
    { value: "backdrop", label: "Backdrop", about: "The desktop wallpaper, sharp, behind a frosted chat column." }
  ]

  function aboutStyle() {
    for (var i = 0; i < styles.length; i++) if (styles[i].value === style) return styles[i].about
    return ""
  }

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

  function pictureText() {
    var picture = status.picture
    if (!picture) return style === "minimal" || style === "full" || style === "too-much" ? "Blurred" : "None"
    var size = picture.width ? picture.width + "×" + picture.height + " " : ""
    var kind = status.rendering === "pixelated" ? "pixel art, " : ""
    return size + kind + String(picture.format).toUpperCase() + ", " + (picture.bytes / 1024).toFixed(1) + " KB"
  }

  function tintText() {
    if (status.tint === undefined) return "—"
    return Math.round(status.tint * 100) + "%" + (autoTint ? ", from the wallpaper" : "")
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
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
          title: "Omarchy+ for T3 Code"
          meta: root.metaText()
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "󰏘"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        SectionHeader { text: "STYLE" }

        Row {
          id: styleRow
          width: parent.width
          spacing: Style.space(5)
          readonly property real cellWidth: (width - spacing * 3) / 4

          Repeater {
            model: root.styles

            PanelButton {
              required property var modelData
              width: styleRow.cellWidth
              text: modelData.label
              focusable: true
              active: root.style === modelData.value
              Keys.onEscapePressed: root.close()
              onClicked: root.service.setStyle(modelData.value)
            }
          }
        }

        Note { text: root.aboutStyle() }

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

        SectionHeader { text: "LAST PUBLISHED" }

        InfoRow { label: "Theme"; value: root.status.theme || "—" }
        InfoRow { label: "Wallpaper"; value: root.pictureText() }
        InfoRow { label: "Tint"; value: root.tintText(); visible: root.backdrop }
        InfoRow {
          label: "CSS"
          value: root.status.chars
            ? root.status.chars.toLocaleString(Qt.locale(), "f", 0) + " of " + (root.status.limit || 20000).toLocaleString(Qt.locale(), "f", 0) + " characters"
            : "—"
        }

        Row {
          id: actionRow
          width: parent.width
          spacing: Style.space(6)
          readonly property real cellWidth: (width - spacing) / 2

          PanelButton {
            width: actionRow.cellWidth
            text: root.service && root.service.publishing ? "Publishing…" : "Publish again"
            tooltipText: "Rebuild the theme now. Full and too-much also deal a new wallpaper."
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

        Note {
          text: "In T3 Code, choose Settings › Appearance › Omarchy+."
          font.pixelSize: Style.font.caption
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

  component Note: Text {
    width: parent.width
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  component InfoRow: Item {
    id: infoRow
    required property string label
    required property string value

    width: parent.width
    height: Math.max(rowLabel.implicitHeight, rowValue.implicitHeight)

    Text {
      id: rowLabel
      anchors.left: parent.left
      text: infoRow.label
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    Text {
      id: rowValue
      anchors.right: parent.right
      width: infoRow.width - rowLabel.implicitWidth - Style.space(12)
      text: infoRow.value
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideLeft
    }
  }
}
