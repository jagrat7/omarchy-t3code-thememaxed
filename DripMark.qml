import QtQuick
import QtQuick.Shapes

// The plugin's icon: T3 Code's T3, from its T3Wordmark.tsx, with paint
// running off the T and the 3. Drawn in one colour, scaled to iconSize.
Item {
  id: root

  property real iconSize: 16
  property color color: "white"

  readonly property real markWidth: 94.3941
  readonly property real markHeight: 85.5
  readonly property real scaleFactor: iconSize / markWidth

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Shape {
    width: root.markWidth
    height: root.markHeight
    y: (root.iconSize - root.markHeight * root.scaleFactor) / 2
    scale: root.scaleFactor
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.color
      fillRule: ShapePath.WindingFill
      strokeWidth: -1
      PathSvg { path: "M17.92 56V10.56H0V0H48.8V10.56H30.88V56H17.92ZM71.1944 56.96C67.3011 56.96 63.4344 56.4533 59.5944 55.44C55.7544 54.3733 52.5011 52.88 49.8344 50.96L54.8744 41.04C57.0077 42.5867 59.4877 43.8133 62.3144 44.72C65.1411 45.6267 67.9944 46.08 70.8744 46.08C74.1277 46.08 76.6877 45.44 78.5544 44.16C80.4211 42.88 81.3544 41.12 81.3544 38.88C81.3544 36.7467 80.5277 35.0667 78.8744 33.84C77.2211 32.6133 74.5544 32 70.8744 32H64.9544V23.44L76.4603 10.4H52.6344V0H91.8341V8.4L79.2489 22.7370C83.3610 23.3863 86.6493 24.7940 89.1141 26.96C92.6341 30.0533 94.3941 34.0267 94.3941 38.88C94.3941 42.0267 93.5681 44.9867 91.9141 47.76C90.2611 50.48 87.7281 52.6933 84.3144 54.4C80.9011 56.1067 76.5277 56.96 71.1944 56.96Z" }
    }
    ShapePath {
      fillColor: root.color
      fillRule: ShapePath.WindingFill
      strokeWidth: -1
      PathSvg { path: "M3 8H12V30A4.5 4.5 0 0 1 3 30Z M62 50H73V80A5.5 5.5 0 0 1 62 80Z M80 46H88V62A4 4 0 0 1 80 62Z" }
    }
  }
}
