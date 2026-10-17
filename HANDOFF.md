# HANDOFF (game)

> **Chat nickname: GAME.** This file is for the game app only (`CHRONO-GAMEAPP`). The board that shows all three chats is `../HANDOFF.md`. Dashboard: `../CHRONO-DASHBOARD/HANDOFF.md`. Landing page: `../CHRONO-LANDING/HANDOFF.md`.
> At the end of a session add a dated entry at the top (automatically, without asking). Keep the newest entry under one page. Keep this file under about 400 lines: when it grows past that, move the oldest entries in full to `docs/handoff-archive/` and leave a one-line pointer under "Older entries" at the bottom.

**Date:** 2026-10-17 (last round: logout keeps the wallet, Poppins bundled, coins after a boss, two more formal lines; **not committed, no APK built**)
**From:** Claude Code (Sonnet 5.5)
- **Logout no longer wipes the coins.** `StorageService.clearAll()` keeps every `wallet_<studentId>` (coins, power-ups, bought characters), the last sign-in, and the settings that belong to the phone (sound, music, volumes, controls, tutorial flag, Test Mode). It still wipes what is per phone so the next student starts clean: the student, level progress, era-progress cache, hearts, character, codex, queued results, downloaded questions. Tests in `last_sign_in_test.dart`.
- **Poppins is inside the app** (`assets/google_fonts/Poppins-{Regular,Medium,SemiBold,Bold,Black}.ttf` and `OFL-Poppins.txt`, declared in `pubspec.yaml`; google_fonts uses them before the internet). The profile class code used JetBrains Mono (variable font only in the Google repo), so it now uses the phone's own `monospace`. `test/core/fonts_bundled_test.dart` fails if the code asks for a weight with no file or for any other downloaded font. **Side effect on every widget test:** they now run with the real Poppins, not the very wide Ahem stand-in, so width checks are less strict and height checks are truer. That exposed a real 3 pixel overflow of the QR scan card on a 900 x 412 phone (the hint line shrinks less with Poppins); fixed in `qr_scan_panel.dart` (fixed line height, `4 * _s` more room kept back).
- **Coins after a boss:** the era-complete screen takes `coins` (sent by `GameScreen` through the route's `extra`) and shows the new `CoinsBadge` (also used on the level-complete screen, `test/widgets/coins_badge_test.dart`).
- **Two more formal lines:** "SCHOOL NATIN" (leaderboard tab) and "Boss level:" (era-complete).
- **Tests:** 889 pass, `flutter analyze` clean.
- **Found, not changed:** hearts are saved per phone (not per student) and logout wipes them, so after an app restart a student who logged out starts with full hearts. Fixing it means saving hearts per student id.
- **Not done:** no APK, not tried on a phone, nothing committed or pushed since `919eeb6`.

---

**Date:** 2026-10-17 (later: test and student builds, "Forgot password?", last sign-in remembered, coins on the level-complete screen, three briefs; **not committed, no APK built**)
**From:** Claude Code (Sonnet 5.5)
- **Two builds, one code.** `AppFlags.testBuild` (`--dart-define=TEST_MODE=true`) and `testBuildProvider` (`unlock_all_provider.dart`). The student build (default) has no Test Mode: the Settings switch is gone, `UnlockAllNotifier` always reads off and `set` does nothing, and `GameNotifier(testBuild:)` ignores a saved switch for free hearts and open characters (a student whose phone kept the switch from 1.1.0 or 1.2.0 does not keep it). Tests build the tester by default. `android/app/build.gradle.kts` reads `-PtestBuild=true`: app id `com.chronoquest.chronoquest.test`, name "ChronoQuest TEST" (manifest label is now `${appLabel}`), version name suffix `-test`. **Commands** (raise pubspec to 1.3.0 first):
  - student, for the landing page: `flutter build apk --release --target-platform android-arm64`
  - tester: `flutter build apk --release --target-platform android-arm64 --dart-define=TEST_MODE=true --android-project-arg=testBuild=true`
  - Checked only by merging the Android manifest for both (`gradlew :app:processReleaseMainManifest`, with `JAVA_HOME` set to Android Studio's `jbr`; Flutter finds it itself, a bare Gradle call does not): student = `com.chronoquest.chronoquest`, label "chronoquest", 1.2.0 (unchanged); tester = `.test`, "ChronoQuest TEST", 1.2.0-test. **No APK was built**, so the first real build of each is the real test. The student label is still the lowercase "chronoquest".
- **Last sign-in remembered.** `StorageService.getLastSignIn/saveLastSignIn` (class code and username, never the password), saved in `ApiService.login`, kept by `clearAll` (logout). "Balik na ako" on a phone that remembers goes straight to the password question with a line "JuanNinja99 · EDG5A1 · Hindi ikaw? Palitan" (Palitan goes to the class code question with the boxes filled). Not used when the student already typed something, or on "Bago ako". `LoginScreen(lastSignIn:)` lets tests pass a fake.
- **Forgot password, game side.** "Forgot password?" under the password box on "Balik na ako" (a bordered button after a wrong password). New route `/forgot-password` (open when signed out; opened with `ForgotPasswordArgs`, anything else goes to sign-in) and `forgot_password_screen.dart`: class code and username to read out, "I-SEND SA TEACHER" (`ApiService.requestPasswordReset`, `POST /student/password-reset-request`), "MAY PASSWORD NA AKO" goes back, "Na-send na!" after. Any failure, including 404, tells the student to say it to the teacher, so it is safe before the dashboard part exists. New `AuthReadout` widget, `resetRequestErrorMessage`. **Brief for the dashboard chat:** `docs/briefs/forgot-password-for-dashboard.md` (also a line in the board's requests table, with the reset-does-not-force-a-new-password gap and the login RegExp finding).
- **Coins on the level-complete screen:** `LevelCompleteResult.coins` (from `game.playerCoins`), a "+35 COINS" badge under the points (`GameBadge` got an optional `leading`). Hidden at 0. The era-complete screen (after a boss) does not show coins yet.
- **Docs for the user:** `docs/WORDING-PASS.md` (62 formal lines with simpler versions; **approved and applied the same day**: 93 text swaps in `lib/` and `test/`, full suite still passes; the login messages and `loginErrorField` changed together), `docs/CHARACTER-POSES-BRIEF.md` (40 pictures for an artist: idle 2, fall 1, attack 3, win 2 per hero, 80 x 80, file names; the game is **not wired** to them yet and keeps today's pictures).
- **Tests:** new `forgot_password_screen_test` (14), `last_sign_in_test` (7), more in `login_steps_test`, `login_errors_test`, `unlock_all_test`, `hearts_free_test`, `wallet_test`, `settings_screens_test`, `level_complete_test`. Full suite 880 pass; `flutter analyze` clean. The `/forgot-password` redirect in `router.dart` has no test (the global router needs storage and a token).
- **Found, not changed:** `StorageService.clearAll()` (logout) clears the whole phone box, including the wallet (`wallet_<id>`: coins, power-ups, bought characters), level progress, hearts and the tutorial flag. Wallets are keyed by student id, so keeping `wallet_*` on logout would be safe; asked the user.
- **Not done:** no APK, not tried on a phone (sign-in with the keyboard up, the two new screens), nothing committed or pushed, poses not wired, the three-phase boss and saved coins and scores (waiting on the dashboard chat) not started.

---

**Date:** 2026-10-17 (mockups for ideas 7 to 9, plan for a test build and a student build; nothing built, no code changed, nothing committed)
**From:** Claude Code (Sonnet 5.5)
- **Mockups:** https://claude.ai/artifact/RU8NGad9tSD3rDyWn39nXZ (2 versions; the second one rewrote the formal Tagalog as everyday Taglish after the user said it sounded awkward, see the memory note `simple-taglish-game-text`). 7 = coins and scores saved to the class (save line on level complete, "welcome back" screen on a new phone); 8 = three-phase boss (6 right answers become 3 phases of 2; timer 15, 12, 10 s; 2, 3, 4 minions per wave; PHASE banner; bar moves to the top middle; last question is FINAL QUESTION); 9 = forgot password (version A tells the student what to say to the teacher, no dashboard change; version B sends a request, needs a new dashboard piece).
- **Waiting on the user:** forgot password A or B (my pick: A now, B later); the order (my pick: test and student builds plus 9A first, then the boss phases, then saved coins); whether to simplify the formal lines already built (see the memory note for the list).
- **Test build and student build (agreed in principle; built later the same day, see the entry above):** Test Mode is `unlockAllProvider` (`lib/providers/unlock_all_provider.dart`), shown as a switch in Settings (`settings_screen.dart`, `_UnlockAllSwitch`); it opens every era and level, stops hearts being spent and unlocks every character, and the saved value stays on the phone. The game already uses `--dart-define` (`API_BASE_URL`, `DEV_SKIP_AUTH` in `core/constants.dart`). Plan: a `TEST_MODE` define; the student build hides the switch and ignores a saved value (a student installing over a test build must not keep it); the test build gets its own app id and name ("ChronoQuest TEST", an Android flavor with an id suffix in `android/app/build.gradle.kts`, id today `com.chronoquest.chronoquest`, release still signed with the debug key) so both can sit on one phone; only the student APK goes on the landing page. Next APK is 1.3.0.
- **Finding for the dashboard chat (read only, not changed):** `resetStudentPassword` in `CBACK/src/controllers/teacher.controller.js` makes a temporary password but does not set `mustChangePassword`, so after a teacher reset the student is not asked to choose a new one (only `createStudent` sets it). One line. Added to the board's requests table.
- **Tried and dropped:** building the missing character poses (idle, attack, fall, win, defeat) in code, first in the browser, then as a Python pipeline (cut-out rig, shaded limbs, effects for enemies and bosses). The user did not like the result and had all the files deleted; nothing of it is in the repo. Do not suggest it again unless asked; real drawn frames are the way.

---

**Date:** 2026-10-14 (new sign-in, sign-up and change-password screens; committed as dd9e9bb and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **History rewritten (same day):** GitHub listed Claude as a contributor because 41 game commits and 37 root commits ended with a "Co-Authored-By: Claude" line. The user asked to remove it, so the line was stripped from every commit and all pushed branches were force-pushed (game: `era-names-six-era-bow`, `main`, `v2-phase-4`; root: `main`, `v2-phase-4`; the root's pointer to the game was rewritten to match). Files are identical. **Every commit id older than this entry has changed**, so ids named in older entries (554455c, e23cd50, 1.1.0 build commit and so on) no longer exist; find them by message. Other clones must be deleted and cloned again. A backup of both repos as they were is in the session scratchpad (`backup-game.bundle`, `backup-root.bundle`), which is temporary. The dashboard repo still has 33 such commits; it was not touched (asked the user, no answer yet).
- **Design:** mockup https://claude.ai/artifact/64EmjGQVtEq2cgMLkbCztj (5 versions; the user rejected a form with every box visible as "overwhelming", then asked for the QR card kept on the left, the choice screen first and the step bar at the top).
- **Sign in** (`lib/screens/auth/login_screen.dart`, rewritten): first screen is two big buttons, "Bago ako" and "Balik na ako". Then one question per screen: Bago = class code, real name, username, password, repeat password (5); Balik = class code, username, password (3). A step bar at the top ("Bago ako · Hakbang 2 ng 5") and a back arrow (also the phone's back button) that keeps what was typed. The QR scan card (unchanged `QrScanPanel`) is on the left of the class code question only; on the other questions the guide (a Luna sprite, a stand-in) says one line. Under 700 wide there is no left side: a scan button sits inside the class code box and opens the full-screen scanner as before. Same rules and the same single `login()` call, sent after the last answer. A server complaint sends the student back to the question it is about, with the answers kept (`loginErrorField` in `login_errors.dart` maps each message); no internet stays on the last question.
- **Change password** (`change_password_screen.dart`, rewritten): same guide and big boxes, two boxes with show/hide eyes, a line that turns green at 6 characters and when both match, the button grey until both are true, no back button. Errors are now Filipino (`changePasswordErrorMessage`, used by `ApiService.changePassword`; the old one showed the raw server text). The screen takes an optional `save` function so tests do not need the server.
- **Shared pieces:** `lib/screens/auth/auth_widgets.dart` (`AuthField`, `AuthStepBar`, `AuthGuide`, `AuthError`, `AuthBusyButton`, `AuthWordmark`).
- **Tests:** new `login_steps_test` (26), `change_password_screen_test` (14), more in `login_errors_test`; the old `login_scan_test` and `login_error_test` were replaced by them. Full suite 831 pass; `flutter analyze` is clean (the 4 old login lints are gone).
- **Not done:** no APK, not tried on a phone (the on-screen keyboard on a landscape phone is the thing to check: it covers part of the screen, the form scrolls). Opening "Balik na ako" does not remember the last class code or username. No "forgot password" flow (needs a dashboard change). Still to do before the student build: remove Test Mode, bundle Poppins.

---

**Date:** 2026-10-13 (new Leaderboard, Background History and Tindahan shop screens; committed as 554455c and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **Design:** mockup https://claude.ai/artifact/FMX12niTrMHCP5FnfzuXN8 (Poppins, the game's real font; the pixel fonts named in `AppFonts` comments are not used anywhere).
- **Leaderboard** (`leaderboard_screen.dart`): "Ikaw" card (rank, score, gap to the next student), podium for the top 3, list for the rest, own row gold, pinned under the list below the top 20. Uses `ApiService.getLeaderboardBoard` (new, returns `LeaderboardBoard{leaders, myRank, myScore}`; `getLeaderboard` still works). Three columns from 760 wide, podium moves into the list from 520, one column below. Empty and offline states; never invents names.
- **Background History** (`background_history_screen.dart`, new `lib/data/era_story.dart`): the era paragraph is cut into events with a label, a timeline, and 3 tap-to-open term cards. HANDA NA AKO stays grey until all terms are opened (it used to open at the bottom of the scroll). Story text is only the era's `historicalText` split up, nothing added. No date-range chip (era titles carry no dates).
- **Shop** (`lib/screens/shop/shop_screen.dart`, route `/shop`): hearts (buy 1, or fill all, all-or-nothing via new `GameNotifier.buyAllHearts`) and the three power-ups, grey button with "Kulang ng N" when short, toast after a buy. Entry points: cart chip on the era list (`PixelGlyph.cart`), the hearts pill "+" (the old buy dialog is gone; `HeartsPill.onBuy` overrides), TINDAHAN button on the level-failed screen, and a link in Profile (the Profile panel only shows holdings now).
- **Tests:** new `leaderboard_screen_test`, `shop_screen_test`; updated history, hearts pill, profile, wallet tests. Full suite 800 pass; analyze shows only the 4 old `login_screen` lints. Test fonts are the wide Ahem face, so overflow checks are stricter than a real phone.
- **Not done:** no APK, not tried on a phone. No weekly tab on the leaderboard (the game endpoint has no week data; the dashboard does). Hero purchase stays in character select. Wallet is still phone-only.

---

**Date:** 2026-10-13 (teacher's question timer, committed as e23cd50 on `era-names-six-era-bow`; asked for in the dashboard chat)
**From:** Claude Code (Sonnet 5.5)
- **What:** a teacher can set a time for each question per level (Question Bank in the dashboard). The game reads it from `GET /student/questions` (`timer: { era: { level: seconds } }`, absent when off), keeps it with the question cache, and shows the countdown bar on ordinary artifact questions. When it runs out the overlay answers with '' (a wrong answer, explanation shown), and `handleAnswerPointAnswer` takes one heart (`loseLife()`); a Shield absorbs it; on the last heart the level fails and the engine stays stopped. A plain wrong answer still costs nothing.
- **Code:** `QuestionBank.applyTimer / timerSecondsFor` (15 to 120 s only, cleared on logout), `QuestionSync` (sync + restore), `question_overlay.dart` (countdown for non-boss when the level has a time), `question_card.dart` (a timed ordinary question keeps 50/50 and Shield; Time Freeze stays boss-only), `answer_point_handler.dart`.
- **Tests:** `test/data/question_timer_test.dart`, new groups in `answer_point_test.dart` and `boss_countdown_test.dart`. Full suite: 787 pass. The flaky `wallet_test` (storage closed before a background hearts save finished) is fixed in the test file.
- **Not done:** no APK built, not tried on a phone. Not confirmed on the device yet.

---

**Date:** 2026-10-11 (Phase 6, the coin shop; committed and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **Where it lives:** the wallet is on the phone, one per student id (`StorageService.getWallet/saveWallet`, key `wallet_<id>`): coins, 50/50, Shield, Time Freeze, and bought characters. The server has no coins field and its power-up endpoint (`PATCH /student/power-ups` takes {type, action}) does not match what `ApiService.updatePowerUps` sends, so nothing is synced; a reinstall starts the wallet again. `gameProvider` listens to the logged-in student id and calls `GameNotifier.loadWallet`.
- **Earning:** `GameScreen` banks `game.playerCoins` once when a level completes or fails (quitting from the pause menu forfeits them) and saves power-up use on exit. The level 3 and 7 milestone rewards are saved too.
- **Spending:** `buyHeart()` (20 coins, keeps the regen countdown, `HeartsState.withHeart`), `buyPowerUp(PowerUpKind)` (50/50 15, Shield 25, Time Freeze 30; `GameConstants`), `unlockCharacter(id)` (the existing `unlockCost`: Luna 100, Bonifacio 200, Del Pilar 300). `selectCharacter` refuses a locked one; a student whose saved character is locked goes back to a free one. Test Mode (unlock all) opens every character.
- **UI:** the hearts dialog BILHIN works; Profile has a "Tindahan" panel (`_Shop`) in place of the old powerups panel; character select dims a locked card, shows its price and offers an unlock dialog.
- **Tests:** `test/providers/wallet_test.dart`, `test/screens/character_unlock_test.dart`, shop cases in `profile_screen_test.dart`, buy cases in `hearts_pill_test.dart`; 774 pass.
- **Not done:** prices are placeholders (a level pays roughly 30 to 60 coins); no server sync (needs a coins field and a spend endpoint in the dashboard backend, a brief can be written); the level-complete screen does not show coins earned; a phone playtest.

**Date:** 2026-10-11 (boss arenas: the six boss levels now have maps; committed and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **What:** each boss level is one fixed room, 76 tiles (1824 units) wide, mirror-symmetric, with a 7-tile wall at each end. Maps: `era1_10`, `era2_5`, `era3_7`, `era4_8`, `era5_8`, `era6_5` (Sinaunang Pilipinas, Pananakop ng Espanya, Pag-usbong ng Nasyonalismo, Himagsikan at Imperyalismong Amerikano, Pamahalaang Kolonyal at Pananakop ng Hapon, Batas Militar at Muling Pagbangon ng Demokrasya). They are written by `node tools/levelgen/arenas.js` (specs in that file: left half, mirrored), which checks each one with the solver before saving (every platform and minion spot reachable, no trap spots, a safe ledge each side).
- **Map objects:** `boss` (centre x, surface y), `minion_spawn` spots, platforms, `spawn`; no gate, no exit. Map property `boss=true`. `LoadedLevel` has `isArena`, `boss`, `minionSpawns`, `mapWidth`.
- **Game:** in an arena the fight starts by itself (`ChronoGame.update`), the boss stands where the map says (no walk-in), the first question comes after 1.8 s, waves spawn on the minion spots furthest from the player (alternating sides, on the surface they stand on), and the camera is clamped inside the room (`cameraLeftEdgeX`). The fight opens with 4 Kaalaman charges (`CombatConstants.bossStartCharges`) and charges regenerate during the fight. The player may now start on raised ground (spawn uses the block under it).
- **Tools:** `solve.js` has an arena mode (goal is getting back to the start); `paths.js` skips arenas; `arena_mock.js` draws them to PNG (see the Level Review artifact). Tests: `test/game/boss_arena_test.dart`, arena cases in `boss_fight_test.dart`, node tests in `levelgen.test.js`; 747 Flutter and 37 node tests pass.
- **Not done:** a phone playtest (wave pacing, room size, safe ledges); Pag-usbong ng Nasyonalismo has no minion sprites of its own (reuses Pananakop ng Espanya); the arena uses the usual backdrop; the three-phase boss.

**Date:** 2026-10-11 (Phase 5, the boss fight, simple version; committed and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **Fight:** the boss asks a question with a 15-second bar (`BossCountdown`, `lib/game/boss_countdown.dart`); six right answers beat it (`GameConstants.bossQuestionsToWin`). A wrong answer or a timeout (the overlay sends an empty answer) costs the boss nothing and shows the explanation; the next question is a different one from the level pool. After every answer a wave of minions spawns (2, then 3 from the third wave; `minionsInWave`); the next question waits until they are all beaten, or 40 seconds pass. Each minion beaten gives one Kaalaman charge (`EnemyComponent.onDefeated`). A shield still turns a wrong answer away; the minions come either way.
- **Time Freeze** shows on the boss question and stops that question bar. It is a count in `PowerUps.timeFreeze`; students start with none, so real use waits for Phase 6 buying.
- **Code:** `BossComponent` runs the fight (question, then wave, then question); `QuestionCard`/`QuestionOverlayWidget` show `CountdownBar` and the Time Freeze button; `ChronoGame.bossQuestions` is gone, the boss draws from `questionPool`. Tests: `test/game/boss_countdown_test.dart`, `boss_fight_test.dart`; 734 pass.
- **Not done:** the six hand-built boss maps (boss levels still use the plain generated ground); the three-phase version; a phone playtest (minion spacing, wave size, bar look).

**Date:** 2026-10-11 (teacher-picked questions, game side; committed and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **What:** a teacher can mark a level "I choose" and tick the questions to always ask. The game asks the picked ones first (random order), then fills the rest at random; a retry never repeats the question just missed. Unknown ids, repeats and more than the level asks (10, boss 22) are ignored. Picks are cached with the download, so they work offline.
- **Contract with the dashboard:** `GET /student/questions` keeps sending the full list per level and adds `picks: { era: { level: [questionId] } }`. Code: `QuestionBank.applySynced(picks:)`, `picksFor`, `QuestionPool(picks:)`, `QuestionSync`; tests in `test/data/question_sync_test.dart`.
- **Dashboard side (not done by this chat):** the "I choose" switch, tick boxes and the `picks` field are for the dashboard chat (a brief was given). Until it sends `picks`, nothing changes in play. Test against the live field once it exists.
- Also done: 246 questions written for the three Grade 6 eras (see the entry below; sources in `tools/questions/grade6/`).
- Tests: 716 pass; `flutter analyze` shows the same 5 old lints.

**Date:** 2026-10-10 (real questions for Sinaunang Pilipinas, Pananakop ng Espanya and Pag-usbong ng Nasyonalismo; committed and pushed on `era-names-six-era-bow`)
**From:** Claude Code (Sonnet 5.5)
- **Source:** `capstone/Term 1 Final.docx`, `Term 2 Final.docx`, `Term 3 Final.docx`. Each ends with "PISA-Type na mga Tanong para sa Educational Game": 10 scenario questions per lesson, 4 choices, answer marked. Lesson N is level N of the era, so 220 questions fill all 22 levels of the three Grade 5 eras. The three Grade 6 eras (Himagsikan at Imperyalismong Amerikano, Pamahalaang Kolonyal at Pananakop ng Hapon, Batas Militar at Muling Pagbangon ng Demokrasya) have no Term 4-6 files, so their 246 questions (92, 92, 62; explanations included) were written for them in Filipino from the level skills, key dates checked online. Sources: `tools/questions/grade6/term4.js` to `term6.js`; `node tools/questions/generate_grade6.js` rebuilds the three era files. A teacher should skim them. If real Term 4-6 docs turn up, `import_terms.js` replaces them.
- **Importer:** `node tools/questions/import_terms.js <folder>` (dependency-free, reads the .docx itself) rewrites `assets/data/questions_<era>.json`; it already knows `Term 4/5/6 Final.docx` for the other three eras, and skips a term whose file is missing. It refuses a lesson that does not have exactly 10 questions.
- **Shape:** ids `pre_3_7`, `spa_1_1`, `nat_2_4`; `subTopic` is the lesson title; all `medium`; **no explanations** in the source. Because of that the wrong-answer card now says "Ang tamang sagot ay B. <the answer text>" and the Codex blurb falls back to "Tamang sagot: <text>" (`Question.correctText`).
- **Boss level** (the last lesson of each era, 22 questions): its own 10 plus 12 reused from the earlier lessons, spread evenly, with their own ids (`..._N_11` to `_22`) so editing one in the dashboard question bank does not touch the lesson it came from. The three imported eras now have keys 1..N only, which also fixes the boss-pool-under-key-10 mismatch for them; Himagsikan at Imperyalismong Amerikano, Pamahalaang Kolonyal at Pananakop ng Hapon and Batas Militar at Muling Pagbangon ng Demokrasya still have the old files (5 a level, boss under key 10).
- **One oddity in the source:** Term 1, Linggo 3, #10: the key says "Ihambing ang mga teorya at patunay" but choice B reads "Ihambing ang mga ebidensya"; the letter (B) was kept. Worth fixing in the .docx.
- **Dashboard side (not touched):** `CBACK/src/data/standardQuestions.js` is generated from these files, so `npm run sync-content` must be re-run there or its drift test fails. The longest question is 272 characters and the longest choice 54, inside the question bank's limits.
- Tests: 710 pass (new `test/data/question_content_test.dart` guards the counts, choices, answers and edit limits); `flutter analyze` shows the same 5 old lints. Not tried on a phone.

---

**Date:** 2026-10-10 (hearts count in server time; teacher question bank reaches the game; committed and pushed on `era-names-six-era-bow` (game) and `v2-phase-4` (root); the dashboard backend with `GET /api/v1/health` and `GET /student/questions` is live on Vercel; arm64 APK built 2026-10-10, not yet on a phone)
**From:** Claude Code (Sonnet 5.5)
- **Hearts and the phone clock:** moving the phone's clock forward used to refill every heart. Hearts now count in the server's time: `lib/services/server_clock.dart` reads `GET /health` (`serverTimeMs`) and carries it forward with a `Stopwatch`, so changing the phone's clock does nothing; the phone's clock is only used to notice a jump and re-read. With no server time yet (offline at launch) hearts do not come back, and a heart lost then starts its countdown at the next connection (`HeartsState.anchoredAt`). `GameNotifier({clock})` takes the clock (tests use `ServerClock.fixed`); `heartCountdown` replaces `timeUntilNext(DateTime.now())` in the three screens. **Needs the backend deployed.**
- **Question bank sync:** `QuestionBank.applySynced` swaps in the questions a teacher published, per level, after re-checking them (unplayable questions are dropped; a level never ends up thinner than what shipped). `QuestionSync` (`lib/services/question_sync.dart`) downloads them after login, on era-select open (via `refreshProfile`) and at startup, keeps a copy in Hive (`question_bank_cache`, per class code) and restores it offline from `main.dart`. Logout clears it. A level's `QuestionPool` is built when it starts, so a download never changes a level mid-play. Regular levels recycle questions when the pool is small; only the boss pads with placeholders.
- Tests: 697 pass; `flutter analyze` shows the same 5 old lints. Not tried on a phone.

---


**Date:** 2026-10-10 (levels redesigned: real terrain and generator v2, all 37 non-boss levels; committed and pushed, not on a phone)
**From:** Claude Code (Sonnet 5.5)
**To:** Claude Code / Chat
**Project:** ChronoQuest

---


**What changed.** The levels were a flat strip with identical floating platforms: the game could only draw one ground height and the tile layer was read as solid-or-empty. Now:
- **Engine.** Ground is a row of blocks, each at its own height (`GroundBlock`, `TerrainGrid` in `level_loader.dart`). `TerrainComponent` draws the map's tile layer (one `drawRawAtlas` call) and `WaterComponent` puts water in every pit, in front of the player (`terrain_component.dart`). Each era has its own tileset image, `assets/tiles/ground_<era>.png`, with the tileset's black fill recoloured (made by `tools/levelgen/recolor.js`; the colours are mirrored in `EraTerrain`, a test checks they match); platforms use it too. `game_collision.dart`: the player lands on the highest ground under the feet, and ground that rises more than `groundBand` (28, one 24-unit tile) above the feet is a wall (`resolveWalls`, run right after every horizontal move). A one-tile rise is walked up. Respawn puts the player on the surface of the block they last stood on; an enemy on raised ground turns at its edge (`isSurfaceUnder`); an artifact takes a `surfaceY` so it stands on the ground under it. Bosses still use the old procedural ground and spawners, so `GroundSpawner`/`EnemySpawner` stay until Phase 5.
- **Map format.** 24-unit tiles (the 16px art at 1.5x, like the player, enemies and platforms). The `ground` layer has `offsety="12"` so row 27 is the base (y 660); a column's first tile is its surface, an empty column is a pit; caps, corners, walls, fill and specks are picked by `terrain.js` when the map is written (grass or bare stone caps, orange earth or blue stone per era). Artifact `y` is the height of the ground under it. `generator` is `levelgen-v2`.
- **Generator v2** (`tools/levelgen`). Eleven set pieces (`pieces.js`: gap, fight, hill, bump, block, mesa, courtyard, pillars, bridge, tower, ridge), packed into the ten sections of each level, on top of a **ground elevation per section** (0-5 tiles, ramps in the rest areas) so a level climbs onto highlands and drops back. The six era openers are authored by hand in `openers.js` (one recipe per era); the other levels pick pieces by act, era flavour and difficulty. 60 seeded candidates per level; each is checked by `validate.js` and **played by `solve.js`**, a search over where a student can stand (walk, drop, jump with the stick held five ways) using a port of the player's movement (`sim.js`) with a 5% slower, lower jump. A level passes only if the gate is reachable and no reachable spot is a trap.
- **Tests.** `node --test tools/levelgen/test/levelgen.test.js` (32). Flutter: `terrain_parity_test` replays 14 scripted moves (`test/fixtures/terrain_parity.json`) through the real `PlayerComponent` and must match `sim.js`; `level_playthrough_test` loads every level through `LevelLoader` and replays a winning run (`test/fixtures/level_paths.json`, frame by frame) through the real player to the gate; `level_lint_test` was rewritten for the new rules (the old per-gap `jump_clearance_test` is gone, the solver supersedes it). 661 Flutter tests, 32 node tests, `flutter analyze` at the usual 5 lints.
- **Regenerate** after any change to `tools/levelgen`: `node tools/levelgen/generate.js --era all --levels all`, then `node tools/levelgen/paths.js` and `node tools/levelgen/parity.js`, then both test suites (a node test fails if a map on disk is stale). To review without a device: `node tools/levelgen/render.js --level assets/tiles/levels/era1_5.tmx --sheet s2,s3,s5,s7 --out sheet.png`, or draw it through the real game: `flutter test tool/level_screenshots_test.dart --dart-define=SHOT_LEVEL=era2_3 --dart-define=SHOT_X=13000 --dart-define=SHOT_OUT=shot.png` (`tool/trace_run_test.dart` prints a replay's positions when the game and the simulator disagree).
- **Playtest fixes, same day.** Any rise, even one tile, is now a wall that has to be jumped (`wallBand` 12 on the ground; in the air a landing up to `groundBand` 28 low still snaps up); the second-tier platform coins sit out of reach from the lower platform; pit water has no extra tile and no animation; bushes were added and then removed (they added nothing to play).
- **Known limits.** The game keeps positions as 32-bit floats and the simulator as doubles, so a replay drifts by a fraction of a unit; the saved winning runs therefore only use moves that still work if they start up to 8 units either side (`robustRun` in `solve.js`). Not yet seen on a device: the feel of the walls, the climb up the ramps, performance of the terrain draw. The tileset's crates are the `block` piece (a pile, drawn cropped) and ladders, vines, tufts and the foliage tiles are unused. The six boss levels have no map (Phase 5).

---

**Date:** 2026-10-04 (level generator, playtest fixes, settings and controls; uncommitted on `v2-phase-4`)
**From:** Claude Code
**To:** Claude Code / Chat
**Project:** ChronoQuest

---

## 1. Goal
Phase 4's generator (all 37 non-boss levels, `era1_1` included since it was replaced) plus the fixes from the first
phone playtest of spanish 1-4.

## 2. Current state
**Uncommitted on `v2-phase-4`.** 456/456 Flutter tests, 22/22 node tests, `flutter analyze` at the
usual 5 pre-existing lints. An arm64 APK with spanish 1-4 and all the fixes was built and sent on 2026-10-04; no device feedback yet.
**2026-10-06, menu icons, Profile redesign, Test Mode (in CHRONO-GAMEAPP on branch `era-names-six-era-bow`, committed as `b8b9b74`; an arm64 APK with it was built the same day; not on a phone; mockup https://claude.ai/artifact/R822GZm6StateQeVZD4q9u):**
One icon set and one button for the menu screens. `PixelIcon` (`lib/widgets/pixel_icon.dart`) draws 14 glyphs from 12 x 12 text grids (back, profile, gear, trophy, book, move, speaker, door, coin, shield, chevron, note, speakerLow, speakerOff), tinted by use. `MenuChip` / `MenuChipFace` (`menu_chip.dart`) is the wooden chip: 40 to look at, 48 to hit, presses in. `MenuTopBar` (`menu_top_bar.dart`) is the shared header; `SettingsHeader` now wraps it. Rule: back top left, Settings the right-most chip, Profile just left of it and hidden on Profile. Applied to character select (Profile chip added; the old `_SideIconButton` is gone), era select (also the era-card book is white now: it was bookColor on a bookColor card, so invisible; the bottom bar shows the chosen hero in `CharacterPortrait`), Profile, Settings (rows, logout is a red `GameButton` with the new `leading` param), Sound (rows and slider ends), level select, leaderboard, the module screen and the level-failed BUMALIK button. Not converted: the leaderboard's refresh icon and the content icons in the module screen body. **Profile** is rebuilt (`profile_screen.dart`): parchment identity card with the hero portrait, class code, school and Puntos/Coins; a tile per era with one pip per level and the real level counts (10, 5, 7, 8, 8, 5; the old screen said /10 for all), a star when finished, a lock when out of reach (Grade 6 eras show locked to a Grade 5 student); powerups and the Kodeks below; fits 800x360, 732x320 and 640x360 without scrolling, one column when narrow. It now reads progress from `progressProvider` (as era select does) and loads it on open. **Test Mode**: the switch is now labelled "Test Mode" ("Bukas ang lahat ng panahon at level, at hindi nawawala ang puso."). The remaining temporary switch must still be removed before student builds. 611 Flutter tests.
**2026-10-06, era names, free hearts, QR size (committed in CHRONO-GAMEAPP on branch `era-names-six-era-bow`, `e77b296`, `5acfb49`, `44dd813`, on top of `1580910`; not pushed, not on a phone):**
(1) **Era names** are the six titles of Section 1 and the dashboard (`allEras` name + subtitle, no date ranges; ids, level counts and question ids unchanged); the three character cards use them too. Titles run to 47 characters, so the era cards allow 3 lines for the name and 2 for the subtitle, the level-select header shrinks to fit, and the character badge wraps. (2) **Hearts are free while the unlock-all switch is on**: `GameNotifier.heartsAreFree` (reads `StorageService.getUnlockAll()`) stops `loseHeart`, lets `canStartLevel` pass on an empty pool, and `GameScreen` starts the level on a full in-level bar. The switch and the logout button moved from Profile to Settings. (3) **QR camera** takes the height left on the screen (about 190 dp on a 360-high phone, was 136; cap 300). Question files do not match eras 3-6 yet: there is no `questions_nationalism.json` (placeholders), `american` has nothing on the Katipunan/Revolution, `ww2` lacks the American colonial government, `modern` levels 1 and 5-9 are off-topic, and every file's 22-question boss pool sits at key 10, which only era 1 reads (the boss reads the key of the era's last level). 594 Flutter tests.
**2026-10-06, level-complete card (uncommitted, not on a phone, built from a mockup the user approved, https://claude.ai/artifact/5XcfznAVkssrGqnh9Y3W3z):** the user's
screenshot showed "5/5 TAMA" on a level of ten artifacts, and the card scrolled. Cause of 5/5: `levelComplete()` scored distinct question ids
and every level has only 5 authored questions (the pool serves each twice for 10 artifacts). Now a level with artifacts is scored per artifact
(`correct = artifactsClaimed`, `total = artifactsTotal`), which also feeds stars, the perfect-level +50 and `onLevelComplete`; the POST payload is
unchanged. Cause of the scrolling: the card was 331 dp tall (382 on levels 3 and 7) on 320-360 dp screens. `LevelCompleteScreen` is now two
columns (about 190 dp) from 556 dp wide up, one column below, with a row of one dot per artifact under the score (green right, outline missed;
none above 12 artifacts or with no artifacts). Still open: 5 questions per level means every question is asked twice in a level; 5 more per level
(185 in all) need writing and teacher review. 565 Flutter tests.
**2026-10-06, after the APK of the fifth round (uncommitted, not on a phone):** from the user's first look at it. (1) **Artifacts**
(approved mockup, https://claude.ai/artifact/PGLNv4rcKdfjwgkUDVL6jx): 56 -> 72 (`artifactSize`, `physics.json`, lint; `artifactHoverHeight`
150 -> 158 keeps the middle where it was), the era tint is gone from the sprite (a spent one still goes dull), and a gold halo that
breathes plus seven sparkles is drawn behind it in `ArtifactComponent.render` (shader built once, skipped when inert or over 900 units
from the player, follows the claim fade-out). 13 levels regenerated for the new size. (2) **Hearts** no longer regenerate during a level:
`GameNotifier.enterLevel()/exitLevel()` (called from `GameScreen` initState/dispose) stop the clock and resume it where it was
(`HeartsState.resumedAfterLevel`); a loss in a level does not regenerate first. Not frozen if the app is killed mid-level. (3) **Progress
bar** is now the "mini pill" (112 x 18 dp, 78% opacity, thin gold line, 12 dp hero face, 13 dp gate, no ticks), bottom 9. 557 Flutter tests.
**2026-10-06, fifth playtest round (the user's 12 notes, Filipino; all uncommitted, not on a phone, no APK built since the QR one):**
(1) **QR card adapts**: `QrScanPanel` scales 1x-1.8x with the column and screen height (tablet), text and brackets too.
(2-4) **Login**: the screen they tested was the APK built *before* the 10-05 error fix, so its messages were the old ones. Two real
gaps remained and are fixed: "Babalik" no longer applies the 6-character rule (a short password there is a wrong one; the length
rule is "Bago" only, and `loginErrorMessage` maps a 400 password reply to "Mali ang password" when not joining), and the error
now clears when any field is edited or a QR is scanned, not only on a tab switch. (6) **Tutorial**: the corner control is a round
X (48 px, key unchanged) in place of the small "LAKTAWAN" text. (11, 13) **Module screen** (`background_history_screen.dart`):
back arrow plus the phone's back button go to the era list; the guide bubble says "Ako si" plus the chosen hero (it used `era.guide`, so a
Lapu-Lapu player read "gagabayan ni Rizal"). (12) **Settings > Tunog** (`sound_screen.dart`, route `/settings/sound`): switch and
volume slider for music and for effects, saved in Hive (`sound_enabled`, `music_enabled`, `sound_volume`, `music_volume`),
`AudioService.loadSaved()` at launch, music volume applies live. (7) **Speed 210 -> 250** and a **progress bar** at the bottom
centre (`level_progress_bar.dart`: hero face from start to the gate icon, ticks at the artifacts, polled every 100 ms).
The jump did not change, so reach is 267 (was 224). Everything derived from it was redone: gaps 192-288 (plain 240), fight gaps
352/384/416, fight platform 240 wide, ledge max 112 (rules.js, Dart lint mirror, sync test), `knockbackDistance` 160 -> 180 (the
invincibility arithmetic would otherwise have been 300 vs 306), attack box 64 -> 80 wide (at the new speed the old box left too
little time to hit an enemy; the physics replay in `jump_clearance_test` failed until this and the wider platform). All 13 levels
regenerated; levels are now about 100 s of walking, was 119. (8) **Praise**: after a right answer a cheer plays
(`assets/sounds/praise.wav`, SYNTHESISED by `tools/sfx/make_praise.js`, not a recording and not listened to by me) and a word
("WOW!", "GALING!"...) pops over the hero (`PraiseComponent`). A real voice clip would replace the wav file as is.
(9) **Enemy death**: white flash, then thrown away from the player spinning and shrinking, sparks and a shock ring, about 0.5 s
(`CombatConstants.death*`; the old three durations are gone); coins drop where it stood; a Heavy's first hit now flinches.
(10) **Attack**: the plain yellow rectangle is now a white slash that sweeps down through the swing with a spark and speed lines, and
the hitbox now travels with the hero (`follow`) instead of staying where it spawned. 541 Flutter tests, 22 node tests, same 5
analyzer lints. Not verified on a device: speed feel, fight difficulty at 250, the slash and death look, the praise sound, the
progress bar's room between the joystick and the buttons on a real phone.
**2026-10-05, login error messages (uncommitted, not on a phone):** the user saw wrong messages on the student login. Cause: the server
answers in English and one answer meant two things. "Babalik" with a mistyped username got "Real name is required for first-time join"
(the server treats an unknown username as a new student); "Bago" with a taken username got "Incorrect password". New
`lib/utils/login_errors.dart` (`loginErrorMessage(e, joining:)`, tab-aware, all Filipino, no developer text such as "check the backend and
API URL"); `ApiService.login` uses it, `AuthNotifier` shows only ready messages and has `clearError()`, called when the tab changes.
Backend NOT changed (it could return distinct codes for "unknown username" and "username taken" later). 511 Flutter tests.
**2026-10-05, QR scan on the login (built from a mockup the user approved; uncommitted, not on a phone):** the login
screen's left column now holds a scan card instead of the logo block (small CHRONOQUEST wordmark kept), camera off until tapped.
`lib/utils/join_link.dart` (`parseJoinCode`: `chronoquest://join?code=X` or a bare code, upper-cased, 2-20 of A-Z 0-9 - _),
`lib/widgets/qr_scan_panel.dart` (`QrScanPanel`, `QrScanner`, `showQrScanSheet`, `ScannerViewBuilder` so tests use a fake
camera), `login_screen.dart` (fills Class Code, which stays editable and shows a green mark only while it still holds the scanned
code; under 700 wide there is no card, so a scan button sits in the Class Code field and opens a full-screen scanner). Added
`mobile_scanner` and the CAMERA permission (`uses-feature` not required). Denied camera: message and "Subukan ulit", typing still
works; there is no "open Settings" button (no package for it). The login row is now top-aligned so the card is on the first screen.
497 Flutter tests, same 5 analyzer lints. NOT verified: the Android build with the new plugin, and a real scan. Next: build an
arm64 APK when asked and scan the dashboard's section QR from a phone. Test note: layout tests need
`tester.view.physicalSize` AND `devicePixelRatio = 1`; `setSurfaceSize` alone was ignored here, so earlier size checks that only used it
(e.g. `gate_hud_test`) ran at 800x600 logical.
**Fourth round, same day (user's playtest notes, built after a mockup they approved):** (1) **Extra wide
gate**: `CombatConstants.gateWidth` 48 -> 144 (6 tiles, height unchanged); `GateComponent` draws any
width, records its still parts once as a `Picture` and does nothing while off screen; generator
`exitMargin` 120 (was 60) so the gate fits, and a lint rule that it does. (2) **Platform fights** (the
user noticed the attack button works in the air): a 288/320/352 gap, a 192 platform, a walker on it;
1-3 per level, never in sections 1-2. Game side: `EnemyComponent.surfaceY`, `LoadedLevel.enemyStaysOnSupport`
/ `platformUnder`, `isPlatformUnder`, and the shove now clamps to a platform. Generator: `planFight`, tmx
enemy `y`, validator and Dart lint rules (mirrored). Finding worth keeping: an enemy cannot be jumped
over (146 units needed, a jump gives 105), so every enemy needs a hit or costs a heart. Tests: 456 Flutter,
22 node, same 5 analyzer lints; the shove-on-platform test was checked to fail without its fix. Not on a
phone yet: the user has not tried a fight, so the numbers (patrol 36, platform 192, 0.15 s swing window)
are first guesses. Charges: start 0, 2 per right answer, +1 per 20 s at 0 only; with 10-13 enemies a
level a student can run dry (offered to shorten the 20 s or raise the floor; not decided).
**Third round, same day (user's playtest notes), all uncommitted, not in the sent APK:** (1) every
section of every generated level now has a gap with a platform and an enemy, with a third element in
the middle sections (10-14 gaps, 10-13 enemies per level, was 7-10 and 2-7); new rules: enemy patrol at
least 160 from a gap edge, and a section-coverage check (JS validator, Dart lint, 17 node tests). The
12 generated levels were regenerated. (2) The gate unlock indicator uses a new `GateIcon`
(`lib/widgets/gate_icon.dart`, a gatehouse with an open padlock, drawn in code) on the artifact pill,
the gate distance chip and its message. (3) Frame drops in the last sections of a level, on two phones:
not reproduced. Dart-side cost per frame is flat along the level (about 0.5 ms in a debug test), so
it is not level content. Found and fixed a real leak: `AudioService` played every effect with
`FlameAudio.play`, which builds a new `AudioPlayer` per jump or coin and never disposes it; it now
reuses a pool of 3 players per sound (`AudioPool`, preloaded in `ChronoGame.onLoad`). Unconfirmed on a
device. If it still drops, ask whether it is gradual or at one spot, and profile on the phone; also
note Poppins is fetched from the network at runtime (bundling it is still unmade).
**Later the same day:** pre-colonial 2-9 (`era1_2..era1_9.tmx`) were generated (all 50/50 valid, no
Heavy since that era has no Heavy art), so 12 levels are generated. They are NOT in the sent APK.
`era1_1` was checked: it passed the physics rules but was a 3,200-unit prototype (about 15 s of
walking) with all 10 artifacts in 3,000 units and enemies on top of artifacts. **The user approved
replacing it, and it is now a generated full-length opener** (`--era pre-colonial --levels 1 --force`),
so 13 levels are generated (pre-colonial 1-9, spanish 1-4) and no hand-built map remains. The old map
is kept as `test/fixtures/hand_built_level.tmx`, which the loader, respawn, level-end and lint tests
read as a "map a person made". The `(1, 1)` hand entry was dropped from `LevelLoader.authored`; the
level 1 integration test now reads its numbers from the loaded level instead of pinning the old ones.

- **Generator:** `CHRONO-GAMEAPP/tools/levelgen/` (stdlib Node). `node tools/levelgen/generate.js
  --era spanish --levels 1-4` writes `assets/tiles/levels/era2_N.tmx` and rewrites
  `lib/game/generated_level_manifest.dart`. Only spanish 1-4 are generated so far; the other 32
  wait on a playtest of these. Tests: `node --test tools/levelgen/test/levelgen.test.js`,
  `level_lint_test.dart`, `levelgen_sync_test.dart` (pins `physics.json`/`eras.json` to the game).
  `jump_clearance_test.dart` replays the game's jump and landing rules against every level.
- **Platforms 104-112 above ground, gaps 176-240** (platformless 208 at most), `era1_1` updated
  to match. 112 is the verified ceiling (peak - 15 = 113); 104 clears an enemy's hit area (99.9).
  The jump is unchanged.
- **Respawn:** returns 300 units back along the same ground, anchored only when the whole foot
  span is over ground (never a platform). The old respawn sat on the lip and drained all hearts.
- **Stalls:** `ChronoGame.updateTree` caps a frame at 0.1s and steps in 1/60s pieces. A stall
  (internet dropping) used to run as one step and drop the player through the floor.
- **Settings > Kontrol:** joystick or left/right arrows, saved on the device
  (`controlSchemeProvider`, `GameInput.setScheme`). Gear on character select, era select and the
  pause menu. Screens in `lib/screens/settings/`. Pause is laid out compactly (Ituloy, then
  Settings and Umalis side by side) because a third stacked button would fill a 360-tall screen.
- **Hearts:** one `HeartsPill`, top right, on character select and level select only; removed from
  era select and profile. The in-level bar is untouched (user is satisfied with it).
- **Knockback:** 160 units over 0.3s with controls locked, stopped at a ledge. With 1.5s of
  invincibility that makes walking back through an enemy impossible (arithmetic pinned in
  `contact_damage_test.dart`).
- **Gate:** drawn in code (stone gatehouse, barred door, padlock and lamp that change when
  unlocked). **Gate HUD** (`gate_hud.dart`): once every artifact is answered, a chip with the
  distance in metres (100 units = 1 m) and a one-time message.

## 3. Decisions made (and why)
- The first fall in the playtest was unexplained; the 3-heart loop and the stall bug were found
  and fixed, but not confirmed on a device. The freeze at 0 hearts is probably the paused engine
  showing a frozen frame while the app moves to the level-failed screen (not reproduced).
- Platform immunity was dropped in favour of higher platforms (user's call).

## 4. Things we tried that did NOT work
- A first jump simulation counted landing back on the near ledge as clearing the gap. Fixed to
  count only the far side, with two negative controls that must fail.

## 5. Next steps (in order)
1. **Device test** of spanish 1-4 with that APK: gaps, platforms, knockback, gate, controls. Ask the user: does the first fall on solid ground still happen, and where? Open question: gear on era select as well as character select (built both). The plan file C:UsersPC.claudeplansstateful-shimmying-flask.md predates the platform/gap change (it still says 90-110 and 128-200).
2. Tune from the notes, then generate the other 24 levels (nationalism 6, american 7, ww2 7, modern 4;
   spanish 1-4 and pre-colonial 1-9 are done).
3. Remove the temporary unlock-all switch before students get a build; question bank is ~5 per
   level; bosses are Phase 5.

## 6. Constraints & conventions
- Hold fixes uncommitted until confirmed on a device; build APKs only on request, arm64-v8a.

---

**Date:** 2026-10-04 (gate asks nothing, 10 artifacts, softlock fix; uncommitted on `v2-phase-4`)
**From:** Claude Code
**To:** Claude Code / Chat
**Project:** ChronoQuest

---

## 1. Goal
Two reports from the latest APK: the end gate still opened a question, and levels had 5
artifacts, not 10.

## 2. Current state
**Uncommitted on `v2-phase-4`.** 325/325 tests pass (~1 min), `flutter analyze` clean at the
usual 5 pre-existing lints. **Not yet on a device.** The APK last sent predates all of this.

- **Gate:** no question. `PlayerComponent.update` calls `game.passEndGate(gate)` when
  `requirementMet`, which opens it and completes the level after 350ms. `showGateQuestion`,
  `GateComponent.questionPending/lastQuestion`, `activeGate`, `gatesTotal/gatesCleared` and
  `AnswerPointKind` are gone. `GateComponent.isLevelExit` stays.
- **10 artifacts:** `artifactsPerLevel` 5 -> 10, `gatesPerLevel` 3 -> 1. `era1_1.tmx` has 10
  artifacts (five added at x=440, 800, 1450, 2250, 2700; the one at 1860 moved to 1800 because
  it floated 4px into gap 2).
- **Procedural levels (the other 42):** one end gate after ten artifacts, `isLevelExit: true`.
- **Tutorial text** no longer says a gate asks a question.
- **Testing switch (temporary):** Profile has "Buksan lahat ng panahon at level", persisted in
  Hive under `dev_unlock_all` (`unlock_all_provider.dart`). On, era selection shows all six
  eras and none are locked, and every level (boss included) is open. It only changes what is
  shown as unlocked; it awards nothing and sends nothing. Logout clears it (`clearAll`).
  **Remove it, or hide it behind a debug flag, before students get a build.**
- **Era selection layout** (found by the user after turning the switch on): the shelf was a
  Wrap of fixed 220x200 cards. A landscape phone has only ~230px between the title and the
  student bar, so six cards wrapped into two 200px rows and the second row (American, WW2,
  Modern) sat behind the bar, where children outside their parent are not hit-testable: those
  three eras could not be tapped. The normal three-era view also wrapped at 640px wide.
  `_buildShelf` now sizes at most three cards across from the space actually available and
  switches to a compact card (icon beside text) below 150px tall. `era_selection_layout_test.dart`
  checks every era is on screen and hit-testable at four phone sizes, with the switch on and off.

## 3. Decisions made (and why)
- **The softlock was mine.** On 2026-10-03 I made every gate require every artifact answered
  but only rebuilt `era1_1`'s layout. The 42 procedural levels still had three gates, the first
  at 1/4 of the level with one artifact behind it: stopped, told to find artifacts they could not
  reach. One gate after all artifacts makes that impossible by construction, and
  `answer_point_test.dart` asserts every artifact precedes the only gate.
- **10 artifacts with ~5 written questions means repeats.** Accepted by the user until the
  question bank is written; the pool recycles real questions.
- **`ArtifactComponent.counted`** is its own flag. Counting off `attempted` double-counted an
  artifact when a Shield absorbed a wrong answer, because a Shield never sets `attempted`.
- **`ChronoGame.levelEnded`** stops a level completing or failing twice (gate and exit marker
  can both fire it).

## 4. Things we tried that did NOT work
- The new "no artifact over a gap" test failed on the first run, on an artifact I had not
  touched, so it caught a real 4px overhang. Fixed in the level, not by loosening the test.

## 5. Next steps (in order)
1. **Device test.** Does 10 artifacts per level feel right, and with only 5 written questions
   do the repeats read as a bug? Is combat too easy with ~20 charges per level?
2. Wire the buy-a-heart purchase (Phase 6 in GAMEPLAY-V2.md).
3. The level generator must emit one end gate and ten artifacts.
4. Question bank: 10-15 per level, and `nationalism` still has no file.

## 6. Constraints & conventions
- Run the full `flutter test` (about a minute). Hold fixes uncommitted until confirmed on a
  device; build APKs only on request, arm64-v8a.

---

## Older entries

Everything before 2026-10-03 (GAMEPLAY-V2 phases 0 to 4, the level generator, playtest rounds, folded one-liners, copy-paste prompts) is in full in `docs/handoff-archive/HANDOFF-2026-09-to-10-04.md`. The superseded checklist of 2026-09-22 is in `docs/handoff-archive/NEXT_STEPS_CHECKLIST-2026-09-22.md`.
