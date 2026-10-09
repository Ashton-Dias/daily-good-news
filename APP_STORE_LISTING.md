# App Store Connect listing (draft)

Every claim below matches the app as it is now. Paste each block into the field named in its heading.
Character counts are checked against Apple's limits.

## App Information
- **Name** (15/30): Daily Good News
- **Subtitle** (25/30): One good story, every day
- **Primary category:** News. **Secondary:** Lifestyle. (Either works. News fits headline-style content; Lifestyle is the fallback if you would rather not be reviewed as a news app.)
- **Age rating:** 4+. In the questionnaire answer "None" to every item (no violence, mature content, gambling, unrestricted web access, user-generated content).
- **Copyright:** 2026 Ashton Dias
- **Support URL:** https://ashton-dias.github.io/daily-good-news/support.html
- **Privacy Policy URL:** https://ashton-dias.github.io/daily-good-news/privacy.html
- **Marketing URL:** leave blank

## Version 1.0
**Promotional text** (118/170):
One uplifting story a day, on your home screen or lock screen. Short, calm and always credited to the original source.

**Keywords** (99/100):
good news,positive,uplifting,widget,daily,hope,progress,optimistic,inspiring,feel good,calm,stories

**What's New:**
First release.

**Description:**
A quiet daily dose of good news.

Each day Daily Good News picks one uplifting story from the world of health, science, nature, community and progress, and gives you a short, plain summary. Every story shows where it came from, and one tap opens the original article.

HOME SCREEN AND LOCK SCREEN WIDGETS
See today's story without opening the app. Small and medium widgets for the home screen, and a rectangular widget for the lock screen.

BROWSE, SEARCH AND SAVE
Look back through recent stories in the archive, search by topic or source, and filter by category. Tap the heart to keep a story in your favourites.

WORKS OFFLINE
Recent stories are saved on your device, so the archive and your favourites open without a connection.

AN OPTIONAL DAILY REMINDER
Turn on a gentle reminder at a time you choose. It is off by default, and the notification never contains the story itself.

CALM BY DESIGN
A warm, quiet look with large, readable type, in light and dark mode.

PRIVATE
No account, no ads and no tracking. Your favourites stay on your device.

Stories are short summaries written in our own words, and each one credits and links to its original source.

## App Privacy
- **Answer:** Data Not Collected.
- **Why this holds:** no accounts, analytics, advertising, crash reporting or third-party SDKs. Favourites, the reminder time and cached stories stay on the device. The reminder is a local notification (no push token, no server). The only network traffic is downloading public JSON from GitHub Pages, and the developer neither receives nor processes request logs. The privacy manifests declare no collected data and no tracking.
- **Revisit** this answer before adding analytics, crash reporting, push notifications or any feedback form.

## Export compliance
- The app uses only standard HTTPS provided by the operating system. `ITSAppUsesNonExemptEncryption` is set to NO in both targets, so answer **No** to proprietary or non-exempt encryption.

## App Review information
- **Sign-in required:** No. No demo account needed.
- **Contact:** Ashton Dias, ashtondias9@gmail.com
- **Notes for the reviewer:**

> Daily Good News needs no login. It shows one short story a day, downloaded from a public JSON feed that we host, and each story credits and links to its original source. The Archive keeps recent stories and works offline. Settings (gear icon on the Today tab) has an optional daily reminder: it is off by default, notification permission is requested only when the user turns the reminder on, and it is a local notification with no story content and no server or push. The home-screen and lock-screen widgets show the current story and need to be added from the device's widget gallery to test. Stories are summaries written in our own words; the full article is always one tap away.

## Screenshots (6.9" iPhone, 1320x2868)
Suggested order and captions:
1. Today (light): "One good story a day"
2. Home-screen widget: "On your home screen"
3. Archive with chips: "Browse by topic"
4. Archive search: "Find any story"
5. Favourites: "Keep the ones you love"
6. Today (dark) or Settings: "Calm in light and dark"

## Before you submit
- support.html and privacy.html must load at the URLs above.
- A publisher-permission reply is strongly recommended for every source (see PUBLISHER_EMAILS.md).
- Test on a real device: widget, tapping it opens the story, airplane-mode offline, reminder, largest text size.
