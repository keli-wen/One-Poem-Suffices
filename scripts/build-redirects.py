#!/usr/bin/env python3
"""Build redirect HTML files from docs/ to https://lastwhisper.dev."""

import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
SITE_DIR = REPO_ROOT / "site"
TARGET_HOST = "https://lastwhisper.dev"

HTML_TEMPLATE = """<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url={target_url}">
<link rel="canonical" href="{target_url}">
<meta name="robots" content="noindex">
<title>已迁移到 lastwhisper.dev</title></head>
<body><p>这篇文章已迁移到 <a href="{target_url}">{display_url}</a>，正在跳转…</p></body></html>
"""

NOT_FOUND_TEMPLATE = """<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="robots" content="noindex">
<title>已迁移到 lastwhisper.dev</title>
<script>
(function() {
  var path = window.location.pathname.replace(/^\\/One-Poem-Suffices(?:\\/|$)/i, '/');
  if (!path.startsWith('/')) path = '/' + path;
  var target = 'https://lastwhisper.dev' + path + window.location.search + window.location.hash;
  window.location.replace(target);
})();
</script>
</head>
<body><p>页面已迁移到 <a id="dest" href="https://lastwhisper.dev/">lastwhisper.dev</a>，正在跳转…</p>
<script>
  var path = window.location.pathname.replace(/^\\/One-Poem-Suffices(?:\\/|$)/i, '/');
  if (!path.startsWith('/')) path = '/' + path;
  var target = 'https://lastwhisper.dev' + path + window.location.search + window.location.hash;
  var a = document.getElementById('dest');
  if (a) { a.href = target; a.textContent = target; }
</script>
</body></html>
"""


def main():
    if SITE_DIR.exists():
        shutil.rmtree(SITE_DIR)
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Generate .nojekyll
    (SITE_DIR / ".nojekyll").touch()

    # 2. Generate 404.html
    (SITE_DIR / "404.html").write_text(NOT_FOUND_TEMPLATE, encoding="utf-8")

    # 3. Traverse docs/**/index.md
    count = 0
    for md_path in sorted(DOCS_DIR.glob("**/index.md")):
        rel = md_path.relative_to(DOCS_DIR)
        parent = rel.parent
        if parent == Path("."):
            dest_html = SITE_DIR / "index.html"
            target_url = f"{TARGET_HOST}/"
            display_url = "lastwhisper.dev/"
        else:
            rel_str = parent.as_posix()
            dest_html = SITE_DIR / parent / "index.html"
            target_url = f"{TARGET_HOST}/{rel_str}/"
            display_url = f"lastwhisper.dev/{rel_str}/"

        dest_html.parent.mkdir(parents=True, exist_ok=True)
        content = HTML_TEMPLATE.format(target_url=target_url, display_url=display_url)
        dest_html.write_text(content, encoding="utf-8")
        count += 1

    print(f"Generated {count} redirect pages + 404.html + .nojekyll in {SITE_DIR}")


if __name__ == "__main__":
    main()
