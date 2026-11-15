import QtQuick

// A small T3 Code window with the wallpaper where a style puts it: the
// sidebar's header, the conversation, the whole sidebar, or sharp behind a
// frosted chat column.
Item {
  id: root

  property string style: "minimal"
  property url wallpaper: ""
  property color foreground: "white"
  property color background: "black"
  property color accent: "white"

  readonly property bool header: style === "minimal" || style === "full" || style === "max"
  readonly property bool conversation: style === "full" || style === "max"
  readonly property bool sidebar: style === "max"
  readonly property bool backdrop: style === "full-alt"

  readonly property real sidebarWidth: Math.round(width * 0.3)
  readonly property real headerHeight: Math.round(height * 0.2)
  readonly property real radius: 5

  function ink(alpha) { return Qt.rgba(foreground.r, foreground.g, foreground.b, alpha) }
  function shade(alpha) { return Qt.rgba(background.r, background.g, background.b, alpha) }

  Rectangle {
    id: frame
    anchors.fill: parent
    radius: root.radius
    color: root.background
    clip: true

    // Conversation
    Item {
      id: chat
      x: root.sidebarWidth
      width: parent.width - x
      height: parent.height

      Wallpaper { visible: root.conversation || root.backdrop; sharp: root.backdrop }

      Rectangle {
        visible: root.backdrop
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.68
        height: parent.height
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: root.shade(0) }
          GradientStop { position: 0.14; color: root.shade(0.72) }
          GradientStop { position: 0.86; color: root.shade(0.72) }
          GradientStop { position: 1; color: root.shade(0) }
        }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16
        width: parent.width * 0.5
        spacing: Math.max(3, parent.height * 0.07)

        Rectangle { anchors.right: parent.right; width: parent.width * 0.55; height: 4; radius: 2; color: root.ink(0.35) }
        Rectangle { width: parent.width; height: 3; radius: 1.5; color: root.ink(0.22) }
        Rectangle { width: parent.width * 0.8; height: 3; radius: 1.5; color: root.ink(0.22) }
        Rectangle { width: parent.width * 0.9; height: 3; radius: 1.5; color: root.ink(0.22) }
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.08
        width: parent.width * 0.56
        height: parent.height * 0.14
        radius: 3
        color: root.shade(0.85)
        border.width: 1
        border.color: root.ink(0.18)
      }
    }

    // Sidebar
    Item {
      width: root.sidebarWidth
      height: parent.height

      Rectangle { anchors.fill: parent; color: root.ink(0.05) }
      Wallpaper { visible: root.sidebar }

      Item {
        width: parent.width
        height: root.headerHeight
        Wallpaper { visible: root.header }
      }

      Column {
        x: parent.width * 0.16
        y: root.headerHeight + parent.height * 0.1
        width: parent.width * 0.68
        spacing: Math.max(3, parent.height * 0.08)

        Repeater {
          model: [1, 0.7, 0.85, 0.6]
          Rectangle {
            required property var modelData
            width: parent.width * modelData
            height: 3
            radius: 1.5
            color: root.ink(0.25)
          }
        }
      }

      Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.ink(0.1) }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 1
    border.color: root.ink(0.16)
  }

  // The wallpaper filling its parent: decoded tiny and stretched for a blur,
  // and tinted, unless sharp.
  component Wallpaper: Item {
    id: picture
    property bool sharp: false
    anchors.fill: parent
    clip: true

    Rectangle { anchors.fill: parent; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35) }

    Image {
      anchors.fill: parent
      source: picture.visible ? root.wallpaper : ""
      sourceSize.width: picture.sharp ? 480 : 28
      fillMode: Image.PreserveAspectCrop
      smooth: true
      cache: true
      asynchronous: true
    }

    Rectangle { anchors.fill: parent; visible: !picture.sharp; color: root.shade(0.35) }
  }
}
