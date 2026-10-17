# HANDOFF (game)

> **Chat nickname: GAME.** This file is for the game app only (`CHRONO-GAMEAPP`). The board that shows all three chats is `../HANDOFF.md`. Dashboard: `../CHRONO-DASHBOARD/HANDOFF.md`. Landing page: `../CHRONO-LANDING/HANDOFF.md`.
> At the end of a session add a dated entry at the top (automatically, without asking). Keep the newest entry under one page. Keep this file under about 400 lines: when it grows past that, move the oldest entries in full to `docs/handoff-archive/` and leave a one-line pointer under "Older entries" at the bottom.

**Date:** 2026-10-17 (hearts per student; **not committed**, no APK built)
**From:** Claude Code (Sonnet 5.5)
- **Hearts belong to the student, like the wallet.** Saved as `student_hearts_<id>` (`StorageService.getHeartsStateFor / saveHeartsStateFor / hasHeartsFor`), kept across logout (`clearAll` keeps the prefix), loaded when the logged-in student is told to `GameNotifier.loadWallet` (`_loadHeartsFor`, saved by `_store` under the owner). So logging out and restarting no longer refills them, and a student sharing the phone has their own set. The old one-set-per-phone keys (`hearts_count`, `hearts_regen_start_ms`) still work with no student (tests, dev runs); the first student to log in after the update takes the old set once, then `dropPerPhoneHearts()` clears it so the next student starts full.
- **Tests:** new `test/providers/hearts_per_student_test.dart` (8: restart, logout and back in, logout then restart, two students, nobody logged in, the old set goes to one student only, an own set wins); `wallet_test` and `last_sign_in_test` updated. Full suite 898 pass, `flutter analyze` clean.
- **Pushed earlier today:** `afc6629` and `0803951` (the last round) and `3111480` (a note from the LANDING PAGE chat in this file). This hearts change is the only thing uncommitted.

---

**Date:** 2026-10-17 (last round: logout keeps the wallet, Poppins bundled, coins after a boss, two more formal lines; committed and pushed as `afc6629`)
**From:** Claude Code (Sonnet 5.5)
- **Logout no longer wipes the coins.** `StorageService.clearAll()` keeps every `wallet_<studentId>` (coins, power-ups, bought characters), the last sign-in, and the settings that belong to the phone (sound, music, volumes, controls, tutorial flag, Test Mode). It still wipes what is per phone so the next student starts clean: the student, level progress, era-progress cache, hearts, character, codex, queued results, downloaded questions. Tests in `last_sign_in_test.dart`.
- **Poppins is inside the app** (`assets/google_fonts/Poppins-{Regular,Medium,SemiBold,Bold,Black}.ttf` and `OFL-Poppins.txt`, declared in `pubspec.yaml`; google_fonts uses them before the internet). The profile class code used JetBrains Mono (variable font only in the Google repo), so it now uses the phone's own `monospace`. `test/core/fonts_bundled_test.dart` fails if the code asks for a weight with no file or for any other downloaded font. **Side effect on every widget test:** they now run with the real Poppins, not the very wide Ahem stand-in, so width checks are less strict and height checks are truer. That exposed a real 3 pixel overflow of the QR scan card on a 900 x 412 phone (the hint line shrinks less with Poppins); fixed in `qr_scan_panel.dart` (fixed line height, `4 * _s` more room kept back).
- **Coins after a boss:** the era-complete screen takes `coins` (sent by `GameScreen` through the route's `extra`) and shows the new `CoinsBadge` (also used on the level-complete screen, `test/widgets/coins_badge_test.dart`).
- **Two more formal lines:** "SCHOOL NATIN" (leaderboard tab) and "Boss level:" (era-complete).
- **Tests:** 889 pass, `flutter analyze` clean.
- **Found, then fixed the same day:** hearts were saved per phone and logout wiped them, so after an app restart a student who logged out started with full hearts. See the entry above.
- **Not done:** no APK, not tried on a phone.

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

**Date:** 2026-10-15 (done to the game from the LANDING PAGE chat; no game code changed)
**From:** Claude Code (Sonnet 5.5), LANDING PAGE chat
- **Handoff moved here.** The game handoff used to be the root `HANDOFF.md` (1,808 lines). It now lives here; entries before 2026-10-03 and the old checklist are in full under `docs/handoff-archive/`. Committed as 5d7e8bf and pushed.
- **APK 1.2.0 built on request** (arm64 only, 36 MB) from commit 5d7e8bf, with Test Mode in it. The version bump (1.1.0+2 to 1.2.0+3) was committed as d02412a. That APK is on the landing page (https://chronoquest-five.vercel.app).
- **Web build made for screenshots:** `flutter build web --profile --dart-define=DEV_SKIP_AUTH=true` (output in `build/web`, git-ignored), driven with `tool/cdp_shot.js` (one full page load per screen: `nav:about:blank;nav:URL`, because hash-only navigation does not re-route). Seven screenshots went to `CHRONO-LANDING/public/screens/` (welcome, eras, levels, run, history, shop, profile). Not captured: a quiz question (the game loop does not advance in a headless background tab) and the leaderboard (needs an account and the server).
- **Art copied, not changed:** sprites and backgrounds from `assets/` were copied into `CHRONO-LANDING/public/art/`.
- **Still wanted by the landing page:** a phone screenshot of a quiz question and of the leaderboard. The next student build (1.3.0) should replace the APK on the landing page.


---

**Date:** 2026-10-15 (done to the game from the LANDING PAGE chat; no game code changed)
**From:** Claude Code (Sonnet 5.5), LANDING PAGE chat
- **Handoff moved here.** The game handoff used to be the root  (1,808 lines). It now lives here; entries before 2026-10-03 and the old checklist are in full under . Committed as 5d7e8bf and pushed.
- **APK 1.2.0 built on request** (arm64 only, 36 MB) from commit 5d7e8bf with Test Mode in it. The version bump (1.1.0+2 to 1.2.0+3) was committed by this chat as d02412a. That APK is on the landing page (https://chronoquest-five.vercel.app).
- **Web build made for screenshots:** Compiling libmain.dart for the Web...                          
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). This usually means you are referring to font families in an IconData class but not including them in the assets section of your pubspec.yaml, are missing the package that would include them, or are missing "uses-material-design: true".
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 12200 bytes (99.3% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Compiling libmain.dart for the Web...                            180.8s
√ Built buildweb (output in , git-ignored), driven with  (full page load per screen: , because hash-only navigation does not re-route). Seven screenshots went to  (welcome, eras, levels, run, history, shop, profile). Not captured: a quiz question (the game loop does not advance in a headless background tab) and the leaderboard (needs an account and the server).
- **Art copied, not changed:** sprites and backgrounds from  were copied into .
- **Asked of this chat's owner:** a phone screenshot of a quiz question and of the leaderboard for the landing page. The next student build (1.3.0) should replace the APK on the landing page.

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

---

## Older entries

Entries from 2026-10-04 to 2026-10-10 (real questions for three eras, hearts in server time, levels redrawn with real terrain, the level generator, the settings and controls, gate and softlock fixes) are in full in `docs/handoff-archive/HANDOFF-2026-10-04-to-10-10.md`.

Everything before 2026-10-03 (GAMEPLAY-V2 phases 0 to 4, the level generator, playtest rounds, folded one-liners, copy-paste prompts) is in full in `docs/handoff-archive/HANDOFF-2026-09-to-10-04.md`. The superseded checklist of 2026-09-22 is in `docs/handoff-archive/NEXT_STEPS_CHECKLIST-2026-09-22.md`.
