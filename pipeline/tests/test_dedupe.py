from dedupe import filter_new, is_duplicate, normalize_url

PUBLISHED = [{
    "headline": "Rural clinic cuts malaria cases by half in two years",
    "source_url": "https://www.example.org/stories/clinic/",
}]


def cand(title, url):
    return {"title": title, "url": url}


def test_normalize_url_ignores_scheme_www_query_slash():
    assert normalize_url("http://www.Example.org/a/b/?utm=1#x") == normalize_url("https://example.org/a/b")


def test_same_url_is_duplicate():
    assert is_duplicate(cand("Different title", "http://example.org/stories/clinic?ref=rss"), PUBLISHED)


def test_similar_title_is_duplicate():
    assert is_duplicate(cand("Rural clinic cuts malaria cases by half in two years!", "https://other.org/x"), PUBLISHED)


def test_new_story_is_not_duplicate():
    assert not is_duplicate(cand("Seagrass meadows return to the bay", "https://other.org/seagrass"), PUBLISHED)


def test_filter_new_drops_published_and_cross_feed_repeats():
    items = [
        cand("A", "https://a.org/1"),
        cand("A again", "https://www.a.org/1/"),
        cand("Rural clinic cuts malaria cases by half in two years", "https://b.org/z"),
        cand("Completely different thing", "https://c.org/3"),
    ]
    assert [c["url"] for c in filter_new(items, PUBLISHED)] == ["https://a.org/1", "https://c.org/3"]


def test_empty_published():
    assert len(filter_new([cand("X", "https://x.org/1")], [])) == 1
