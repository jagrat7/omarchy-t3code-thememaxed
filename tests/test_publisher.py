"""Tests for bin/t3code-omarchy-plus. Run: python3 -m unittest discover -s tests -v"""

import importlib.machinery
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
loader = importlib.machinery.SourceFileLoader("publisher", str(ROOT / "bin/t3code-omarchy-plus"))
spec = importlib.util.spec_from_loader("publisher", loader)
publisher = importlib.util.module_from_spec(spec)
loader.exec_module(publisher)

TEMPLATE = (ROOT / "themed/t3code.css.tpl").read_text()


class Blocks(unittest.TestCase):
    def css_for(self, style, radius="4px"):
        keep = set(publisher.STYLES[style])
        if radius == "0px":
            keep.add("square")
        return publisher.keep_blocks(TEMPLATE, keep)

    def test_minimal_keeps_only_the_header(self):
        css = self.css_for("minimal")
        self.assertIn("var(--omarchy-header-wallpaper)", css)
        self.assertNotIn("var(--omarchy-wallpaper)", css)
        self.assertNotIn("100% 100%, cover", css)

    def test_full_adds_the_conversation(self):
        css = self.css_for("full")
        self.assertIn('[data-workspace-area="conversation"]', css)
        self.assertNotIn("100% 100%, cover", css)

    def test_too_much_adds_the_sidebar(self):
        css = self.css_for("too-much")
        self.assertIn('[data-workspace-area="conversation"]', css)
        self.assertIn("100% 100%, cover", css)

    def test_backdrop_drops_the_blurred_parts(self):
        css = self.css_for("backdrop")
        self.assertIn("var(--omarchy-wallpaper)", css)
        self.assertIn("var(--omarchy-wallpaper) center / cover no-repeat,", css)
        self.assertIn("backdrop-filter: blur(", css)
        self.assertIn("var(--chat-content-max-width)", css)
        self.assertNotIn("var(--omarchy-header-wallpaper)", css)
        self.assertNotIn("var(--omarchy-tint)", css)

    def test_backdrop_wallpaper_is_not_blurred(self):
        calls = []

        def run(command, **kwargs):
            if command[0] == "magick" and command[1] != "identify":
                calls.append(command)
            return mock.Mock(returncode=0, stdout=b"x")

        with mock.patch.object(publisher.subprocess, "run", side_effect=run), \
                mock.patch.object(publisher, "hyprland_blur", return_value={"sigma": 30, "brightness": 0.8, "contrast": 0.9}):
            publisher.wallpaper_css(Path("/tmp/wall.jpg"), 1000, publisher.SHARP_STEPS)
            publisher.wallpaper_css(Path("/tmp/wall.jpg"), 1000, publisher.BACKGROUND_STEPS, 20)
        self.assertNotIn("-blur", calls[0])
        self.assertNotIn("Multiply", calls[0])
        self.assertIn("-blur", calls[1])

    @unittest.skipUnless(publisher.shutil.which("magick"), "needs ImageMagick")
    def test_pixel_art_is_found_by_its_blocks(self):
        with tempfile.TemporaryDirectory() as folder:
            art, photo = Path(folder) / "art.png", Path(folder) / "photo.png"
            # 30x20 random art pixels drawn as 5x5 blocks, and the same smoothed.
            publisher.subprocess.run(["magick", "-size", "30x20", "xc:", "+noise", "Random", "-sample", "150x100!", art], check=True)
            publisher.subprocess.run(["magick", art, "-blur", "0x1", photo], check=True)
            self.assertEqual(publisher.pixel_block(art, 150, 100), 5)
            self.assertEqual(publisher.pixel_block(photo, 150, 100), 1)

    def test_settings_are_saved_in_place(self):
        with tempfile.TemporaryDirectory() as folder, \
                mock.patch.object(publisher, "CONFIG", Path(folder) / "config.toml"):
            publisher.save_setting("style", '"backdrop"')
            publisher.save_setting("backdrop_tint", "0.3")
            publisher.save_setting("backdrop_tint", '"auto"')
            lines = [line for line in publisher.CONFIG.read_text().splitlines() if line and not line.startswith("#")]
        self.assertEqual(lines, ['style = "backdrop"', 'backdrop_tint = "auto"'])

    def test_tint_takes_auto_or_a_fraction(self):
        self.assertEqual(publisher.tint_value("auto"), "auto")
        self.assertEqual(publisher.tint_value("0.35"), "0.35")
        for wrong in ("2", "-0.1", "dark"):
            with self.assertRaises(publisher.argparse.ArgumentTypeError):
                publisher.tint_value(wrong)

    def test_backdrop_tint_follows_the_wallpaper(self):
        with mock.patch.object(publisher, "picture_luminance", return_value=0.1):
            dark_picture = publisher.backdrop_alpha("auto", Path("/w.jpg"), "#0b1b2b")
        with mock.patch.object(publisher, "picture_luminance", return_value=0.5):
            bright_picture = publisher.backdrop_alpha("auto", Path("/w.jpg"), "#0b1b2b")
        with mock.patch.object(publisher, "picture_luminance", return_value=0.3):
            light_theme = publisher.backdrop_alpha("auto", Path("/w.jpg"), "#f4f1ea")
        low, high = publisher.BACKDROP_TINT_BOUNDS
        self.assertEqual(dark_picture, low)
        self.assertEqual(bright_picture, high)
        self.assertGreater(light_theme, low)
        self.assertEqual(publisher.backdrop_alpha(0.3, None, "#000000"), 0.3)

    def test_square_corners_only_without_rounding(self):
        self.assertNotIn('[class*="rounded-xl"]', self.css_for("full", "8px"))
        self.assertIn('[class*="rounded-xl"]', self.css_for("full", "0px"))

    def test_no_markers_survive(self):
        for style in publisher.STYLES:
            self.assertNotIn("@end", self.css_for(style))


class Rendering(unittest.TestCase):
    def test_values_offer_omarchys_three_forms(self):
        output = "accent\t#2a78b0\nmode\tdark\n"
        with mock.patch.object(publisher, "command_output", return_value=output):
            values = publisher.theme_values()
        self.assertEqual(values["accent"], "#2a78b0")
        self.assertEqual(values["accent_strip"], "2a78b0")
        self.assertEqual(values["accent_rgb"], "42,120,176")
        self.assertEqual(values["mode"], "dark")
        self.assertNotIn("mode_rgb", values)

    def test_unknown_tokens_are_left_for_the_check(self):
        rendered = publisher.render_template("a {{ accent }} b {{ nope }}", {"accent": "#fff"})
        self.assertEqual(rendered, "a #fff b {{ nope }}")

    def test_every_template_token_is_a_theme_key(self):
        tokens = set(publisher.re.findall(r"\{\{\s*(\w+)\s*\}\}", publisher.re.sub(r"/\*.*?\*/", "", TEMPLATE, flags=publisher.re.S)))
        known = {"background", "dark_background", "foreground", "accent", "selection_background", "selection_foreground"}
        known |= {f"{bright}{name}" for bright in ("", "bright_") for name in ("red", "green", "yellow", "blue", "magenta", "cyan")}
        known.add("orange")
        self.assertLessEqual(tokens, known)


class Colors(unittest.TestCase):
    def test_hyprland_and_hex_forms(self):
        self.assertEqual(publisher.css_color("rgb(ed9998)"), "#ed9998")
        self.assertEqual(publisher.css_color("rgba(665f5899)"), "rgb(102 95 88 / 0.6)")
        self.assertEqual(publisher.css_color("0xffed9998"), "#ed9998")
        self.assertEqual(publisher.css_color("#ed9998", 0.5), "rgb(237 153 152 / 0.5)")
        self.assertIsNone(publisher.css_color("red"))

    def test_hyprland_options_come_from_one_batch(self):
        answers = '{"option": "decoration:rounding", "int": 12, "set": true }\n\n\nno such option\n\n\n' \
            '{"option": "decoration:blur:brightness", "float": 0.75, "set": true }'
        with mock.patch.object(publisher, "command_output", return_value=answers) as hyprctl:
            options = publisher.hyprland_options.__wrapped__()
        self.assertEqual(hyprctl.call_count, 1)
        self.assertEqual(options["decoration:rounding"], 12)
        self.assertEqual(options["decoration:blur:brightness"], 0.75)
        self.assertEqual(options["general:border_size"], publisher.HYPRLAND_DEFAULTS["general:border_size"])

    def test_gradient_angle_turns_to_css(self):
        colors, angle = publisher.parse_border("rgb(ed9998) rgb(fbe4c5) 45deg")
        self.assertEqual(publisher.css_gradient(colors, angle), "linear-gradient(135deg, #ed9998, #fbe4c5)")


class Settings(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.config = Path(self.folder.name) / "config.toml"
        patcher = mock.patch.object(publisher, "CONFIG", self.config)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.addCleanup(self.folder.cleanup)

    def test_first_save_writes_the_commented_defaults(self):
        publisher.save_setting("style", '"minimal"')
        text = self.config.read_text()
        self.assertIn('style = "minimal"', text)
        self.assertIn("# min_blur", text)

    def test_saving_keeps_the_rest_of_the_file(self):
        self.config.write_text('style = "full"\nmin_tint = 0.9\n')
        publisher.save_setting("style", '"too-much"')
        self.assertEqual(self.config.read_text(), 'style = "too-much"\nmin_tint = 0.9\n')
        settings = publisher.load_settings()
        self.assertEqual(settings["style"], "too-much")
        self.assertEqual(settings["min_tint"], 0.9)

    def test_bad_values_fall_back(self):
        self.config.write_text('style = "loud"\nmin_blur = "lots"\nmin_tint = 3\n')
        with mock.patch.object(publisher, "warn"):
            settings = publisher.load_settings()
        self.assertEqual(settings["style"], publisher.DEFAULT_STYLE)
        self.assertEqual(settings["min_blur"], publisher.MIN_BLUR)
        self.assertEqual(settings["min_tint"], 1.0)


class Budget(unittest.TestCase):
    """build_css gives the pictures what the CSS limit leaves."""

    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        tokens = set(publisher.re.findall(r"\{\{\s*(\w+)\s*\}\}", TEMPLATE))
        for patcher in (
            mock.patch.object(publisher, "THEME_DIR", Path(self.folder.name)),
            mock.patch.object(publisher, "theme_values", return_value={token: "#123456" for token in tokens}),
            mock.patch.object(publisher, "command_output", return_value=""),
            mock.patch.object(publisher, "desktop_wallpaper", return_value=Path("/w.jpg")),
            mock.patch.object(publisher, "first_wallpaper", return_value=Path("/w.jpg")),
            mock.patch.object(publisher, "random_wallpaper", return_value=Path("/w.jpg")),
            mock.patch.object(publisher, "picture_luminance", return_value=0.2),
            mock.patch.object(publisher, "REPORT", {}),
            mock.patch.object(publisher, "warn"),
        ):
            patcher.start()
            self.addCleanup(patcher.stop)

    def budgets(self, style, limit, picture="none"):
        calls = []

        def sharp(source, budget):
            calls.append(budget)
            return picture, "auto"

        def blurred(source, budget, steps, min_blur=None):
            calls.append(budget)
            return picture

        settings = {"style": style, "min_blur": 20, "min_tint": 0.75, "backdrop_tint": "auto"}
        with mock.patch.object(publisher, "CSS_LIMIT", limit), \
                mock.patch.object(publisher, "sharp_wallpaper_css", side_effect=sharp), \
                mock.patch.object(publisher, "wallpaper_css", side_effect=blurred):
            css = publisher.build_css(settings)
        return calls, css

    def test_the_backdrop_gets_what_the_limit_leaves(self):
        (small,), _ = self.budgets("backdrop", 20000)
        (large,), _ = self.budgets("backdrop", 50000)
        self.assertEqual(large - small, 30000)
        self.assertLess(small, 20000)

    def test_full_shares_the_room_between_header_and_conversation(self):
        calls, _ = self.budgets("full", 50000)
        header, background = calls[:2]
        self.assertGreater(header, 20000)
        self.assertLessEqual(header + background, 50000)

    def test_css_over_the_limit_is_dropped(self):
        _, css = self.budgets("backdrop", 20000, picture="x" * 30000)
        self.assertIsNone(css)
        _, css = self.budgets("backdrop", 50000, picture="x" * 30000)
        self.assertIsNotNone(css)


class SharpSearch(unittest.TestCase):
    """The sharp picture's search, on made-up sizes that grow with width and level."""

    widths = [1920, 1600, 1280, 960]

    @staticmethod
    def size(width, quality):
        return int(900 * (width / 960) ** 1.7 * publisher.math.exp(0.07 * publisher.avif_level(quality)))

    def expected(self, room, good=20, top=90):
        for width in self.widths:
            if self.size(width, good) <= room:
                return width, publisher.avif_level(max(q for q in range(good, top + 1) if self.size(width, q) <= room))
        fits = [q for q in range(good) if self.size(self.widths[-1], q) <= room]
        return (self.widths[-1], publisher.avif_level(max(fits))) if fits else None

    def search(self, room, sizes=None):
        sizes = {} if sizes is None else sizes
        measured = []

        def measure(pairs):
            measured.extend(pairs)
            return [self.size(*pair) for pair in pairs]

        def sketch(width):
            return {q: int(self.size(width, q) * 1.2) for q in publisher.SHARP_SKETCH_QUALITIES}

        chosen = publisher.sharp_search(sizes, room, self.widths, 20, 90, measure, sketch)
        return chosen, measured

    def test_finds_what_trying_every_quality_would(self):
        for room in range(1500, 60000, 1700):
            chosen, measured = self.search(room)
            level = chosen and (chosen[0], publisher.avif_level(chosen[1]))
            self.assertEqual(level, self.expected(room), room)
            self.assertLess(len(measured), 12, room)

    def test_qualities_of_one_level_are_encoded_once(self):
        self.assertEqual(publisher.avif_level(25), publisher.avif_level(26))
        self.assertNotEqual(publisher.avif_level(24), publisher.avif_level(25))
        _, measured = self.search(9000)
        levels = [(width, publisher.avif_level(quality)) for width, quality in measured]
        self.assertEqual(len(levels), len(set(levels)))

    def test_known_sizes_need_no_encoding(self):
        sizes = {}
        first, _ = self.search(9000, sizes)
        again, measured = self.search(9000, sizes)
        self.assertEqual(again, first)
        self.assertEqual(measured, [])


@unittest.skipUnless(publisher.shutil.which("magick") and publisher.shutil.which("avifenc"), "needs ImageMagick and avifenc")
class SharpPicture(unittest.TestCase):
    def setUp(self):
        self.folder = Path(tempfile.mkdtemp())
        self.addCleanup(publisher.shutil.rmtree, self.folder)
        for patcher in (
            mock.patch.object(publisher, "SHARP_CACHE", self.folder / "sharp-cache.json"),
            mock.patch.object(publisher, "REPORT", {}),
        ):
            patcher.start()
            self.addCleanup(patcher.stop)

    def encodes(self, source, budget):
        calls = []
        run = publisher.subprocess.run

        def counted(command, **kwargs):
            if command[0] == "avifenc":
                calls.append(command)
            return run(command, **kwargs)

        with mock.patch.object(publisher.subprocess, "run", side_effect=counted):
            image, rendering = publisher.sharp_wallpaper_css(source, budget)
        return image, rendering, len(calls)

    def test_a_wallpaper_published_again_is_not_encoded_again(self):
        photo = self.folder / "photo.png"
        publisher.subprocess.run(["magick", "-size", "480x270", "plasma:", "-blur", "0x1", photo], check=True)
        image, rendering, first = self.encodes(photo, 6000)
        self.assertTrue(image.startswith('url("data:image/avif;base64,'))
        self.assertLessEqual(len(image), 6000)
        self.assertEqual(rendering, "auto")
        self.assertGreater(first, 0)
        again, _, second = self.encodes(photo, 6000)
        self.assertEqual(again, image)
        self.assertEqual(second, 0)

    def test_pixel_art_is_sent_at_its_own_size(self):
        art = self.folder / "art.png"
        publisher.subprocess.run(["magick", "-size", "48x27", "xc:", "+noise", "Random", "-sample", "480x270!", art], check=True)
        image, rendering, _ = self.encodes(art, 12000)
        self.assertEqual(rendering, "pixelated")
        self.assertTrue(image.startswith('url("data:image/webp;base64,'))
        data = publisher.base64.b64decode(image.split(",", 1)[1].rstrip('")'))
        size = publisher.subprocess.run(["magick", "identify", "-format", "%w %h", "-"], input=data, capture_output=True).stdout
        self.assertEqual(size, b"48 27")
        # Too little room for the lossless picture: the best AVIF that fits, still pixelated.
        image, rendering, _ = self.encodes(art, 2500)
        self.assertEqual(rendering, "pixelated")
        self.assertTrue(image.startswith('url("data:image/avif;base64,'))
        self.assertLessEqual(len(image), 2500)


class Theme(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.theme_dir = Path(self.folder.name)
        patcher = mock.patch.object(publisher, "THEME_DIR", self.theme_dir)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_builds_on_omarchys_palette_under_its_own_name(self):
        (self.theme_dir / "t3code.json").write_text(json.dumps({"name": "Omarchy", "canvas": "#000000"}))
        with mock.patch.object(publisher, "build_css", return_value=":root{}"):
            theme = publisher.build_theme({"style": "full"})
        self.assertEqual(theme["name"], "Omarchy+")
        self.assertEqual(theme["canvas"], "#000000")
        self.assertEqual(theme["css"], ":root{}")

    def test_leaves_the_last_theme_when_the_palette_is_unresolved(self):
        (self.theme_dir / "t3code.json").write_text('{"name": "{{ accent }}"}')
        with mock.patch.object(publisher, "warn"):
            self.assertIsNone(publisher.build_theme({"style": "full"}))


if __name__ == "__main__":
    unittest.main()
