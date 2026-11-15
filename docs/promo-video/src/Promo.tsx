import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion"
import type { CSSProperties, FC } from "react"
import snapshot from "../data/snapshot-2026-11-15.json"
import { Panel, PANEL_H, tileCenter } from "./Panel"
import { at, CLICK_BARS, easeInOut, easeOut, easeSoft, END_BAR, THEME_START, ZOOM_BAR } from "./timing"

const DISPLAY = "Instrument Serif"
const LABEL = "Zen Maru Gothic"
const MONO = "Maple Mono"
const WIPE = 16
const FADE = 8
const SHOT = { w: 2528, h: 1378 }
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const

type Rect = { x: number; y: number; w: number; h: number }
const sized = (x: number, y: number, w: number): Rect => ({ x, y, w, h: Math.round((w * SHOT.h) / SHOT.w) })
const SMALL = sized(76, 196, 1250)
const BIG = sized(250, 196, 1420)
const PANEL_X = 1374
const PANEL_Y = SMALL.y + Math.round((SMALL.h - PANEL_H) / 2)

const styles = snapshot.styles
const themes = snapshot.themes
const pickAt = CLICK_BARS.map((bar) => at(bar, 1))
const themeStart = themes.map((_, i) => at(THEME_START + i))
const themeAt = themeStart.slice(1)

type Layer = { src: string; start: number }
const windowLayers: Layer[] = [
  { src: styles[0].shot, start: 0 },
  ...styles.slice(1).map((style, i) => ({ src: style.shot, start: pickAt[i] })),
  ...themes.map((theme, i) => ({ src: theme.shot, start: themeStart[i] })),
]
const desktopLayers: Layer[] = [
  { src: themes[0].desktop, start: 0 },
  ...themes.slice(1).map((theme, i) => ({ src: theme.desktop, start: themeAt[i] })),
]
const accents = [
  { color: themes[0].accent, start: 0 },
  ...themes.slice(1).map((theme, i) => ({ color: theme.accent, start: themeAt[i] + WIPE / 2 })),
]
type Face = { family: string; italic?: boolean; weight?: number; size: number }
const DISPLAY_FACE: Face = { family: DISPLAY, italic: true, size: 96 }
const themeFaces: Record<string, Face> = {
  "rose-meridian": { family: "Cormorant Garamond", italic: true, weight: 600, size: 104 },
  "ame-quattro-local": { family: "Space Grotesk", weight: 600, size: 84 },
  "infrared-snooze": { family: "Caveat", weight: 700, size: 116 },
  "sunlit-sands": { family: "Rye", size: 80 },
  "harbor": { family: "Josefin Sans", weight: 600, size: 86 },
}

const headlines: { text: string; mode?: string; face?: Face; start: number }[] = [
  { text: "T3 Code Thememaxed", start: 0 },
  { text: styles[0].label, start: at(ZOOM_BAR) },
  ...styles.slice(1).map((style, i) => ({ text: style.label, start: pickAt[i] })),
  ...themes.map((theme, i) => ({ text: theme.name, mode: theme.style, face: themeFaces[theme.id], start: themeStart[i] })),
]

const header: Rect = { x: 0, y: 0, w: 310, h: 46 }
const sidebar: Rect = { x: 0, y: 0, w: 310, h: SHOT.h }
const conversation: Rect = { x: 310, y: 48, w: SHOT.w - 310, h: SHOT.h - 48 }
const besideColumn: Rect = { x: 310, y: 48, w: 640, h: SHOT.h - 48 }
const column: Rect = { x: 950, y: 48, w: 940, h: SHOT.h - 48 }

type Note = { span: Rect; text: string; above?: boolean; alignStart?: boolean; delay?: number }
type Spotlight = { start: number; end: number; lit: Rect[]; notes: Note[] }
const spotlightFor = (bar: number, lit: Rect[], notes: Note[]): Spotlight => ({ start: at(bar, 2), end: at(bar + 1, 3), lit, notes })
const spotlights: Spotlight[] = [
  {
    start: at(ZOOM_BAR, 1),
    end: at(ZOOM_BAR + 1) - FADE,
    lit: [header],
    notes: [{ span: header, text: "Wallpaper in the sidebar header", above: true, alignStart: true }],
  },
  spotlightFor(CLICK_BARS[0], [header, conversation], [{ span: conversation, text: "Blurred wallpaper behind the chat" }]),
  spotlightFor(CLICK_BARS[1], [sidebar, conversation], [{ span: sidebar, text: "And behind the sidebar", above: true, alignStart: true }]),
  spotlightFor(CLICK_BARS[2], [conversation], [
    { span: besideColumn, text: "Sharp wallpaper", above: true },
    { span: column, text: "Frosted chat column", delay: at(0, 1) },
  ]),
]

const lerp = (a: number, b: number, t: number) => a + (b - a) * t

const wipe = (frame: number, start: number) => interpolate(frame, [start, start + WIPE], [0, 100], { ...clamp, easing: easeSoft })

const Stack: FC<{ layers: Layer[]; frame: number; fade?: boolean }> = ({ layers, frame, fade }) => (
  <>
    {layers.map((layer, i) => {
      if (frame < layer.start) return null
      const next = layers[i + 1]
      if (next && frame >= next.start + WIPE) return null
      const p = i === 0 ? 100 : wipe(frame, layer.start)
      const style: CSSProperties = fade ? { opacity: p / 100 } : { clipPath: `inset(0 ${100 - p}% 0 0)` }
      return (
        <div key={layer.src + layer.start}>
          <Img
            src={staticFile(layer.src)}
            style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", ...style }}
          />
          {!fade && p > 0 && p < 100 && (
            <div style={{ position: "absolute", top: 0, bottom: 0, left: `${p}%`, width: 3, marginLeft: -1.5, background: "rgba(255,255,255,0.9)" }} />
          )}
        </div>
      )
    })}
  </>
)

const current = <T extends { start: number }>(items: T[], frame: number) =>
  items.reduce((found, item) => (frame >= item.start ? item : found), items[0])

const activeSpotlight = (frame: number) => spotlights.find((item) => frame >= item.start && frame < item.end + FADE)

const shownFrom = (frame: number, spot: Spotlight, from: number) =>
  interpolate(frame, [from, from + FADE, spot.end, spot.end + FADE], [0, 1, 1, 0], { ...clamp, easing: easeSoft })

const Dim: FC<{ frame: number; scale: number }> = ({ frame, scale }) => {
  const spot = activeSpotlight(frame)
  if (!spot) return null
  return (
    <svg width="100%" height="100%" style={{ position: "absolute", inset: 0, opacity: shownFrom(frame, spot, spot.start) }}>
      <defs>
        <mask id="lit">
          <rect width="100%" height="100%" fill="white" />
          {spot.lit.map((r) => (
            <rect key={`${r.x},${r.y}`} x={r.x * scale} y={r.y * scale} width={r.w * scale} height={r.h * scale} fill="black" />
          ))}
        </mask>
      </defs>
      <rect width="100%" height="100%" fill="rgba(0,0,0,0.6)" mask="url(#lit)" />
    </svg>
  )
}

const Notes: FC<{ frame: number; scale: number; win: Rect; accent: string }> = ({ frame, scale, win, accent }) => {
  const spot = activeSpotlight(frame)
  if (!spot) return null
  const gap = 16
  return (
    <>
      {spot.notes.map((note) => {
        const shown = shownFrom(frame, spot, spot.start + (note.delay ?? 0))
        const left = win.x + Math.max(0, note.span.x * scale) + 4
        const right = win.x + Math.min(win.w, (note.span.x + note.span.w) * scale) - 4
        return (
          <div
            key={note.text}
            style={{
              position: "absolute",
              left,
              width: right - left,
              opacity: shown,
              display: "flex",
              flexDirection: note.above ? "column-reverse" : "column",
              gap: 12,
              ...(note.above ? { bottom: 1080 - win.y + gap } : { top: win.y + win.h + gap }),
            }}
          >
            <div
              style={{
                height: 12,
                borderLeft: `2px solid ${accent}`,
                borderRight: `2px solid ${accent}`,
                [note.above ? "borderTop" : "borderBottom"]: `2px solid ${accent}`,
                transformOrigin: note.above ? "50% 100%" : "50% 0",
                transform: `scaleX(${0.6 + 0.4 * shown})`,
              }}
            />
            <div
              style={{
                display: "flex",
                justifyContent: note.alignStart ? "flex-start" : "center",
                fontFamily: LABEL,
                fontWeight: 500,
                fontSize: 30,
                color: "#ffffff",
                whiteSpace: "nowrap",
                textShadow: "0 2px 10px rgba(0,0,0,0.8)",
                transform: `translateY(${(1 - shown) * (note.above ? -8 : 8)}px)`,
              }}
            >
              {note.text}
            </div>
          </div>
        )
      })}
    </>
  )
}

const Cursor: FC<{ frame: number; opacity: number }> = ({ frame, opacity }) => {
  const tile = (i: number) => {
    const c = tileCenter(i)
    return { x: PANEL_X + c.x, y: PANEL_Y + c.y }
  }
  let pos = tile(0)
  pickAt.forEach((pick, i) => {
    const t = interpolate(frame, [pick - 16, pick - 3], [0, 1], { ...clamp, easing: easeInOut })
    const next = tile(i + 1)
    pos = { x: lerp(pos.x, next.x, t), y: lerp(pos.y, next.y, t) }
  })
  const press = Math.max(...pickAt.map((pick) => interpolate(frame, [pick, pick + 3, pick + 9], [0, 1, 0], clamp)))
  return (
    <svg
      width={30}
      height={44}
      viewBox="0 0 17 25"
      style={{ position: "absolute", left: pos.x - 2, top: pos.y - 2, opacity, transform: `scale(${1 - press * 0.15})`, transformOrigin: "0 0" }}
    >
      <path d="M1 1 L1 20 L5.5 15.5 L9 23 L12 21.6 L8.6 14.6 L15 14.6 Z" fill="#ffffff" stroke="#000000" strokeWidth={1.2} strokeLinejoin="round" />
    </svg>
  )
}

const Headline: FC<{ frame: number; win: Rect }> = ({ frame, win }) => {
  if (frame >= at(END_BAR)) return null
  const line = current(headlines, frame)
  const face = line.face ?? DISPLAY_FACE
  const enter = interpolate(frame - line.start, [0, 12], [0, 1], { easing: easeOut, extrapolateRight: "clamp" })
  return (
    <div
      style={{
        position: "absolute",
        left: win.x,
        width: win.w,
        top: 64,
        textAlign: "center",
        fontFamily: face.family,
        fontStyle: face.italic ? "italic" : "normal",
        fontWeight: face.weight ?? 400,
        fontSize: face.size,
        lineHeight: 1,
        height: 96,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: "#ffffff",
        textShadow: "0 2px 14px rgba(0,0,0,0.75)",
        opacity: enter,
        transform: `translateY(${(1 - enter) * 12}px)`,
      }}
    >
      {line.text}
      {line.mode && (
        <span style={{ fontFamily: LABEL, fontStyle: "normal", fontWeight: 500, fontSize: 40, marginLeft: 28, opacity: 0.8 }}>
          {line.mode}
        </span>
      )}
    </div>
  )
}

const EndCard: FC<{ frame: number }> = ({ frame }) => {
  const start = at(END_BAR)
  if (frame < start) return null
  const local = frame - start
  const scrim = interpolate(local, [0, 16], [0, 0.82], { easing: easeSoft, extrapolateRight: "clamp" })
  const enter = (delay: number) => interpolate(local, [delay, delay + 12], [0, 1], { ...clamp, easing: easeOut })
  const rise = (delay: number) => ({ opacity: enter(delay), transform: `translateY(${(1 - enter(delay)) * 16}px)` })
  return (
    <AbsoluteFill style={{ backgroundColor: `rgba(11,13,17,${scrim})`, alignItems: "center", justifyContent: "center" }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 30, color: "#fff" }}>
        <Img src={staticFile("icon.png")} style={{ width: 150, height: 150, ...rise(4) }} />
        <div style={{ fontFamily: DISPLAY, fontStyle: "italic", fontSize: 128, lineHeight: 1, ...rise(8) }}>T3 Code Thememaxed</div>
        <div style={{ fontFamily: MONO, fontSize: 32, color: "#d9dde3", ...rise(at(0, 2)) }}>
          omarchy plugin add github.com/jagrat7/omarchy-t3code-thememaxed
        </div>
      </div>
    </AbsoluteFill>
  )
}

export const Promo: FC = () => {
  const frame = useCurrentFrame()
  const enter = interpolate(frame, [0, 14], [0, 1], { easing: easeOut, extrapolateRight: "clamp" })
  const accent = current(accents, frame).color
  const grow = interpolate(frame, [at(THEME_START), at(THEME_START) + 22], [0, 1], { ...clamp, easing: easeInOut })
  const win: Rect = {
    x: lerp(SMALL.x, BIG.x, grow),
    y: lerp(SMALL.y, BIG.y, grow),
    w: lerp(SMALL.w, BIG.w, grow),
    h: lerp(SMALL.h, BIG.h, grow),
  }
  const zoomIn = interpolate(frame, [at(ZOOM_BAR), at(ZOOM_BAR) + 18], [0, 1], { ...clamp, easing: easeSoft })
  const zoomOut = interpolate(frame, [at(ZOOM_BAR + 1), at(ZOOM_BAR + 1) + 18], [0, 1], { ...clamp, easing: easeSoft })
  const zoom = 1 + 2 * (zoomIn - zoomOut)
  const scale = (win.w / SHOT.w) * zoom
  const picked = pickAt.filter((pick) => frame >= pick).length
  const slide = picked === 0 ? 1 : interpolate(frame, [pickAt[picked - 1], pickAt[picked - 1] + 8], [0, 1], { ...clamp, easing: easeOut })
  const panelIn = interpolate(frame, [at(0, 1), at(0, 1) + 12], [0, 1], { ...clamp, easing: easeOut })
  const panelOut = interpolate(frame, [at(THEME_START), at(THEME_START) + 14], [0, 1], { ...clamp, easing: easeOut })
  const cursorIn = interpolate(frame, [at(ZOOM_BAR, 3), at(ZOOM_BAR, 3) + FADE], [0, 1], clamp)
  return (
    <AbsoluteFill style={{ backgroundColor: "#0b0d11" }}>
      <Stack layers={desktopLayers} frame={frame} fade />
      <AbsoluteFill style={{ background: "linear-gradient(rgba(0,0,0,0.55), transparent 22%)" }} />
      <div
        style={{
          position: "absolute",
          left: win.x,
          top: win.y,
          width: win.w,
          height: win.h,
          borderRadius: 14,
          overflow: "hidden",
          boxShadow: `0 0 0 3px ${accent}, 0 24px 60px rgba(0,0,0,0.5)`,
          opacity: enter,
          transform: `translateY(${(1 - enter) * 24}px)`,
        }}
      >
        <div style={{ position: "absolute", inset: 0, transform: `scale(${zoom})`, transformOrigin: "0% 0%" }}>
          <Stack layers={windowLayers} frame={frame} />
        </div>
        <Dim frame={frame} scale={scale} />
      </div>
      <Notes frame={frame} scale={scale} win={win} accent={accent} />
      {panelOut < 1 && (
        <>
          <Panel
            chosen={picked}
            slidingFrom={Math.max(0, picked - 1)}
            slide={slide}
            style={{ left: PANEL_X + panelOut * 60, top: PANEL_Y + (1 - panelIn) * 16, opacity: panelIn * (1 - panelOut) }}
          />
          <Cursor frame={frame} opacity={cursorIn * (1 - panelOut)} />
        </>
      )}
      <Headline frame={frame} win={win} />
      <EndCard frame={frame} />
    </AbsoluteFill>
  )
}
