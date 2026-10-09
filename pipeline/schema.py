"""Story schema validation and the no-copying guard."""
import re
from datetime import date
from urllib.parse import urlparse

FIELDS = ("date", "headline", "summary", "category", "source_name", "source_url")
OPTIONAL_FIELDS = ("is_teaser",)  # only written when true
CATEGORIES = (
    "Health", "Environment", "Science", "Community", "Technology",
    "Economy", "Education", "Wildlife", "Other",
)
MAX_HEADLINE = 80
MAX_SUMMARY = 220


class ValidationError(ValueError):
    pass


def validate_story(story):
    """Return a clean, ordered copy of `story` or raise ValidationError."""
    if not isinstance(story, dict):
        raise ValidationError("story must be an object")
    missing = [f for f in FIELDS if f not in story]
    extra = [k for k in story if k not in FIELDS + OPTIONAL_FIELDS]
    if missing:
        raise ValidationError(f"missing fields: {', '.join(missing)}")
    if extra:
        raise ValidationError(f"unexpected fields: {', '.join(extra)}")
    for f in FIELDS:
        if not isinstance(story[f], str) or not story[f].strip():
            raise ValidationError(f"{f} must be a non-empty string")
    clean = {f: story[f].strip() for f in FIELDS}
    if "is_teaser" in story:
        if not isinstance(story["is_teaser"], bool):
            raise ValidationError("is_teaser must be a boolean")
        if story["is_teaser"]:
            clean["is_teaser"] = True
    try:
        date.fromisoformat(clean["date"])
    except ValueError:
        raise ValidationError("date must be YYYY-MM-DD")
    if len(clean["headline"]) > MAX_HEADLINE:
        raise ValidationError(f"headline over {MAX_HEADLINE} chars")
    if len(clean["summary"]) > MAX_SUMMARY:
        raise ValidationError(f"summary over {MAX_SUMMARY} chars")
    if clean["category"] not in CATEGORIES:
        raise ValidationError(f"category must be one of {', '.join(CATEGORIES)}")
    parsed = urlparse(clean["source_url"])
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValidationError("source_url must be an http(s) URL")
    return clean


def _words(text):
    return re.findall(r"[a-z0-9']+", text.lower())


def copied_phrase(text, source, n=5):
    """Return the first run of `n` consecutive words that `text` shares with
    `source`, or None. Used to enforce 'never copy source wording'."""
    src = _words(source)
    grams = {tuple(src[i:i + n]) for i in range(len(src) - n + 1)}
    words = _words(text)
    for i in range(len(words) - n + 1):
        if tuple(words[i:i + n]) in grams:
            return " ".join(words[i:i + n])
    return None
