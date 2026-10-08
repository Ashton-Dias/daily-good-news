"""Load feeds and turn entries into plain candidate dicts."""
import html
import re
import sys

import feedparser
import yaml

USER_AGENT = "DailyGoodNewsBot/1.0 (+https://github.com)"
PER_FEED = 15
SNIPPET_CHARS = 600


def load_sources(path):
    with open(path, encoding="utf-8") as f:
        feeds = yaml.safe_load(f)["feeds"]
    return [{"name": x["name"], "url": x["url"]} for x in feeds]


def _clean(text):
    text = re.sub(r"<[^>]+>", " ", text or "")
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def fetch_candidates(sources, per_feed=PER_FEED):
    candidates = []
    for src in sources:
        parsed = feedparser.parse(src["url"], agent=USER_AGENT)
        if not parsed.entries:
            print(f"warning: no entries from {src['name']} ({src['url']})", file=sys.stderr)
            continue
        for entry in parsed.entries[:per_feed]:
            title = _clean(entry.get("title"))
            url = (entry.get("link") or "").strip()
            if not title or not url:
                continue
            candidates.append({
                "title": title,
                "url": url,
                "source_name": src["name"],
                "snippet": _clean(entry.get("summary"))[:SNIPPET_CHARS],
            })
    for i, c in enumerate(candidates):
        c["id"] = i
    return candidates
