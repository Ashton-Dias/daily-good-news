"""Read/write the published JSON files."""
import json
import os
from pathlib import Path


def _write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def load_index(public_dir):
    path = Path(public_dir) / "index.json"
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def publish_story(public_dir, story):
    """Write stories/DATE.json, latest.json and index.json (newest first)."""
    public = Path(public_dir)
    index = [s for s in load_index(public) if s["date"] != story["date"]]
    index.append(story)
    index.sort(key=lambda s: s["date"], reverse=True)
    _write_json(public / "stories" / f"{story['date']}.json", story)
    _write_json(public / "latest.json", story)
    _write_json(public / "index.json", index)
