"""Rebase embedded evidence links for the output page, including flat HTML URLs."""
import os
import re
from pathlib import Path
from urllib.parse import urlsplit, unquote


def on_post_page(output, page, config):
    parent = Path(page.file.dest_uri).parent

    def fix(match):
        url = match.group(2)
        parts = urlsplit(url)
        if parts.scheme or parts.netloc or '/assets/' not in parts.path:
            return match.group(0)
        asset = 'assets/' + parts.path.split('/assets/', 1)[1]
        if not (Path(config['docs_dir']) / unquote(asset)).is_file():
            return match.group(0)
        target = os.path.relpath(asset, parent).replace('\\', '/')
        if parts.query:
            target += '?' + parts.query
        if parts.fragment:
            target += '#' + parts.fragment
        return match.group(1) + target + match.group(3)

    return re.sub(r'((?:href|src)=["\'])([^"\']+)(["\'])', fix, output)
