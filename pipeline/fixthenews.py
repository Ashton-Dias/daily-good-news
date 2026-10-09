"""Turn Fix The News (Substack) feed entries into candidate items.

Only text the public RSS feed serves is used. Nothing is fetched from paywalled
pages and nothing is reconstructed beyond what the feed says.

Two kinds of candidate come out of an edition:
  * free items: the "This week's top stories" paragraphs (bold lead + body)
  * teaser items: the one-sentence topics listed after "Paid subscribers get the
    rest, including:". Only the teaser sentence itself is ever used as source.
"""
import hashlib
import html
import re

EDITION_TITLE = re.compile(r"^\d+:\s")  # "356: Fire Amoeba. ..."; skips podcasts/essays
EDITIONS_PER_RUN = 1
MIN_ITEM_CHARS = 120  # shorter than this is a stub like "And finally, a video"

TEASER_MARKER = re.compile(
    r"paid\s+subscribers\s+get\s+the\s+rest,?\s+including\s*:", re.I)
FUNDRAISING = re.compile(r"Fix\s+The\s+News\s+is\s+100%\s+independent", re.I)

_TAG = re.compile(r"<[^>]+>")


def _text(fragment):
    fragment = re.sub(r"</(p|div|h\d)>", "\n\n", fragment or "", flags=re.I)
    fragment = _TAG.sub(" ", fragment)
    fragment = html.unescape(fragment).replace("’", "'").replace("‘", "'")
    return re.sub(r"[ \t\r\f\v\xa0]+", " ", fragment).strip()


def _flat(fragment):
    return re.sub(r"\s+", " ", _text(fragment)).strip()


def item_url(edition_url, kind, text):
    """Distinct per item so dedupe can tell items of one edition apart, while the
    link still opens the original post (Substack ignores the fragment)."""
    digest = hashlib.sha1(f"{kind}:{text}".encode()).hexdigest()[:10]
    return f"{edition_url}#item-{digest}"


def free_items(content_html):
    """Bold-led paragraphs under the 'top stories' heading: (lead, full text)."""
    parts = re.split(r"<h1[^>]*>.*?</h1>", content_html, flags=re.I | re.S)
    headings = re.findall(r"<h1[^>]*>(.*?)</h1>", content_html, flags=re.I | re.S)
    body = ""
    for heading, section in zip(headings, parts[1:]):
        if "top stories" in _flat(heading).lower():
            body = section
            break
    items = []
    for m in re.finditer(r"<p[^>]*>(.*?)</p>", body, flags=re.I | re.S):
        para = m.group(1)
        lead = re.search(r"<strong[^>]*>(.*?)</strong>", para, flags=re.I | re.S)
        if not lead:
            continue
        lead_text, full = _flat(lead.group(1)), _flat(para)
        if len(full) >= MIN_ITEM_CHARS and lead_text:
            items.append((lead_text, full))
    return items


def _split_top_level(text):
    """Split on commas outside parentheses."""
    out, depth, cur = [], 0, []
    for ch in text:
        depth += (ch == "(") - (ch == ")")
        if ch == "," and depth == 0:
            out.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return out


_CONTINUATIONS = ("courtesy of", "thanks to", "according to", "via", "including")


def _continues(previous, piece):
    """True if a comma-separated `piece` belongs to the `previous` item: a trailing
    phrase ("..., courtesy of the computers") or coordinate adjectives
    ("the world's newest, tallest wind turbine")."""
    if piece.lower().startswith(_CONTINUATIONS):
        return True
    return previous.split()[-1].endswith("est") and piece.split()[0].endswith("est")


def teaser_items(content_html):
    """Split the 'Paid subscribers get the rest, including:' paragraph into one
    string per topic. Returns [] if the marker is absent (never guesses)."""
    text = _text(content_html)
    m = TEASER_MARKER.search(text)
    if not m:
        return []
    block = text[m.end():].strip()
    end = FUNDRAISING.search(block)
    if end:
        block = block[:end.start()]
    block = re.sub(r"\s+", " ", block.split("\n\n")[0]).strip()
    if not block:
        return []
    pieces = []
    for sentence in re.split(r"(?<=[.!?])\s+", block):
        pieces.extend(_split_top_level(sentence.rstrip(".!? ")))
    items = []
    for piece in pieces:
        piece = re.sub(r"^\s*(?:and|plus)\s+", "", piece.strip(), flags=re.I).strip(" .")
        if not piece:
            continue
        if items and _continues(items[-1], piece):
            items[-1] = f"{items[-1]}, {piece}"
        else:
            items.append(piece)
    return items


def extract(entries, source_name, snippet_chars=600):
    """Candidate dicts (title/url/source_name/snippet, plus is_teaser) from the
    newest numbered editions in `entries` (feedparser entries)."""
    candidates = []
    editions = [e for e in entries if EDITION_TITLE.match(e.get("title", ""))]
    for entry in editions[:EDITIONS_PER_RUN]:
        url = (entry.get("link") or "").strip()
        content = (entry.get("content") or [{}])[0].get("value") or entry.get("summary", "")
        if not url or not content:
            continue
        for lead, full in free_items(content):
            candidates.append({
                "title": lead,
                "url": item_url(url, "free", lead),
                "source_name": source_name,
                "snippet": full[:snippet_chars],
                "is_teaser": False,
            })
        for topic in teaser_items(content):
            candidates.append({
                "title": topic,
                "url": item_url(url, "teaser", topic),
                "source_name": source_name,
                "snippet": topic,
                "is_teaser": True,
            })
    return candidates
