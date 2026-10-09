# Ship checklist (things only you can do)

Tick these in order. Anything marked **(Xcode)** or **(ASC)** = App Store Connect.

## 1. Backend live first
- [ ] Push the repo to GitHub.
- [ ] Settings > Secrets and variables > Actions: secret `ANTHROPIC_API_KEY`, variable `ANTHROPIC_MODEL`.
- [ ] Settings > Pages > Source: **GitHub Actions**.
- [ ] Settings > Actions > General > Workflow permissions: **Read and write**.
- [ ] Run **Actions > Daily story > Run workflow**; confirm `https://<user>.github.io/<repo>/latest.json` loads.
- [x] Edit `public/privacy.html`: replace `YOUR_CONTACT_EMAIL` (done). Still to do after deploy: commit, and confirm
      `https://<user>.github.io/<repo>/privacy.html` loads. This is your Privacy Policy URL.

## 2. Config
- [ ] Edit `ios/Config/Config.xcconfig`: `APP_BUNDLE_ID`, `APP_GROUP_ID`, `JSON_BASE_URL`, `DEVELOPMENT_TEAM`.
- [ ] `cd ios && xcodegen generate && open DailyGoodNews.xcodeproj`.

## 3. Apple Developer account (developer.apple.com, paid membership)
- [ ] Register the App Group (Identifiers > App Groups) matching `APP_GROUP_ID`.
- [ ] Register two App IDs: `APP_BUNDLE_ID` and `APP_BUNDLE_ID.widget`, both with the
      **App Groups** capability set to that group. (Automatic signing in Xcode can do this for you.)

## 4. Xcode
- [ ] Both targets > Signing & Capabilities: select your Team; confirm "App Groups" shows your group on both.
- [ ] Run on a real device: add the widget (small, medium, lock screen), confirm it shows the story,
      tap it and confirm the app opens on that story. Turn on airplane mode and confirm the cached story shows.
- [ ] Replace the placeholder icon: put your own 1024x1024 PNG (no transparency) at
      `ios/App/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- [ ] Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `ios/project.yml` for each upload; re-run `xcodegen generate`.
- [ ] Product > Archive > Distribute App > App Store Connect. Fix any validation errors.
- [ ] (Optional) Product > Generate Privacy Report to double-check the manifests.

## 5. App Store Connect
- [ ] My Apps > + New App: name, primary language, bundle ID, SKU.
- [ ] App Information: Privacy Policy URL (from step 1), category (suggest News or Lifestyle), age rating questionnaire (no objectionable content).
- [ ] **App Privacy**: choose **Data Not Collected**. (No analytics, accounts or tracking; favourites stay on device.)
- [ ] Export compliance: already set (`ITSAppUsesNonExemptEncryption = NO`, HTTPS only); answer the prompt accordingly.
- [ ] Screenshots: required 6.9" (or 6.7") iPhone set. Include the widget on the home screen if you like.
- [ ] Description, keywords, support URL (can be your Pages site or GitHub repo), copyright line.
- [ ] Select the uploaded build, then **Submit for Review**.
- [ ] Review notes: say the app needs no login and shows one story a day from a public JSON feed.
      The reviewer needs `latest.json` to exist, so publish at least one story before submitting.

## 6. Content and licensing sanity checks
- [ ] Skim a week of generated stories: confirm headlines/summaries are original and sources are shown.
- [ ] Confirm each source's terms are okay with headline-style rewrites that link back
      (the app never copies images or article text). Consider emailing the publishers.
- [ ] Anthropic API spend: set a monthly limit in the Console. The job makes about 2 requests a day.

## After launch
- [ ] Watch the Actions tab occasionally. Failures show as warnings and the old story stays up.
- [ ] GitHub pauses scheduled workflows after 60 days without repo activity; the daily commit normally prevents this.
