import pytest

from schema import ValidationError, copied_phrase, validate_story

GOOD = {
    "date": "2026-10-05",
    "headline": "Town turns old rail line into a mile-long community garden",
    "summary": "Volunteers converted an unused rail corridor into shared growing space.",
    "category": "Community",
    "source_name": "Good News Network",
    "source_url": "https://www.goodnewsnetwork.org/x/",
}


def bad(**kw):
    return {**GOOD, **kw}


def test_valid_story_passes():
    assert validate_story(GOOD) == GOOD


def test_missing_and_extra_fields():
    with pytest.raises(ValidationError):
        validate_story({k: v for k, v in GOOD.items() if k != "category"})
    with pytest.raises(ValidationError):
        validate_story(bad(image="x.png"))


@pytest.mark.parametrize("field,value", [
    ("date", "05-10-2026"),
    ("headline", "x" * 81),
    ("summary", "x" * 221),
    ("category", "Sports"),
    ("source_url", "ftp://example.org/a"),
    ("source_name", "  "),
])
def test_invalid_values(field, value):
    with pytest.raises(ValidationError):
        validate_story(bad(**{field: value}))


def test_limits_are_inclusive():
    validate_story(bad(headline="x" * 80, summary="y" * 220))


def test_copied_phrase_detection():
    src = "Scientists in Kenya have planted two million mangrove trees along the coast"
    assert copied_phrase("They planted two million mangrove trees this year", src)
    assert copied_phrase("Kenya restores coastal mangroves at huge scale", src) is None
