"""Drop candidates already published (or repeated across feeds)."""
import re
from difflib import SequenceMatcher
from urllib.parse import urlparse

TITLE_SIMILARITY = 0.85


def normalize_url(url):
    p = urlparse(url.strip())
    host = p.netloc.lower().removeprefix("www.")
    key = f"{host}{p.path.rstrip('/')}".lower()
    # Newsletter items share one post URL; their "#item-..." fragment tells them apart.
    if p.fragment.startswith("item-"):
        key += f"#{p.fragment}"
    return key


def normalize_title(title):
    return " ".join(re.findall(r"[a-z0-9]+", title.lower()))


def is_duplicate(candidate, published):
    """`candidate` has title/url; `published` is a list of stories
    (headline/source_url)."""
    url = normalize_url(candidate["url"])
    title = normalize_title(candidate["title"])
    for story in published:
        if normalize_url(story["source_url"]) == url:
            return True
        other = normalize_title(story["headline"])
        if title and other and SequenceMatcher(None, title, other).ratio() >= TITLE_SIMILARITY:
            return True
    return False


def filter_new(candidates, published):
    """Remove published duplicates and repeats within `candidates`."""
    seen = set()
    fresh = []
    for c in candidates:
        key = normalize_url(c["url"])
        if key in seen or is_duplicate(c, published):
            continue
        seen.add(key)
        fresh.append(c)
    return fresh
