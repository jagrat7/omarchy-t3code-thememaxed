import { Img, staticFile } from "remotion"
import type { CSSProperties, FC } from "react"
import snapshot from "../data/snapshot-2026-11-15.json"

const theme = snapshot.themes[0]
const FONT = "Maple Mono"

export const rgba = (hex: string, alpha: number) => {
  const n = parseInt(hex.slice(1), 16)
  return `rgba(${n >> 16},${(n >> 8) & 255},${n & 255},${alpha})`
}
const ink = (alpha: number) => rgba(theme.foreground, alpha)
const shade = (alpha: number) => rgba(theme.background, alpha)

export const PANEL_W = 470
const PAD = 20
const GAP = 8
const TILE_W = (PANEL_W - PAD * 2 - GAP) / 2
const PREVIEW_W = TILE_W - 16
const PREVIEW_H = Math.round(PREVIEW_W * 0.58)
const TILE_H = PREVIEW_H + 40
const GRID_TOP = PAD + 58
const RULE_Y = GRID_TOP + TILE_H * 2 + GAP + 14
export const PANEL_H = RULE_Y + 1 + 12 + 34 + PAD

const LABELS = ["Minimal", "Full", "Max", "Full alt"]
const STYLES = ["minimal", "full", "max", "full-alt"]

const tileAt = (i: number) => ({ x: PAD + (i % 2) * (TILE_W + GAP), y: GRID_TOP + Math.floor(i / 2) * (TILE_H + GAP) })
export const tileCenter = (i: number) => {
  const { x, y } = tileAt(i)
  return { x: x + TILE_W / 2, y: y + PREVIEW_H / 2 + 8 }
}

const fill: CSSProperties = { position: "absolute", inset: 0 }

const Wallpaper: FC<{ sharp?: boolean }> = ({ sharp }) => (
  <div style={{ ...fill, overflow: "hidden", background: rgba(theme.accent, 0.35) }}>
    <Img
      src={staticFile(snapshot.panel.wallpaper)}
      style={{
        ...fill,
        width: "100%",
        height: "100%",
        objectFit: "cover",
        filter: sharp ? undefined : "blur(6px)",
        transform: sharp ? undefined : "scale(1.3)",
      }}
    />
    {!sharp && <div style={{ ...fill, background: shade(0.35) }} />}
  </div>
)

const Line: FC<{ width: string; height: number; alpha: number; right?: boolean }> = ({ width, height, alpha, right }) => (
  <div style={{ width, height, borderRadius: height / 2, background: ink(alpha), alignSelf: right ? "flex-end" : undefined }} />
)

const Preview: FC<{ style: string }> = ({ style }) => {
  const header = style !== "full-alt"
  const conversation = style === "full" || style === "max"
  const backdrop = style === "full-alt"
  const sidebarWidth = Math.round(PREVIEW_W * 0.3)
  const headerHeight = Math.round(PREVIEW_H * 0.2)
  return (
    <div style={{ position: "relative", width: PREVIEW_W, height: PREVIEW_H, borderRadius: 5, background: theme.background, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: sidebarWidth, top: 0, width: PREVIEW_W - sidebarWidth, height: PREVIEW_H, overflow: "hidden" }}>
        {(conversation || backdrop) && <Wallpaper sharp={backdrop} />}
        {backdrop && (
          <div
            style={{
              position: "absolute",
              left: "16%",
              width: "68%",
              top: 0,
              bottom: 0,
              background: `linear-gradient(90deg, ${shade(0)}, ${shade(0.72)} 14%, ${shade(0.72)} 86%, ${shade(0)})`,
            }}
          />
        )}
        <div style={{ position: "absolute", left: "25%", width: "50%", top: "16%", display: "flex", flexDirection: "column", gap: 8 }}>
          <Line width="55%" height={4} alpha={0.35} right />
          <Line width="100%" height={3} alpha={0.22} />
          <Line width="80%" height={3} alpha={0.22} />
          <Line width="90%" height={3} alpha={0.22} />
        </div>
        <div
          style={{
            position: "absolute",
            left: "22%",
            width: "56%",
            bottom: "8%",
            height: "14%",
            borderRadius: 3,
            background: shade(0.85),
            border: `1px solid ${ink(0.18)}`,
          }}
        />
      </div>
      <div style={{ position: "absolute", left: 0, top: 0, width: sidebarWidth, height: PREVIEW_H, background: ink(0.05) }}>
        {style === "max" && <Wallpaper />}
        <div style={{ position: "relative", width: sidebarWidth, height: headerHeight, overflow: "hidden" }}>{header && <Wallpaper />}</div>
        <div style={{ position: "absolute", left: "16%", width: "68%", top: headerHeight + PREVIEW_H * 0.1, display: "flex", flexDirection: "column", gap: 9 }}>
          {[1, 0.7, 0.85, 0.6].map((width) => (
            <Line key={width} width={`${width * 100}%`} height={3} alpha={0.25} />
          ))}
        </div>
        <div style={{ position: "absolute", right: 0, top: 0, width: 1, height: "100%", background: ink(0.1) }} />
      </div>
      <div style={{ ...fill, borderRadius: 5, border: `1px solid ${ink(0.16)}` }} />
    </div>
  )
}

const DripMark: FC<{ size: number }> = ({ size }) => (
  <svg width={size} height={size} viewBox="0 -4.5 94.3941 94.3941" fill={theme.foreground}>
    <path d="M17.92 56V10.56H0V0H48.8V10.56H30.88V56H17.92ZM71.1944 56.96C67.3011 56.96 63.4344 56.4533 59.5944 55.44C55.7544 54.3733 52.5011 52.88 49.8344 50.96L54.8744 41.04C57.0077 42.5867 59.4877 43.8133 62.3144 44.72C65.1411 45.6267 67.9944 46.08 70.8744 46.08C74.1277 46.08 76.6877 45.44 78.5544 44.16C80.4211 42.88 81.3544 41.12 81.3544 38.88C81.3544 36.7467 80.5277 35.0667 78.8744 33.84C77.2211 32.6133 74.5544 32 70.8744 32H64.9544V23.44L76.4603 10.4H52.6344V0H91.8341V8.4L79.2489 22.737C83.361 23.3863 86.6493 24.794 89.1141 26.96C92.6341 30.0533 94.3941 34.0267 94.3941 38.88C94.3941 42.0267 93.5681 44.9867 91.9141 47.76C90.2611 50.48 87.7281 52.6933 84.3144 54.4C80.9011 56.1067 76.5277 56.96 71.1944 56.96Z" />
    <path d="M3 8H12V30A4.5 4.5 0 0 1 3 30Z M62 50H73V80A5.5 5.5 0 0 1 62 80Z M80 46H88V62A4 4 0 0 1 80 62Z" />
  </svg>
)

export const Panel: FC<{ chosen: number; slidingFrom: number; slide: number; style?: CSSProperties }> = ({ chosen, slidingFrom, slide, style }) => {
  const a = tileAt(slidingFrom)
  const b = tileAt(chosen)
  const [c1, c2, c3] = snapshot.panel.border
  return (
    <div
      style={{
        position: "absolute",
        width: PANEL_W,
        height: PANEL_H,
        borderRadius: 14,
        padding: 1.5,
        background: `linear-gradient(${90 + snapshot.panel.borderAngle}deg, ${c1}, ${c2}, ${c3})`,
        boxShadow: "0 24px 60px rgba(0,0,0,0.5)",
        ...style,
      }}
    >
      <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 12.5, background: theme.background, fontFamily: FONT, color: theme.foreground }}>
        <div style={{ position: "absolute", left: PAD, top: PAD, display: "flex", alignItems: "center", gap: 14 }}>
          <DripMark size={36} />
          <div>
            <div style={{ fontSize: 19, fontWeight: 700 }}>T3 Code Thememaxed</div>
            <div style={{ fontSize: 11.5, letterSpacing: 1.6, textTransform: "uppercase", opacity: 0.65, marginTop: 4 }}>{snapshot.panel.meta}</div>
          </div>
        </div>
        <div
          style={{
            position: "absolute",
            left: a.x + (b.x - a.x) * slide,
            top: a.y + (b.y - a.y) * slide,
            width: TILE_W,
            height: TILE_H,
            borderRadius: 10,
            background: "rgba(255,255,255,0.16)",
            boxShadow: `inset 0 -2px 0 ${theme.accent}`,
          }}
        />
        {STYLES.map((name, i) => {
          const { x, y } = tileAt(i)
          const picked = i === chosen
          return (
            <div key={name} style={{ position: "absolute", left: x + 8, top: y + 8, width: PREVIEW_W }}>
              <Preview style={name} />
              <div
                style={{
                  marginTop: 8,
                  textAlign: "center",
                  fontSize: 14.5,
                  fontWeight: picked ? 700 : 400,
                  color: picked ? theme.accent : theme.foreground,
                }}
              >
                {LABELS[i]}
              </div>
            </div>
          )
        })}
        <div style={{ position: "absolute", left: PAD, right: PAD, top: RULE_Y, height: 1, background: ink(0.15) }} />
        <div style={{ position: "absolute", left: PAD, right: PAD, top: RULE_Y + 13, height: 34, display: "flex", fontSize: 14.5 }}>
          {["New wallpaper", "Edit config"].map((text) => (
            <div key={text} style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
              {text}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
