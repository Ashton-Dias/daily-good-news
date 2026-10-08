# Daily Good News

One piece of good news a day, shown in an iOS home-screen widget.
A daily job picks and rewrites a story and publishes static JSON. The app and
widget only download that JSON.

```
pipeline/            Python daily job (feedparser + Anthropic SDK)
public/              Published JSON, served by GitHub Pages
ios/                 SwiftUI app + WidgetKit extension (Phase 2)
.github/workflows/   Daily cron + Pages deploy
```

## How the pipeline works

1. Reads the feeds in `pipeline/sources.yaml`.
2. Drops anything already published (same URL, or a near-identical headline).
3. Sends the rest to Claude in one batch, scoring each 0-10 on: genuinely
   positive, substantive, not an ad or fluff, not political or divisive. A story
   needs every score >= 5 and an average >= 7 to qualify.
4. Claude writes an original headline (<= 80 chars) and summary (<= 220 chars).
   Output is rejected and retried if it is too long or reuses any 5-word run
   from the source. Source images are never touched.
5. Writes `public/latest.json`, `public/stories/YYYY-MM-DD.json` and
   `public/index.json` (array, newest first).

Story schema: `date`, `headline`, `summary`, `category`, `source_name`, `source_url`.

If anything fails or nothing qualifies, the job logs a warning, exits 0 and
leaves yesterday's files untouched.

## Local setup

```bash
cd pipeline
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest                                   # unit tests, no network or API key

export ANTHROPIC_API_KEY=sk-ant-...
export ANTHROPIC_MODEL=<model id>        # see docs.anthropic.com for current IDs
python main.py --dry-run                 # top 5 candidates + scores, writes nothing
python main.py                           # publish today's story into ../public
```

`--date YYYY-MM-DD` overrides the story date. A date that is already in
`index.json` is skipped.

## GitHub setup (manual)

1. Create a GitHub repo and push this project.
2. **Settings > Secrets and variables > Actions**
   - Secrets tab: add `ANTHROPIC_API_KEY`.
   - Variables tab: add `ANTHROPIC_MODEL` (the model ID string).
3. **Settings > Pages > Build and deployment > Source: GitHub Actions.**
4. **Settings > Actions > General > Workflow permissions:** Read and write
   (the job commits the new JSON).
5. **Actions > Daily story > Run workflow** to publish the first story. Your
   JSON base URL is then `https://<user>.github.io/<repo>/`
   (try `.../latest.json`).

The cron runs at 04:00 UTC. GitHub may delay scheduled runs by several minutes,
and disables schedules on repos with no activity for 60 days; the daily commit
normally keeps it alive.
