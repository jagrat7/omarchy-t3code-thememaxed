"""Run the publisher CLI with isolated homes and real image encoders."""

import base64
import importlib.machinery
import importlib.util
import json
import math
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBLISHER = ROOT / "bin/t3code-omarchy-plus"
MAGICK = shutil.which("magick")
AVIFENC = shutil.which("avifenc")


@unittest.skipUnless(MAGICK, "needs ImageMagick with AVIF support")
class Publisher(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.env = {
            "HOME": str(self.home), "PATH": str(self.bin), "LC_ALL": "C",
            **{f"XDG_{name}_HOME": str(self.home / name.lower()) for name in ("CONFIG", "STATE", "CACHE", "DATA")},
            "XDG_RUNTIME_DIR": str(self.home / "runtime"), "TMPDIR": str(self.home / "tmp"),
        }
        for key, value in self.env.items():
            if key.startswith("XDG_") or key == "TMPDIR":
                Path(value).mkdir(parents=True)
        self.current = self.home / "state/omarchy/current"
        self.theme = self.current / "theme"
        self.backgrounds = self.theme / "backgrounds"
        self.backgrounds.mkdir(parents=True)
        self.target = self.home / ".t3/userdata/themes/omarchy-plus.json"
        self.target.parent.mkdir(parents=True)
        self.status = self.home / "state/omarchy-t3code-plus/status.json"
        self.cache = self.status.with_name("sharp-cache.json")
        self.config = self.home / "config/omarchy-t3code-plus/config.toml"
        self.config.parent.mkdir(parents=True)
        self.log = self.home / "commands.log"
        colors = {
            "background": "#101820", "dark_background": "#080c10",
            "foreground": "#e8e0d8", "accent": "#90b0d0",
            "selection_background": "#304050", "selection_foreground": "#ffffff", "orange": "#d09050",
        }
        for index, name in enumerate(("red", "green", "yellow", "blue", "magenta", "cyan")):
            colors[name] = f"#{index + 8:x}08090"
            colors[f"bright_{name}"] = f"#{index + 8:x}0a0b0"
        (self.theme / "colors.toml").write_text("".join(f'{key} = "{value}"\n' for key, value in colors.items()))
        (self.theme / "shell.toml").write_text(
            '[menu]\nselected-border = "rgb(90b0d0) rgb(e8e0d8) 45deg"\n'
            'selected-border-width = "1 2 3 4"\nscrim-alpha = 0.8\n'
        )
        self.palette = {"name": "Omarchy", "canvas": colors["background"], "css": "stale"}
        (self.theme / "t3code.json").write_text(json.dumps(self.palette))
        (self.current / "theme.name").write_text("fixture")
        self.tool("fc-match", "printf 'Fixture Mono,monospace'")
        self.tool("hyprctl", """case "$*" in
  *--batch*) printf '%s' '{"option":"decoration:rounding","int":12}


{"option":"general:border_size","int":3}' ;;
  *) printf '%s' '[{"name":"fixture","width":1920,"scale":1,"focused":true}]' ;;
esac""")
        self.tool("omarchy-theme-color", f"""exec {shlex.quote(sys.executable)} -c '
import sys, tomllib
with open(sys.argv[1], "rb") as source:
    for key, value in tomllib.load(source).items():
        print(key, value, sep="\\t")
' "$2"
""")
        self.tool("magick", f'exec {shlex.quote(MAGICK)} "$@"')
        if AVIFENC:
            self.tool("avifenc", f'exec {shlex.quote(AVIFENC)} "$@"')
        self.tool("nice", "exit 0")
        self.walls = []
        for index, color in enumerate(("#90b0d0", "#d09050", "#509070", "#905070")):
            path = self.backgrounds / f"{index}.png"
            subprocess.run([MAGICK, "-size", "160x90", f"gradient:{color}-#101820", "-seed", str(index), "+noise", "Random", str(path)],
                           env=self.env, check=True, capture_output=True)
            self.walls.append(path)
        (self.current / "background").symlink_to(self.walls[1])

    def tool(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/sh\nprintf '%s\\n' {shlex.quote(name)} \"$*\" >> {shlex.quote(str(self.log))}\n{body}\n")
        path.chmod(0o755)

    def publish(self, *args):
        result = subprocess.run([sys.executable, str(PUBLISHER), *args], env=self.env,
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def output(self, style):
        theme = json.loads(self.target.read_text())
        status = json.loads(self.status.read_text())
        self.assertEqual(theme["name"], "Thememaxed")
        self.assertEqual(theme["canvas"], self.palette["canvas"])
        css = theme["css"]
        self.assertLessEqual(len(css), 50000)
        self.assertNotRegex(css, r"\{\{|\}\}|@end")
        self.assertEqual(status["chars"], len(css))
        self.assertEqual(status["style"], style)
        self.assertEqual(status["limit"], 50000)
        self.assertTrue(status["published"])
        self.assertEqual(status["theme"], "fixture")
        self.assertIsInstance(status["time"], int)
        self.assertIn("backdropTint", status)
        self.assertIn("rendering", status)
        return css, status

    def one_wallpaper(self):
        for path in self.walls[1:]:
            path.unlink()

    def test_styles_publish_real_images_and_shell_values(self):
        self.one_wallpaper()
        for style in ("minimal", "full", "max", "full-alt"):
            with self.subTest(style=style):
                self.publish("--style", style)
                css, status = self.output(style)
                self.assertIn('data:image/avif;base64,', css)
                self.assertEqual("--omarchy-header-wallpaper:" in css, style != "full-alt")
                self.assertEqual("--omarchy-wallpaper:" in css, style != "minimal")
                self.assertEqual("100% 100%,cover" in css, style == "max")
                self.assertEqual("backdrop-filter:blur(" in css, style == "full-alt")
                self.assertIn('--omarchy-font:"Fixture Mono";', css)
                self.assertIn('--omarchy-radius:12px;', css)
                self.assertIn('--omarchy-border-width:3px;', css)
                if style != "minimal":
                    data = base64.b64decode(re.search(r'--omarchy-wallpaper:url\("data:image/avif;base64,([^"]+)', css)[1])
                    size = subprocess.run([MAGICK, "identify", "-format", "%w %h", "-"], input=data,
                                          env=self.env, capture_output=True, check=True).stdout
                    self.assertEqual(size, b"160 90")
                    self.assertEqual(status["picture"], {"format": "avif", "bytes": len(data), "width": 160, "height": 90})
                self.assertEqual(json.loads((self.theme / "t3code.json").read_text()), self.palette)

    def test_settings_persist_and_old_styles_migrate(self):
        self.config.write_text('# keep me\nstyle = "full"\nmin_tint = 0.9\n')
        self.publish("--style", "max", "--tint", "0.35")
        self.publish()
        self.assertEqual(self.output("max")[1]["backdropTint"], 0.35)
        self.assertEqual(tomllib.loads(self.config.read_text()), {"style": "max", "min_tint": 0.9, "backdrop_tint": 0.35})
        self.assertIn("# keep me", self.config.read_text())
        self.publish("--tint", "auto")
        self.assertEqual(tomllib.loads(self.config.read_text())["backdrop_tint"], "auto")
        self.one_wallpaper()
        for old, new in (("too-much", "max"), ("backdrop", "full-alt")):
            with self.subTest(old=old):
                self.config.write_text(f'style = "{old}"\n')
                self.publish()
                self.output(new)
                self.assertEqual(tomllib.loads(self.config.read_text())["style"], new)

    def test_inside_wallpaper_avoids_desktop_header_and_last_then_falls_back(self):
        shown = []
        for _ in range(3):
            self.publish()
            path = Path(self.output("full")[1]["wallpaper"])
            self.assertIn(path, self.walls[2:])
            if shown:
                self.assertNotEqual(path, shown[-1])
            shown.append(path)
        for remaining, expected in ((3, self.walls[2]), (2, self.walls[0]), (1, self.walls[0])):
            self.walls[remaining].unlink()
            self.publish()
            self.assertEqual(Path(self.output("full")[1]["wallpaper"]), expected)

    def test_bad_config_falls_back_and_unresolved_palette_preserves_theme(self):
        for config in ('style = [broken', 'style = []', 'style = {bad = 1}',
                       'style = "loud"\nmin_blur = "lots"\nmin_tint = 3\nbackdrop_tint = false\n'):
            with self.subTest(config=config):
                self.config.write_text(config)
                self.publish()
                self.output("full")
        previous = self.target.read_bytes()
        (self.theme / "t3code.json").write_text('{"name":"{{ accent }}"}')
        self.publish()
        self.assertEqual(self.target.read_bytes(), previous)
        status = json.loads(self.status.read_text())
        self.assertFalse(status["published"])
        self.assertIn("unresolved", status["warning"])

    def test_css_over_the_limit_publishes_the_palette_without_it(self):
        self.tool("fc-match", "printf '%s' " + "F" * 60000)
        self.publish()
        theme = json.loads(self.target.read_text())
        self.assertEqual(theme["name"], "Thememaxed")
        self.assertNotIn("css", theme)
        self.assertIn("over T3 Code's 50000 limit", json.loads(self.status.read_text())["warning"])

    @unittest.skipUnless(AVIFENC, "needs avifenc")
    def test_full_alt_cache_warm_and_image_changes(self):
        self.one_wallpaper()
        self.publish("--style", "full-alt", "--tint", "0.3")
        css, status = self.output("full-alt")
        self.assertEqual(status["picture"]["format"], "avif")
        self.assertEqual(status["tint"], 0.3)
        self.assertIn("avifenc", self.log.read_text())
        self.assertNotIn("-blur", self.log.read_text())
        self.assertNotIn("-function", self.log.read_text())
        self.log.write_text("")
        self.publish()
        self.assertEqual(self.output("full-alt")[0], css)
        self.assertNotIn("avifenc", self.log.read_text())
        self.walls[1].write_bytes(self.walls[0].read_bytes())
        self.publish()
        previous = self.target.read_bytes(), self.status.read_bytes()
        self.publish("--warm")
        self.assertIn("nice\n-n 19", self.log.read_text())
        self.assertEqual((self.target.read_bytes(), self.status.read_bytes()), previous)
        self.assertEqual(len(json.loads(self.cache.read_text())), 2)
        self.log.write_text("")
        self.publish()
        self.output("full-alt")
        self.assertNotIn("avifenc", self.log.read_text())
        self.walls[0].write_bytes(self.walls[0].read_bytes() + b"\n")
        self.publish()
        self.output("full-alt")
        self.assertIn("avifenc", self.log.read_text())

    @unittest.skipUnless(AVIFENC, "needs avifenc")
    def test_sharp_cache_adapts_to_a_smaller_css_budget(self):
        self.one_wallpaper()
        subprocess.run([MAGICK, "-size", "320x180", "xc:", "-seed", "7", "+noise", "Random", str(self.walls[0])],
                       env=self.env, check=True, capture_output=True)
        self.publish("--style", "full-alt")
        css, first = self.output("full-alt")
        self.assertGreater(len(css), 40000)
        self.tool("fc-match", "printf '%s' '" + "F" * 3000 + "'")
        self.publish()
        _, smaller = self.output("full-alt")
        self.assertLess(smaller["quality"], first["quality"])
        self.assertLess(smaller["picture"]["bytes"], first["picture"]["bytes"])

    @unittest.skipUnless(AVIFENC, "needs avifenc")
    def test_pixel_art_keeps_native_pixels_and_fallback_works_without_avifenc(self):
        self.one_wallpaper()
        subprocess.run([MAGICK, "-size", "16x9", "pattern:checkerboard", "-sample", "160x90!", str(self.walls[0])],
                       env=self.env, check=True, capture_output=True)
        self.publish("--style", "full-alt")
        _, status = self.output("full-alt")
        self.assertEqual(status["rendering"], "pixelated")
        self.assertEqual(status["picture"]["format"], "webp")
        self.assertEqual((status["picture"]["width"], status["picture"]["height"]), (16, 9))
        (self.bin / "avifenc").unlink()
        self.publish()
        _, status = self.output("full-alt")
        self.assertEqual(status["picture"]["format"], "avif")
        self.assertEqual(status["rendering"], "auto")


class SharpSearch(unittest.TestCase):
    def test_search_matches_exhaustive_choice_and_reuses_measured_levels(self):
        loader = importlib.machinery.SourceFileLoader("publisher", str(PUBLISHER))
        publisher = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
        loader.exec_module(publisher)
        widths = [1920, 1600, 1280, 960]

        def size(width, quality):
            return int(900 * (width / 960) ** 1.7 * math.exp(0.07 * publisher.avif_level(quality)))

        for room in range(1500, 60000, 1700):
            with self.subTest(room=room):
                measured, sizes = [], {}

                def measure(pairs):
                    measured.extend(pairs)
                    return [size(*pair) for pair in pairs]

                def sketch(width):
                    return {q: int(size(width, q) * 1.2) for q in publisher.SHARP_SKETCH_QUALITIES}

                chosen = publisher.sharp_search(sizes, room, widths, 20, 90, measure, sketch)
                width = next((w for w in widths if size(w, 20) <= room), widths[-1])
                qualities = [q for q in range(91) if size(width, q) <= room]
                expected = (width, publisher.avif_level(max(qualities))) if qualities else None
                self.assertEqual(chosen and (chosen[0], publisher.avif_level(chosen[1])), expected)
                self.assertLess(len(measured), 12)
                levels = [(w, publisher.avif_level(q)) for w, q in measured]
                self.assertEqual(len(levels), len(set(levels)))
                measured.clear()
                self.assertEqual(publisher.sharp_search(sizes, room, widths, 20, 90, measure, sketch), chosen)
                self.assertEqual(measured, [])


if __name__ == "__main__":
    unittest.main()
