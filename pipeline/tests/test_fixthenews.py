import pytest

import fixthenews
from dedupe import filter_new, normalize_url
from schema import ValidationError, validate_story

TEASER_HTML = """
<p>That&#8217;s the free edition. Paid subscribers get the rest, including:</p>
<p>America&#8217;s falling cancer death rates, hundreds of rhinos from the world&#8217;s
largest captive herd headed back into the wild, how renewables stopped 3.7
billion tonnes of CO2 getting dumped into the atmosphere last year (about
three-quarters of what the US emits), and two new cousins for CRISPR,
courtesy of the computers. Plus Brazil&#8217;s new protections for women, India&#8217;s
tigers going to Cambodia, and the world&#8217;s newest, tallest wind turbine.</p>
<p>Fix The News is 100% independent, fully boot-strapped, and entirely reliant
on our paid subscribers to keep running. If you get value from these
newsletters, please consider supporting us :)</p>
"""

FREE_HTML = """
<h1>Intro</h1><p><strong>Not a story.</strong> This is before the stories and is ignored entirely, however long it is. FILLER</p>
<h1>This week&#8217;s top stories</h1>
<p><strong><br />American teenagers are feeling less hopeless.</strong> The share of high schoolers
reporting persistent sadness fell from 42% in 2021 to 33% in 2025, according to the <a href="x">CDC</a>.</p>
<p><em>And finally,</em> <strong>a short video.</strong></p>
<p>No bold lead here, so it is skipped, even though it is quite a long paragraph of plain text that goes on.</p>
<h1>Next section</h1><p><strong>Ignored.</strong> Also long enough to pass the length floor but outside the section, so it must not appear.</p>
""".replace("FILLER", "x " * 80)


def test_teaser_split_matches_the_newsletter_paragraph():
    assert fixthenews.teaser_items(TEASER_HTML) == [
        "America's falling cancer death rates",
        "hundreds of rhinos from the world's largest captive herd headed back into the wild",
        "how renewables stopped 3.7 billion tonnes of CO2 getting dumped into the atmosphere "
        "last year (about three-quarters of what the US emits)",
        "two new cousins for CRISPR, courtesy of the computers",
        "Brazil's new protections for women",
        "India's tigers going to Cambodia",
        "the world's newest, tallest wind turbine",
    ]


def test_teaser_drops_fundraising_paragraph():
    assert not any("independent" in t for t in fixthenews.teaser_items(TEASER_HTML))


def test_teaser_without_marker_returns_nothing():
    assert fixthenews.teaser_items("<p>Just a normal edition with, commas, and more.</p>") == []


def test_teaser_marker_tolerates_curly_apostrophes_and_spacing():
    html = "<p>Paid  subscribers get the rest,  including:</p><p>Rhinos go wild, and tigers travel.</p>"
    assert fixthenews.teaser_items(html) == ["Rhinos go wild", "tigers travel"]


def test_free_items_only_from_top_stories_with_bold_lead():
    items = fixthenews.free_items(FREE_HTML)
    assert [lead for lead, _ in items] == ["American teenagers are feeling less hopeless."]
    assert "according to the CDC" in items[0][1]


def test_extract_skips_non_editions_and_marks_teasers():
    entries = [
        {"title": "Introducing our Progress Library", "link": "https://x/p/a",
         "content": [{"value": FREE_HTML}]},
        {"title": "356: Fire Amoeba.", "link": "https://x/p/356",
         "content": [{"value": FREE_HTML + TEASER_HTML}]},
    ]
    out = fixthenews.extract(entries, "Fix The News")
    assert {c["is_teaser"] for c in out} == {True, False}
    assert all(c["url"].startswith("https://x/p/356#item-") for c in out)
    assert len({c["url"] for c in out}) == len(out)
    assert sum(c["is_teaser"] for c in out) == 7


def test_items_of_one_edition_dedupe_separately():
    a = {"title": "A", "url": fixthenews.item_url("https://x.org/p/1", "free", "A")}
    b = {"title": "B something else", "url": fixthenews.item_url("https://x.org/p/1", "free", "B")}
    assert len(filter_new([a, b], [])) == 2
    published = [{"headline": "zzz", "source_url": a["url"]}]
    assert [c["title"] for c in filter_new([a, b], published)] == ["B something else"]


def test_plain_fragments_still_ignored_in_urls():
    assert normalize_url("https://x.org/a#top") == normalize_url("https://x.org/a")


def test_schema_is_teaser_optional_and_written_only_when_true():
    base = {"date": "2026-10-09", "headline": "Tigers travel to Cambodia",
            "summary": "India is sending tigers to Cambodia.", "category": "Wildlife",
            "source_name": "Fix The News", "source_url": "https://x.org/p/1#item-abc"}
    assert "is_teaser" not in validate_story(base)
    assert "is_teaser" not in validate_story({**base, "is_teaser": False})
    assert validate_story({**base, "is_teaser": True})["is_teaser"] is True
    with pytest.raises(ValidationError):
        validate_story({**base, "is_teaser": "yes"})
