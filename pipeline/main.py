"""Daily Good News pipeline.

    python main.py             # pick and publish today's story
    python main.py --dry-run   # print top 5 scored candidates, write nothing

A real run never fails the CI job: on any error or if nothing good is found it
logs and exits 0, leaving the previously published story in place.
"""
import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

import dedupe
import llm
import publish
import schema
import sources

HERE = Path(__file__).resolve().parent
MAX_TO_LLM = 45


def run(args):
    public = Path(args.public_dir)
    today = args.date
    published = publish.load_index(public)

    if not args.dry_run and any(s["date"] == today for s in published):
        print(f"{today} already published; nothing to do.")
        return

    candidates = sources.fetch_candidates(sources.load_sources(args.sources))
    fresh = dedupe.filter_new(candidates, published)[:MAX_TO_LLM]
    for i, c in enumerate(fresh):
        c["id"] = i
    print(f"{len(candidates)} fetched, {len(fresh)} new after dedupe.")
    if not fresh:
        print("No new candidates; keeping the current story.")
        return

    client, model = llm.make_client()
    scored = llm.score_candidates(client, model, fresh)

    if args.dry_run:
        for s in scored[:5]:
            flag = "ok  " if s["eligible"] else "skip"
            print(f"\n[{flag}] {s['overall']:>5}  {s['category']}  ({s['source_name']})")
            print(f"       {s['title']}")
            print(f"       {s['url']}")
            print(f"       {s['scores']}  {s['reason']}")
        return

    ranked = [s for s in scored if s["eligible"]]
    if not ranked:
        print(f"Nothing met the bar (best was {scored[0]['overall'] if scored else 'n/a'}); "
              "keeping the current story.")
        return

    for cand in ranked[:3]:
        try:
            headline, summary = llm.write_copy(client, model, cand)
            story = schema.validate_story({
                "date": today,
                "headline": headline,
                "summary": summary,
                "category": cand["category"],
                "source_name": cand["source_name"],
                "source_url": cand["url"],
            })
        except Exception as e:  # try the next-best candidate
            print(f"skipping '{cand['title']}': {e}", file=sys.stderr)
            continue
        publish.publish_story(public, story)
        print(f"Published: {story['headline']}")
        return
    print("No candidate produced valid copy; keeping the current story.")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true",
                   help="print top 5 candidates with scores; write nothing")
    p.add_argument("--date", default=datetime.now(timezone.utc).date().isoformat(),
                   help="story date, YYYY-MM-DD (default: today UTC)")
    p.add_argument("--sources", default=str(HERE / "sources.yaml"))
    p.add_argument("--public-dir", default=str(HERE.parent / "public"))
    args = p.parse_args()
    try:
        run(args)
    except Exception as e:
        print(f"::warning::pipeline failed: {type(e).__name__}: {e}", file=sys.stderr)
        if args.dry_run:
            sys.exit(1)
        print("Keeping the current story.")
    sys.exit(0)


if __name__ == "__main__":
    main()
