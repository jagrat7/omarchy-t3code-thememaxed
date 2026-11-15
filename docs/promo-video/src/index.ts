import { loadFont } from "@remotion/fonts"
import { Composition, registerRoot, staticFile } from "remotion"
import { createElement } from "react"
import { Promo } from "./Promo"
import { DURATION, FPS } from "./timing"

loadFont({ family: "Maple Mono", url: staticFile("MapleMono-Regular.ttf"), weight: "400" })
loadFont({ family: "Maple Mono", url: staticFile("MapleMono-Bold.ttf"), weight: "700" })
loadFont({ family: "Instrument Serif", url: staticFile("InstrumentSerif-Italic.ttf"), style: "italic", weight: "400" })
loadFont({ family: "Zen Maru Gothic", url: staticFile("ZenMaruGothic-Medium.ttf"), weight: "500" })
loadFont({ family: "Cormorant Garamond", url: staticFile("fonts/CormorantGaramond-Italic.ttf"), style: "italic", weight: "300 700" })
loadFont({ family: "Space Grotesk", url: staticFile("fonts/SpaceGrotesk.ttf"), weight: "300 700" })
loadFont({ family: "Caveat", url: staticFile("fonts/Caveat.ttf"), weight: "400 700" })
loadFont({ family: "Rye", url: staticFile("fonts/Rye-Regular.ttf"), weight: "400" })
loadFont({ family: "Josefin Sans", url: staticFile("fonts/JosefinSans.ttf"), weight: "100 700" })

const Root = () =>
  createElement(Composition, {
    id: "Promo",
    component: Promo,
    durationInFrames: DURATION,
    fps: FPS,
    width: 1920,
    height: 1080,
  })

registerRoot(Root)
