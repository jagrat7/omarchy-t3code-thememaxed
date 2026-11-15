import { Easing } from "remotion"
import grid from "../data/beat-grid.json"
import snapshot from "../data/snapshot-2026-11-15.json"

export const FPS = 30
export const BAR = grid.bar_seconds * FPS
export const at = (bar: number, beats = 0) => Math.round((bar + beats / 4) * BAR)

export const easeOut = Easing.bezier(0.23, 1, 0.32, 1)
export const easeInOut = Easing.bezier(0.77, 0, 0.175, 1)
export const easeSoft = Easing.bezier(0.65, 0, 0.35, 1)

export const MUSIC_START = grid.bars[snapshot.music.startBar].start

export const ZOOM_BAR = 1
export const CLICK_BARS = [2, 4, 6]
export const THEME_START = 8
export const END_BAR = 14
export const TOTAL_BARS = 16
export const DURATION = at(TOTAL_BARS)
