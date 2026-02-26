"""
Blog Export Tool — Screenshots for 小红书 & Markdown for Typora.

See scripts/README.md for full usage.
"""

import argparse
import asyncio
import os
import re
from pathlib import Path

# Recommended defaults for 小红书 (tuned through v1-v6 iterations)
DEFAULT_WIDTH = 3000
DEFAULT_HEIGHT = 4500
DEFAULT_DPR = 4       # viewport 750px, text renders large
DEFAULT_ZOOM = 1.2    # extra 20% zoom for phone readability
DEFAULT_OVERLAP = 80  # overlap in output pixels between pages
DEFAULT_PORT = 8000

SITE_BASE_URL = "https://keli-wen.github.io/One-Poem-Suffices"


# ─── Screenshot Mode ────────────────────────────────────────────

async def prepare_page(page, url: str, viewport_w: int, viewport_h: int):
    """Navigate to URL, hide non-content elements, trigger lazy loading."""

    print("\n[1/4] Navigating to page...")
    await page.goto(url, wait_until="networkidle", timeout=30000)

    print("[2/4] Hiding nav/sidebar/footer elements...")
    await page.evaluate("""() => {
        const hideSelectors = [
            'header', 'nav', '.md-header', '.md-tabs',
            '.md-sidebar', '.md-sidebar--primary', '.md-sidebar--secondary',
            '.md-footer', 'footer',
            '.md-nav--secondary', '.toc',
            '.md-footer-nav', '.md-footer__inner',
            '.md-banner', '.md-announce',
            '.md-source', '.md-content__button',
            '.md-dialog', '.md-consent',
            '.md-top',
        ];

        hideSelectors.forEach(sel => {
            document.querySelectorAll(sel).forEach(el => {
                el.style.display = 'none';
            });
        });

        const content = document.querySelector('.md-content') ||
                       document.querySelector('.md-main__inner') ||
                       document.querySelector('main') ||
                       document.querySelector('article');
        if (content) {
            content.style.maxWidth = '100%';
            content.style.margin = '0 auto';
            content.style.padding = '24px 28px';
        }

        document.querySelectorAll('.md-container, .md-main, .md-main__inner, .md-content__inner').forEach(el => {
            el.style.maxWidth = '100%';
            el.style.padding = '0';
            el.style.margin = '0';
        });

        document.querySelectorAll('img[loading="lazy"]').forEach(img => {
            img.setAttribute('loading', 'eager');
        });
    }""")

    print("[3/4] Pre-scrolling to trigger lazy content...")
    total_height = await page.evaluate("() => document.documentElement.scrollHeight")

    scroll_step = viewport_h // 2
    current_pos = 0
    while current_pos < total_height:
        await page.evaluate(f"window.scrollTo(0, {current_pos})")
        await page.wait_for_timeout(300)
        current_pos += scroll_step

    await page.wait_for_timeout(1000)
    await page.evaluate("window.scrollTo(0, 0)")
    await page.wait_for_timeout(500)


async def export_screenshots(
    url: str,
    output_dir: str,
    target_width: int = DEFAULT_WIDTH,
    target_height: int = DEFAULT_HEIGHT,
    dpr: int = DEFAULT_DPR,
    overlap_px: int = DEFAULT_OVERLAP,
    zoom: float = DEFAULT_ZOOM,
):
    """Capture a blog page as sequential screenshots for 小红书."""
    from playwright.async_api import async_playwright

    viewport_w = target_width // dpr
    viewport_h = target_height // dpr
    overlap_vp = overlap_px // dpr

    print(f"[Screenshot Mode] {target_width}x{target_height} @ {dpr}x DPR, zoom {zoom}x")
    print(f"URL: {url}")
    print(f"Output: {output_dir}/")

    os.makedirs(output_dir, exist_ok=True)

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": viewport_w, "height": viewport_h},
            device_scale_factor=dpr,
        )
        page = await context.new_page()

        await prepare_page(page, url, viewport_w, viewport_h)

        if zoom != 1.0:
            print(f"     Applying CSS zoom: {zoom}x")
            await page.evaluate(f"document.body.style.zoom = '{zoom}'")
            await page.wait_for_timeout(300)

        total_height = await page.evaluate("() => document.documentElement.scrollHeight")
        print(f"     Page height: {total_height}px")

        print("[4/4] Capturing screenshots...")
        step = viewport_h - overlap_vp
        screenshots = []
        page_num = 0
        scroll_pos = 0

        while scroll_pos < total_height:
            page_num += 1
            await page.evaluate(f"window.scrollTo(0, {scroll_pos})")
            await page.wait_for_load_state("networkidle")
            await page.wait_for_timeout(500)

            actual_pos = await page.evaluate("() => window.scrollY")
            filename = f"page_{page_num:02d}.png"
            filepath = os.path.join(output_dir, filename)

            await page.screenshot(path=filepath, type="png", full_page=False)

            file_size = os.path.getsize(filepath)
            print(f"     [{page_num}] scroll={actual_pos}px -> {filename} ({file_size // 1024}KB)")
            screenshots.append(filepath)

            scroll_pos += step
            if actual_pos + viewport_h >= total_height:
                break

        print(f"\nDone! {len(screenshots)} screenshots -> {output_dir}/")
        await browser.close()


# ─── Markdown Export Mode ───────────────────────────────────────

def resolve_relative_link(rel_path: str, article_path: str) -> str:
    """Resolve a relative link to an absolute URL.

    article_path: e.g. "thinking-in-context/when-multi-agent"
    rel_path:     e.g. "../../one-poem-suffices/context-engineering/"
    """
    # For ./assets/* image paths, resolve relative to the article
    if rel_path.startswith("./"):
        return f"{SITE_BASE_URL}/{article_path}/{rel_path[2:]}"

    # Resolve ../ paths relative to the article's directory
    base_parts = article_path.strip("/").split("/")
    rel_parts = rel_path.split("/")

    # Walk up for each ..
    while rel_parts and rel_parts[0] == "..":
        rel_parts.pop(0)
        if base_parts:
            base_parts.pop()

    resolved = "/".join(base_parts + rel_parts).strip("/")
    return f"{SITE_BASE_URL}/{resolved}"


def convert_admonitions(lines: list[str]) -> list[str]:
    """Convert MkDocs admonitions to blockquotes for Typora."""
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Match admonition start: !!! type "title"
        admon_match = re.match(r'^!!!\s+\w+\s+"(.+)"', line)
        if admon_match:
            title = admon_match.group(1)
            result.append(f"> **{title}**")
            result.append(">")
            i += 1

            # Skip optional blank line after !!!
            if i < len(lines) and lines[i].strip() == "":
                i += 1

            # Collect indented content (4 spaces)
            while i < len(lines):
                content_line = lines[i]
                if content_line.startswith("    "):
                    result.append(f"> {content_line[4:]}")
                    i += 1
                elif content_line.strip() == "":
                    # Blank line inside admonition — peek ahead
                    if i + 1 < len(lines) and lines[i + 1].startswith("    "):
                        result.append(">")
                        i += 1
                    else:
                        break
                else:
                    break

            result.append("")  # blank line after blockquote
        else:
            result.append(line)
            i += 1

    return result


def resolve_links_in_line(line: str, article_path: str) -> str:
    """Replace relative markdown links and HTML img src with absolute URLs."""

    # Markdown links: [text](../../relative/path/)
    def replace_md_link(m):
        url = m.group(1)
        if url.startswith(("http://", "https://", "#")):
            return m.group(0)  # already absolute or anchor
        resolved = resolve_relative_link(url, article_path)
        return f"]({resolved})"

    line = re.sub(r'\]\(([^)]+)\)', replace_md_link, line)

    # HTML img src="./assets/..."
    def replace_img_src(m):
        src = m.group(1)
        if src.startswith(("http://", "https://")):
            return m.group(0)
        resolved = resolve_relative_link(src, article_path)
        return f'src="{resolved}"'

    line = re.sub(r'src="([^"]+)"', replace_img_src, line)

    return line


def export_markdown(article_path: str, output_path: str):
    """Convert a blog post to Typora-compatible markdown with absolute links."""
    # Find the source file
    docs_dir = Path(__file__).parent.parent / "docs"
    source_file = docs_dir / article_path / "index.md"

    if not source_file.exists():
        print(f"Error: Source file not found: {source_file}")
        return

    print(f"[Markdown Mode]")
    print(f"Source: {source_file}")
    print(f"Output: {output_path}")

    content = source_file.read_text(encoding="utf-8")
    lines = content.split("\n")

    # 1. Convert admonitions to blockquotes
    lines = convert_admonitions(lines)

    # 2. Resolve relative links to absolute URLs
    lines = [resolve_links_in_line(line, article_path) for line in lines]

    # Write output
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    Path(output_path).write_text("\n".join(lines), encoding="utf-8")

    file_size = os.path.getsize(output_path)
    print(f"\nDone! {output_path} ({file_size // 1024}KB)")


# ─── CLI ────────────────────────────────────────────────────────

def slug_from_path(article_path: str) -> str:
    """Extract a slug from an article path for the output name."""
    cleaned = article_path.strip("/")
    parts = cleaned.split("/")
    return parts[-1] if parts else "output"


def main():
    parser = argparse.ArgumentParser(
        description="Blog Export Tool — Screenshots & Markdown",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Screenshots (小红书)
  uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent

  # Typora-compatible markdown
  uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --md

  # Markdown to custom path
  uv run scripts/screenshot_blog.py thinking-in-context/when-multi-agent --md -o ./export.md
        """,
    )
    parser.add_argument(
        "article", nargs="?",
        help="Article path under docs/ (e.g. 'thinking-in-context/when-multi-agent')",
    )
    parser.add_argument("--url", help="Full URL for screenshot mode (overrides article path)")
    parser.add_argument("--port", "-p", type=int, default=DEFAULT_PORT, help=f"Local server port (default: {DEFAULT_PORT})")
    parser.add_argument("--output-dir", "-o", help="Output directory or file path")

    # Mode
    parser.add_argument("--md", action="store_true", help="Export as Typora-compatible markdown")

    # Screenshot-specific options
    parser.add_argument("--width", "-W", type=int, default=DEFAULT_WIDTH, help=f"Image width (default: {DEFAULT_WIDTH})")
    parser.add_argument("--height", "-H", type=int, default=DEFAULT_HEIGHT, help=f"Image height (default: {DEFAULT_HEIGHT})")
    parser.add_argument("--dpr", type=int, default=DEFAULT_DPR, help=f"Device pixel ratio (default: {DEFAULT_DPR})")
    parser.add_argument("--overlap", type=int, default=DEFAULT_OVERLAP, help=f"Page overlap in px (default: {DEFAULT_OVERLAP})")
    parser.add_argument("--zoom", type=float, default=DEFAULT_ZOOM, help=f"CSS zoom (default: {DEFAULT_ZOOM})")

    args = parser.parse_args()

    if not args.article and not args.url:
        parser.error("Please provide an article path or --url.")

    article = args.article.strip("/") if args.article else None
    slug = slug_from_path(article or args.url)

    if args.md:
        if not article:
            parser.error("--md mode requires an article path (not --url).")
        output_path = args.output_dir or os.path.join("archived", "md", f"{slug}.md")
        export_markdown(article_path=article, output_path=output_path)
    else:
        if args.url:
            url = args.url
        elif article:
            url = f"http://localhost:{args.port}/{article}/"
        else:
            parser.error("Screenshot mode requires an article path or --url.")

        output_dir = args.output_dir or os.path.join("archived", "xiaohongshu", slug)
        asyncio.run(export_screenshots(
            url=url, output_dir=output_dir,
            target_width=args.width, target_height=args.height,
            dpr=args.dpr, overlap_px=args.overlap, zoom=args.zoom,
        ))


if __name__ == "__main__":
    main()
