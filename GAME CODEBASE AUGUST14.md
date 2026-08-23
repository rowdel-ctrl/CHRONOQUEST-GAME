This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
android/
  app/
    src/
      debug/
        AndroidManifest.xml
      main/
        kotlin/
          com/
            chronoquest/
              chronoquest/
                MainActivity.kt
        res/
          drawable/
            launch_background.xml
          drawable-v21/
            launch_background.xml
          mipmap-hdpi/
            ic_launcher.png
          mipmap-mdpi/
            ic_launcher.png
          mipmap-xhdpi/
            ic_launcher.png
          mipmap-xxhdpi/
            ic_launcher.png
          mipmap-xxxhdpi/
            ic_launcher.png
          values/
            styles.xml
          values-night/
            styles.xml
        AndroidManifest.xml
      profile/
        AndroidManifest.xml
    build.gradle.kts
  build/
    reports/
      problems/
        problems-report.html
  gradle/
    wrapper/
      gradle-wrapper.properties
  .gitignore
  build.gradle.kts
  gradle.properties
  settings.gradle.kts
assets/
  animations/
    fireworks.json
  backgrounds/
    american_far.png
    american_near.png
    bookshelf_bg.png
    character_select_bg.png
    login_bg.png
    modern_far.png
    modern_near.png
    precolonial_far.png
    precolonial_near.png
    spanish_far.png
    spanish_near.png
    ww2_far.png
    ww2_near.png
  bosses/
    bakunawa_attack.png
    bakunawa_defeated.png
    bakunawa_idle.png
    commander_attack.png
    commander_defeated.png
    commander_idle.png
    corruption_boss_attack.png
    corruption_boss_defeated.png
    corruption_boss_idle.png
    general_attack.png
    general_defeated.png
    general_idle.png
    governor_attack.png
    governor_defeated.png
    governor_idle.png
  characters/
    bonifacio_hurt.png
    bonifacio_jump.png
    bonifacio_walk_1.png
    bonifacio_walk_2.png
    bonifacio_walk_3.png
    bonifacio_walk_4.png
    delpilar_hurt.png
    delpilar_jump.png
    delpilar_walk_1.png
    delpilar_walk_2.png
    delpilar_walk_3.png
    delpilar_walk_4.png
    lapu_hurt.png
    lapu_jump.png
    lapu_walk_1.png
    lapu_walk_2.png
    lapu_walk_3.png
    lapu_walk_4.png
    luna_hurt.png
    luna_jump.png
    luna_walk_1.png
    luna_walk_2.png
    luna_walk_3.png
    luna_walk_4.png
    rizal_hurt.png
    rizal_jump.png
    rizal_walk_1.png
    rizal_walk_2.png
    rizal_walk_3.png
    rizal_walk_4.png
  collectibles/
    artifact_1.png
    artifact_2.png
    artifact_3.png
    artifact_4.png
    artifact_5.png
    coin.png
  data/
    questions_american.json
    questions_modern.json
    questions_pre-colonial.json
    questions_spanish.json
    questions_ww2.json
  enemies/
    american_soldier_1.png
    american_soldier_2.png
    corruption_figure_1.png
    corruption_figure_2.png
    dark_spirit_1.png
    dark_spirit_2.png
    japanese_soldier_1.png
    japanese_soldier_2.png
    misinfo_cloud_1.png
    misinfo_cloud_2.png
    propaganda_1.png
    propaganda_2.png
    spanish_soldier_1.png
    spanish_soldier_2.png
    tank_1.png
    tank_2.png
    tax_collector_1.png
    tax_collector_2.png
    tribal_warrior_1.png
    tribal_warrior_2.png
  obstacles/
    american_wall.png
    modern_wall.png
    precolonial_wall.png
    spanish_wall.png
    ww2_wall.png
  powerups/
    fifty_fifty.png
    shield.png
    time_freeze.png
  sounds/
    bgm_american.mp3
    bgm_modern.mp3
    bgm_precolonial.mp3
    bgm_spanish.mp3
    bgm_ww2.mp3
    boss_appear.mp3
    boss_defeat.mp3
    coin.mp3
    correct.mp3
    enemy_defeat.mp3
    era_complete.mp3
    footsteps.mp3
    jump.mp3
    level_complete.mp3
    level_failed.mp3
    player_hurt.mp3
    powerup.mp3
    wrong.mp3
  ui/
    heart_empty.png
    heart_full.png
    lock_icon.png
    star_empty.png
    star_full.png
lib/
  core/
    constants.dart
    dio_client.dart
    router.dart
    theme.dart
  data/
    question_bank.dart
  game/
    components/
      boss_component.dart
      coin_component.dart
      enemy_component.dart
      enemy_spawner.dart
      gap_component.dart
      ground_component.dart
      player_component.dart
      wall_component.dart
    overlays/
      hud_overlay.dart
      pause_overlay.dart
      question_overlay.dart
    chrono_game.dart
  models/
    era_progress.dart
    question.dart
    quiz_result.dart
    student.dart
  providers/
    auth_provider.dart
    game_provider.dart
    progress_provider.dart
  screens/
    auth/
      login_screen.dart
    game/
      background_history_screen.dart
      era_complete_screen.dart
      game_screen.dart
      level_complete_screen.dart
      level_failed_screen.dart
      level_select_screen.dart
    home/
      character_selection_screen.dart
      era_selection_screen.dart
    profile/
      leaderboard_screen.dart
      profile_screen.dart
  services/
    api_service.dart
    audio_service.dart
    storage_service.dart
  widgets/
    pixel_ui.dart
  app.dart
  main.dart
windows/
  flutter/
    CMakeLists.txt
    generated_plugin_registrant.cc
    generated_plugin_registrant.h
    generated_plugins.cmake
  runner/
    resources/
      app_icon.ico
    CMakeLists.txt
    flutter_window.cpp
    flutter_window.h
    main.cpp
    resource.h
    runner.exe.manifest
    Runner.rc
    utils.cpp
    utils.h
    win32_window.cpp
    win32_window.h
  .gitignore
  CMakeLists.txt
.gitignore
.metadata
analysis_options.yaml
generate_assets.ps1
pubspec.lock
pubspec.yaml
README.md
```

# Files

## File: android/app/src/debug/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

## File: android/app/src/main/kotlin/com/chronoquest/chronoquest/MainActivity.kt
```kotlin
package com.chronoquest.chronoquest

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

## File: android/app/src/main/res/drawable/launch_background.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

## File: android/app/src/main/res/drawable-v21/launch_background.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="?android:colorBackground" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

## File: android/app/src/main/res/values/styles.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

## File: android/app/src/main/res/values-night/styles.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is on -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

## File: android/app/src/profile/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

## File: android/build/reports/problems/problems-report.html
```html
<!DOCTYPE html>

<html lang="en">
<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

                    <style type="text/css">
                /*! normalize.css v7.0.0 | MIT License | github.com/necolas/normalize.css */
html {
    line-height: 1.15;
    -ms-text-size-adjust: 100%;
    -webkit-text-size-adjust: 100%
}

body {
    margin: 0
}

article, aside, footer, header, nav, section {
    display: block
}

h1 {
    font-size: 2em;
    margin: .67em 0
}

figcaption, figure, main {
    display: block
}

figure {
    margin: 1em 40px
}

hr {
    box-sizing: content-box;
    height: 0;
    overflow: visible
}

pre {
    font-family: monospace, monospace;
    font-size: 1em
}

a {
    background-color: transparent;
    -webkit-text-decoration-skip: objects
}

abbr[title] {
    border-bottom: none;
    text-decoration: underline;
    text-decoration: underline dotted
}

b, strong {
    font-weight: inherit
}

b, strong {
    font-weight: bolder
}

code, kbd, samp {
    font-family: monospace, monospace;
    font-size: 1em
}

dfn {
    font-style: italic
}

mark {
    background-color: #ff0;
    color: #000
}

small {
    font-size: 80%
}

sub, sup {
    font-size: 75%;
    line-height: 0;
    position: relative;
    vertical-align: baseline
}

sub {
    bottom: -.25em
}

sup {
    top: -.5em
}

audio, video {
    display: inline-block
}

audio:not([controls]) {
    display: none;
    height: 0
}

img {
    border-style: none
}

svg:not(:root) {
    overflow: hidden
}

button, input, optgroup, select, textarea {
    font-family: sans-serif;
    font-size: 100%;
    line-height: 1.15;
    margin: 0
}

button, input {
    overflow: visible
}

button, select {
    text-transform: none
}

[type=reset], [type=submit], button, html [type=button] {
    -webkit-appearance: button
}

[type=button]::-moz-focus-inner, [type=reset]::-moz-focus-inner, [type=submit]::-moz-focus-inner, button::-moz-focus-inner {
    border-style: none;
    padding: 0
}

[type=button]:-moz-focusring, [type=reset]:-moz-focusring, [type=submit]:-moz-focusring, button:-moz-focusring {
    outline: 1px dotted ButtonText
}

fieldset {
    padding: .35em .75em .625em
}

legend {
    box-sizing: border-box;
    color: inherit;
    display: table;
    max-width: 100%;
    padding: 0;
    white-space: normal
}

progress {
    display: inline-block;
    vertical-align: baseline
}

textarea {
    overflow: auto
}

[type=checkbox], [type=radio] {
    box-sizing: border-box;
    padding: 0
}

[type=number]::-webkit-inner-spin-button, [type=number]::-webkit-outer-spin-button {
    height: auto
}

[type=search] {
    -webkit-appearance: textfield;
    outline-offset: -2px
}

[type=search]::-webkit-search-cancel-button, [type=search]::-webkit-search-decoration {
    -webkit-appearance: none
}

::-webkit-file-upload-button {
    -webkit-appearance: button;
    font: inherit
}

details, menu {
    display: block
}

summary {
    display: list-item
}

canvas {
    display: inline-block
}

template {
    display: none
}

[hidden] {
    display: none
}

/* configuration cache styles */

.report-wrapper {
    margin: 0;
    padding: 0 24px;
}

.gradle-logo {
    width: 32px;
    height: 24px;
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAYCAYAAACbU/80AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAGAAAAAA915G0AAAD5klEQVRIDbVWC0xTZxT+emmhVUEeA1/ROh/tFAFFGK7oJisIKsNVoOwBbJPowEWHzikRxeiMRpwwjDWRBHQLIzOmiRhe22BT40TitiyaMBQFfMEeLMIEaSmk+/+rvd7be4no6Elu7n++c/5zzv845/wyOyG4iGyDgzCdNOPLM9W41n4bnmNUiHo5DNsz0hGsmcV6lbkyAOOWXJjrz4qWp1C4o3z/LqzWL4VcJB1FIHmZHn/f78a6pDcxbeIEfNvQiPwTZbDZBpC24zOEaGfDpTsgtZby6u+QlrubFWUY3nh6AH39/ahr/Bn1jZfxW3ML2js60dtvgbtcQVblj8CZM7A0PBSrol6Ft+c4KZ8iTB1nwN0//8IEP9/hA2i924Gir0/iq8oa/NvbJzLiDKiUSqTE6pGVbEBY4BxnsYAPSnwXTa3tLCZ5BF3dPdAkGNHzoFcwcaRMnC4CeZkZiAgKFE252nITC1Pew9Dj5GNEGgS4Rbb5eZ1Te7UXG6FLX4cV6zeh5kIDaDpSunL9Boyf5nLOpwT4Sx+BxWrFK8QAnTAapPRQwofcj86uLoG59cbVEOzA0NAQNh38Atn5RSjY8rFAmc/I3dyQvOx1PsSNVy7Roa3ajHDePbBYLSLn1MaGd5KFAXy07xAOl59C6elK+I73hIHcbGd6wXs8qkyH8FZcjLOI5X/9/TrOnLsAldJDUu4As1NToFFPe3IEpm/M2HigwCFnU6t4Zw6Ck1JhGRhgcXq5juXloKyqFnlHirmz5CaNcEAv59kSE9wVikcB3O78A/MSU0Fznk/H9+yAetJEnPr+B8RFLsLcGS8ia28+qQuX+WrPNNZOV+Nc6VH4+3iz89g0pEaLzRUiQ3LGDWsM8Qidq2WL0PGKKlgf74ZIeQTAfFJ6a44WIsDXh9OW/dPdY58aawC9KK6kpOgolO7JxViVSuBGXnvxksudZ5F0O5yzGYxMJnBOGaau4fnPU2RNAtCFBKFoa7akczaAptY2iWmjB33+yQa4kZwfjpi2ex3Dyf43vuAljWQ/4Btmei1WPj+q45hF4U+1J4fEizCEvNf0EWHoIW244sfzoN1RipaT2kDfdjfv3MNpojdISjmfIheE8Fnp8WR9vJ2Zr+O+bYUmO+kJ9KnIUtf9bnvY2x9wcqrrvnCJvfL8Tw4V9v9LU7PdKzJaoNdy645AR4ph1JMncZHRKrVvYyYY5kmP8iO1v2T3dk6HDtYmrgJtOnwKnaPFrg8z+BBX7QSgEyOPJfX9Qd9DFs40GgTOHbrBs2ch4bXFuEG2mmFkeD9hpUMk+NMXEe0TNtsg/Ly94DVurEAuxfwHC1WiVbe0U7MAAAAASUVORK5CYII=");
    background-size: contain;
}

.header {
    display: flex;
    flex-wrap: wrap;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    padding: 24px 24px 0 24px;
    background-color: white;
    z-index: 1;
}

.learn-more {
    margin-left: auto;
    align-self: center;
    font-size: 0.875rem;
    font-weight: normal;
}

.title {
    display: flex;
    align-items: center;
    padding: 18px 0 24px 0;
    flex: 1 0 100%;
}

.content {
    font-size: 0.875rem;
    padding: 240px 0 48px;
    overflow-x: auto;
    white-space: nowrap;
}

.content ol:first-of-type {
    margin: 0;
}

.tree-btn {
    cursor: pointer;
    display: inline-block;
    width: 16px;
    height: 16px;
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-top: -0.2em;
}

.tree-btn.collapsed {
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 512"><path d="M166.9 264.5l-117.8 116c-4.7 4.7-12.3 4.7-17 0l-7.1-7.1c-4.7-4.7-4.7-12.3 0-17L127.3 256 25.1 155.6c-4.7-4.7-4.7-12.3 0-17l7.1-7.1c4.7-4.7 12.3-4.7 17 0l117.8 116c4.6 4.7 4.6 12.3-.1 17z" fill="%23999999" stroke="%23999999"/></svg>');
}

.tree-btn.expanded {
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 512"><path d="M119.5 326.9L3.5 209.1c-4.7-4.7-4.7-12.3 0-17l7.1-7.1c4.7-4.7 12.3-4.7 17 0L128 287.3l100.4-102.2c4.7-4.7 12.3-4.7 17 0l7.1 7.1c4.7 4.7 4.7 12.3 0 17L136.5 327c-4.7 4.6-12.3 4.6-17-.1z" fill="%23999999" stroke="%23999999"/></svg>');
}

ul .tree-btn {
    margin-right: 3px;
}

.leaf-icon {
    display: inline-block;
    width: 16px;
    height: 16px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 512"><path d="M32 256 H224" stroke="%23999999" stroke-width="48" stroke-linecap="round"/></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-top: -0.2em;
}

.invisible-text {
    user-select: all; /* Allow the text to be selectable */
    color: transparent; /* Hide the text */
    text-indent: -9999px; /* Move the text out of view */
    position: relative;
    white-space: pre; /* Preserve meaningful whitespace in the invisible text for copying */
}

.text-for-copy {
    display: inline-block;
}

.enum-icon {
    display: inline-block;
    width: 16px;
    height: 16px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><circle cx="512" cy="512" r="200" /></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.5ex;
    margin-inline-end: 0.5ex;
    margin-top: -0.2em;
}

.error-icon {
    display: inline-block;
    width: 16px;
    height: 16px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512"><path d="M193.94 256L296.5 153.44l21.15-21.15c3.12-3.12 3.12-8.19 0-11.31l-22.63-22.63c-3.12-3.12-8.19-3.12-11.31 0L160 222.06 36.29 98.34c-3.12-3.12-8.19-3.12-11.31 0L2.34 120.97c-3.12 3.12-3.12 8.19 0 11.31L126.06 256 2.34 379.71c-3.12 3.12-3.12 8.19 0 11.31l22.63 22.63c3.12 3.12 8.19 3.12 11.31 0L160 289.94 262.56 392.5l21.15 21.15c3.12 3.12 8.19 3.12 11.31 0l22.63-22.63c3.12-3.12 3.12-8.19 0-11.31L193.94 256z" fill="%23FC461E" stroke="%23FC461E"/></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.5ex;
    margin-inline-end: 0.5ex;
    margin-top: -0.2em;
}

.advice-icon {
    display: inline-block;
    width: 16px;
    height: 16px;
    background-image: url('data:image/svg+xml;utf8,<svg width="800px" height="800px" viewBox="-4.93 0 122.88 122.88" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"  style="enable-background:new 0 0 113.01 122.88" xml:space="preserve"><g><path d="M44.13,102.06c-1.14,0.03-2.14-0.81-2.3-1.96c-0.17-1.2,0.64-2.31,1.82-2.54c-1.3-7.37-4.85-11.43-8.6-15.72 c-2.92-3.34-5.95-6.81-8.34-11.92c-2.35-5.03-3.64-10.23-3.6-15.63c0.05-5.4,1.42-10.96,4.4-16.71c0.02-0.04,0.04-0.07,0.06-0.11 l0,0c3.91-6.62,9.38-11.04,15.47-13.52c5.11-2.09,10.66-2.8,16.1-2.3c5.42,0.5,10.73,2.2,15.37,4.94 c5.9,3.49,10.75,8.67,13.42,15.21c1.44,3.54,2.42,7.49,2.54,11.82c0.12,4.31-0.62,8.96-2.61,13.88 c-2.66,6.59-6.18,10.68-9.47,14.51c-3.03,3.53-5.85,6.81-7.42,11.84c0.89,0.21,1.59,0.94,1.73,1.9c0.17,1.24-0.7,2.39-1.94,2.56 l-0.77,0.11c-0.14,1.09-0.23,2.26-0.27,3.51l0.25-0.04c1.24-0.17,2.39,0.7,2.56,1.94c0.17,1.24-0.7,2.39-1.94,2.56l-0.78,0.11 c0.01,0.15,0.02,0.3,0.03,0.45l0,0c0.07,0.88,0.08,1.73,0.03,2.54l0.13-0.02c1.25-0.15,2.38,0.74,2.54,1.98 c0.15,1.25-0.74,2.38-1.98,2.54l-1.68,0.21c-1.2,3.11-3.34,5.48-5.87,6.94c-1.74,1.01-3.67,1.59-5.61,1.71 c-1.97,0.12-3.96-0.25-5.78-1.13c-2.08-1.02-3.94-2.71-5.29-5.14c-0.65-0.33-1.13-0.97-1.23-1.75c-0.04-0.31-0.01-0.61,0.07-0.89 c-0.39-1.16-0.68-2.43-0.87-3.83l-0.07,0.01c-1.24,0.17-2.39-0.7-2.56-1.94c-0.17-1.24,0.7-2.39,1.94-2.56l0.54-0.08 C44.19,104.32,44.18,103.16,44.13,102.06L44.13,102.06z M2.18,58.86C1.01,58.89,0.04,57.98,0,56.81c-0.04-1.17,0.88-2.14,2.05-2.18 l8.7-0.3c1.17-0.04,2.14,0.88,2.18,2.05c0.04,1.17-0.88,2.14-2.05,2.18L2.18,58.86L2.18,58.86z M110.68,50.25 c1.16-0.12,2.2,0.73,2.32,1.89c0.12,1.16-0.73,2.2-1.89,2.32l-8.66,0.91c-1.16,0.12-2.2-0.73-2.32-1.89 c-0.12-1.16,0.73-2.2,1.89-2.32L110.68,50.25L110.68,50.25z M94.91,14.78c0.65-0.97,1.96-1.23,2.93-0.58 c0.97,0.65,1.23,1.96,0.58,2.93l-4.84,7.24c-0.65,0.97-1.96,1.23-2.93,0.58c-0.97-0.65-1.23-1.96-0.58-2.93L94.91,14.78 L94.91,14.78z M57.63,2.06c0.03-1.17,1-2.09,2.16-2.06c1.17,0.03,2.09,1,2.06,2.16l-0.22,8.7c-0.03,1.17-1,2.09-2.16,2.06 c-1.17-0.03-2.09-1-2.06-2.16L57.63,2.06L57.63,2.06z M13.88,15.53c-0.86-0.8-0.9-2.14-0.11-2.99c0.8-0.86,2.14-0.9,2.99-0.11 l6.37,5.94c0.86,0.8,0.9,2.14,0.11,2.99c-0.8,0.86-2.14,0.9-2.99,0.11L13.88,15.53L13.88,15.53z M47.88,96.95l18.49-2.63 c1.59-6.7,5.05-10.73,8.8-15.08c3.08-3.58,6.36-7.4,8.76-13.34c1.76-4.35,2.41-8.43,2.31-12.19c-0.1-3.75-0.96-7.21-2.24-10.34 c-2.3-5.63-6.51-10.11-11.65-13.15c-4.11-2.43-8.8-3.94-13.59-4.37c-4.77-0.44-9.64,0.19-14.13,2.02 c-5.26,2.15-9.99,5.97-13.39,11.72c-2.64,5.12-3.86,10.02-3.9,14.73c-0.04,4.74,1.11,9.33,3.2,13.8c2.13,4.56,4.97,7.8,7.69,10.92 C42.47,83.9,46.48,88.49,47.88,96.95L47.88,96.95z M65.62,99.02l-17.27,2.45c0.05,1.1,0.07,2.25,0.05,3.47l17.05-2.42 C65.47,101.29,65.52,100.12,65.62,99.02L65.62,99.02z M48.49,109.52c0.12,0.92,0.3,1.76,0.53,2.54l16.55-2.04 c0.11-0.86,0.13-1.77,0.05-2.74l0,0l0-0.02l-0.01-0.17L48.49,109.52L48.49,109.52z M51.37,116.36c0.64,0.67,1.35,1.19,2.1,1.55 c1.15,0.56,2.42,0.79,3.67,0.72c1.29-0.08,2.57-0.47,3.74-1.15c1.1-0.64,2.09-1.53,2.88-2.65L51.37,116.36L51.37,116.36z"/></g></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.5ex;
    margin-inline-end: 0.5ex;
    margin-top: -0.2em;
}

.warning-icon {
    display: inline-block;
    width: 13px;
    height: 13px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path d="M270.2 160h35.5c3.4 0 6.1 2.8 6 6.2l-7.5 196c-.1 3.2-2.8 5.8-6 5.8h-20.5c-3.2 0-5.9-2.5-6-5.8l-7.5-196c-.1-3.4 2.6-6.2 6-6.2zM288 388c-15.5 0-28 12.5-28 28s12.5 28 28 28 28-12.5 28-28-12.5-28-28-28zm281.5 52L329.6 24c-18.4-32-64.7-32-83.2 0L6.5 440c-18.4 31.9 4.6 72 41.6 72H528c36.8 0 60-40 41.5-72zM528 480H48c-12.3 0-20-13.3-13.9-24l240-416c6.1-10.6 21.6-10.7 27.7 0l240 416c6.2 10.6-1.5 24-13.8 24z" fill="%23DEAD22" stroke="%23DEAD22"/></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.3ex;
    margin-inline-end: 1.1ex;
    margin-top: -0.1em;
}

.documentation-button {
    cursor: pointer;
    display: inline-block;
    width: 13px;
    height: 13px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path d="M256 340c-15.464 0-28 12.536-28 28s12.536 28 28 28 28-12.536 28-28-12.536-28-28-28zm7.67-24h-16c-6.627 0-12-5.373-12-12v-.381c0-70.343 77.44-63.619 77.44-107.408 0-20.016-17.761-40.211-57.44-40.211-29.144 0-44.265 9.649-59.211 28.692-3.908 4.98-11.054 5.995-16.248 2.376l-13.134-9.15c-5.625-3.919-6.86-11.771-2.645-17.177C185.658 133.514 210.842 116 255.67 116c52.32 0 97.44 29.751 97.44 80.211 0 67.414-77.44 63.849-77.44 107.408V304c0 6.627-5.373 12-12 12zM256 40c118.621 0 216 96.075 216 216 0 119.291-96.61 216-216 216-119.244 0-216-96.562-216-216 0-119.203 96.602-216 216-216m0-32C119.043 8 8 119.083 8 256c0 136.997 111.043 248 248 248s248-111.003 248-248C504 119.083 392.957 8 256 8z" fill="%23999999" stroke="%23999999"/></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.5ex;
    margin-inline-end: 0.5ex;
    margin-top: -0.2em;
}

.documentation-button::selection {
    color: transparent;
}

.documentation-button:hover {
    color: transparent;
}

.copy-button {
    cursor: pointer;
    display: inline-block;
    width: 12px;
    height: 12px;
    background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path d="M433.941 193.941l-51.882-51.882A48 48 0 0 0 348.118 128H320V80c0-26.51-21.49-48-48-48h-66.752C198.643 13.377 180.858 0 160 0s-38.643 13.377-45.248 32H48C21.49 32 0 53.49 0 80v288c0 26.51 21.49 48 48 48h80v48c0 26.51 21.49 48 48 48h224c26.51 0 48-21.49 48-48V227.882a48 48 0 0 0-14.059-33.941zm-22.627 22.627a15.888 15.888 0 0 1 4.195 7.432H352v-63.509a15.88 15.88 0 0 1 7.431 4.195l51.883 51.882zM160 30c9.941 0 18 8.059 18 18s-8.059 18-18 18-18-8.059-18-18 8.059-18 18-18zM48 384c-8.822 0-16-7.178-16-16V80c0-8.822 7.178-16 16-16h66.752c6.605 18.623 24.389 32 45.248 32s38.643-13.377 45.248-32H272c8.822 0 16 7.178 16 16v48H176c-26.51 0-48 21.49-48 48v208H48zm352 96H176c-8.822 0-16-7.178-16-16V176c0-8.822 7.178-16 16-16h144v72c0 13.2 10.8 24 24 24h72v208c0 8.822-7.178 16-16 16z" fill="%23999999" stroke="%23999999"/></svg>');
    background-size: contain;
    background-repeat: no-repeat;
    vertical-align: middle;
    margin-inline-start: 0.5ex;
    margin-top: -0.2em;
}

.groups{
    display: flex;
    border-bottom: 1px solid #EDEEEF;
    flex: 1 0 100%;
}

.uncategorized {
    display: flex;
    border-top: 4px solid #EDEEEF;
    flex: 1 0 100%;
}

.group-selector {
    padding: 0 52px 24px 0;
    font-size: 0.9rem;
    font-weight: bold;
    color: #999999;
    cursor: pointer;
}

.group-selector__count {
    margin: 0 8px;
    border-radius: 8px;
    background-color: #999;
    color: #fff;
    padding: 1px 8px 2px;
    font-size: 0.75rem;
}

.group-selector--active {
    color: #02303A;
    cursor: auto;
}

.group-selector--active .group-selector__count {
    background-color: #686868;
}

.group-selector--disabled {
    cursor: not-allowed;
}

.accordion-header {
    cursor: pointer;
}

.container {
    padding-left: 0.5em;
    padding-right: 0.5em;
}

.stacktrace {
    border-radius: 4px;
    overflow-x: auto;
    padding: 0.5rem;
    margin-bottom: 0;
    min-width: 1000px;
}

/* Lato (bold, regular) */
@font-face {
    font-display: swap;
    font-family: Lato;
    font-weight: 500;
    font-style: normal;
    src: url("https://assets.gradle.com/lato/fonts/lato-semibold/lato-semibold.woff2") format("woff2"),
    url("https://assets.gradle.com/lato/fonts/lato-semibold/lato-semibold.woff") format("woff");
}

@font-face {
    font-display: swap;
    font-family: Lato;
    font-weight: bold;
    font-style: normal;
    src: url("https://assets.gradle.com/lato/fonts/lato-bold/lato-bold.woff2") format("woff2"),
    url("https://assets.gradle.com/lato/fonts/lato-bold/lato-bold.woff") format("woff");
}

* {
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    box-sizing: border-box;
}

html,
body {
    margin: 0;
    padding: 0;
}

html {
    font-family: "Lato", "Helvetica Neue", Arial, sans-serif;
    font-size: 16px;
    font-weight: 400;
    line-height: 1.5;
}

body {
    color: #02303A;
    background-color: #ffffff;
    -webkit-text-size-adjust: 100%;
    -ms-text-size-adjust: 100%;
    -webkit-font-smoothing: antialiased;
}


/* typography */
h1, h2, h3, h4, h5, h6 {
    color: #02303A;
    text-rendering: optimizeLegibility;
    margin: 0;
}

h1 {
    font-size: 1rem;
}

h2 {
    font-size: 0.9rem;
}

h3 {
    font-size: 1.125rem;
}

h4, h5, h6 {
    font-size: 0.875rem;
}

h1 code {
    font-weight: bold;
}

ul, ol, dl {
    list-style-position: outside;
    line-height: 1.6;
    padding: 0;
    margin: 0 0 0 20px;
    list-style-type: none;
}

li {
    line-height: 2;
}

a {
    color: #1DA2BD;
    text-decoration: none;
    transition: all 0.3s ease, visibility 0s;
}

a:hover {
    color: #35c1e4;
}

/* code */
code, pre {
    font-family: Inconsolata, Monaco, "Courier New", monospace;
    font-style: normal;
    font-variant-ligatures: normal;
    font-variant-caps: normal;
    font-variant-numeric: normal;
    font-variant-east-asian: normal;
    font-weight: normal;
    font-stretch: normal;
    color: #686868;
}

*:not(pre) > code {
    letter-spacing: 0;
    padding: 0.1em 0.5ex;
    text-rendering: optimizeSpeed;
    word-spacing: -0.15em;
    word-wrap: break-word;
}

pre {
    font-size: 0.75rem;
    line-height: 1.8;
    margin-top: 0;
    margin-bottom: 1.5em;
    padding: 1rem;
}

pre code {
    background-color: transparent;
    color: inherit;
    line-height: 1.8;
    font-size: 100%;
    padding: 0;
}

a code {
    color: #1BA8CB;
}

pre.code, pre.programlisting, pre.screen, pre.tt {
    background-color: #f7f7f8;
    border-radius: 4px;
    font-size: 1em;
    line-height: 1.45;
    margin-bottom: 1.25em;
    overflow-x: auto;
    padding: 1rem;
}

li em, p em {
    padding: 0 1px;
}

code em, tt em {
    text-decoration: none;
}

code + .copy-button {
    margin-inline-start: 0.2ex;
}

.java-exception {
    font-size: 0.75rem;
    padding-left: 24px;
}

.java-exception ul {
    margin: 0;
    line-height: inherit;
}

.java-exception code {
    white-space: pre;
}

.java-exception-part-toggle {
    user-select: none;
    cursor: pointer;
    border-radius: 2px;
    padding: 0.1em 0.2em;
    background: azure;
    color: #686868;
}

                </style>
    <!-- Inconsolata is used as a default monospace font in the report. -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Inconsolata:400,700" />

    <title>Gradle Configuration Cache</title>
</head>
<body>

<div id="playground"></div>

<div class="report" id="report">
    Loading...
</div>

<script type="text/javascript">
function configurationCacheProblems() { return (
// begin-report-data
{"diagnostics":[{"locations":[{"pluginId":"kotlin-android"}],"problem":[{"text":"Deprecated 'org.jetbrains.kotlin.android' plugin usage"}],"severity":"WARNING","problemDetails":[{"text":"The 'org.jetbrains.kotlin.android' plugin in project ':app' is no longer required for Kotlin support since AGP 9.0."}],"contextualLabel":"Deprecated 'org.jetbrains.kotlin.android' plugin usage","documentationLink":"https://kotl.in/gradle/agp-built-in-kotlin","problemId":[{"name":"kgp:deprecation","displayName":"Kotlin Gradle Plugin Deprecation"},{"name":"kotlin","displayName":"Kotlin"},{"name":"deprecated-kotlin-android-plugin","displayName":"Deprecated 'org.jetbrains.kotlin.android' plugin usage"}],"solutions":[[{"text":"Remove both `android.builtInKotlin=true` and `android.newDsl=false` from `gradle.properties`, then migrate to built-in Kotlin."}]]}],"problemsReport":{"totalProblemCount":1,"buildName":"android","requestedTasks":"assembleDebug","documentationLink":"https://docs.gradle.org/9.1.0/userguide/reporting_problems.html","documentationLinkCaption":"Problem report","summaries":[]}}
// end-report-data
);}
</script>
                <script type="text/javascript">
                !function(n,t){"object"==typeof exports&&"object"==typeof module?module.exports=t():"function"==typeof define&&define.amd?define([],t):"object"==typeof exports?exports["configuration-cache-report"]=t():n["configuration-cache-report"]=t()}(this,(()=>(({70:function(){void 0===ArrayBuffer.isView&&(ArrayBuffer.isView=function(n){return null!=n&&null!=n.__proto__&&n.__proto__.__proto__===Int8Array.prototype.__proto__}),void 0===Math.imul&&(Math.imul=function(n,t){return(4294901760&n)*(65535&t)+(65535&n)*(0|t)|0}),this["configuration-cache-report"]=function(n){"use strict";var t,r,i,e,u,o,f,s,c,a,h,l,_,v,d,g,w,b,p,m,k,q,y,B,C,x,j,P,I,S,z,T,E,L,N,A,M,F,D,O,R,H,$,G,U,V,Q,Z,Y,W,K,X,J,nn,tn,rn,en,un,on,fn,sn,cn,an,hn,ln,_n,vn,dn,gn,wn,bn,pn,mn,kn,qn,yn,Bn,Cn,xn,jn,Pn,In,Sn,zn,Tn,En,Ln,Nn,An,Mn=Math.imul,Fn=ArrayBuffer.isView;function Dn(n,t){if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));return function(n,t){if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));if(0===t)return Ct();if(t>=n.length)return function(n){switch(n.length){case 0:return Ct();case 1:return qr(n[0]);default:return function(n){return Hr(function(n){return new It(n,!1)}(n))}(n)}}(n);if(1===t)return qr(n[0]);var r=0,i=Rr(),e=0,u=n.length;n:for(;e<u;){var o=n[e];if(e=e+1|0,i.d(o),(r=r+1|0)===t)break n}return i}(n,rt(n.length-t|0,0))}function On(n,t,r,i,e,u,o){return t=t===A?", ":t,r=r===A?"":r,i=i===A?"":i,e=e===A?-1:e,u=u===A?"...":u,o=o===A?null:o,function(n,t,r,i,e,u,o,f){r=r===A?", ":r,i=i===A?"":i,e=e===A?"":e,u=u===A?-1:u,o=o===A?"...":o,f=f===A?null:f,t.e(i);var s=0,c=0,a=n.length;n:for(;c<a;){var h=n[c];if(c=c+1|0,(s=s+1|0)>1&&t.e(r),!(u<0||s<=u))break n;Jt(t,h,f)}return u>=0&&s>u&&t.e(o),t.e(e),t}(n,Bi(),t,r,i,e,u,o).toString()}function Rn(n){return n.length-1|0}function Hn(n,t){if(null==t){var r=0,i=n.length-1|0;if(r<=i)do{var e=r;if(r=r+1|0,null==n[e])return e}while(r<=i)}else{var u=0,o=n.length-1|0;if(u<=o)do{var f=u;if(u=u+1|0,le(t,n[f]))return f}while(u<=o)}return-1}function $n(n,t,r,i,e,u,o){return t=t===A?", ":t,r=r===A?"":r,i=i===A?"":i,e=e===A?-1:e,u=u===A?"...":u,o=o===A?null:o,Gn(n,Bi(),t,r,i,e,u,o).toString()}function Gn(n,t,r,i,e,u,o,f){r=r===A?", ":r,i=i===A?"":i,e=e===A?"":e,u=u===A?-1:u,o=o===A?"...":o,f=f===A?null:f,t.e(i);var s=0,c=n.f();n:for(;c.g();){var a=c.h();if((s=s+1|0)>1&&t.e(r),!(u<0||s<=u))break n;Jt(t,a,f)}return u>=0&&s>u&&t.e(o),t.e(e),t}function Un(n){if(n.i())throw xu("List is empty.");return n.j(0)}function Vn(n){return new tt(n)}function Qn(n){if(Ke(n,Di)){var t;switch(n.k()){case 0:t=Ct();break;case 1:t=qr(Ke(n,Fi)?n.j(0):n.f().h());break;default:t=Zn(n)}return t}return xt(Xn(n))}function Zn(n){return Hr(n)}function Yn(n){if(Ke(n,Di)&&n.k()<=1)return Qn(n);var t=Xn(n);return function(n){var t=(n.k()/2|0)-1|0;if(t<0)return br();var r=jt(n),i=0;if(i<=t)do{var e=i;i=i+1|0;var u=n.j(e);n.f4(e,n.j(r)),n.f4(r,u),r=r-1|0}while(e!==t)}(t),t}function Wn(n,t){if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));return function(n,t){if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));if(0===t)return Ct();if(Ke(n,Di)){if(t>=n.k())return Qn(n);if(1===t)return qr(function(n){if(Ke(n,Fi))return Un(n);var t=n.f();if(!t.g())throw xu("Collection is empty.");return t.h()}(n))}var r=0,i=Rr(),e=n.f();n:for(;e.g();){var u=e.h();if(i.d(u),(r=r+1|0)===t)break n}return xt(i)}(n,rt(n.k()-t|0,0))}function Kn(n,t){if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));if(0===t)return Ct();var r=n.k();if(t>=r)return Qn(n);if(1===t)return qr(Jn(n));var i=Rr();if(Ke(n,bi)){var e=r-t|0;if(e<r)do{var u=e;e=e+1|0,i.d(n.j(u))}while(e<r)}else for(var o=n.l(r-t|0);o.g();){var f=o.h();i.d(f)}return i}function Xn(n){return Ke(n,Di)?Zn(n):nt(n,Or())}function Jn(n){if(n.i())throw xu("List is empty.");return n.j(jt(n))}function nt(n,t){for(var r=n.f();r.g();){var i=r.h();t.d(i)}return t}function tt(n){this.n_1=n}function rt(n,t){return n<t?t:n}function it(n,t){return n>t?t:n}function et(n,t){return Kt().q(n,t,-1)}function ut(n,t){return new Ft(n,t)}function ot(n){var t=n.f();if(!t.g())return Ct();var r=t.h();if(!t.g())return qr(r);var i=Or();for(i.d(r);t.g();)i.d(t.h());return i}function ft(n){this.r_1=n}function st(n,t){this.s_1=n,this.t_1=t}function ct(){}function at(n){this.x_1=n,this.w_1=0}function ht(n,t){this.a1_1=n,at.call(this,n),_t().b1(t,this.a1_1.k()),this.w_1=t}function lt(){t=this}function _t(){return null==t&&new lt,t}function vt(){_t(),ct.call(this)}function dt(n){this.h1_1=n}function gt(n,t){return t===n?"(this Map)":Vi(t)}function wt(n,t){var r;n:{for(var i=n.o().f();i.g();){var e=i.h();if(le(e.j1(),t)){r=e;break n}}r=null}return r}function bt(){r=this}function pt(){return null==r&&new bt,r}function mt(n){this.q1_1=n,ct.call(this)}function kt(){pt(),this.n1_1=null,this.o1_1=null}function qt(){i=this}function yt(){return null==i&&new qt,i}function Bt(n){return n.length>0?ou(n):Ct()}function Ct(){return null==e&&new Pt,e}function xt(n){switch(n.k()){case 0:return Ct();case 1:return qr(n.j(0));default:return n}}function jt(n){return n.k()-1|0}function Pt(){e=this,this.z1_1=new ke(-1478467534,-1720727600)}function It(n,t){this.b2_1=n,this.c2_1=t}function St(){u=this}function zt(){return null==u&&new St,u}function Tt(n,t){return Ke(n,Di)?n.k():t}function Et(n,t){if(Ke(t,Di))return n.m(t);for(var r=!1,i=t.f();i.g();){var e=i.h();n.d(e)&&(r=!0)}return r}function Lt(){}function Nt(n,t){this.h2_1=n,this.g2_1=n.i2_1.l(function(n,t){if(!(0<=t&&t<=n.k()))throw du("Position index "+t+" must be in range ["+Ve(0,n.k())+"].");return n.k()-t|0}(n,t))}function At(n){vt.call(this),this.i2_1=n}function Mt(n){this.k2_1=n,this.j2_1=n.l2_1.f()}function Ft(n,t){this.l2_1=n,this.m2_1=t}function Dt(n){for(;n.n2_1.g();){var t=n.n2_1.h();if(n.q2_1.t2_1(t)===n.q2_1.s2_1)return n.p2_1=t,n.o2_1=1,br()}n.o2_1=0}function Ot(n){this.q2_1=n,this.n2_1=n.r2_1.f(),this.o2_1=-1,this.p2_1=null}function Rt(n,t,r){t=t===A||t,this.r2_1=n,this.s2_1=t,this.t2_1=r}function Ht(){return null==o&&new $t,o}function $t(){o=this,this.u2_1=new ke(1993859828,793161749)}function Gt(n,t,r){return Ut(Ut(n,r)-Ut(t,r)|0,r)}function Ut(n,t){var r=n%t|0;return r>=0?r:r+t|0}function Vt(){f=this,this.p_1=new Zt(1,0)}function Qt(){return null==f&&new Vt,f}function Zt(n,t){Qt(),Xt.call(this,n,t,1)}function Yt(n,t,r){Lt.call(this),this.d3_1=r,this.e3_1=t,this.f3_1=this.d3_1>0?n<=t:n>=t,this.g3_1=this.f3_1?n:this.e3_1}function Wt(){s=this}function Kt(){return null==s&&new Wt,s}function Xt(n,t,r){if(Kt(),0===r)throw _u("Step must be non-zero.");if(r===mr().MIN_VALUE)throw _u("Step must be greater than Int.MIN_VALUE to avoid overflow on negation.");this.z2_1=n,this.a3_1=function(n,t,r){var i;if(r>0)i=n>=t?t:t-Gt(t,n,r)|0;else{if(!(r<0))throw _u("Step is zero.");i=n<=t?t:t+Gt(n,t,0|-r)|0}return i}(n,t,r),this.b3_1=r}function Jt(n,t,r){null!=r?n.e(r(t)):null==t||nu(t)?n.e(t):t instanceof Mi?n.i3(t.h3_1):n.e(Vi(t))}function nr(n,t,r){if(n===t)return!0;if(!(r=r!==A&&r))return!1;var i=xi(n),e=xi(t);return i===e||le(new Mi(ne(Li(i).toLowerCase(),0)),new Mi(ne(Li(e).toLowerCase(),0)))}function tr(n){return re(n)-1|0}function rr(n,t,r,i){return r=r===A?0:r,(i=i!==A&&i)||"string"!=typeof n?ir(n,t,r,re(n),i):n.indexOf(t,r)}function ir(n,t,r,i,e,u){var o=(u=u!==A&&u)?et(it(r,tr(n)),rt(i,0)):Ve(rt(r,0),it(i,re(n)));if("string"==typeof n&&"string"==typeof t){var f=o.z2_1,s=o.a3_1,c=o.b3_1;if(c>0&&f<=s||c<0&&s<=f)do{var a=f;if(f=f+c|0,Ti(t,0,n,a,re(t),e))return a}while(a!==s)}else{var h=o.z2_1,l=o.a3_1,_=o.b3_1;if(_>0&&h<=l||_<0&&l<=h)do{var v=h;if(h=h+_|0,fr(t,0,n,v,re(t),e))return v}while(v!==l)}return-1}function er(n){var t=0,r=re(n)-1|0,i=!1;n:for(;t<=r;){var e=ji(ne(n,i?r:t));if(i){if(!e)break n;r=r-1|0}else e?t=t+1|0:i=!0}return ie(n,t,r+1|0)}function ur(n,t){return ce(ie(n,t.y2(),t.c3()+1|0))}function or(n,t,r,i,e){r=r===A?0:r,i=i!==A&&i,sr(e=e===A?0:e);var u,o,f=ou(t);return new hr(n,r,e,(u=f,o=i,function(n,t){var r=function(n,t,r,i){if(!i&&1===t.k()){var e=function(n){if(Ke(n,Fi))return function(n){var t;switch(n.k()){case 0:throw xu("List is empty.");case 1:t=n.j(0);break;default:throw _u("List has more than one element.")}return t}(n);var t=n.f();if(!t.g())throw xu("Collection is empty.");var r=t.h();if(t.g())throw _u("Collection has more than one element.");return r}(t),u=rr(n,e,r);return u<0?null:_r(u,e)}var o=Ve(rt(r,0),re(n));if("string"==typeof n){var f=o.z2_1,s=o.a3_1,c=o.b3_1;if(c>0&&f<=s||c<0&&s<=f)do{var a,h=f;f=f+c|0;n:{for(var l=t.f();l.g();){var _=l.h();if(Ti(_,0,n,h,_.length,i)){a=_;break n}}a=null}if(null!=a)return _r(h,a)}while(h!==s)}else{var v=o.z2_1,d=o.a3_1,g=o.b3_1;if(g>0&&v<=d||g<0&&d<=v)do{var w,b=v;v=v+g|0;n:{for(var p=t.f();p.g();){var m=p.h();if(fr(m,0,n,b,m.length,i)){w=m;break n}}w=null}if(null!=w)return _r(b,w)}while(b!==d)}return null}(n,u,t,o);return null==r?null:_r(r.t3_1,r.u3_1.length)}))}function fr(n,t,r,i,e,u){if(i<0||t<0||t>(re(n)-e|0)||i>(re(r)-e|0))return!1;var o=0;if(o<e)do{var f=o;if(o=o+1|0,!nr(ne(n,t+f|0),ne(r,i+f|0),u))return!1}while(o<e);return!0}function sr(n){if(!(n>=0))throw _u(ce("Limit must be non-negative, but was "+n))}function cr(n){if(n.l3_1<0)n.j3_1=0,n.m3_1=null;else{var t;if(n.o3_1.r3_1>0?(n.n3_1=n.n3_1+1|0,t=n.n3_1>=n.o3_1.r3_1):t=!1,t||n.l3_1>re(n.o3_1.p3_1))n.m3_1=Ve(n.k3_1,tr(n.o3_1.p3_1)),n.l3_1=-1;else{var r=n.o3_1.s3_1(n.o3_1.p3_1,n.l3_1);if(null==r)n.m3_1=Ve(n.k3_1,tr(n.o3_1.p3_1)),n.l3_1=-1;else{var i=r.v3(),e=r.w3();n.m3_1=function(n,t){return t<=mr().MIN_VALUE?Qt().p_1:Ve(n,t-1|0)}(n.k3_1,i),n.k3_1=i+e|0,n.l3_1=n.k3_1+(0===e?1:0)|0}}n.j3_1=1}}function ar(n){this.o3_1=n,this.j3_1=-1,this.k3_1=function(n,t,r){if(0>r)throw _u("Cannot coerce value to an empty range: maximum "+r+" is less than minimum 0.");return n<0?0:n>r?r:n}(n.q3_1,0,re(n.p3_1)),this.l3_1=this.k3_1,this.m3_1=null,this.n3_1=0}function hr(n,t,r,i){this.p3_1=n,this.q3_1=t,this.r3_1=r,this.s3_1=i}function lr(n,t){this.t3_1=n,this.u3_1=t}function _r(n,t){return new lr(n,t)}function vr(){}function dr(){}function gr(){}function wr(){c=this}function br(){return null==c&&new wr,c}function pr(){a=this,this.MIN_VALUE=-2147483648,this.MAX_VALUE=2147483647,this.SIZE_BYTES=4,this.SIZE_BITS=32}function mr(){return null==a&&new pr,a}function kr(n){for(var t=[],r=n.f();r.g();)t.push(r.h());return t}function qr(n){return 0===(t=[n]).length?Or():Hr(new It(t,!0));var t}function yr(n){return n<0&&function(){throw Pu("Index overflow has happened.")}(),n}function Br(n){return void 0!==n.toArray?n.toArray():kr(n)}function Cr(n){return function(n,t){for(var r=0,i=n.length;r<i;){var e=n[r];r=r+1|0,t.d(e)}return t}(t=[n],(r=t.length,i=de(ve(ni)),function(n,t,r){Mr.call(r),ni.call(r),r.y5_1=function(n){return Kr(n,0,de(ve(Xr)))}(n)}(r,0,i),i));var t,r,i}function xr(){ct.call(this)}function jr(n){this.j4_1=n,this.h4_1=0,this.i4_1=-1}function Pr(n,t){this.n4_1=n,jr.call(this,n),_t().b1(t,this.n4_1.k()),this.h4_1=t}function Ir(){xr.call(this),this.o4_1=0}function Sr(n){this.r4_1=n}function zr(n){this.s4_1=n}function Tr(n,t){this.t4_1=n,this.u4_1=t}function Er(){Mr.call(this)}function Lr(n){this.x4_1=n,Mr.call(this)}function Nr(n){this.e5_1=n,xr.call(this)}function Ar(){kt.call(this),this.c5_1=null,this.d5_1=null}function Mr(){xr.call(this)}function Fr(){h=this;var n=Rr();n.c_1=!0,this.i5_1=n}function Dr(){return null==h&&new Fr,h}function Or(){return n=de(ve(Gr)),t=[],Gr.call(n,t),n;var n,t}function Rr(n){return t=de(ve(Gr)),r=[],Gr.call(t,r),t;var t,r}function Hr(n){return function(n,t){var r;return r=Br(n),Gr.call(t,r),t}(n,de(ve(Gr)))}function $r(n,t){return _t().e1(t,n.k()),t}function Gr(n){Dr(),Ir.call(this),this.b_1=n,this.c_1=!1}function Ur(n,t,r,i,e){if(r===i)return n;var u=(r+i|0)/2|0,o=Ur(n,t,r,u,e),f=Ur(n,t,u+1|0,i,e),s=o===t?n:t,c=r,a=u+1|0,h=r;if(h<=i)do{var l=h;if(h=h+1|0,c<=u&&a<=i){var _=o[c],v=f[a];e.compare(_,v)<=0?(s[l]=_,c=c+1|0):(s[l]=v,a=a+1|0)}else c<=u?(s[l]=o[c],c=c+1|0):(s[l]=f[a],a=a+1|0)}while(l!==i);return s}function Vr(n,t){return(3&n)-(3&t)|0}function Qr(){_=this}function Zr(n){this.n5_1=n,Er.call(this)}function Yr(n){return function(n,t){Ar.call(t),Xr.call(t),t.t5_1=n,t.u5_1=n.w5()}(new ui((null==_&&new Qr,_)),n),n}function Wr(){return Yr(de(ve(Xr)))}function Kr(n,t,r){if(Yr(r),!(n>=0))throw _u(ce("Negative initial capacity: "+n));if(!(t>=0))throw _u(ce("Non-positive load factor: "+t));return r}function Xr(){this.v5_1=null}function Jr(n,t){return Mr.call(t),ni.call(t),t.y5_1=n,t}function ni(){}function ti(n,t){var r=ii(n,n.h6_1.m5(t));if(null==r)return null;var i=r;if(null!=i&&Xe(i))return ri(i,n,t);var e=i;return n.h6_1.l5(e.j1(),t)?e:null}function ri(n,t,r){var i;n:{for(var e=0,u=n.length;e<u;){var o=n[e];if(e=e+1|0,t.h6_1.l5(o.j1(),r)){i=o;break n}}i=null}return i}function ii(n,t){var r=n.i6_1[t];return void 0===r?null:r}function ei(n){this.g6_1=n,this.z5_1=-1,this.a6_1=Object.keys(n.i6_1),this.b6_1=-1,this.c6_1=null,this.d6_1=!1,this.e6_1=-1,this.f6_1=null}function ui(n){this.h6_1=n,this.i6_1=this.k6(),this.j6_1=0}function oi(){}function fi(n){this.n6_1=n,this.l6_1=null,this.m6_1=null,this.m6_1=this.n6_1.y6_1.v6_1}function si(){v=this;var n,t=(_i(0,0,n=de(ve(vi))),n);t.x6_1=!0,this.e7_1=t}function ci(){return null==v&&new si,v}function ai(n,t,r){this.d7_1=n,Tr.call(this,t,r),this.b7_1=null,this.c7_1=null}function hi(n){this.y6_1=n,Er.call(this)}function li(){return Yr(n=de(ve(vi))),vi.call(n),n.w6_1=Wr(),n;var n}function _i(n,t,r){return Kr(n,t,r),vi.call(r),r.w6_1=Wr(),r}function vi(){ci(),this.v6_1=null,this.x6_1=!1}function di(){d=this;var n=gi(0),t=n.y5_1;(t instanceof vi?t:pe()).j5(),this.f7_1=n}function gi(n){return function(n,t){return function(n,t,r){Jr(function(n,t){return _i(n,t,de(ve(vi)))}(n,t),r),wi.call(r)}(n,0,t),t}(n,de(ve(wi)))}function wi(){null==d&&new di}function bi(){}function pi(){}function mi(n){pi.call(this),this.k7_1=n}function ki(){qi.call(this)}function qi(){pi.call(this),this.m7_1=""}function yi(){if(!w){w=!0;var n="undefined"!=typeof process&&process.versions&&!!process.versions.node;g=n?new mi(process.stdout):new ki}}function Bi(){return n=de(ve(Ci)),Ci.call(n,""),n;var n}function Ci(n){this.o7_1=void 0!==n?n:""}function xi(n){var t=Li(n).toUpperCase();return t.length>1?n:ne(t,0)}function ji(n){return function(n){return 9<=n&&n<=13||28<=n&&n<=32||160===n||n>4096&&(5760===n||8192<=n&&n<=8202||8232===n||8233===n||8239===n||8287===n||12288===n)}(n)}function Pi(){b=this,this.q7_1=new RegExp("[\\\\^$*+?.()|[\\]{}]","g"),this.r7_1=new RegExp("[\\\\$]","g"),this.s7_1=new RegExp("\\$","g")}function Ii(){return null==b&&new Pi,b}function Si(n,t){Ii(),this.v7_1=n,this.w7_1=function(n){if(Ke(n,Di)){var t;switch(n.k()){case 0:t=Ht();break;case 1:t=Cr(Ke(n,Fi)?n.j(0):n.f().h());break;default:t=nt(n,gi(n.k()))}return t}return function(n){switch(n.k()){case 0:return Ht();case 1:return Cr(n.f().h());default:return n}}(nt(n,(r=de(ve(wi)),Jr(li(),r),wi.call(r),r)));var r}(t),this.x7_1=new RegExp(n,$n(t,"","gu",A,A,A,zi)),this.y7_1=null,this.z7_1=null}function zi(n){return n.d8_1}function Ti(n,t,r,i,e,u){return fr(n,t,r,i,e,u=u!==A&&u)}function Ei(n,t){return n-t|0}function Li(n){return String.fromCharCode(n)}function Ni(){p=this,this.e8_1=0,this.f8_1=65535,this.g8_1=55296,this.h8_1=56319,this.i8_1=56320,this.j8_1=57343,this.k8_1=55296,this.l8_1=57343,this.m8_1=2,this.n8_1=16}function Ai(){return null==p&&new Ni,p}function Mi(n){Ai(),this.h3_1=n}function Fi(){}function Di(){}function Oi(){}function Ri(){}function Hi(){}function $i(){}function Gi(){m=this}function Ui(n,t){null==m&&new Gi,this.p8_1=n,this.q8_1=t}function Vi(n){var t=null==n?null:ce(n);return null==t?"null":t}function Qi(n){return new Zi(n)}function Zi(n){this.t8_1=n,this.s8_1=0}function Yi(){return Ji(),k}function Wi(){return Ji(),q}function Ki(){return Ji(),y}function Xi(){return Ji(),B}function Ji(){x||(x=!0,k=new ArrayBuffer(8),q=new Float64Array(Yi()),new Float32Array(Yi()),y=new Int32Array(Yi()),Wi()[0]=-1,B=0!==Ki()[0]?1:0,C=1-Xi()|0)}function ne(n,t){var r;if(te(n)){var i,e=n.charCodeAt(t);if(Ai(),e<0?i=!0:(Ai(),i=e>65535),i)throw _u("Invalid Char code: "+e);r=Ue(e)}else r=n.y3(t);return r}function te(n){return"string"==typeof n}function re(n){return te(n)?n.length:n.x3()}function ie(n,t,r){return te(n)?n.substring(t,r):n.z3(t,r)}function ee(n){return ce(n)}function ue(n,t){var r;switch(typeof n){case"number":r="number"==typeof t?oe(n,t):t instanceof ke?oe(n,t.w8()):fe(n,t);break;case"string":case"boolean":r=fe(n,t);break;default:r=function(n,t){return n.a4(t)}(n,t)}return r}function oe(n,t){var r;if(n<t)r=-1;else if(n>t)r=1;else if(n===t){var i;if(0!==n)i=0;else{var e=1/n;i=e===1/t?0:e<0?-1:1}r=i}else r=n!=n?t!=t?0:1:-1;return r}function fe(n,t){return n<t?-1:n>t?1:0}function se(n){if(!("kotlinHashCodeValue$"in n)){var t=4294967296*Math.random()|0,r=new Object;r.value=t,r.enumerable=!1,Object.defineProperty(n,"kotlinHashCodeValue$",r)}return n.kotlinHashCodeValue$}function ce(n){return null==n?"null":function(n){return!!Ye(n)||Fn(n)}(n)?"[...]":n.toString()}function ae(n){if(null==n)return 0;var t;switch(typeof n){case"object":t="function"==typeof n.hashCode?n.hashCode():se(n);break;case"function":t=se(n);break;case"number":t=function(n){return Ji(),(0|n)===n?Ge(n):(Wi()[0]=n,Mn(Ki()[(Ji(),C)],31)+Ki()[Xi()]|0)}(n);break;case"boolean":t=n?1:0;break;default:t=he(String(n))}return t}function he(n){var t=0,r=0,i=n.length-1|0;if(r<=i)do{var e=r;r=r+1|0;var u=n.charCodeAt(e);t=Mn(t,31)+u|0}while(e!==i);return t}function le(n,t){return null==n?null==t:null!=t&&("object"==typeof n&&"function"==typeof n.equals?n.equals(t):n!=n?t!=t:"number"==typeof n&&"number"==typeof t?n===t&&(0!==n||1/n==1/t):n===t)}function _e(n,t){null!=Error.captureStackTrace?Error.captureStackTrace(n,t):n.stack=(new Error).stack}function ve(n){return n.prototype}function de(n){return Object.create(n)}function ge(n,t,r){Error.call(n),function(n,t,r){var i=eu(Object.getPrototypeOf(n));if(!(1&i)){var e;if(null==t){var u;if(null!==t){var o=null==r?null:r.toString();u=null==o?A:o}else u=A;e=u}else e=t;n.message=e}2&i||(n.cause=r),n.name=Object.getPrototypeOf(n).constructor.name}(n,t,r)}function we(n){var t;return null==n?function(){throw Eu()}():t=n,t}function be(){throw Nu()}function pe(){throw Mu()}function me(){j=this,this.x8_1=new ke(0,-2147483648),this.y8_1=new ke(-1,2147483647),this.z8_1=8,this.a9_1=64}function ke(n,t){null==j&&new me,gr.call(this),this.u8_1=n,this.v8_1=t}function qe(){return $e(),P}function ye(){return $e(),I}function Be(){return $e(),S}function Ce(){return $e(),T}function xe(){return $e(),E}function je(n,t){if($e(),Te(n,t))return 0;var r=Ne(n),i=Ne(t);return r&&!i?-1:!r&&i?1:Ne(Ie(n,t))?-1:1}function Pe(n,t){$e();var r=n.v8_1>>>16|0,i=65535&n.v8_1,e=n.u8_1>>>16|0,u=65535&n.u8_1,o=t.v8_1>>>16|0,f=65535&t.v8_1,s=t.u8_1>>>16|0,c=0,a=0,h=0,l=0;return c=(c=c+((a=(a=a+((h=(h=h+((l=l+(u+(65535&t.u8_1)|0)|0)>>>16|0)|0)+(e+s|0)|0)>>>16|0)|0)+(i+f|0)|0)>>>16|0)|0)+(r+o|0)|0,new ke((h&=65535)<<16|(l&=65535),(c&=65535)<<16|(a&=65535))}function Ie(n,t){return $e(),Pe(n,t.e9())}function Se(n,t){if($e(),Ae(n))return qe();if(Ae(t))return qe();if(Te(n,Ce()))return Me(t)?Ce():qe();if(Te(t,Ce()))return Me(n)?Ce():qe();if(Ne(n))return Ne(t)?Se(Fe(n),Fe(t)):Fe(Se(Fe(n),t));if(Ne(t))return Fe(Se(n,Fe(t)));if(De(n,xe())&&De(t,xe()))return Oe(ze(n)*ze(t));var r=n.v8_1>>>16|0,i=65535&n.v8_1,e=n.u8_1>>>16|0,u=65535&n.u8_1,o=t.v8_1>>>16|0,f=65535&t.v8_1,s=t.u8_1>>>16|0,c=65535&t.u8_1,a=0,h=0,l=0,_=0;return l=l+((_=_+Mn(u,c)|0)>>>16|0)|0,_&=65535,h=(h=h+((l=l+Mn(e,c)|0)>>>16|0)|0)+((l=(l&=65535)+Mn(u,s)|0)>>>16|0)|0,l&=65535,a=(a=(a=a+((h=h+Mn(i,c)|0)>>>16|0)|0)+((h=(h&=65535)+Mn(e,s)|0)>>>16|0)|0)+((h=(h&=65535)+Mn(u,f)|0)>>>16|0)|0,h&=65535,a=a+(((Mn(r,c)+Mn(i,s)|0)+Mn(e,f)|0)+Mn(u,o)|0)|0,new ke(l<<16|_,(a&=65535)<<16|h)}function ze(n){return $e(),4294967296*n.v8_1+function(n){return $e(),n.u8_1>=0?n.u8_1:4294967296+n.u8_1}(n)}function Te(n,t){return $e(),n.v8_1===t.v8_1&&n.u8_1===t.u8_1}function Ee(n,t){if($e(),t<2||36<t)throw mu("radix out of range: "+t);if(Ae(n))return"0";if(Ne(n)){if(Te(n,Ce())){var r=Le(t),i=n.d9(r),e=Ie(Se(i,r),n).g9();return Ee(i,t)+e.toString(t)}return"-"+Ee(Fe(n),t)}for(var u=2===t?31:t<=10?9:t<=21?7:t<=35?6:5,o=Oe(Math.pow(t,u)),f=n,s="";;){var c=f.d9(o),a=Ie(f,Se(c,o)).g9().toString(t);if(Ae(f=c))return a+s;for(;a.length<u;)a="0"+a;s=a+s}}function Le(n){return $e(),new ke(n,n<0?-1:0)}function Ne(n){return $e(),n.v8_1<0}function Ae(n){return $e(),0===n.v8_1&&0===n.u8_1}function Me(n){return $e(),!(1&~n.u8_1)}function Fe(n){return $e(),n.e9()}function De(n,t){return $e(),je(n,t)<0}function Oe(n){if($e(),(t=n)!=t)return qe();if(n<=-0x8000000000000000)return Ce();if(n+1>=0x8000000000000000)return $e(),z;if(n<0)return Fe(Oe(-n));var t,r=4294967296;return new ke(n%r|0,n/r|0)}function Re(n,t){return $e(),je(n,t)>0}function He(n,t){return $e(),je(n,t)>=0}function $e(){L||(L=!0,P=Le(0),I=Le(1),S=Le(-1),z=new ke(-1,2147483647),T=new ke(0,-2147483648),E=Le(16777216))}function Ge(n){return n instanceof ke?n.g9():function(n){return n>2147483647?2147483647:n<-2147483648?-2147483648:0|n}(n)}function Ue(n){var t;return t=function(n){return n<<16>>16}(Ge(n)),function(n){return 65535&n}(t)}function Ve(n,t){return new Zt(n,t)}function Qe(n,t,r,i){return Ze("class",n,t,r,i,null)}function Ze(n,t,r,i,e,u){return{kind:n,simpleName:t,associatedObjectKey:r,associatedObjects:i,suspendArity:e,$kClass$:A,iid:u}}function Ye(n){return Array.isArray(n)}function We(n,t,r,i,e,u,o,f){null!=i&&(n.prototype=Object.create(i.prototype),n.prototype.constructor=n);var s=r(t,u,o,null==f?[]:f);n.$metadata$=s,null!=e&&((null!=s.iid?n:n.prototype).$imask$=function(n){for(var t=1,r=[],i=0,e=n.length;i<e;){var u=n[i];i=i+1|0;var o=t,f=u.prototype.$imask$,s=null==f?u.$imask$:f;null!=s&&(r.push(s),o=s.length);var c=u.$metadata$.iid,a=null==c?null:(l=void 0,v=1<<(31&(h=c)),(l=new Int32Array(1+(h>>5)|0))[_=h>>5]=l[_]|v,l);null!=a&&(r.push(a),o=Math.max(o,a.length)),o>t&&(t=o)}var h,l,_,v;return function(n,t){for(var r=0,i=new Int32Array(n);r<n;){for(var e=r,u=0,o=0,f=t.length;o<f;){var s=t[o];o=o+1|0,e<s.length&&(u|=s[e])}i[e]=u,r=r+1|0}return i}(t,r)}(e))}function Ke(n,t){return function(n,t){var r=n.$imask$;return null!=r&&function(n,t){var r=t>>5;if(r>n.length)return!1;var i=1<<(31&t);return!(0===(n[r]&i))}(r,t)}(n,t.$metadata$.iid)}function Xe(n){return!!Ye(n)&&!n.$type$}function Je(n){var t;switch(typeof n){case"string":case"number":case"boolean":case"function":t=!0;break;default:t=n instanceof Object}return t}function nu(n){return"string"==typeof n||Ke(n,vr)}function tu(n,t,r,i){return Ze("interface",n,t,r,i,(null==N&&(N=0),N=ru()+1|0,ru()))}function ru(){if(null!=N)return N;!function(){throw Du("lateinit property iid has not been initialized")}()}function iu(n,t,r,i){return Ze("object",n,t,r,i,null)}function eu(n){var t=n.constructor,r=null==t?null:t.$metadata$,i=null==r?null:r.errorInfo;if(null!=i)return i;var e,u=0;if(uu(n,"message")&&(u|=1),uu(n,"cause")&&(u|=2),3!==u){var o=(e=n,Object.getPrototypeOf(e));o!=Error.prototype&&(u|=eu(o))}return null!=r&&(r.errorInfo=u),u}function uu(n,t){return n.hasOwnProperty(t)}function ou(n){return new Gr(n)}function fu(n,t,r){for(var i=new Int32Array(r),e=0,u=0,o=0,f=0,s=n.length;f<s;){var c=ne(n,f);f=f+1|0;var a=t[c];if(u|=(31&a)<<o,a<32){var h=e;e=h+1|0,i[h]=u,u=0,o=0}else o=o+5|0}return i}function su(n,t){for(var r=0,i=n.length-1|0,e=-1,u=0;r<=i;)if(t>(u=n[e=(r+i|0)/2|0]))r=e+1|0;else{if(t===u)return e;i=e-1|0}return e-(t<u?1:0)|0}function cu(){M=this;var n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",t=new Int32Array(128),r=0,i=re(n)-1|0;if(r<=i)do{var e=r;r=r+1|0,t[ne(n,e)]=e}while(r<=i);var u=fu("hCgBpCQGYHZH5BRpBPPPPPPRMP5BPPlCPP6BkEPPPPcPXPzBvBrB3BOiDoBHwD+E3DauCnFmBmB2D6E1BlBTiBmBlBP5BhBiBrBvBjBqBnBPRtBiCmCtBlB0BmB5BiB7BmBgEmChBZgCoEoGVpBSfRhBPqKQ2BwBYoFgB4CJuTiEvBuCuDrF5DgEgFlJ1DgFmBQtBsBRGsB+BPiBlD1EIjDPRPPPQPPPPPGQSQS/DxENVNU+B9zCwBwBPPCkDPNnBPqDYY1R8B7FkFgTgwGgwUwmBgKwBuBScmEP/BPPPPPPrBP8B7F1B/ErBqC6B7BiBmBfQsBUwCw/KwqIwLwETPcPjQgJxFgBlBsD",t,222),o=new Int32Array(u.length),f=0,s=u.length-1|0;if(f<=s)do{var c=f;f=f+1|0,o[c]=0===c?u[c]:o[c-1|0]+u[c]|0}while(f<=s);this.h9_1=o,this.i9_1=fu("aaMBXHYH5BRpBPPPPPPRMP5BPPlCPPzBDOOPPcPXPzBvBjB3BOhDmBBpB7DoDYxB+EiBP1DoExBkBQhBekBPmBgBhBctBiBMWOOXhCsBpBkBUV3Ba4BkB0DlCgBXgBtD4FSdBfPhBPpKP0BvBXjEQ2CGsT8DhBtCqDpFvD1D3E0IrD2EkBJrBDOBsB+BPiBlB1EIjDPPPPPPPPPPPGPPMNLsBNPNPKCvBvBPPCkDPBmBPhDXXgD4B6FzEgDguG9vUtkB9JcuBSckEP/BPPPPPPBPf4FrBjEhBpC3B5BKaWPrBOwCk/KsCuLqDHPbPxPsFtEaaqDL",t,222),this.j9_1=fu("GFjgggUHGGFFZZZmzpz5qB6s6020B60ptltB6smt2sB60mz22B1+vv+8BZZ5s2850BW5q1ymtB506smzBF3q1q1qB1q1q1+Bgii4wDTm74g3KiggxqM60q1q1Bq1o1q1BF1qlrqrBZ2q5wprBGFZWWZGHFsjiooLowgmOowjkwCkgoiIk7ligGogiioBkwkiYkzj2oNoi+sbkwj04DghhkQ8wgiYkgoioDsgnkwC4gikQ//v+85BkwvoIsgoyI4yguI0whiwEowri4CoghsJowgqYowgm4DkwgsY/nwnzPowhmYkg6wI8yggZswikwHgxgmIoxgqYkwgk4DkxgmIkgoioBsgssoBgzgyI8g9gL8g9kI0wgwJoxgkoC0wgioFkw/wI0w53iF4gioYowjmgBHGq1qkgwBF1q1q8qBHwghuIwghyKk0goQkwgoQk3goQHGFHkyg0pBgxj6IoinkxDswno7Ikwhz9Bo0gioB8z48Rwli0xN0mpjoX8w78pDwltoqKHFGGwwgsIHFH3q1q16BFHWFZ1q10q1B2qlwq1B1q10q1B2q1yq1B6q1gq1Biq1qhxBir1qp1Bqt1q1qB1g1q1+B//3q16B///q1qBH/qlqq9Bholqq9B1i00a1q10qD1op1HkwmigEigiy6Cptogq1Bixo1kDq7/j00B2qgoBWGFm1lz50B6s5q1+BGWhggzhwBFFhgk4//Bo2jigE8wguI8wguI8wgugUog1qoB4qjmIwwi2KgkYHHH4lBgiFWkgIWoghssMmz5smrBZ3q1y50B5sm7gzBtz1smzB5smz50BqzqtmzB5sgzqzBF2/9//5BowgoIwmnkzPkwgk4C8ys65BkgoqI0wgy6FghquZo2giY0ghiIsgh24B4ghsQ8QF/v1q1OFs0O8iCHHF1qggz/B8wg6Iznv+//B08QgohsjK0QGFk7hsQ4gB",t,222)}function au(){return null==M&&new cu,M}function hu(){F=this,this.k9_1=new Int32Array([170,186,688,704,736,837,890,7468,7544,7579,8305,8319,8336,8560,9424,11388,42652,42864,43e3,43868]),this.l9_1=new Int32Array([1,1,9,2,5,1,1,63,1,37,1,1,13,16,26,2,2,1,2,4])}function lu(){return null==F&&new hu,F}function _u(n){var t=function(n,t){return yu(n,t),vu.call(t),t}(n,de(ve(vu)));return _e(t,_u),t}function vu(){_e(this,vu)}function du(n){var t=function(n,t){return yu(n,t),gu.call(t),t}(n,de(ve(gu)));return _e(t,du),t}function gu(){_e(this,gu)}function wu(n){var t=function(n,t){return yu(n,t),bu.call(t),t}(n,de(ve(bu)));return _e(t,wu),t}function bu(){_e(this,bu)}function pu(n,t){return ge(t,n),ku.call(t),t}function mu(n){var t=pu(n,de(ve(ku)));return _e(t,mu),t}function ku(){_e(this,ku)}function qu(n){return function(n){ge(n),ku.call(n)}(n),Bu.call(n),n}function yu(n,t){return pu(n,t),Bu.call(t),t}function Bu(){_e(this,Bu)}function Cu(){var n,t=(qu(n=de(ve(ju))),ju.call(n),n);return _e(t,Cu),t}function xu(n){var t=function(n,t){return yu(n,t),ju.call(t),t}(n,de(ve(ju)));return _e(t,xu),t}function ju(){_e(this,ju)}function Pu(n){var t=function(n,t){return yu(n,t),Iu.call(t),t}(n,de(ve(Iu)));return _e(t,Pu),t}function Iu(){_e(this,Iu)}function Su(){var n,t=(qu(n=de(ve(Tu))),Tu.call(n),n);return _e(t,Su),t}function zu(n){var t=function(n,t){return yu(n,t),Tu.call(t),t}(n,de(ve(Tu)));return _e(t,zu),t}function Tu(){_e(this,Tu)}function Eu(){var n,t=(qu(n=de(ve(Lu))),Lu.call(n),n);return _e(t,Eu),t}function Lu(){_e(this,Lu)}function Nu(){var n,t=(qu(n=de(ve(Au))),Au.call(n),n);return _e(t,Nu),t}function Au(){_e(this,Au)}function Mu(){var n,t=(qu(n=de(ve(Fu))),Fu.call(n),n);return _e(t,Mu),t}function Fu(){_e(this,Fu)}function Du(n){var t=function(n,t){return yu(n,t),Ou.call(t),t}(n,de(ve(Ou)));return _e(t,Du),t}function Ou(){_e(this,Ou)}function Ru(n,t){var r,i=n.className;return(r="(^|.*\\s+)"+t+"($|\\s+.*)",function(n,t){return Si.call(t,n,Ht()),t}(r,de(ve(Si)))).a8(i)}function Hu(n,t){this.o9_1=n,this.p9_1=t}function $u(n){this.q9_1=n}function Gu(n,t,r){var i,e=Gf(),u=ro(),o=$f().ga(t),f=ro();if(0===re(r))i=Of();else{var s=n.ia_1,c=null==s?null:new $u(s).v9(r,"Copy reference to the clipboard");i=null==c?Of():c}return e.ja([u,o,f,i])}function Uu(n){n=n===A?null:n,this.ia_1=n}function Vu(n,t,r){to.call(this),this.ma_1=n,this.na_1=t,this.oa_1=r}function Qu(n,t){this.ra_1=n,this.sa_1=t}function Zu(n,t){to.call(this),this.va_1=n,this.wa_1=t}function Yu(n,t){to.call(this),this.xa_1=n,this.ya_1=t}function Wu(n){to.call(this),this.za_1=n}function Ku(n){to.call(this),this.ab_1=n}function Xu(n){to.call(this),this.bb_1=n}function Ju(n,t){to.call(this),this.cb_1=n,this.db_1=t}function no(n){to.call(this),this.eb_1=n}function to(){}function ro(){return so(),D}function io(){return so(),O}function eo(){return so(),R}function uo(){return so(),H}function oo(n){return so(),Gf().fb(us(fo),n)}function fo(n){return so(),n.gb(["invisible-text","text-for-copy"]),br()}function so(){$||($=!0,D=oo("`"),O=oo(" "),R=oo("("),H=oo(")"))}function co(n,t){to.call(this),this.hb_1=n,this.ib_1=t}function ao(n){to.call(this),this.jb_1=n}function ho(n,t){to.call(this),this.kb_1=n,this.lb_1=t}function lo(n){to.call(this),this.mb_1=n}function _o(n){to.call(this),this.nb_1=n}function vo(n){to.call(this),this.ob_1=n}function go(n,t,r){to.call(this),this.pb_1=n,this.qb_1=t,this.rb_1=r}function wo(n){to.call(this),this.sb_1=n}function bo(n){to.call(this),this.tb_1=n}function po(n){return n.xb_1.vb_1.k()}function mo(){if(Z)return br();Z=!0,G=new jo("Inputs",0,"Build configuration inputs"),U=new jo("ByMessage",1,"Problems grouped by message"),V=new jo("ByLocation",2,"Problems grouped by location"),Q=new jo("IncompatibleTasks",3,"Incompatible tasks")}function ko(n){Fc.call(this),this.yb_1=n}function qo(n){Fc.call(this),this.ac_1=n}function yo(n){Fc.call(this),this.bc_1=n}function Bo(n){Fc.call(this),this.cc_1=n}function Co(n){Po.call(this),this.dc_1=n}function xo(n,t,r,i,e,u,o,f){this.ec_1=n,this.fc_1=t,this.gc_1=r,this.hc_1=i,this.ic_1=e,this.jc_1=u,this.kc_1=o,this.lc_1=f}function jo(n,t,r){Ui.call(this,n,t),this.qc_1=r}function Po(){Oc.call(this)}function Io(n,t){var r=Hf(),i=us(Oo),e=Hf().y9(us(Ro),[]),u=function(n,t){var r,i=Hf(),e=us(Vo),u=Gf().ga("Learn more about the "),o=Yf();return i.y9(e,[u,o.fb(us((r=t,function(n){return n.bd(r.tc_1),br()})),t.sc_1),Gf().ga(".")])}(0,t.gc_1),o=Hf().y9(us(Ho),[zo(0,t)]),f=Hf();return r.y9(i,[e,u,o,f.y9(us($o),[No(0,Qo(),t.lc_1,po(t.jc_1)),No(0,Zo(),t.lc_1,po(t.hc_1)),No(0,Yo(),t.lc_1,po(t.ic_1)),No(0,Wo(),t.lc_1,po(t.kc_1))])])}function So(n,t){var r,i,e=Hf(),u=us(Go);switch(t.lc_1.q8_1){case 0:r=Mo(0,t.jc_1,((i=function(n){return new yo(n)}).callableName="<init>",i));break;case 3:r=Mo(0,t.kc_1,function(){var n=function(n){return new Bo(n)};return n.callableName="<init>",n}());break;case 1:r=Mo(0,t.hc_1,function(){var n=function(n){return new qo(n)};return n.callableName="<init>",n}());break;case 2:r=Mo(0,t.ic_1,function(){var n=function(n){return new ko(n)};return n.callableName="<init>",n}());break;default:be()}return e.y9(u,[r])}function zo(n,t){return Hf().ja([Lo(0,t),To(0,t)])}function To(n,t){for(var r=Hf(),i=t.fc_1,e=Or(),u=0,o=i.f();o.g();){var f=o.h(),s=u;u=s+1|0,Et(e,0===yr(s)?qr(Eo(Xo(),f)):Bt([Wf().ja([]),Eo(Xo(),f)]))}return r.ha(e)}function Eo(n,t){return Uf().ja([Uc(t)])}function Lo(n,t){return Rf().ja([$c().ka(t.ec_1)])}function No(n,t,r,i){var e,u,o;return Hf().y9(us((e=i,u=t,o=r,function(n){return n.t9("group-selector"),0===e?(n.t9("group-selector--disabled"),br()):u.equals(o)?(n.t9("group-selector--active"),br()):(n.u9(function(n){return function(t){return new Co(n)}}(u)),br()),br()})),[Gf().rc(t.qc_1,[Ao(0,i)])])}function Ao(n,t){return Gf().y9(us(Uo),[io(),eo(),Gf().ga(""+t),uo()])}function Mo(n,t,r){return function(n,t,r){var i,e=Hf(),u=Vf();return e.ja([u.ha(Ps(t,(i=r,function(n){var t,r=n.cd().ub_1;return r instanceof Zu?Kc(i,(Xo(),(t=function(n){return Fo(0,n)}).callableName="viewNode",t),n,r.va_1,r.wa_1,Rc()):r instanceof Yu?Kc(i,function(){var n=function(n){return Fo(0,n)};return n.callableName="viewNode",n}(Xo()),n,r.xa_1,r.ya_1,Hc()):r instanceof co?Kc(i,function(){var n=function(n){return Fo(0,n)};return n.callableName="viewNode",n}(Xo()),n,r.hb_1,r.ib_1,A,Ao(Xo(),n.cd().vb_1.k())):r instanceof Vu?Wc(i,n,r):Kc(i,function(){var n=function(n){return Fo(0,n)};return n.callableName="viewNode",n}(Xo()),n,r)})))])}(0,t.xb_1.uc().vc(),r)}function Fo(n,t){var r;return t instanceof ao?Vc((r=t,function(n){return n.ed("project "),n.fd(r.jb_1),br()})):t instanceof go?Vc(function(n){return function(t){return t.ed(n.pb_1+" "),t.fd(n.qb_1),t.ed(" of "),t.fd(n.rb_1),br()}}(t)):t instanceof vo?Vc(function(n){return function(t){return t.ed("system property "),t.fd(n.ob_1),br()}}(t)):t instanceof ho?Vc(function(n){return function(t){return t.ed("task "),t.fd(n.kb_1),t.ed(" of type "),t.fd(n.lb_1),br()}}(t)):t instanceof _o?Vc(function(n){return function(t){return t.ed("bean of type "),t.fd(n.nb_1),br()}}(t)):t instanceof wo?Vc(function(n){return function(t){return t.ed(n.sb_1),br()}}(t)):t instanceof bo?Vc(function(n){return function(t){return t.ed("class "),t.fd(n.tb_1),br()}}(t)):t instanceof no?Vc(function(n){return function(t){return t.ed(n.eb_1),br()}}(t)):t instanceof Wu?Uc(t.za_1):t instanceof Ju?Jo(t):Gf().ga(ce(t))}function Do(n){return n.t9("report-wrapper"),br()}function Oo(n){return n.t9("header"),br()}function Ro(n){return n.t9("gradle-logo"),br()}function Ho(n){return n.t9("title"),br()}function $o(n){return n.t9("groups"),br()}function Go(n){return n.t9("content"),br()}function Uo(n){return n.t9("group-selector__count"),br()}function Vo(n){return n.t9("learn-more"),br()}function Qo(){return mo(),G}function Zo(){return mo(),U}function Yo(){return mo(),V}function Wo(){return mo(),Q}function Ko(){Y=this}function Xo(){return null==Y&&new Ko,Y}function Jo(n){var t;return Yf().fb(us((t=n,function(n){return n.t9("documentation-button"),n.bd(t.cb_1),br()})),n.db_1)}function nf(n,t,r){this.kd_1=n,this.ld_1=t,this.md_1=r}function tf(n,t,r){this.nd_1=n,this.od_1=t,this.pd_1=r}function rf(n,t){for(var r=mf(n),i=t.trace,e=Rr(i.length),u=0,o=i.length;u<o;){var f,s=i[u];u=u+1|0,f=of(s),e.d(f)}return new nf(t,r,e)}function ef(n,t){var r,i=null==(r=t.kd_1.error)?null:ff(r);null==i||n.d(i)}function uf(n){return function(n,t,r){var i=null==n.error?null:new Zu(t,r);return null==i?new Yu(t,r):i}(n.kd_1,new Wu(n.ld_1),af(n.kd_1))}function of(n){var t;switch(n.kind){case"Project":t=new ao(n.path);break;case"Task":t=new ho(n.path,n.type);break;case"TaskPath":t=new lo(n.path);break;case"Bean":t=new _o(n.type);break;case"Field":t=new go("field",n.name,n.declaringType);break;case"InputProperty":t=new go("input property",n.name,n.task);break;case"OutputProperty":t=new go("output property",n.name,n.task);break;case"SystemProperty":t=new vo(n.name);break;case"PropertyUsage":t=new go("property",n.name,n.from);break;case"BuildLogic":t=new wo(n.location);break;case"BuildLogicClass":t=new bo(n.type);break;default:t=new no("Gradle runtime")}return t}function ff(n){var t=n.parts;if(null==t){var r=n.summary;return null==r?null:new Wu(mf(r))}for(var i=n.summary,e=null==i?null:mf(i),u=Or(),o=Qi(t);o.g();){var f=cf(o.h());null==f||u.d(f)}for(var s=$n(u,"\n"),c=Or(),a=Qi(t);a.g();){var h=sf(a.h());null==h||c.d(h)}return new Vu(e,s,c)}function sf(n){var t=cf(n);if(null==t)return null;var r,i,e=ot(new Rt(function(n,t,r,i){var e;return ut(or(n,["\r\n","\n","\r"],A,r=r!==A&&r,i=i===A?0:i),(e=n,function(n){return ur(e,n)}))}(t),!0,bf));return new Qu(e,(r=!(null==n.internalText),i=e.k(),r&&i>1?Cs():null))}function cf(n){var t=n.text;return null==t?n.internalText:t}function af(n){var t=n.documentationLink;return null==t?null:new Ju(t,"")}function hf(n,t){return new ds(lf(n,Ef().sd(t),Cs()))}function lf(n,t,r){return new js(n,function(n,t){var r,i=ut(Vn(n.o()),Nf);return ot(ut(new st(i,new _f(pf)),(r=t,function(n){return lf(n.v3(),n.w3().wd_1,r)})))}(t,1===Lf(t)?xs():Cs()),0===Lf(t)?Cs():r)}function _f(n){this.td_1=n}function vf(n){var t=Or(),r=n.ld_1,i=Un(r.ca_1).fa_1,e=ce(er(nu(i)?i:pe())),u=r.vd(function(n,t){var r;if(!(t>=0))throw _u(ce("Requested element count "+t+" is less than zero."));if(0===t)return Qn(n);if(Ke(n,Di)){var i=n.k()-t|0;if(i<=0)return Ct();if(1===i)return qr(function(n){if(Ke(n,Fi))return Jn(n);var t=n.f();if(!t.g())throw xu("Collection is empty.");for(var r=t.h();t.g();)r=t.h();return r}(n));if(r=Rr(),Ke(n,Fi)){if(Ke(n,bi)){var e=t,u=n.k();if(e<u)do{var o=e;e=e+1|0,r.d(n.j(o))}while(e<u)}else for(var f=n.l(t);f.g();){var s=f.h();r.d(s)}return r}}else r=Or();for(var c=0,a=n.f();a.g();){var h=a.h();c>=t?r.d(h):c=c+1|0}return xt(r)}(r.ca_1,1));return t.d(new co(new no(e),af(n.kd_1))),t.d(new Wu(u)),t.m(n.md_1),t.j5()}function df(n){var t=Or(),r=n.ld_1,i=r.vd(r.ca_1);return t.d(new Yu(new Wu(i),af(n.kd_1))),t.j5()}function gf(n){var t=Or();return t.d(uf(n)),t.m(n.md_1),ef(t,n),t.j5()}function wf(n){var t=Or();return t.m(new At(n.md_1)),t.d(uf(n)),ef(t,n),t.j5()}function bf(n){return re(n)>0}function pf(n,t){return function(n,t){return n===t?0:null==n?-1:null==t?1:ue(null!=n&&("string"==(i=typeof(r=n))||"boolean"===i||function(n){return"number"==typeof n||n instanceof ke}(r)||Ke(r,dr))?n:pe(),t);var r,i}(Vi(n.v3()),Vi(t.v3()))}function mf(n){var t;return Sf().qd((t=n,function(n){for(var r=t,i=0,e=r.length;i<e;){var u=r[i];i=i+1|0;var o=u.text;null==o||n.ed(o);var f=u.name;null==f||(n.fd(f),br())}return br()}))}function kf(n,t){return(0!==(r=n)?r.toString():"No")+" "+qf(t,n)+" "+yf(n)+" found";var r}function qf(n,t){return t<2?n:n+"s"}function yf(n){return n<=1?"was":"were"}function Bf(n,t){this.sc_1=n,this.tc_1=t}function Cf(n){jf.call(this),this.fa_1=n}function xf(n,t){jf.call(this),this.da_1=n,this.ea_1=t}function jf(){}function Pf(){this.dd_1=Or()}function If(){W=this}function Sf(){return null==W&&new If,W}function zf(n){Sf(),this.ca_1=n}function Tf(){K=this}function Ef(){return null==K&&new Tf,K}function Lf(n){return n.k()}function Nf(n){var t=n.j1(),r=n.i1();return _r(t,new Af(Ke(r,Ri)?r:pe()))}function Af(n){Ef(),this.wd_1=n}function Mf(n,t,r){var i;Df(t,n,r),i="Component mounted at #"+n.id+".",yi(),(yi(),g).j7(i)}function Ff(n){var t=document.getElementById(n);if(null==t)throw wu("'"+n+"' element missing");return t}function Df(n,t,r){var i,e,u;i=n.z9(r),e=t,u=function(n,t,r){return function(i){return Df(n,r,n.ba(i,t)),br()}}(n,r,t),_s(),e.innerHTML="",hs(e,i,u)}function Of(){return _s(),X}function Rf(){return _s(),J}function Hf(){return _s(),nn}function $f(){return _s(),tn}function Gf(){return _s(),rn}function Uf(){return _s(),en}function Vf(){return _s(),un}function Qf(){return _s(),on}function Zf(){return _s(),fn}function Yf(){return _s(),sn}function Wf(){return _s(),cn}function Kf(n){this.x9_1=n}function Xf(){an=this}function Jf(){return null==an&&new Xf,an}function ns(){hn=this,es.call(this)}function ts(){return null==hn&&new ns,hn}function rs(n,t,r,i){t=t===A?Ct():t,r=r===A?null:r,i=i===A?Ct():i,es.call(this),this.be_1=n,this.ce_1=t,this.de_1=r,this.ee_1=i}function is(){}function es(){Jf()}function us(n){_s();var t,r=Or();return n(new os((t=r,function(n){return t.d(n),br()}))),r}function os(n){this.r9_1=n}function fs(n,t){as.call(this),this.fe_1=n,this.ge_1=t}function ss(n){as.call(this),this.he_1=n}function cs(n,t){as.call(this),this.ie_1=n,this.je_1=t}function as(){}function hs(n,t,r){if(_s(),t instanceof rs)!function(n,t,r){var i=function(n,t,r){var i=n.createElement(t);return r(i),i}(we(n.ownerDocument),t,r);n.appendChild(i)}(n,t.be_1,(e=t,u=r,function(n){for(var t=e.ce_1.f();t.g();)ls(n,t.h(),u);var r=e.de_1;null==r||function(n,t){n.appendChild(we(n.ownerDocument).createTextNode(t))}(n,r);for(var i=e.ee_1.f();i.g();)hs(n,i.h(),u);return br()}));else if(t instanceof is){var i=t instanceof is?t:pe();hs(n,i.ke_1,function(n,t){return function(r){return n(t.le_1(r)),br()}}(r,i))}else if(le(t,ts()))return br();var e,u}function ls(n,t,r){var i,e;_s(),t instanceof cs?n.setAttribute(t.ie_1,t.je_1):t instanceof ss?function(n,t){for(var r=Or(),i=0,e=t.length;i<e;){var u=t[i];i=i+1|0,Ru(n,u)||r.d(u)}var o=r;if(!o.i()){var f=n.className,s=ce(er(nu(f)?f:pe())),c=Bi();c.p7(s),0!==re(s)&&c.p7(" "),Gn(o,c," "),n.className=c.toString()}}(n,[t.he_1]):t instanceof fs&&n.addEventListener(t.fe_1,(i=r,e=t,function(n){return n.stopPropagation(),i(e.ge_1(n)),br()}))}function _s(){ln||(ln=!0,X=ts(),new Kf("hr"),J=new Kf("h1"),new Kf("h2"),nn=new Kf("div"),new Kf("pre"),tn=new Kf("code"),rn=new Kf("span"),en=new Kf("small"),un=new Kf("ol"),on=new Kf("ul"),fn=new Kf("li"),sn=new Kf("a"),cn=new Kf("br"),new Kf("p"))}function vs(n){gs.call(this),this.ne_1=n}function ds(n){this.xb_1=n}function gs(){}function ws(n){return n.me(A,A,n.wb_1.ad())}function bs(){_n=this}function ps(){return null==_n&&new bs,_n}function ms(){if(gn)return br();gn=!0,vn=new ys("Collapsed",0),dn=new ys("Expanded",1)}function ks(n){Bs.call(this),this.ve_1=n}function qs(n,t,r){Bs.call(this),this.se_1=n,this.te_1=t,this.ue_1=r}function ys(n,t){Ui.call(this,n,t)}function Bs(){}function Cs(){return ms(),vn}function xs(){return ms(),dn}function js(n,t,r){t=t===A?Ct():t,r=r===A?Cs():r,this.ub_1=n,this.vb_1=t,this.wb_1=r}function Ps(n,t){return ot(ut(n,(r=t,function(n){return function(n,t){var r,i=n.cd(),e=Zf(),u=t(n),o=i.vb_1;r=null==(i.wb_1.equals(xs())&&!o.i()?o:null)?null:function(n,t){return Qf().ha(function(n,t){return Ps(n.vc(),t)}(n,t))}(n,t);var f=r;return e.ja([u,null==f?Of():f])}(n,r)})));var r}function Is(){if(xn)return br();xn=!0,kn=new Ss("ByMessage",0,"Messages"),qn=new Ss("ByGroup",1,"Group"),yn=new Ss("ByFileLocation",2,"File Locations"),Bn=new Ss("ByPluginLocation",3,"Plugin Locations"),Cn=new Ss("ByTaskLocation",4,"Task Locations")}function Ss(n,t,r){Ui.call(this,n,t),this.cf_1=r}function zs(n,t){this.df_1=n,this.ef_1=t}function Ts(n,t){this.ff_1=n,this.gf_1=t}function Es(n,t,r){ec();for(var i=Or(),e=li(),u=0,o=n.length;u<o;){var f=n[u];u=u+1|0;var s=f.locations;null==s||0===s.length?i.d(Os(f)):r(f,e)||i.d(Os(f))}var c=function(n,t,r){ec();for(var i=n.w1(),e=Rr(Tt(i,10)),u=i.f();u.g();){var o;o=u.h().t3_1,e.d(o)}var f=Zn(e);return t.i()||f.d(new js(new oc(Sf().rd("no location"),!0),t)),r>0&&f.d(Ns(r)),f}(e,i,t);return new ds(new js(new uc("text"),c))}function Ls(n){return ec(),t=n,function(n,r){var i,e=n.locations;if(null==e)i=null;else{for(var u=Or(),o=Qi(e);o.g();){var f=o.h();null!=t(f)&&u.d(f)}i=u}var s,c=i;if(null==c||c.i())s=!1;else{for(var a=c.f();a.g();){var h=a.h();As(r,we(t(h)),n,h)}s=!0}return s};var t}function Ns(n){return ec(),new js(new Wu(Sf().rd(n+" more problem"+(n>1?"s have":" has")+" been skipped")))}function As(n,t,r,i){ec();var e,u,o=n.v1(t);if(null==o){var f=Or(),s=_r(new js(new oc(Sf().qd((u=t,function(n){return n.fd(u),br()}))),f,xs()),f);n.h5(t,s),e=s}else e=o;e.u3_1.d(Os(r,i))}function Ms(n,t,r,i){var e,u;if(t=t===A?Or():t,r=r===A?li():r,i===A){var o=(ec(),mn);u=o+1|0,ec(),mn=u,e=o}else e=i;i=e,this.hf_1=n,this.if_1=t,this.jf_1=r,this.kf_1=i}function Fs(n,t){if(ec(),t.i())return null;for(var r,i=n,e=null,u=t.f();u.g();){var o=u.h();r=e;var f,s=i,c=o.ef_1+" ("+o.df_1+")",a=s.v1(c);if(null==a){var h=Or(),l=new Ms(new js(new oc(Sf().qd(Ys(o))),h,xs()),h);s.h5(c,l),f=l}else f=a;e=f,null==r||we(r).if_1.u(we(e).hf_1)||we(r).if_1.d(we(e).hf_1),i=we(e).jf_1}return e}function Ds(n,t){if(ec(),n.k()===t.length){var r;n:{var i=function(n,t){var r=t.length,i=Tt(n,10),e=Rr(Math.min(i,r)),u=0,o=n.f();t:for(;o.g();){var f,s=o.h();if(u>=r)break t;var c=u;u=c+1|0,f=_r(s,t[c]),e.d(f)}return e}(n,t);if(Ke(i,Di)&&i.i())r=!0;else{for(var e=i.f();e.g();){var u=e.h();if(u.t3_1.df_1!==u.u3_1.name||u.t3_1.ef_1!==u.u3_1.displayName){r=!1;break n}}r=!0}}return r}return!1}function Os(n,t,r){t=t===A?null:t,r=r!==A&&r,ec();var i=function(n,t,r){t=t===A?null:t,r=r!==A&&r,ec();var i=$s(function(n,t){return ec(),n&&null!=t.contextualLabel?we(t.contextualLabel):Rs(t)}(r,n),t).j5();return Hs(n,new Wu(i))}(n,t,r),e=function(n,t,r){r=r!==A&&r,ec();var i,e=n.problemDetails;if(null==e)i=null;else{var u,o=e[0].text,f=null==o?null:function(n,t,r,i){if(r=r!==A&&r,i=i===A?0:i,1===t.length){var e=t[0];if(0!==re(e))return function(n,t,r,i){sr(i);var e=0,u=rr(n,t,e,r);if(-1===u||1===i)return qr(ce(n));var o,f=i>0,s=Rr(f&&it(i,10));n:do{var c;if(c=ce(ie(n,e,u)),s.d(c),e=u+t.length|0,f&&s.k()===(i-1|0))break n;u=rr(n,t,e,r)}while(-1!==u);return o=ce(ie(n,e,re(n))),s.d(o),s}(n,e,r,i)}for(var u=function(n){return new ft(n)}(or(n,t,A,r,i)),o=Rr(Tt(u,10)),f=u.f();f.g();){var s;s=ur(n,f.h()),o.d(s)}return o}(o,["\n"]);if(null==f)u=null;else{for(var s=Rr(Tt(f,10)),c=f.f();c.g();){var a,h=c.h();a=Us(n)?Sf().qd(Ks(h)):Sf().rd(h),s.d(a)}u=s}var l,_=u;if(null==_)l=null;else{for(var v=Rr(Tt(_,10)),d=_.f();d.g();){var g;g=new js(new Wu(d.h())),v.d(g)}l=v}var w=null==l?null:Zn(l);i=null==w?Or():w}var b=i,p=null==b?Or():b;r||null==n.contextualLabel||p.d(new js(new Wu(Sf().rd(we(n.contextualLabel)))));var m=function(n){ec();var t=n.solutions;if(null==t||0===t.length)return null;for(var r=new Xu(Sf().rd("Solutions")),i=we(n.solutions),e=Rr(i.length),u=0,o=i.length;u<o;){var f,s=i[u];u=u+1|0,f=new js(new Ku(mf(s))),e.d(f)}return new js(r,e)}(n);null==m||p.d(m);var k,q=n.error,y=null==q?null:ff(q);if(null==y||p.d(new js(y)),t){var B=n.locations;k=!(null==B||0===B.length)}else k=!1;return k&&p.d(function(n){ec();var t,r=n.locations;if(null==r)t=null;else{for(var i=Rr(r.length),e=Qi(r);e.g();){var u,o=e.h();u=new js(new Wu(Sf().qd(Xs(o)))),i.d(u)}t=i}var f=t;return new js(new no("Locations"),null==f?Ct():f)}(n)),p}(n,null==t,r);return new js(i,e)}function Rs(n){return ec(),function(n){if(0===n.length)throw xu("Array is empty.");return n[Rn(n)]}(n.problemId).displayName}function Hs(n,t){var r;switch(ec(),n.severity){case"WARNING":var i=n.documentationLink;r=new Yu(t,null==i?null:new Ju(i,""));break;case"ERROR":var e=n.documentationLink;r=new Zu(t,null==e?null:new Ju(e,""));break;case"ADVICE":var u=n.documentationLink;r=new fc(t,null==u?null:new Ju(u,""));break;default:console.error("no severity "+n.severity),r=t}return r}function $s(n,t){t=t===A?null:t,ec();var r,i=new Pf;if(i.ed(n),null==t);else if(null!=t.line){var e=Gs(t);i.xd(e+(r=t,ec(),null==r.line||null==r.length?"":"-"+r.length),""+t.path+e),br()}else null!=t.taskPath?(i.fd(we(t.taskPath)),br()):null!=t.pluginId&&(i.fd(we(t.pluginId)),br());return i}function Gs(n){var t;if(ec(),null==n.line)t=null;else{var r,i=":"+n.line,e=n.column;t=i+(null==(r=null==e?null:":"+e)?"":r)}return null==t?"":t}function Us(n){var t;ec();var r,i=n.problemId;n:{for(var e=0,u=i.length;e<u;){var o=i[e];if(e=e+1|0,"compilation"===o.name){r=o;break n}}r=null}if(null!=r){var f,s=n.problemId;n:{for(var c=0,a=s.length;c<a;){var h=s[c];if(c=c+1|0,"java"===h.name){f=h;break n}}f=null}t=!(null==f)}else t=!1;return t}function Vs(n){return ec(),n.path}function Qs(n){return ec(),n.pluginId}function Zs(n){return ec(),n.taskPath}function Ys(n){return function(t){return t.ed(n.ef_1),t.fd(n.df_1),br()}}function Ws(n){return ec(),n.name}function Ks(n){return function(t){return t.xd(function(n,t,r,i){i=i!==A&&i;var e=new RegExp(Ii().t7(" "),i?"gui":"gu"),u=Ii().u7(" ");return n.replace(e,u)}(n),""),br()}}function Xs(n){return function(t){var r;return t.ed("- "),t.fd((r=n,ec(),null!=r.path?""+r.path+Gs(r):null!=r.taskPath?we(r.taskPath):null!=r.pluginId?we(r.pluginId):"<undefined>")),br()}}function Js(){return Is(),kn}function nc(){return Is(),qn}function tc(){return Is(),yn}function rc(){return Is(),Bn}function ic(){return Is(),Cn}function ec(){jn||(jn=!0,wn=Ls(Vs),bn=Ls(Qs),pn=Ls(Zs),mn=0)}function uc(n){sc.call(this),this.lf_1=n}function oc(n,t){t=t!==A&&t,sc.call(this),this.mf_1=n,this.nf_1=t}function fc(n,t){t=t===A?null:t,to.call(this),this.of_1=n,this.pf_1=t}function sc(){to.call(this)}function cc(n){Fc.call(this),this.qf_1=n}function ac(n){Fc.call(this),this.rf_1=n}function hc(n){Fc.call(this),this.sf_1=n}function lc(n){Fc.call(this),this.tf_1=n}function _c(n){Fc.call(this),this.uf_1=n}function vc(n){gc.call(this),this.vf_1=n}function dc(n,t,r,i,e,u,o,f,s,c){this.wf_1=n,this.xf_1=t,this.yf_1=r,this.zf_1=i,this.ag_1=e,this.bg_1=u,this.cg_1=o,this.dg_1=f,this.eg_1=s,this.fg_1=c}function gc(){Oc.call(this)}function wc(n,t){var r=Or();po(t.zf_1)>0&&r.d(yc(0,Js(),t.fg_1,t.eg_1)),po(t.ag_1)>0&&r.d(yc(0,nc(),t.fg_1,t.eg_1)),po(t.bg_1)>0&&r.d(yc(0,tc(),t.fg_1,t.eg_1)),po(t.cg_1)>0&&r.d(yc(0,rc(),t.fg_1,t.eg_1)),po(t.dg_1)>0&&r.d(yc(0,ic(),t.fg_1,t.eg_1));var i=Hf(),e=us(jc),u=Hf().y9(us(Pc),[]),o=function(n,t){var r,i=Hf(),e=us(Ec),u=Gf().ga("Learn more about "),o=Yf();return i.y9(e,[u,o.fb(us((r=t,function(n){return n.bd(r.tc_1),br()})),t.sc_1),Gf().ga(".")])}(0,t.yf_1),f=Hf().y9(us(Ic),[pc(0,t)]),s=Hf();return i.y9(e,[u,o,f,s.zd(us(Sc),r)])}function bc(n,t){var r,i,e=Hf(),u=us(zc);switch(t.fg_1.q8_1){case 0:r=Bc(0,t.zf_1,((i=function(n){return new cc(n)}).callableName="<init>",i));break;case 1:r=Bc(0,t.ag_1,function(){var n=function(n){return new ac(n)};return n.callableName="<init>",n}());break;case 2:r=Bc(0,t.bg_1,function(){var n=function(n){return new hc(n)};return n.callableName="<init>",n}());break;case 3:r=Bc(0,t.cg_1,function(){var n=function(n){return new lc(n)};return n.callableName="<init>",n}());break;case 4:r=Bc(0,t.dg_1,function(){var n=function(n){return new _c(n)};return n.callableName="<init>",n}());break;default:be()}return e.y9(u,[r])}function pc(n,t){return Hf().ja([qc(0,t),mc(0,t)])}function mc(n,t){for(var r=Hf(),i=t.xf_1,e=Or(),u=0,o=i.f();o.g();){var f=o.h(),s=u;u=s+1|0,Et(e,0===yr(s)?qr(kc(Nc(),f)):Bt([Wf().ja([]),kc(Nc(),f)]))}return r.ha(e)}function kc(n,t){return Uf().ja([Uc(t)])}function qc(n,t){return Rf().ja([$c().ka(t.wf_1)])}function yc(n,t,r,i){var e,u,o,f;return Hf().y9(us((e=i,u=t,o=r,function(n){return n.t9("group-selector"),0===e?(n.t9("group-selector--disabled"),br()):u.equals(o)?(n.t9("group-selector--active"),br()):(n.u9(function(n){return function(t){return new vc(n)}}(u)),br()),br()})),[Gf().rc(t.cf_1,[(f=i,Gf().y9(us(Tc),[io(),eo(),Gf().ga(""+f),uo()]))])])}function Bc(n,t,r){return function(n,t,r){var i,e=Hf(),u=Vf();return e.ja([u.ha(Ps(t,(i=r,function(n){return function(n,t,r,i){var e,u;return t instanceof uc?Uc(Sf().rd(t.lf_1)):t instanceof oc?Hf().y9(us((u=t,function(n){return u.nf_1&&(n.t9("uncategorized"),br()),br()})),[Hf().ja([Qc(r,i),Uc(t.mf_1)])]):t instanceof Vu?Wc(i,r,t):t instanceof Wu?Uc(t.za_1):t instanceof Ku?Hf().ja([(sa(),Tn),Uc(t.ab_1)]):t instanceof Xu?Hf().ja([Qc(r,i),Uc(t.bb_1)]):t instanceof Zu?Kc(i,((e=function(n){return Cc(0,n)}).callableName="viewIt",e),r,t.va_1,t.wa_1,Rc()):t instanceof fc?Kc(i,function(){var n=function(n){return Cc(0,n)};return n.callableName="viewIt",n}(),r,t.of_1,t.pf_1,(sa(),Sn)):t instanceof Yu?Kc(i,function(){var n=function(n){return Cc(0,n)};return n.callableName="viewIt",n}(),r,t.xa_1,t.ya_1,Hc()):t instanceof no?Hf().ja([Qc(r,i),Uc(Sf().rd(t.eb_1))]):Gf().ga("Unknown node type viewNode: "+t)}(Nc(),n.cd().ub_1,n,i)})))])}(0,t.xb_1.uc().vc(),r)}function Cc(n,t){var r;if(t instanceof Ju)r=Jo(t);else if(t instanceof no)r=Uc(Sf().rd(t.eb_1));else if(t instanceof Wu)r=Uc(t.za_1);else{var i="Unknown node type viewIt: "+t;console.error(i),r=Gf().ga(i)}return r}function xc(n){return n.t9("report-wrapper"),br()}function jc(n){return n.t9("header"),br()}function Pc(n){return n.t9("gradle-logo"),br()}function Ic(n){return n.t9("title"),br()}function Sc(n){return n.t9("groups"),br()}function zc(n){return n.t9("content"),br()}function Tc(n){return n.t9("group-selector__count"),br()}function Ec(n){return n.t9("learn-more"),br()}function Lc(){Pn=this,document.title="Gradle - Problems Report"}function Nc(){return null==Pn&&new Lc,Pn}function Ac(n,t,r){return n.pe(t.zb().oe(),r)}function Mc(n){Oc.call(this),this.hd_1=n}function Fc(){Oc.call(this)}function Dc(n,t){Oc.call(this),this.wc_1=n,this.xc_1=t}function Oc(){}function Rc(){return sa(),In}function Hc(){return sa(),zn}function $c(){return sa(),En}function Gc(){return sa(),Ln}function Uc(n){return sa(),Gc().ka(n)}function Vc(n){return sa(),Gc().ka(Sf().qd(n))}function Qc(n,t){return sa(),n.cd().ye()?Xc(n,t):function(n){return sa(),Gf().fb(us(oa),Jc(n))}(n)}function Zc(n,t,r,i){var e,u,o;return sa(),Gf().fb(us((e=r,u=t,o=i,function(n){return n.t9("java-exception-part-toggle"),n.u9(function(n,t){return function(r){return new Dc(n,t())}}(u,o)),n.s9("Click to "+function(n){var t;switch(sa(),n.q8_1){case 0:t="show";break;case 1:t="hide";break;default:be()}return t}(e)),br()})),"("+n+" internal "+qf("line",n)+" "+function(n){var t;switch(sa(),n.q8_1){case 0:t="hidden";break;case 1:t="shown";break;default:be()}return t}(r)+")")}function Yc(n,t){t=t===A?Of():t,sa();for(var r=Qf(),i=Rr(Tt(n,10)),e=0,u=n.f();u.g();){var o,f=e;e=f+1|0,s=u.h(),c=(c=0===yr(f)?t:Of())===A?Of():c,sa(),o=Zf().ja([$f().ga(s),c]),i.d(o)}var s,c;return r.ha(i)}function Wc(n,t,r){sa();var i,e,u,o=Hf(),f=Xc(t,n),s=Gf().ga("Exception"),c=Gf().ja([(sa(),Nn).v9(r.na_1,"Copy exception to the clipboard")]),a=null==r.ma_1?null:Gf().ga(" "),h=null==a?Of():a,l=r.ma_1,_=null==l?null:Uc(l),v=null==_?Of():_;switch(t.cd().wb_1.q8_1){case 0:i=Of();break;case 1:i=function(n,t){sa();for(var r=Hf(),i=us(fa),e=n.oa_1,u=Rr(Tt(e,10)),o=0,f=e.f();f.g();){var s,c=f.h(),a=o;o=a+1|0;var h,l=yr(a);if(null!=c.sa_1){var _,v=Zc(c.ra_1.k(),l,c.sa_1,t),d=c.sa_1;switch(null==d?-1:d.q8_1){case 0:_=Yc(Kn(c.ra_1,1),v);break;case 1:_=Yc(c.ra_1,v);break;default:be()}h=_}else h=Yc(c.ra_1);s=h,u.d(s)}return r.zd(i,u)}(r,(e=n,u=t,function(){return e(new vs(u))}));break;default:be()}return o.ja([f,s,c,h,v,i])}function Kc(n,t,r,i,e,u,o){e=e===A?null:e,u=u===A?Of():u,o=o===A?Of():o,sa();var f=Hf(),s=Qc(r,n),c=t(i),a=null==e?null:t(e);return f.ja([s,u,c,null==a?Of():a,o])}function Xc(n,t){var r,i;return sa(),Gf().fb(us((r=n,i=t,function(n){return n.gb(["invisible-text","tree-btn"]),r.cd().wb_1===Cs()&&(n.t9("collapsed"),br()),r.cd().wb_1===xs()&&(n.t9("expanded"),br()),n.s9("Click to "+function(n){var t;switch(sa(),n.q8_1){case 0:t="expand";break;case 1:t="collapse";break;default:be()}return t}(r.cd().wb_1)),n.u9(function(n,t){return function(r){return n(new vs(t))}}(i,r)),br()})),Jc(n))}function Jc(n){return sa(),function(n,t){var r;if(!(t>=0))throw _u(ce("Count 'n' must be non-negative, but was "+t+"."));switch(t){case 0:r="";break;case 1:r=ce(n);break;default:var i="";if(0!==re(n))for(var e=ce(n),u=t;1&~u||(i+=e),0!=(u=u>>>1|0);)e+=e;return i}return r}("    ",n.we()-1|0)+"- "}function na(n){return sa(),n.gb(["invisible-text","error-icon"]),br()}function ta(n){return sa(),n.gb(["invisible-text","advice-icon"]),br()}function ra(n){return sa(),n.gb(["invisible-text","warning-icon"]),br()}function ia(n){return sa(),n.gb(["invisible-text","enum-icon"]),br()}function ea(n){return sa(),new Mc(n)}function ua(n){return sa(),new Mc(n)}function oa(n){return sa(),n.gb(["invisible-text","leaf-icon"]),br()}function fa(n){return sa(),n.t9("java-exception"),br()}function sa(){if(!An){An=!0;var n=Gf();In=n.fb(us(na),"[error] ");var t=Gf();Sn=t.fb(us(ta),"[advice] ");var r=Gf();zn=r.fb(us(ra),"[warn]  ");var i=Gf();Tn=i.fb(us(ia),"[enum]  "),En=new Uu,Ln=new Uu(ea),Nn=new $u(ua)}}return We(tt,A,Qe),We(ft,A,Qe),We(st,A,Qe),We(Di,"Collection",tu),We(ct,"AbstractCollection",Qe,A,[Di]),We(at,"IteratorImpl",Qe),We(ht,"ListIteratorImpl",Qe,at),We(lt,"Companion",iu),We(Fi,"List",tu,A,[Di]),We(vt,"AbstractList",Qe,ct,[ct,Fi]),We(dt,A,Qe),We(bt,"Companion",iu),We(mt,A,Qe,ct),We(Ri,"Map",tu),We(kt,"AbstractMap",Qe,A,[Ri]),We(qt,"Companion",iu),We(bi,"RandomAccess",tu),We(Pt,"EmptyList",iu,A,[Fi,bi]),We(It,"ArrayAsCollection",Qe,A,[Di]),We(St,"EmptyIterator",iu),We(Lt,"IntIterator",Qe),We(Nt,A,Qe),We(At,"ReversedListReadOnly",Qe,vt),We(Mt,A,Qe),We(Ft,"TransformingSequence",Qe),We(Ot,A,Qe),We(Rt,"FilteringSequence",Qe),We($i,"Set",tu,A,[Di]),We($t,"EmptySet",iu,A,[$i]),We(Vt,"Companion",iu),We(Xt,"IntProgression",Qe),We(Zt,"IntRange",Qe,Xt),We(Yt,"IntProgressionIterator",Qe,Lt),We(Wt,"Companion",iu),We(ar,A,Qe),We(hr,"DelimitedRangesSequence",Qe),We(lr,"Pair",Qe),We(vr,"CharSequence",tu),We(dr,"Comparable",tu),We(gr,"Number",Qe),We(wr,"Unit",iu),We(pr,"IntCompanionObject",iu),We(xr,"AbstractMutableCollection",Qe,ct,[ct,Di]),We(jr,"IteratorImpl",Qe),We(Pr,"ListIteratorImpl",Qe,jr),We(Ir,"AbstractMutableList",Qe,xr,[xr,Fi,Di]),We(Sr,A,Qe),We(zr,A,Qe),We(Oi,"Entry",tu),We(Hi,"MutableEntry",tu,A,[Oi]),We(Tr,"SimpleEntry",Qe,A,[Hi]),We(Mr,"AbstractMutableSet",Qe,xr,[xr,$i,Di]),We(Er,"AbstractEntrySet",Qe,Mr),We(Lr,A,Qe,Mr),We(Nr,A,Qe,xr),We(Ar,"AbstractMutableMap",Qe,kt,[kt,Ri]),We(Fr,"Companion",iu),We(Gr,"ArrayList",Qe,Ir,[Ir,Fi,Di,bi]),We(Qr,"HashCode",iu),We(Zr,"EntrySet",Qe,Er),We(Xr,"HashMap",Qe,Ar,[Ar,Ri]),We(ni,"HashSet",Qe,Mr,[Mr,$i,Di]),We(ei,A,Qe),We(oi,"InternalMap",tu),We(ui,"InternalHashCodeMap",Qe,A,[oi]),We(fi,"EntryIterator",Qe),We(si,"Companion",iu),We(ai,"ChainEntry",Qe,Tr),We(hi,"EntrySet",Qe,Er),We(vi,"LinkedHashMap",Qe,Xr,[Xr,Ri]),We(di,"Companion",iu),We(wi,"LinkedHashSet",Qe,ni,[ni,$i,Di]),We(pi,"BaseOutput",Qe),We(mi,"NodeJsOutput",Qe,pi),We(qi,"BufferedOutput",Qe,pi),We(ki,"BufferedOutputToConsoleLog",Qe,qi),We(Ci,"StringBuilder",Qe,A,[vr]),We(Pi,"Companion",iu),We(Si,"Regex",Qe),We(Ni,"Companion",iu),We(Mi,"Char",Qe,A,[dr]),We(Gi,"Companion",iu),We(Ui,"Enum",Qe,A,[dr]),We(Zi,A,Qe),We(me,"Companion",iu),We(ke,"Long",Qe,gr,[gr,dr]),We(cu,"Letter",iu),We(hu,"OtherLowercase",iu),We(ku,"Exception",Qe,Error),We(Bu,"RuntimeException",Qe,ku),We(vu,"IllegalArgumentException",Qe,Bu),We(gu,"IndexOutOfBoundsException",Qe,Bu),We(bu,"IllegalStateException",Qe,Bu),We(ju,"NoSuchElementException",Qe,Bu),We(Iu,"ArithmeticException",Qe,Bu),We(Tu,"UnsupportedOperationException",Qe,Bu),We(Lu,"NullPointerException",Qe,Bu),We(Au,"NoWhenBranchMatchedException",Qe,Bu),We(Fu,"ClassCastException",Qe,Bu),We(Ou,"UninitializedPropertyAccessException",Qe,Bu),We(Hu,"Model",Qe),We($u,"CopyButtonComponent",Qe),We(Uu,"PrettyTextComponent",Qe),We(to,"ProblemNode",Qe),We(Vu,"Exception",Qe,to),We(Qu,"StackTracePart",Qe),We(Zu,"Error",Qe,to),We(Yu,"Warning",Qe,to),We(Wu,"Message",Qe,to),We(Ku,"ListElement",Qe,to),We(Xu,"TreeNode",Qe,to),We(Ju,"Link",Qe,to),We(no,"Label",Qe,to),We(co,"Info",Qe,to),We(ao,"Project",Qe,to),We(ho,"Task",Qe,to),We(lo,"TaskPath",Qe,to),We(_o,"Bean",Qe,to),We(vo,"SystemProperty",Qe,to),We(go,"Property",Qe,to),We(wo,"BuildLogic",Qe,to),We(bo,"BuildLogicClass",Qe,to),We(Oc,"BaseIntent",Qe),We(Fc,"TreeIntent",Qe,Oc),We(ko,"TaskTreeIntent",Qe,Fc),We(qo,"MessageTreeIntent",Qe,Fc),We(yo,"InputTreeIntent",Qe,Fc),We(Bo,"IncompatibleTaskTreeIntent",Qe,Fc),We(Po,"Intent",Qe,Oc),We(Co,"SetTab",Qe,Po),We(xo,"Model",Qe),We(jo,"Tab",Qe,Ui),We(Ko,"ConfigurationCacheReportPage",iu),We(nf,"ImportedProblem",Qe),We(tf,"ImportedDiagnostics",Qe),We(_f,"sam$kotlin_Comparator$0",Qe),We(Bf,"LearnMore",Qe),We(jf,"Fragment",Qe),We(Cf,"Text",Qe,jf),We(xf,"Reference",Qe,jf),We(Pf,"Builder",Qe),We(If,"Companion",iu),We(zf,"PrettyText",Qe),We(Tf,"Companion",iu),We(Af,"Trie",Qe),We(Kf,"ViewFactory",Qe),We(Xf,"Companion",iu),We(es,"View",Qe),We(ns,"Empty",iu,es),We(rs,"Element",Qe,es),We(is,"MappedView",Qe,es),We(os,"Attributes",Qe),We(as,"Attribute",Qe),We(fs,"OnEvent",Qe,as),We(ss,"ClassName",Qe,as),We(cs,"Named",Qe,as),We(gs,"Intent",Qe),We(vs,"Toggle",Qe,gs),We(ds,"Model",Qe),We(bs,"TreeView",iu),We(Bs,"Focus",Qe),We(ks,"Original",Qe,Bs),We(qs,"Child",Qe,Bs),We(ys,"ViewState",Qe,Ui),We(js,"Tree",Qe),We(Ss,"Tab",Qe,Ui),We(zs,"ProblemIdElement",Qe),We(Ts,"ProblemSummary",Qe),We(Ms,"ProblemNodeGroup",Qe),We(sc,"ProblemApiNode",Qe,to),We(uc,"Text",Qe,sc),We(oc,"ProblemIdNode",Qe,sc),We(fc,"Advice",Qe,to),We(cc,"MessageTreeIntent",Qe,Fc),We(ac,"ProblemIdTreeIntent",Qe,Fc),We(hc,"FileLocationTreeIntent",Qe,Fc),We(lc,"PluginLocationTreeIntent",Qe,Fc),We(_c,"TaskLocationTreeIntent",Qe,Fc),We(gc,"Intent",Qe,Oc),We(vc,"SetTab",Qe,gc),We(dc,"Model",Qe),We(Lc,"ProblemsReportPage",iu),We(Mc,"Copy",Qe,Oc),We(Dc,"ToggleStackTracePart",Qe,Oc),ve(tt).f=function(){return this.n_1.f()},ve(ft).f=function(){return this.r_1.f()},ve(st).f=function(){var n,t,r=function(n,t){for(var r=n.f();r.g();){var i=r.h();t.d(i)}return t}(this.s_1,Or());return n=r,t=this.t_1,function(n,t){if(n.k()<=1)return br();var r=Br(n);!function(n,t){if(function(){if(null!=l)return l;l=!1;var n=[],t=0;if(t<600)do{var r=t;t=t+1|0,n.push(r)}while(t<600);var i=Vr;n.sort(i);var e=1,u=n.length;if(e<u)do{var o=e;e=e+1|0;var f=n[o-1|0],s=n[o];if((3&f)==(3&s)&&f>=s)return!1}while(e<u);return l=!0,!0}()){var r=(i=t,function(n,t){return i.compare(n,t)});n.sort(r)}else!function(n,t,r,i){var e=n.length,u=function(n){var t=0,r=n.length-1|0;if(t<=r)do{var i=t;t=t+1|0,n[i]=null}while(i!==r);return n}(Array(e)),o=Ur(n,u,0,r,i);if(o!==n){var f=0;if(f<=r)do{var s=f;f=f+1|0,n[s]=o[s]}while(s!==r)}}(n,0,Rn(n),t);var i}(r,t);var i=0,e=r.length;if(i<e)do{var u=i;i=i+1|0,n.f4(u,r[u])}while(i<e)}(n,t),r.f()},ve(ct).u=function(n){var t;n:if(Ke(this,Di)&&this.i())t=!1;else{for(var r=this.f();r.g();)if(le(r.h(),n)){t=!0;break n}t=!1}return t},ve(ct).v=function(n){var t;n:if(Ke(n,Di)&&n.i())t=!0;else{for(var r=n.f();r.g();){var i=r.h();if(!this.u(i)){t=!1;break n}}t=!0}return t},ve(ct).i=function(){return 0===this.k()},ve(ct).toString=function(){return $n(this,", ","[","]",A,A,(n=this,function(t){return t===n?"(this Collection)":Vi(t)}));var n},ve(ct).toArray=function(){return kr(this)},ve(at).g=function(){return this.w_1<this.x_1.k()},ve(at).h=function(){if(!this.g())throw Cu();var n=this.w_1;return this.w_1=n+1|0,this.x_1.j(n)},ve(ht).c1=function(){return this.w_1>0},ve(ht).d1=function(){if(!this.c1())throw Cu();return this.w_1=this.w_1-1|0,this.a1_1.j(this.w_1)},ve(lt).e1=function(n,t){if(n<0||n>=t)throw du("index: "+n+", size: "+t)},ve(lt).b1=function(n,t){if(n<0||n>t)throw du("index: "+n+", size: "+t)},ve(lt).f1=function(n){for(var t=1,r=n.f();r.g();){var i=r.h(),e=Mn(31,t),u=null==i?null:ae(i);t=e+(null==u?0:u)|0}return t},ve(lt).g1=function(n,t){if(n.k()!==t.k())return!1;for(var r=t.f(),i=n.f();i.g();)if(!le(i.h(),r.h()))return!1;return!0},ve(vt).f=function(){return new at(this)},ve(vt).l=function(n){return new ht(this,n)},ve(vt).equals=function(n){return n===this||!(null==n||!Ke(n,Fi))&&_t().g1(this,n)},ve(vt).hashCode=function(){return _t().f1(this)},ve(dt).g=function(){return this.h1_1.g()},ve(dt).h=function(){return this.h1_1.h().i1()},ve(bt).k1=function(n){var t=n.j1(),r=null==t?null:ae(t),i=null==r?0:r,e=n.i1(),u=null==e?null:ae(e);return i^(null==u?0:u)},ve(bt).l1=function(n){return Vi(n.j1())+"="+Vi(n.i1())},ve(bt).m1=function(n,t){return!(null==t||!Ke(t,Oi))&&!!le(n.j1(),t.j1())&&le(n.i1(),t.i1())},ve(mt).r1=function(n){return this.q1_1.s1(n)},ve(mt).u=function(n){return!(null!=n&&!Je(n))&&this.r1(null==n||Je(n)?n:pe())},ve(mt).f=function(){return new dt(this.q1_1.o().f())},ve(mt).k=function(){return this.q1_1.k()},ve(kt).t1=function(n){return!(null==wt(this,n))},ve(kt).s1=function(n){var t;n:{var r=this.o();if(Ke(r,Di)&&r.i())t=!1;else{for(var i=r.f();i.g();)if(le(i.h().i1(),n)){t=!0;break n}t=!1}}return t},ve(kt).u1=function(n){if(null==n||!Ke(n,Oi))return!1;var t=n.j1(),r=n.i1(),i=(Ke(this,Ri)?this:pe()).v1(t);return!(!le(r,i)||null==i&&!(Ke(this,Ri)?this:pe()).t1(t))},ve(kt).equals=function(n){if(n===this)return!0;if(null==n||!Ke(n,Ri))return!1;if(this.k()!==n.k())return!1;var t;n:{var r=n.o();if(Ke(r,Di)&&r.i())t=!0;else{for(var i=r.f();i.g();){var e=i.h();if(!this.u1(e)){t=!1;break n}}t=!0}}return t},ve(kt).v1=function(n){var t=wt(this,n);return null==t?null:t.i1()},ve(kt).hashCode=function(){return ae(this.o())},ve(kt).i=function(){return 0===this.k()},ve(kt).k=function(){return this.o().k()},ve(kt).toString=function(){var n;return $n(this.o(),", ","{","}",A,A,(n=this,function(t){return n.p1(t)}))},ve(kt).p1=function(n){return gt(this,n.j1())+"="+gt(this,n.i1())},ve(kt).w1=function(){return null==this.o1_1&&(this.o1_1=new mt(this)),we(this.o1_1)},ve(qt).x1=function(n){for(var t=0,r=n.f();r.g();){var i=r.h(),e=t,u=null==i?null:ae(i);t=e+(null==u?0:u)|0}return t},ve(qt).y1=function(n,t){return n.k()===t.k()&&n.v(t)},ve(Pt).equals=function(n){return!(null==n||!Ke(n,Fi))&&n.i()},ve(Pt).hashCode=function(){return 1},ve(Pt).toString=function(){return"[]"},ve(Pt).k=function(){return 0},ve(Pt).i=function(){return!0},ve(Pt).a2=function(n){return n.i()},ve(Pt).v=function(n){return this.a2(n)},ve(Pt).j=function(n){throw du("Empty list doesn't contain element at index "+n+".")},ve(Pt).f=function(){return zt()},ve(Pt).l=function(n){if(0!==n)throw du("Index: "+n);return zt()},ve(It).k=function(){return this.b2_1.length},ve(It).i=function(){return 0===this.b2_1.length},ve(It).d2=function(n){return function(n,t){return Hn(n,t)>=0}(this.b2_1,n)},ve(It).e2=function(n){var t;n:if(Ke(n,Di)&&n.i())t=!0;else{for(var r=n.f();r.g();){var i=r.h();if(!this.d2(i)){t=!1;break n}}t=!0}return t},ve(It).v=function(n){return this.e2(n)},ve(It).f=function(){return Qi(this.b2_1)},ve(St).g=function(){return!1},ve(St).c1=function(){return!1},ve(St).h=function(){throw Cu()},ve(St).d1=function(){throw Cu()},ve(Lt).h=function(){return this.f2()},ve(Nt).g=function(){return this.g2_1.c1()},ve(Nt).c1=function(){return this.g2_1.g()},ve(Nt).h=function(){return this.g2_1.d1()},ve(Nt).d1=function(){return this.g2_1.h()},ve(At).k=function(){return this.i2_1.k()},ve(At).j=function(n){return this.i2_1.j(function(n,t){if(!(0<=t&&t<=jt(n)))throw du("Element index "+t+" must be in range ["+Ve(0,jt(n))+"].");return jt(n)-t|0}(this,n))},ve(At).f=function(){return this.l(0)},ve(At).l=function(n){return new Nt(this,n)},ve(Mt).h=function(){return this.k2_1.m2_1(this.j2_1.h())},ve(Mt).g=function(){return this.j2_1.g()},ve(Ft).f=function(){return new Mt(this)},ve(Ot).h=function(){if(-1===this.o2_1&&Dt(this),0===this.o2_1)throw Cu();var n=this.p2_1;return this.p2_1=null,this.o2_1=-1,null==n||Je(n)?n:pe()},ve(Ot).g=function(){return-1===this.o2_1&&Dt(this),1===this.o2_1},ve(Rt).f=function(){return new Ot(this)},ve($t).equals=function(n){return!(null==n||!Ke(n,$i))&&n.i()},ve($t).hashCode=function(){return 0},ve($t).toString=function(){return"[]"},ve($t).k=function(){return 0},ve($t).i=function(){return!0},ve($t).a2=function(n){return n.i()},ve($t).v=function(n){return this.a2(n)},ve($t).f=function(){return zt()},ve(Zt).y2=function(){return this.z2_1},ve(Zt).c3=function(){return this.a3_1},ve(Zt).i=function(){return this.z2_1>this.a3_1},ve(Zt).equals=function(n){return n instanceof Zt&&(!(!this.i()||!n.i())||this.z2_1===n.z2_1&&this.a3_1===n.a3_1)},ve(Zt).hashCode=function(){return this.i()?-1:Mn(31,this.z2_1)+this.a3_1|0},ve(Zt).toString=function(){return this.z2_1+".."+this.a3_1},ve(Yt).g=function(){return this.f3_1},ve(Yt).f2=function(){var n=this.g3_1;if(n===this.e3_1){if(!this.f3_1)throw Cu();this.f3_1=!1}else this.g3_1=this.g3_1+this.d3_1|0;return n},ve(Wt).q=function(n,t,r){return new Xt(n,t,r)},ve(Xt).f=function(){return new Yt(this.z2_1,this.a3_1,this.b3_1)},ve(Xt).i=function(){return this.b3_1>0?this.z2_1>this.a3_1:this.z2_1<this.a3_1},ve(Xt).equals=function(n){return n instanceof Xt&&(!(!this.i()||!n.i())||this.z2_1===n.z2_1&&this.a3_1===n.a3_1&&this.b3_1===n.b3_1)},ve(Xt).hashCode=function(){return this.i()?-1:Mn(31,Mn(31,this.z2_1)+this.a3_1|0)+this.b3_1|0},ve(Xt).toString=function(){return this.b3_1>0?this.z2_1+".."+this.a3_1+" step "+this.b3_1:this.z2_1+" downTo "+this.a3_1+" step "+(0|-this.b3_1)},ve(ar).h=function(){if(-1===this.j3_1&&cr(this),0===this.j3_1)throw Cu();var n=this.m3_1,t=n instanceof Zt?n:pe();return this.m3_1=null,this.j3_1=-1,t},ve(ar).g=function(){return-1===this.j3_1&&cr(this),1===this.j3_1},ve(hr).f=function(){return new ar(this)},ve(lr).toString=function(){return"("+this.t3_1+", "+this.u3_1+")"},ve(lr).v3=function(){return this.t3_1},ve(lr).w3=function(){return this.u3_1},ve(lr).hashCode=function(){var n=null==this.t3_1?0:ae(this.t3_1);return Mn(n,31)+(null==this.u3_1?0:ae(this.u3_1))|0},ve(lr).equals=function(n){if(this===n)return!0;if(!(n instanceof lr))return!1;var t=n instanceof lr?n:pe();return!!le(this.t3_1,t.t3_1)&&!!le(this.u3_1,t.u3_1)},ve(wr).toString=function(){return"kotlin.Unit"},ve(pr).b4=function(){return this.MIN_VALUE},ve(pr).c4=function(){return this.MAX_VALUE},ve(pr).d4=function(){return this.SIZE_BYTES},ve(pr).e4=function(){return this.SIZE_BITS},ve(xr).m=function(n){this.g4();for(var t=!1,r=n.f();r.g();){var i=r.h();this.d(i)&&(t=!0)}return t},ve(xr).toJSON=function(){return this.toArray()},ve(xr).g4=function(){},ve(jr).g=function(){return this.h4_1<this.j4_1.k()},ve(jr).h=function(){if(!this.g())throw Cu();var n=this.h4_1;return this.h4_1=n+1|0,this.i4_1=n,this.j4_1.j(this.i4_1)},ve(Pr).c1=function(){return this.h4_1>0},ve(Pr).d1=function(){if(!this.c1())throw Cu();return this.h4_1=this.h4_1-1|0,this.i4_1=this.h4_1,this.n4_1.j(this.i4_1)},ve(Ir).d=function(n){return this.g4(),this.p4(this.k(),n),!0},ve(Ir).f=function(){return new jr(this)},ve(Ir).u=function(n){return this.q4(n)>=0},ve(Ir).q4=function(n){var t=0,r=jt(this);if(t<=r)do{var i=t;if(t=t+1|0,le(this.j(i),n))return i}while(i!==r);return-1},ve(Ir).l=function(n){return new Pr(this,n)},ve(Ir).equals=function(n){return n===this||!(null==n||!Ke(n,Fi))&&_t().g1(this,n)},ve(Ir).hashCode=function(){return _t().f1(this)},ve(Sr).g=function(){return this.r4_1.g()},ve(Sr).h=function(){return this.r4_1.h().j1()},ve(zr).g=function(){return this.s4_1.g()},ve(zr).h=function(){return this.s4_1.h().i1()},ve(Tr).j1=function(){return this.t4_1},ve(Tr).i1=function(){return this.u4_1},ve(Tr).v4=function(n){var t=this.u4_1;return this.u4_1=n,t},ve(Tr).hashCode=function(){return pt().k1(this)},ve(Tr).toString=function(){return pt().l1(this)},ve(Tr).equals=function(n){return pt().m1(this,n)},ve(Er).u=function(n){return this.w4(n)},ve(Lr).y4=function(n){throw zu("Add is not supported on keys")},ve(Lr).d=function(n){return this.y4(null==n||Je(n)?n:pe())},ve(Lr).z4=function(n){return this.x4_1.t1(n)},ve(Lr).u=function(n){return!(null!=n&&!Je(n))&&this.z4(null==n||Je(n)?n:pe())},ve(Lr).f=function(){return new Sr(this.x4_1.o().f())},ve(Lr).k=function(){return this.x4_1.k()},ve(Lr).g4=function(){return this.x4_1.g4()},ve(Nr).f5=function(n){throw zu("Add is not supported on values")},ve(Nr).d=function(n){return this.f5(null==n||Je(n)?n:pe())},ve(Nr).r1=function(n){return this.e5_1.s1(n)},ve(Nr).u=function(n){return!(null!=n&&!Je(n))&&this.r1(null==n||Je(n)?n:pe())},ve(Nr).f=function(){return new zr(this.e5_1.o().f())},ve(Nr).k=function(){return this.e5_1.k()},ve(Nr).g4=function(){return this.e5_1.g4()},ve(Ar).g5=function(){return null==this.c5_1&&(this.c5_1=new Lr(this)),we(this.c5_1)},ve(Ar).w1=function(){return null==this.d5_1&&(this.d5_1=new Nr(this)),we(this.d5_1)},ve(Ar).g4=function(){},ve(Mr).equals=function(n){return n===this||!(null==n||!Ke(n,$i))&&yt().y1(this,n)},ve(Mr).hashCode=function(){return yt().x1(this)},ve(Gr).j5=function(){return this.g4(),this.c_1=!0,this.k()>0?this:Dr().i5_1},ve(Gr).k=function(){return this.b_1.length},ve(Gr).j=function(n){var t=this.b_1[$r(this,n)];return null==t||Je(t)?t:pe()},ve(Gr).f4=function(n,t){this.g4(),$r(this,n);var r=this.b_1[n];this.b_1[n]=t;var i=r;return null==i||Je(i)?i:pe()},ve(Gr).d=function(n){return this.g4(),this.b_1.push(n),this.o4_1=this.o4_1+1|0,!0},ve(Gr).p4=function(n,t){this.g4(),this.b_1.splice(function(n,t){return _t().b1(t,n.k()),t}(this,n),0,t),this.o4_1=this.o4_1+1|0},ve(Gr).m=function(n){if(this.g4(),n.i())return!1;for(var t,r,i,e=(t=this,r=n.k(),i=t.k(),t.b_1.length=t.k()+r|0,i),u=0,o=n.f();o.g();){var f=o.h(),s=u;u=s+1|0;var c=yr(s);this.b_1[e+c|0]=f}return this.o4_1=this.o4_1+1|0,!0},ve(Gr).q4=function(n){return Hn(this.b_1,n)},ve(Gr).toString=function(){return On(this.b_1,", ","[","]",A,A,ee)},ve(Gr).k5=function(){return[].slice.call(this.b_1)},ve(Gr).toArray=function(){return this.k5()},ve(Gr).g4=function(){if(this.c_1)throw Su()},ve(Qr).l5=function(n,t){return le(n,t)},ve(Qr).m5=function(n){var t=null==n?null:ae(n);return null==t?0:t},ve(Zr).o5=function(n){throw zu("Add is not supported on entries")},ve(Zr).d=function(n){return this.o5(null!=n&&Ke(n,Hi)?n:pe())},ve(Zr).w4=function(n){return this.n5_1.u1(n)},ve(Zr).f=function(){return this.n5_1.t5_1.f()},ve(Zr).k=function(){return this.n5_1.k()},ve(Xr).t1=function(n){return this.t5_1.z4(n)},ve(Xr).s1=function(n){var t;n:{var r=this.t5_1;if(Ke(r,Di)&&r.i())t=!1;else{for(var i=r.f();i.g();){var e=i.h();if(this.u5_1.l5(e.i1(),n)){t=!0;break n}}t=!1}}return t},ve(Xr).o=function(){return null==this.v5_1&&(this.v5_1=this.x5()),we(this.v5_1)},ve(Xr).x5=function(){return new Zr(this)},ve(Xr).v1=function(n){return this.t5_1.v1(n)},ve(Xr).h5=function(n,t){return this.t5_1.h5(n,t)},ve(Xr).k=function(){return this.t5_1.k()},ve(ni).d=function(n){return null==this.y5_1.h5(n,this)},ve(ni).u=function(n){return this.y5_1.t1(n)},ve(ni).i=function(){return this.y5_1.i()},ve(ni).f=function(){return this.y5_1.g5().f()},ve(ni).k=function(){return this.y5_1.k()},ve(ei).g=function(){return-1===this.z5_1&&(this.z5_1=function(n){if(null!=n.c6_1&&n.d6_1){var t=n.c6_1.length;if(n.e6_1=n.e6_1+1|0,n.e6_1<t)return 0}if(n.b6_1=n.b6_1+1|0,n.b6_1<n.a6_1.length){n.c6_1=n.g6_1.i6_1[n.a6_1[n.b6_1]];var r=n,i=n.c6_1;return r.d6_1=null!=i&&Xe(i),n.e6_1=0,0}return n.c6_1=null,1}(this)),0===this.z5_1},ve(ei).h=function(){if(!this.g())throw Cu();var n=this.d6_1?this.c6_1[this.e6_1]:this.c6_1;return this.f6_1=n,this.z5_1=-1,n},ve(ui).w5=function(){return this.h6_1},ve(ui).k=function(){return this.j6_1},ve(ui).h5=function(n,t){var r=this.h6_1.m5(n),i=ii(this,r);if(null==i)this.i6_1[r]=new Tr(n,t);else{if(null==i||!Xe(i)){var e,u=i;return this.h6_1.l5(u.j1(),n)?u.v4(t):(e=[u,new Tr(n,t)],this.i6_1[r]=e,this.j6_1=this.j6_1+1|0,null)}var o=i,f=ri(o,this,n);if(null!=f)return f.v4(t);o.push(new Tr(n,t))}return this.j6_1=this.j6_1+1|0,null},ve(ui).z4=function(n){return!(null==ti(this,n))},ve(ui).v1=function(n){var t=ti(this,n);return null==t?null:t.i1()},ve(ui).f=function(){return new ei(this)},ve(fi).g=function(){return!(null===this.m6_1)},ve(fi).h=function(){if(!this.g())throw Cu();var n=we(this.m6_1);this.l6_1=n;var t,r=n.b7_1;return t=r!==this.n6_1.y6_1.v6_1?r:null,this.m6_1=t,n},ve(ai).v4=function(n){return this.d7_1.g4(),ve(Tr).v4.call(this,n)},ve(hi).o5=function(n){throw zu("Add is not supported on entries")},ve(hi).d=function(n){return this.o5(null!=n&&Ke(n,Hi)?n:pe())},ve(hi).w4=function(n){return this.y6_1.u1(n)},ve(hi).f=function(){return new fi(this)},ve(hi).k=function(){return this.y6_1.k()},ve(hi).g4=function(){return this.y6_1.g4()},ve(vi).j5=function(){var n;if(this.g4(),this.x6_1=!0,this.k()>0)n=this;else{var t=ci().e7_1;n=Ke(t,Ri)?t:pe()}return n},ve(vi).t1=function(n){return this.w6_1.t1(n)},ve(vi).s1=function(n){var t=this.v6_1;if(null==t)return!1;var r=t;do{if(le(r.i1(),n))return!0;r=we(r.b7_1)}while(r!==this.v6_1);return!1},ve(vi).x5=function(){return new hi(this)},ve(vi).v1=function(n){var t=this.w6_1.v1(n);return null==t?null:t.i1()},ve(vi).h5=function(n,t){this.g4();var r=this.w6_1.v1(n);if(null==r){var i=new ai(this,n,t);return this.w6_1.h5(n,i),function(n,t){if(null!=n.b7_1||null!=n.c7_1)throw wu(ce("Check failed."));var r=t.v6_1;if(null==r)t.v6_1=n,n.b7_1=n,n.c7_1=n;else{var i=r.c7_1;if(null==i)throw wu(ce("Required value was null."));var e=i;n.c7_1=e,n.b7_1=r,r.c7_1=n,e.b7_1=n}}(i,this),null}return r.v4(t)},ve(vi).k=function(){return this.w6_1.k()},ve(vi).g4=function(){if(this.x6_1)throw Su()},ve(wi).g4=function(){return this.y5_1.g4()},ve(pi).h7=function(){this.i7("\n")},ve(pi).j7=function(n){this.i7(n),this.h7()},ve(mi).i7=function(n){var t=String(n);this.k7_1.write(t)},ve(ki).i7=function(n){var t=String(n),r=t.lastIndexOf("\n",0);if(r>=0){var i=this.m7_1;this.m7_1=i+t.substring(0,r),this.n7();var e=r+1|0;t=t.substring(e)}this.m7_1=this.m7_1+t},ve(ki).n7=function(){console.log(this.m7_1),this.m7_1=""},ve(qi).i7=function(n){var t=this.m7_1;this.m7_1=t+String(n)},ve(Ci).x3=function(){return this.o7_1.length},ve(Ci).y3=function(n){var t=this.o7_1;if(!(n>=0&&n<=tr(t)))throw du("index: "+n+", length: "+this.x3()+"}");return ne(t,n)},ve(Ci).z3=function(n,t){return this.o7_1.substring(n,t)},ve(Ci).i3=function(n){return this.o7_1=this.o7_1+new Mi(n),this},ve(Ci).e=function(n){return this.o7_1=this.o7_1+Vi(n),this},ve(Ci).p7=function(n){var t=this.o7_1;return this.o7_1=t+(null==n?"null":n),this},ve(Ci).toString=function(){return this.o7_1},ve(Pi).t7=function(n){var t=this.q7_1;return n.replace(t,"\\$&")},ve(Pi).u7=function(n){var t=this.s7_1;return n.replace(t,"$$$$")},ve(Si).a8=function(n){this.x7_1.lastIndex=0;var t=this.x7_1.exec(ce(n));return null!=t&&0===t.index&&this.x7_1.lastIndex===re(n)},ve(Si).toString=function(){return this.x7_1.toString()},ve(Mi).o8=function(n){return Ei(this.h3_1,n)},ve(Mi).a4=function(n){return function(n,t){return Ei(n.h3_1,t instanceof Mi?t.h3_1:pe())}(this,n)},ve(Mi).equals=function(n){return function(n,t){return t instanceof Mi&&n===t.h3_1}(this.h3_1,n)},ve(Mi).hashCode=function(){return this.h3_1},ve(Mi).toString=function(){return Li(this.h3_1)},ve(Ui).r8=function(n){return ue(this.q8_1,n.q8_1)},ve(Ui).a4=function(n){return this.r8(n instanceof Ui?n:pe())},ve(Ui).equals=function(n){return this===n},ve(Ui).hashCode=function(){return se(this)},ve(Ui).toString=function(){return this.p8_1},ve(Zi).g=function(){return!(this.s8_1===this.t8_1.length)},ve(Zi).h=function(){if(this.s8_1===this.t8_1.length)throw xu(""+this.s8_1);var n=this.s8_1;return this.s8_1=n+1|0,this.t8_1[n]},ve(ke).b9=function(n){return je(this,n)},ve(ke).a4=function(n){return this.b9(n instanceof ke?n:pe())},ve(ke).c9=function(n){return Pe(this,n)},ve(ke).d9=function(n){return function(n,t){if($e(),Ae(t))throw mu("division by zero");if(Ae(n))return qe();if(Te(n,Ce())){if(Te(t,ye())||Te(t,Be()))return Ce();if(Te(t,Ce()))return ye();var r=function(n){$e();return new ke(n.u8_1>>>1|n.v8_1<<31,n.v8_1>>1)}(n),i=function(n){$e();return new ke(n.u8_1<<1,n.v8_1<<1|n.u8_1>>>31)}(r.d9(t));return Te(i,qe())?Ne(t)?ye():Be():Pe(i,Ie(n,Se(t,i)).d9(t))}if(Te(t,Ce()))return qe();if(Ne(n))return Ne(t)?Fe(n).d9(Fe(t)):Fe(Fe(n).d9(t));if(Ne(t))return Fe(n.d9(Fe(t)));for(var e=qe(),u=n;He(u,t);){for(var o=ze(u)/ze(t),f=Math.max(1,Math.floor(o)),s=Math.ceil(Math.log(f)/Math.LN2),c=s<=48?1:Math.pow(2,s-48),a=Oe(f),h=Se(a,t);Ne(h)||Re(h,u);)h=Se(a=Oe(f-=c),t);Ae(a)&&(a=ye()),e=Pe(e,a),u=Ie(u,h)}return e}(this,n)},ve(ke).e9=function(){return this.f9().c9(new ke(1,0))},ve(ke).f9=function(){return new ke(~this.u8_1,~this.v8_1)},ve(ke).g9=function(){return this.u8_1},ve(ke).w8=function(){return ze(this)},ve(ke).valueOf=function(){return this.w8()},ve(ke).equals=function(n){return n instanceof ke&&Te(this,n)},ve(ke).hashCode=function(){return $e(),this.u8_1^this.v8_1},ve(ke).toString=function(){return Ee(this,10)},ve(Hu).toString=function(){return"Model(text="+this.o9_1+", tooltip="+this.p9_1+")"},ve(Hu).hashCode=function(){var n=he(this.o9_1);return Mn(n,31)+he(this.p9_1)|0},ve(Hu).equals=function(n){if(this===n)return!0;if(!(n instanceof Hu))return!1;var t=n instanceof Hu?n:pe();return this.o9_1===t.o9_1&&this.p9_1===t.p9_1},ve($u).v9=function(n,t){return this.w9(new Hu(n,t))},ve($u).w9=function(n){var t,r;return Uf().y9(us((t=n,r=this,function(n){return n.s9(t.p9_1),n.t9("copy-button"),n.u9(function(n,t){return function(r){return n.q9_1(t.o9_1)}}(r,t)),br()})),[])},ve($u).z9=function(n){return this.w9(n instanceof Hu?n:pe())},ve($u).aa=function(n,t){return t},ve($u).ba=function(n,t){var r=null==n||Je(n)?n:pe();return this.aa(r,t instanceof Hu?t:pe())},ve(Uu).ka=function(n){return function(n,t){for(var r=Gf(),i=t.ca_1,e=Rr(Tt(i,10)),u=i.f();u.g();){var o,f,s=u.h();s instanceof Cf?f=Gf().ga(s.fa_1):s instanceof xf?f=Gu(n,s.da_1,s.ea_1):be(),o=f,e.d(o)}return r.ha(e)}(this,n)},ve(Uu).z9=function(n){return this.ka(n instanceof zf?n:pe())},ve(Uu).la=function(n,t){return t},ve(Uu).ba=function(n,t){var r=null==n||Je(n)?n:pe();return this.la(r,t instanceof zf?t:pe())},ve(Vu).pa=function(n,t,r){return new Vu(n,t,r)},ve(Vu).qa=function(n,t,r,i){return n=n===A?this.ma_1:n,t=t===A?this.na_1:t,r=r===A?this.oa_1:r,i===A?this.pa(n,t,r):i.pa.call(this,n,t,r)},ve(Vu).toString=function(){return"Exception(summary="+this.ma_1+", fullText="+this.na_1+", parts="+this.oa_1+")"},ve(Vu).hashCode=function(){var n=null==this.ma_1?0:this.ma_1.hashCode();return n=Mn(n,31)+he(this.na_1)|0,Mn(n,31)+ae(this.oa_1)|0},ve(Vu).equals=function(n){if(this===n)return!0;if(!(n instanceof Vu))return!1;var t=n instanceof Vu?n:pe();return!!le(this.ma_1,t.ma_1)&&this.na_1===t.na_1&&!!le(this.oa_1,t.oa_1)},ve(Qu).ta=function(n,t){return new Qu(n,t)},ve(Qu).ua=function(n,t,r){return n=n===A?this.ra_1:n,t=t===A?this.sa_1:t,r===A?this.ta(n,t):r.ta.call(this,n,t)},ve(Qu).toString=function(){return"StackTracePart(lines="+this.ra_1+", state="+this.sa_1+")"},ve(Qu).hashCode=function(){var n=ae(this.ra_1);return Mn(n,31)+(null==this.sa_1?0:this.sa_1.hashCode())|0},ve(Qu).equals=function(n){if(this===n)return!0;if(!(n instanceof Qu))return!1;var t=n instanceof Qu?n:pe();return!!le(this.ra_1,t.ra_1)&&!!le(this.sa_1,t.sa_1)},ve(Zu).toString=function(){return"Error(label="+this.va_1+", docLink="+this.wa_1+")"},ve(Zu).hashCode=function(){var n=ae(this.va_1);return Mn(n,31)+(null==this.wa_1?0:ae(this.wa_1))|0},ve(Zu).equals=function(n){if(this===n)return!0;if(!(n instanceof Zu))return!1;var t=n instanceof Zu?n:pe();return!!le(this.va_1,t.va_1)&&!!le(this.wa_1,t.wa_1)},ve(Yu).toString=function(){return"Warning(label="+this.xa_1+", docLink="+this.ya_1+")"},ve(Yu).hashCode=function(){var n=ae(this.xa_1);return Mn(n,31)+(null==this.ya_1?0:ae(this.ya_1))|0},ve(Yu).equals=function(n){if(this===n)return!0;if(!(n instanceof Yu))return!1;var t=n instanceof Yu?n:pe();return!!le(this.xa_1,t.xa_1)&&!!le(this.ya_1,t.ya_1)},ve(Wu).toString=function(){return"Message(prettyText="+this.za_1+")"},ve(Wu).hashCode=function(){return this.za_1.hashCode()},ve(Wu).equals=function(n){if(this===n)return!0;if(!(n instanceof Wu))return!1;var t=n instanceof Wu?n:pe();return!!this.za_1.equals(t.za_1)},ve(Ku).toString=function(){return"ListElement(prettyText="+this.ab_1+")"},ve(Ku).hashCode=function(){return this.ab_1.hashCode()},ve(Ku).equals=function(n){if(this===n)return!0;if(!(n instanceof Ku))return!1;var t=n instanceof Ku?n:pe();return!!this.ab_1.equals(t.ab_1)},ve(Xu).toString=function(){return"TreeNode(prettyText="+this.bb_1+")"},ve(Xu).hashCode=function(){return this.bb_1.hashCode()},ve(Xu).equals=function(n){if(this===n)return!0;if(!(n instanceof Xu))return!1;var t=n instanceof Xu?n:pe();return!!this.bb_1.equals(t.bb_1)},ve(Ju).toString=function(){return"Link(href="+this.cb_1+", label="+this.db_1+")"},ve(Ju).hashCode=function(){var n=he(this.cb_1);return Mn(n,31)+he(this.db_1)|0},ve(Ju).equals=function(n){if(this===n)return!0;if(!(n instanceof Ju))return!1;var t=n instanceof Ju?n:pe();return this.cb_1===t.cb_1&&this.db_1===t.db_1},ve(no).toString=function(){return"Label(text="+this.eb_1+")"},ve(no).hashCode=function(){return he(this.eb_1)},ve(no).equals=function(n){if(this===n)return!0;if(!(n instanceof no))return!1;var t=n instanceof no?n:pe();return this.eb_1===t.eb_1},ve(co).toString=function(){return"Info(label="+this.hb_1+", docLink="+this.ib_1+")"},ve(co).hashCode=function(){var n=ae(this.hb_1);return Mn(n,31)+(null==this.ib_1?0:ae(this.ib_1))|0},ve(co).equals=function(n){if(this===n)return!0;if(!(n instanceof co))return!1;var t=n instanceof co?n:pe();return!!le(this.hb_1,t.hb_1)&&!!le(this.ib_1,t.ib_1)},ve(ao).toString=function(){return"Project(path="+this.jb_1+")"},ve(ao).hashCode=function(){return he(this.jb_1)},ve(ao).equals=function(n){if(this===n)return!0;if(!(n instanceof ao))return!1;var t=n instanceof ao?n:pe();return this.jb_1===t.jb_1},ve(ho).toString=function(){return"Task(path="+this.kb_1+", type="+this.lb_1+")"},ve(ho).hashCode=function(){var n=he(this.kb_1);return Mn(n,31)+he(this.lb_1)|0},ve(ho).equals=function(n){if(this===n)return!0;if(!(n instanceof ho))return!1;var t=n instanceof ho?n:pe();return this.kb_1===t.kb_1&&this.lb_1===t.lb_1},ve(lo).toString=function(){return"TaskPath(path="+this.mb_1+")"},ve(lo).hashCode=function(){return he(this.mb_1)},ve(lo).equals=function(n){if(this===n)return!0;if(!(n instanceof lo))return!1;var t=n instanceof lo?n:pe();return this.mb_1===t.mb_1},ve(_o).toString=function(){return"Bean(type="+this.nb_1+")"},ve(_o).hashCode=function(){return he(this.nb_1)},ve(_o).equals=function(n){if(this===n)return!0;if(!(n instanceof _o))return!1;var t=n instanceof _o?n:pe();return this.nb_1===t.nb_1},ve(vo).toString=function(){return"SystemProperty(name="+this.ob_1+")"},ve(vo).hashCode=function(){return he(this.ob_1)},ve(vo).equals=function(n){if(this===n)return!0;if(!(n instanceof vo))return!1;var t=n instanceof vo?n:pe();return this.ob_1===t.ob_1},ve(go).toString=function(){return"Property(kind="+this.pb_1+", name="+this.qb_1+", owner="+this.rb_1+")"},ve(go).hashCode=function(){var n=he(this.pb_1);return n=Mn(n,31)+he(this.qb_1)|0,Mn(n,31)+he(this.rb_1)|0},ve(go).equals=function(n){if(this===n)return!0;if(!(n instanceof go))return!1;var t=n instanceof go?n:pe();return this.pb_1===t.pb_1&&this.qb_1===t.qb_1&&this.rb_1===t.rb_1},ve(wo).toString=function(){return"BuildLogic(location="+this.sb_1+")"},ve(wo).hashCode=function(){return he(this.sb_1)},ve(wo).equals=function(n){if(this===n)return!0;if(!(n instanceof wo))return!1;var t=n instanceof wo?n:pe();return this.sb_1===t.sb_1},ve(bo).toString=function(){return"BuildLogicClass(type="+this.tb_1+")"},ve(bo).hashCode=function(){return he(this.tb_1)},ve(bo).equals=function(n){if(this===n)return!0;if(!(n instanceof bo))return!1;var t=n instanceof bo?n:pe();return this.tb_1===t.tb_1},ve(ko).zb=function(){return this.yb_1},ve(ko).toString=function(){return"TaskTreeIntent(delegate="+this.yb_1+")"},ve(ko).hashCode=function(){return ae(this.yb_1)},ve(ko).equals=function(n){if(this===n)return!0;if(!(n instanceof ko))return!1;var t=n instanceof ko?n:pe();return!!le(this.yb_1,t.yb_1)},ve(qo).zb=function(){return this.ac_1},ve(qo).toString=function(){return"MessageTreeIntent(delegate="+this.ac_1+")"},ve(qo).hashCode=function(){return ae(this.ac_1)},ve(qo).equals=function(n){if(this===n)return!0;if(!(n instanceof qo))return!1;var t=n instanceof qo?n:pe();return!!le(this.ac_1,t.ac_1)},ve(yo).zb=function(){return this.bc_1},ve(yo).toString=function(){return"InputTreeIntent(delegate="+this.bc_1+")"},ve(yo).hashCode=function(){return ae(this.bc_1)},ve(yo).equals=function(n){if(this===n)return!0;if(!(n instanceof yo))return!1;var t=n instanceof yo?n:pe();return!!le(this.bc_1,t.bc_1)},ve(Bo).zb=function(){return this.cc_1},ve(Bo).toString=function(){return"IncompatibleTaskTreeIntent(delegate="+this.cc_1+")"},ve(Bo).hashCode=function(){return ae(this.cc_1)},ve(Bo).equals=function(n){if(this===n)return!0;if(!(n instanceof Bo))return!1;var t=n instanceof Bo?n:pe();return!!le(this.cc_1,t.cc_1)},ve(Co).toString=function(){return"SetTab(tab="+this.dc_1+")"},ve(Co).hashCode=function(){return this.dc_1.hashCode()},ve(Co).equals=function(n){if(this===n)return!0;if(!(n instanceof Co))return!1;var t=n instanceof Co?n:pe();return!!this.dc_1.equals(t.dc_1)},ve(xo).mc=function(n,t,r,i,e,u,o,f){return new xo(n,t,r,i,e,u,o,f)},ve(xo).nc=function(n,t,r,i,e,u,o,f,s){return n=n===A?this.ec_1:n,t=t===A?this.fc_1:t,r=r===A?this.gc_1:r,i=i===A?this.hc_1:i,e=e===A?this.ic_1:e,u=u===A?this.jc_1:u,o=o===A?this.kc_1:o,f=f===A?this.lc_1:f,s===A?this.mc(n,t,r,i,e,u,o,f):s.mc.call(this,n,t,r,i,e,u,o,f)},ve(xo).toString=function(){return"Model(heading="+this.ec_1+", summary="+this.fc_1+", learnMore="+this.gc_1+", messageTree="+this.hc_1+", locationTree="+this.ic_1+", inputTree="+this.jc_1+", incompatibleTaskTree="+this.kc_1+", tab="+this.lc_1+")"},ve(xo).hashCode=function(){var n=this.ec_1.hashCode();return n=Mn(n,31)+ae(this.fc_1)|0,n=Mn(n,31)+this.gc_1.hashCode()|0,n=Mn(n,31)+this.hc_1.hashCode()|0,n=Mn(n,31)+this.ic_1.hashCode()|0,n=Mn(n,31)+this.jc_1.hashCode()|0,n=Mn(n,31)+this.kc_1.hashCode()|0,Mn(n,31)+this.lc_1.hashCode()|0},ve(xo).equals=function(n){if(this===n)return!0;if(!(n instanceof xo))return!1;var t=n instanceof xo?n:pe();return!!(this.ec_1.equals(t.ec_1)&&le(this.fc_1,t.fc_1)&&this.gc_1.equals(t.gc_1)&&this.hc_1.equals(t.hc_1)&&this.ic_1.equals(t.ic_1)&&this.jc_1.equals(t.jc_1)&&this.kc_1.equals(t.kc_1)&&this.lc_1.equals(t.lc_1))},ve(Ko).gd=function(n,t){var r,i;return n instanceof ko?r=t.nc(A,A,A,A,ps().id(n.yb_1,t.ic_1)):n instanceof qo?r=t.nc(A,A,A,ps().id(n.ac_1,t.hc_1)):n instanceof yo?r=t.nc(A,A,A,A,A,ps().id(n.bc_1,t.jc_1)):n instanceof Bo?r=t.nc(A,A,A,A,A,A,ps().id(n.cc_1,t.kc_1)):n instanceof Dc?r=function(n,t,r,i){var e;return r instanceof qo?e=n.nc(A,A,A,Ac(n.hc_1,r,i)):r instanceof ko?e=n.nc(A,A,A,A,Ac(n.ic_1,r,i)):r instanceof yo?e=n.nc(A,A,A,A,A,Ac(n.jc_1,r,i)):r instanceof Bo?e=n.nc(A,A,A,A,A,A,Ac(n.kc_1,r,i)):(console.error("Unhandled tree intent: "+r),e=n),e}(t,0,n.xc_1,(i=n,function(n){var t;if(!(n instanceof Vu))throw _u(ce("Failed requirement."));for(var r=n.oa_1,e=i.wc_1,u=Rr(Tt(r,10)),o=0,f=r.f();f.g();){var s,c,a=f.h(),h=o;if(o=h+1|0,e===yr(h)){var l=a.sa_1;c=a.ua(A,null==l?null:l.ad())}else c=a;s=c,u.d(s)}return t=u,n.qa(A,A,t)})):n instanceof Mc?(window.navigator.clipboard.writeText(n.hd_1),r=t):n instanceof Co?r=t.nc(A,A,A,A,A,A,A,n.dc_1):(console.error("Unhandled intent: "+n),r=t),r},ve(Ko).ba=function(n,t){var r=n instanceof Oc?n:pe();return this.gd(r,t instanceof xo?t:pe())},ve(Ko).jd=function(n){return Hf().y9(us(Do),[Io(0,n),So(0,n)])},ve(Ko).z9=function(n){return this.jd(n instanceof xo?n:pe())},ve(nf).toString=function(){return"ImportedProblem(problem="+this.kd_1+", message="+this.ld_1+", trace="+this.md_1+")"},ve(nf).hashCode=function(){var n=ae(this.kd_1);return n=Mn(n,31)+this.ld_1.hashCode()|0,Mn(n,31)+ae(this.md_1)|0},ve(nf).equals=function(n){if(this===n)return!0;if(!(n instanceof nf))return!1;var t=n instanceof nf?n:pe();return!!le(this.kd_1,t.kd_1)&&!!this.ld_1.equals(t.ld_1)&&!!le(this.md_1,t.md_1)},ve(_f).ud=function(n,t){return this.td_1(n,t)},ve(_f).compare=function(n,t){return this.ud(n,t)},ve(Bf).toString=function(){return"LearnMore(text="+this.sc_1+", documentationLink="+this.tc_1+")"},ve(Bf).hashCode=function(){var n=he(this.sc_1);return Mn(n,31)+he(this.tc_1)|0},ve(Bf).equals=function(n){if(this===n)return!0;if(!(n instanceof Bf))return!1;var t=n instanceof Bf?n:pe();return this.sc_1===t.sc_1&&this.tc_1===t.tc_1},ve(Cf).toString=function(){return"Text(text="+this.fa_1+")"},ve(Cf).hashCode=function(){return he(this.fa_1)},ve(Cf).equals=function(n){if(this===n)return!0;if(!(n instanceof Cf))return!1;var t=n instanceof Cf?n:pe();return this.fa_1===t.fa_1},ve(xf).toString=function(){return"Reference(name="+this.da_1+", clipboardString="+this.ea_1+")"},ve(xf).hashCode=function(){var n=he(this.da_1);return Mn(n,31)+he(this.ea_1)|0},ve(xf).equals=function(n){if(this===n)return!0;if(!(n instanceof xf))return!1;var t=n instanceof xf?n:pe();return this.da_1===t.da_1&&this.ea_1===t.ea_1},ve(Pf).ed=function(n){return this.dd_1.d(new Cf(n)),this},ve(Pf).xd=function(n,t){return this.dd_1.d(new xf(n,t)),this},ve(Pf).fd=function(n,t,r){return t=t===A?n:t,r===A?this.xd(n,t):r.xd.call(this,n,t)},ve(Pf).j5=function(){return new zf(Qn(this.dd_1))},ve(If).rd=function(n){return new zf(qr(new Cf(n)))},ve(If).qd=function(n){var t=new Pf;return n(t),t.j5()},ve(zf).vd=function(n){return new zf(n)},ve(zf).toString=function(){return"PrettyText(fragments="+this.ca_1+")"},ve(zf).hashCode=function(){return ae(this.ca_1)},ve(zf).equals=function(n){if(this===n)return!0;if(!(n instanceof zf))return!1;var t=n instanceof zf?n:pe();return!!le(this.ca_1,t.ca_1)},ve(Tf).sd=function(n){return function(n){for(var t=Wr(),r=n.f();r.g();)for(var i=t,e=r.h().f();e.g();){var u,o=e.h(),f=i,s=f.v1(o);if(null==s){var c=Wr();f.h5(o,c),u=c}else u=s;i=u instanceof Xr?u:pe()}return t}(n)},ve(Af).toString=function(){return"Trie(nestedMaps="+this.wd_1+")"},ve(Af).hashCode=function(){return ae(this.wd_1)},ve(Af).equals=function(n){return function(n,t){return t instanceof Af&&!!le(n,t instanceof Af?t.wd_1:pe())}(this.wd_1,n)},ve(Kf).ga=function(n){return Jf().yd(this.x9_1,A,n)},ve(Kf).ha=function(n){return Jf().yd(this.x9_1,A,A,n)},ve(Kf).ja=function(n){return Jf().yd(this.x9_1,A,A,ou(n))},ve(Kf).y9=function(n,t){return Jf().yd(this.x9_1,n,A,ou(t))},ve(Kf).zd=function(n,t){return Jf().yd(this.x9_1,n,A,t)},ve(Kf).fb=function(n,t){return Jf().yd(this.x9_1,n,t)},ve(Kf).rc=function(n,t){return Jf().yd(this.x9_1,A,n,ou(t))},ve(Kf).toString=function(){return"ViewFactory(elementName="+this.x9_1+")"},ve(Kf).hashCode=function(){return he(this.x9_1)},ve(Kf).equals=function(n){if(this===n)return!0;if(!(n instanceof Kf))return!1;var t=n instanceof Kf?n:pe();return this.x9_1===t.x9_1},ve(Xf).ae=function(n,t,r,i){return new rs(n,t,r,i)},ve(Xf).yd=function(n,t,r,i,e){return t=t===A?Ct():t,r=r===A?null:r,i=i===A?Ct():i,e===A?this.ae(n,t,r,i):e.ae.call(this,n,t,r,i)},ve(rs).toString=function(){return"Element(elementName="+this.be_1+", attributes="+this.ce_1+", innerText="+this.de_1+", children="+this.ee_1+")"},ve(rs).hashCode=function(){var n=he(this.be_1);return n=Mn(n,31)+ae(this.ce_1)|0,n=Mn(n,31)+(null==this.de_1?0:he(this.de_1))|0,Mn(n,31)+ae(this.ee_1)|0},ve(rs).equals=function(n){if(this===n)return!0;if(!(n instanceof rs))return!1;var t=n instanceof rs?n:pe();return this.be_1===t.be_1&&!!le(this.ce_1,t.ce_1)&&this.de_1==t.de_1&&!!le(this.ee_1,t.ee_1)},ve(os).u9=function(n){return this.r9_1(new fs("click",n))},ve(os).t9=function(n){return this.r9_1(new ss(n))},ve(os).gb=function(n){for(var t=0,r=n.length;t<r;){var i=n[t];t=t+1|0,this.r9_1(new ss(i))}return br()},ve(os).s9=function(n){return this.r9_1(new cs("title",n))},ve(os).bd=function(n){return this.r9_1(new cs("href",n))},ve(vs).oe=function(){return this.ne_1},ve(vs).toString=function(){return"Toggle(focus="+this.ne_1+")"},ve(vs).hashCode=function(){return ae(this.ne_1)},ve(vs).equals=function(n){if(this===n)return!0;if(!(n instanceof vs))return!1;var t=n instanceof vs?n:pe();return!!le(this.ne_1,t.ne_1)},ve(ds).pe=function(n,t){return this.re(n.qe((r=t,function(n){return n.me(r(n.ub_1))})));var r},ve(ds).re=function(n){return new ds(n)},ve(ds).toString=function(){return"Model(tree="+this.xb_1+")"},ve(ds).hashCode=function(){return this.xb_1.hashCode()},ve(ds).equals=function(n){if(this===n)return!0;if(!(n instanceof ds))return!1;var t=n instanceof ds?n:pe();return!!this.xb_1.equals(t.xb_1)},ve(bs).id=function(n,t){var r;if(n instanceof vs){var i=n.oe();r=t.re(i.qe(ws))}else be();return r},ve(ks).cd=function(){return this.ve_1},ve(ks).we=function(){return 0},ve(ks).qe=function(n){return n(this.ve_1)},ve(ks).toString=function(){return"Original(tree="+this.ve_1+")"},ve(ks).hashCode=function(){return this.ve_1.hashCode()},ve(ks).equals=function(n){if(this===n)return!0;if(!(n instanceof ks))return!1;var t=n instanceof ks?n:pe();return!!this.ve_1.equals(t.ve_1)},ve(qs).cd=function(){return this.ue_1},ve(qs).we=function(){return this.se_1.we()+1|0},ve(qs).qe=function(n){return this.se_1.qe((t=this,r=n,function(n){for(var i,e=n.vb_1,u=t.te_1,o=Rr(Tt(e,10)),f=0,s=e.f();s.g();){var c,a=s.h(),h=f;f=h+1|0,c=u===yr(h)?r(a):a,o.d(c)}return i=o,n.me(A,i)}));var t,r},ve(qs).toString=function(){return"Child(parent="+this.se_1+", index="+this.te_1+", tree="+this.ue_1+")"},ve(qs).hashCode=function(){var n=ae(this.se_1);return n=Mn(n,31)+this.te_1|0,Mn(n,31)+this.ue_1.hashCode()|0},ve(qs).equals=function(n){if(this===n)return!0;if(!(n instanceof qs))return!1;var t=n instanceof qs?n:pe();return!!le(this.se_1,t.se_1)&&this.te_1===t.te_1&&!!this.ue_1.equals(t.ue_1)},ve(ys).ad=function(){var n;switch(this.q8_1){case 0:n=xs();break;case 1:n=Cs();break;default:be()}return n},ve(Bs).vc=function(){var n,t;return ut(Vn(Ve(0,this.cd().vb_1.k()-1|0)),(n=this,(t=function(t){return n.xe(t)}).callableName="child",t))},ve(Bs).xe=function(n){return new qs(this,n,this.cd().vb_1.j(n))},ve(js).uc=function(){return new ks(this)},ve(js).ye=function(){return!this.vb_1.i()},ve(js).ze=function(n,t,r){return new js(n,t,r)},ve(js).me=function(n,t,r,i){return n=n===A?this.ub_1:n,t=t===A?this.vb_1:t,r=r===A?this.wb_1:r,i===A?this.ze(n,t,r):i.ze.call(this,n,t,r)},ve(js).toString=function(){return"Tree(label="+this.ub_1+", children="+this.vb_1+", state="+this.wb_1+")"},ve(js).hashCode=function(){var n=null==this.ub_1?0:ae(this.ub_1);return n=Mn(n,31)+ae(this.vb_1)|0,Mn(n,31)+this.wb_1.hashCode()|0},ve(js).equals=function(n){if(this===n)return!0;if(!(n instanceof js))return!1;var t=n instanceof js?n:pe();return!!le(this.ub_1,t.ub_1)&&!!le(this.vb_1,t.vb_1)&&!!this.wb_1.equals(t.wb_1)},ve(zs).toString=function(){return"ProblemIdElement(name="+this.df_1+", displayName="+this.ef_1+")"},ve(zs).hashCode=function(){var n=he(this.df_1);return Mn(n,31)+he(this.ef_1)|0},ve(zs).equals=function(n){if(this===n)return!0;if(!(n instanceof zs))return!1;var t=n instanceof zs?n:pe();return this.df_1===t.df_1&&this.ef_1===t.ef_1},ve(Ts).toString=function(){return"ProblemSummary(problemId="+this.ff_1+", count="+this.gf_1+")"},ve(Ts).hashCode=function(){var n=ae(this.ff_1);return Mn(n,31)+this.gf_1|0},ve(Ts).equals=function(n){if(this===n)return!0;if(!(n instanceof Ts))return!1;var t=n instanceof Ts?n:pe();return!!le(this.ff_1,t.ff_1)&&this.gf_1===t.gf_1},ve(Ms).toString=function(){return"ProblemNodeGroup(tree="+this.hf_1+", children="+this.if_1+", childGroups="+this.jf_1+", id="+this.kf_1+")"},ve(Ms).hashCode=function(){var n=this.hf_1.hashCode();return n=Mn(n,31)+ae(this.if_1)|0,n=Mn(n,31)+ae(this.jf_1)|0,Mn(n,31)+this.kf_1|0},ve(Ms).equals=function(n){if(this===n)return!0;if(!(n instanceof Ms))return!1;var t=n instanceof Ms?n:pe();return!!this.hf_1.equals(t.hf_1)&&!!le(this.if_1,t.if_1)&&!!le(this.jf_1,t.jf_1)&&this.kf_1===t.kf_1},ve(uc).toString=function(){return"Text(text="+this.lf_1+")"},ve(uc).hashCode=function(){return he(this.lf_1)},ve(uc).equals=function(n){if(this===n)return!0;if(!(n instanceof uc))return!1;var t=n instanceof uc?n:pe();return this.lf_1===t.lf_1},ve(oc).toString=function(){return"ProblemIdNode(prettyText="+this.mf_1+", separator="+this.nf_1+")"},ve(oc).hashCode=function(){var n=this.mf_1.hashCode();return Mn(n,31)+(0|this.nf_1)|0},ve(oc).equals=function(n){if(this===n)return!0;if(!(n instanceof oc))return!1;var t=n instanceof oc?n:pe();return!!this.mf_1.equals(t.mf_1)&&this.nf_1===t.nf_1},ve(fc).toString=function(){return"Advice(label="+this.of_1+", docLink="+this.pf_1+")"},ve(fc).hashCode=function(){var n=ae(this.of_1);return Mn(n,31)+(null==this.pf_1?0:ae(this.pf_1))|0},ve(fc).equals=function(n){if(this===n)return!0;if(!(n instanceof fc))return!1;var t=n instanceof fc?n:pe();return!!le(this.of_1,t.of_1)&&!!le(this.pf_1,t.pf_1)},ve(cc).zb=function(){return this.qf_1},ve(cc).toString=function(){return"MessageTreeIntent(delegate="+this.qf_1+")"},ve(cc).hashCode=function(){return ae(this.qf_1)},ve(cc).equals=function(n){if(this===n)return!0;if(!(n instanceof cc))return!1;var t=n instanceof cc?n:pe();return!!le(this.qf_1,t.qf_1)},ve(ac).zb=function(){return this.rf_1},ve(ac).toString=function(){return"ProblemIdTreeIntent(delegate="+this.rf_1+")"},ve(ac).hashCode=function(){return ae(this.rf_1)},ve(ac).equals=function(n){if(this===n)return!0;if(!(n instanceof ac))return!1;var t=n instanceof ac?n:pe();return!!le(this.rf_1,t.rf_1)},ve(hc).zb=function(){return this.sf_1},ve(hc).toString=function(){return"FileLocationTreeIntent(delegate="+this.sf_1+")"},ve(hc).hashCode=function(){return ae(this.sf_1)},ve(hc).equals=function(n){if(this===n)return!0;if(!(n instanceof hc))return!1;var t=n instanceof hc?n:pe();return!!le(this.sf_1,t.sf_1)},ve(lc).zb=function(){return this.tf_1},ve(lc).toString=function(){return"PluginLocationTreeIntent(delegate="+this.tf_1+")"},ve(lc).hashCode=function(){return ae(this.tf_1)},ve(lc).equals=function(n){if(this===n)return!0;if(!(n instanceof lc))return!1;var t=n instanceof lc?n:pe();return!!le(this.tf_1,t.tf_1)},ve(_c).zb=function(){return this.uf_1},ve(_c).toString=function(){return"TaskLocationTreeIntent(delegate="+this.uf_1+")"},ve(_c).hashCode=function(){return ae(this.uf_1)},ve(_c).equals=function(n){if(this===n)return!0;if(!(n instanceof _c))return!1;var t=n instanceof _c?n:pe();return!!le(this.uf_1,t.uf_1)},ve(vc).toString=function(){return"SetTab(tab="+this.vf_1+")"},ve(vc).hashCode=function(){return this.vf_1.hashCode()},ve(vc).equals=function(n){if(this===n)return!0;if(!(n instanceof vc))return!1;var t=n instanceof vc?n:pe();return!!this.vf_1.equals(t.vf_1)},ve(dc).gg=function(n,t,r,i,e,u,o,f,s,c){return new dc(n,t,r,i,e,u,o,f,s,c)},ve(dc).hg=function(n,t,r,i,e,u,o,f,s,c,a){return n=n===A?this.wf_1:n,t=t===A?this.xf_1:t,r=r===A?this.yf_1:r,i=i===A?this.zf_1:i,e=e===A?this.ag_1:e,u=u===A?this.bg_1:u,o=o===A?this.cg_1:o,f=f===A?this.dg_1:f,s=s===A?this.eg_1:s,c=c===A?this.fg_1:c,a===A?this.gg(n,t,r,i,e,u,o,f,s,c):a.gg.call(this,n,t,r,i,e,u,o,f,s,c)},ve(dc).toString=function(){return"Model(heading="+this.wf_1+", summary="+this.xf_1+", learnMore="+this.yf_1+", messageTree="+this.zf_1+", problemIdTree="+this.ag_1+", fileLocationTree="+this.bg_1+", pluginLocationTree="+this.cg_1+", taskLocationTree="+this.dg_1+", problemCount="+this.eg_1+", tab="+this.fg_1+")"},ve(dc).hashCode=function(){var n=this.wf_1.hashCode();return n=Mn(n,31)+ae(this.xf_1)|0,n=Mn(n,31)+this.yf_1.hashCode()|0,n=Mn(n,31)+this.zf_1.hashCode()|0,n=Mn(n,31)+this.ag_1.hashCode()|0,n=Mn(n,31)+this.bg_1.hashCode()|0,n=Mn(n,31)+this.cg_1.hashCode()|0,n=Mn(n,31)+this.dg_1.hashCode()|0,n=Mn(n,31)+this.eg_1|0,Mn(n,31)+this.fg_1.hashCode()|0},ve(dc).equals=function(n){if(this===n)return!0;if(!(n instanceof dc))return!1;var t=n instanceof dc?n:pe();return!!(this.wf_1.equals(t.wf_1)&&le(this.xf_1,t.xf_1)&&this.yf_1.equals(t.yf_1)&&this.zf_1.equals(t.zf_1)&&this.ag_1.equals(t.ag_1)&&this.bg_1.equals(t.bg_1)&&this.cg_1.equals(t.cg_1)&&this.dg_1.equals(t.dg_1)&&this.eg_1===t.eg_1&&this.fg_1.equals(t.fg_1))},ve(Lc).ig=function(n,t){var r,i;return n instanceof hc?r=t.hg(A,A,A,A,A,ps().id(n.sf_1,t.bg_1)):n instanceof lc?r=t.hg(A,A,A,A,A,A,ps().id(n.tf_1,t.cg_1)):n instanceof _c?r=t.hg(A,A,A,A,A,A,A,ps().id(n.uf_1,t.dg_1)):n instanceof ac?r=t.hg(A,A,A,A,ps().id(n.rf_1,t.ag_1)):n instanceof cc?r=t.hg(A,A,A,ps().id(n.qf_1,t.zf_1)):n instanceof Dc?r=function(n,t,r,i){var e;return r instanceof cc?e=n.hg(A,A,A,Ac(n.zf_1,r,i)):r instanceof ac?e=n.hg(A,A,A,A,Ac(n.ag_1,r,i)):r instanceof hc?e=n.hg(A,A,A,A,A,Ac(n.bg_1,r,i)):r instanceof lc?e=n.hg(A,A,A,A,A,A,Ac(n.cg_1,r,i)):r instanceof _c?e=n.hg(A,A,A,A,A,A,A,Ac(n.dg_1,r,i)):(console.error("Unhandled tree intent: "+r),e=n),e}(t,0,n.xc_1,(i=n,function(n){var t;if(!(n instanceof Vu))throw _u(ce("Failed requirement."));for(var r=n.oa_1,e=i.wc_1,u=Rr(Tt(r,10)),o=0,f=r.f();f.g();){var s,c,a=f.h(),h=o;if(o=h+1|0,e===yr(h)){var l=a.sa_1;c=a.ua(A,null==l?null:l.ad())}else c=a;s=c,u.d(s)}return t=u,n.qa(A,A,t)})):n instanceof Mc?(window.navigator.clipboard.writeText(n.hd_1),r=t):n instanceof vc?r=t.hg(A,A,A,A,A,A,A,A,A,n.vf_1):(console.error("Unhandled intent: "+n),r=t),r},ve(Lc).ba=function(n,t){var r=n instanceof Oc?n:pe();return this.ig(r,t instanceof dc?t:pe())},ve(Lc).jg=function(n){return Hf().y9(us(xc),[wc(0,n),bc(0,n)])},ve(Lc).z9=function(n){return this.jg(n instanceof dc?n:pe())},ve(Mc).toString=function(){return"Copy(text="+this.hd_1+")"},ve(Mc).hashCode=function(){return he(this.hd_1)},ve(Mc).equals=function(n){if(this===n)return!0;if(!(n instanceof Mc))return!1;var t=n instanceof Mc?n:pe();return this.hd_1===t.hd_1},ve(Dc).toString=function(){return"ToggleStackTracePart(partIndex="+this.wc_1+", location="+this.xc_1+")"},ve(Dc).hashCode=function(){var n=this.wc_1;return Mn(n,31)+ae(this.xc_1)|0},ve(Dc).equals=function(n){if(this===n)return!0;if(!(n instanceof Dc))return!1;var t=n instanceof Dc?n:pe();return this.wc_1===t.wc_1&&!!le(this.xc_1,t.xc_1)},ve(ui).k6=function(){var n=Object.create(null);return n.foo=1,delete n.foo,br(),n},l=null,function(){var n=configurationCacheProblems();if(null==n.problemsReport)Mf(Ff("report"),Xo(),function(n){var t,r,i,e,u,o,f,s,c,a,h=function(n){for(var t=Or(),r=Or(),i=Or(),e=0,u=n.length;e<u;){var o=n[e];e=e+1|0;var f,s=o.input,c=null==s?null:r.d(rf(s,o));if(null==c){var a=o.incompatibleTask;f=null==a?null:i.d(rf(a,o))}else f=c;if(null==f){var h=we(o.problem);t.d(rf(h,o))}}return new tf(t,r,i)}(n.diagnostics),l=n.totalProblemCount;return new xo((f=(t=n).buildName,s=t.requestedTasks,c=null==s?null:rr(s," ",A,r=r!==A&&r)>=0,a=null==c||c,Sf().qd((i=t,e=f,u=s,o=a,function(n){n.ed(function(n){var t;if(re(n)>0){var r,i=ne(n,0);r=function(n){return 97<=n&&n<=122||!(Ei(n,128)<0)&&function(n){var t;return t=1===function(n){var t=n,r=su(au().h9_1,t),i=au().h9_1[r],e=(i+au().i9_1[r]|0)-1|0,u=au().j9_1[r];if(t>e)return 0;var o=3&u;if(0===o){var f=2,s=i,c=0;if(c<=1)do{if(c=c+1|0,(s=s+(u>>f&127)|0)>t)return 3;if((s=s+(u>>(f=f+7|0)&127)|0)>t)return 0;f=f+7|0}while(c<=1);return 3}if(u<=7)return o;var a=t-i|0;return u>>Mn(2,u<=31?a%2|0:a)&3}(n)||function(n){var t=su(lu().k9_1,n);return t>=0&&n<(lu().k9_1[t]+lu().l9_1[t]|0)}(n),t}(n)}(i)?function(n){return function(n){var t=Li(n).toUpperCase();if(t.length>1){var r;if(329===n)r=t;else{var i=ne(t,0),e=t.substring(1).toLowerCase();r=Li(i)+e}return r}return Li(function(n){return function(n){var t=n;return 452<=t&&t<=460||497<=t&&t<=499?Ue(Mn(3,(t+1|0)/3|0)):4304<=t&&t<=4346||4349<=t&&t<=4351?n:xi(n)}(n)}(n))}(n)}(i):Li(i),t=ce(r)+n.substring(1)}else t=n;return t}(i.cacheAction)+" the configuration cache for ");var t=e;null==t||n.fd(t),null==e||n.ed(" build and ");var r=u;return null==(null==r?null:n.fd(r))&&n.ed("default"),n.ed(o?" tasks":" task"),br()}))),function(n,t){var r=n.cacheActionDescription,i=null==r?null:mf(r),e=Sf().rd(function(n){var t=n.od_1.k(),r=kf(t,"build configuration input");return t>0?r+" and will cause the cache to be discarded when "+(t<=1?"its":"their")+" value change":r}(t)),u=Sf().rd(function(n,t){var r=n.totalProblemCount,i=t.nd_1.k(),e=kf(r,"problem");return r>i?e+", only the first "+i+" "+yf(i)+" included in this report":e}(n,t));return function(n,t){for(var r=0,i=n.length;r<i;){var e=n[r];r=r+1|0,null!=e&&t.d(e)}return t}([i,e,u],Or())}(n,h),new Bf("Gradle Configuration Cache",n.documentationLink),hf(new no(Zo().qc_1),ut(Vn(h.nd_1),gf)),hf(new no(Yo().qc_1),function(n){return ut(Vn(n),wf)}(h.nd_1)),hf(new no(Qo().qc_1),ut(Vn(h.od_1),vf)),hf(new no(Wo().qc_1),ut(Vn(h.pd_1),df)),0===l?Qo():Zo())}(n));else{var t=n.problemsReport;Mf(Ff("report"),Nc(),function(n,t){ec();for(var r=n.summaries,i=Rr(r.length),e=0,u=r.length;e<u;){var o,f=r[e];e=e+1|0;for(var s=f.problemId,c=Rr(s.length),a=0,h=s.length;a<h;){var l,_=s[a];a=a+1|0,l=new zs(_.name,_.displayName),c.d(l)}o=new Ts(c,f.count),i.d(o)}for(var v=i,d=function(n,t){ec();for(var r=li(),i=0,e=n.length;i<e;){var u=n[i];i=i+1|0;var o,f=(a=u.problemId,ec(),On(a,":",A,A,A,A,Ws)),s=r.v1(f);if(null==s){var c=Or();r.h5(f,c),o=c}else o=s;o.d(u)}for(var a,h=r.o(),l=Rr(Tt(h,10)),_=h.f();_.g();){for(var v,d=_.h(),g=d.i1(),w=Rr(Tt(g,10)),b=g.f();b.g();){var p;p=Os(b.h(),null,!0),w.d(p)}var m,k=Zn(w),q=Un(d.i1()),y=Hs(q,new Wu($s(Rs(q)).ed(" ("+d.i1().k()+")").j5()));n:{for(var B=t.f();B.g();){var C=B.h();if(Ds(C.ff_1,q.problemId)){m=C;break n}}m=null}var x=m;null==x||k.d(Ns(x.gf_1)),v=new js(y,k),l.d(v)}var j=l;return new ds(new js(new uc("message tree root"),j))}(t,v),g=function(n,t){ec();for(var r=function(){ec();var n=Or();return new Ms(new js(new oc(Sf().rd("Ungrouped"),!0),n),n,li())}(),i=li(),e=0,u=n.length;e<u;){var o=n[e];e=e+1|0;for(var f=Yn(Dn(o.problemId,1)),s=Rr(Tt(f,10)),c=f.f();c.g();){var a,h=c.h();a=new zs(h.name,h.displayName),s.d(a)}var l=Fs(i,s),_=Os(o);null==l?r.if_1.d(_):l.if_1.d(_)}for(var v=Rr(Tt(t,10)),d=t.f();d.g();){var g,w=d.h();g=new Ts(Yn(Wn(w.ff_1,1)),w.gf_1),v.d(g)}for(var b=li(),p=v.f();p.g();){var m,k=p.h(),q=k.ff_1,y=b.v1(q);if(null==y){var B=Or();b.h5(q,B),m=B}else m=y;m.d(k)}for(var C=b.o(),x=Rr(Tt(C,10)),j=C.f();j.g();){for(var P,I=j.h(),S=I.j1(),z=0,T=I.i1().f();T.g();)z=z+T.h().gf_1|0;P=new Ts(S,z),x.d(P)}for(var E=x.f();E.g();){var L=E.h(),N=Fs(i,L.ff_1),A=null==N?null:N.if_1;null==A||A.d(Ns(L.gf_1))}for(var M=i.w1(),F=Rr(Tt(M,10)),D=M.f();D.g();){var O;O=D.h().hf_1,F.d(O)}var R=function(n,t){var r=Rr(n.k());return r.m(n),r.d(t),r}(F,r.hf_1);return new ds(new js(new uc("group tree root"),R))}(t,v),w=0,b=v.f();b.g();)w=w+b.h().gf_1|0;for(var p=Es(t,w,(ec(),wn)),m=0,k=v.f();k.g();)m=m+k.h().gf_1|0;for(var q=Es(t,m,(ec(),bn)),y=0,B=v.f();B.g();)y=y+B.h().gf_1|0;var C=Es(t,y,(ec(),pn));return new dc(Sf().rd("Problems Report"),function(n,t){ec();var r,i,e,u=n.description,o=null==u?null:qr(mf(u));return r=null==o?qr(Sf().qd((i=t,e=n,function(n){n.ed(i.length+" problems have been reported during the execution");var t=e.buildName;null==t||(n.ed(" of build "),n.fd(t));var r=e.requestedTasks;return null==r||(n.ed(" for the following tasks:"),n.fd(r),br()),br()}))):o,r}(n,t),new Bf("reporting problems",n.documentationLink),d,g,p,q,C,t.length,function(n,t,r,i,e){return ec(),po(r)>0?tc():po(n)>0?Js():po(t)>0?nc():po(i)>0?rc():po(e)>0?ic():Js()}(d,g,p,q,C))}(t,n.diagnostics))}}(),n}(void 0===this["configuration-cache-report"]?{}:this["configuration-cache-report"])}}[70](),{}))));
//# sourceMappingURL=configuration-cache-report.js.map
                </script>

</body>
</html>
```

## File: android/gradle/wrapper/gradle-wrapper.properties
```
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.1.0-all.zip
```

## File: android/.gitignore
```
gradle-wrapper.jar
/.gradle
/captures/
/gradlew
/gradlew.bat
/local.properties
GeneratedPluginRegistrant.java
.cxx/

# Remember to never publicly share your keystore.
# See https://flutter.dev/to/reference-keystore
key.properties
**/*.keystore
**/*.jks
```

## File: android/build.gradle.kts
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```

## File: android/gradle.properties
```
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
# This newDsl flag was added by the Flutter template
android.newDsl=false
# This builtInKotlin flag was added by the Flutter template
android.builtInKotlin=false
```

## File: android/settings.gradle.kts
```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
```

## File: assets/animations/fireworks.json
```json
{"v":"5.5.7","fr":30,"ip":0,"op":60,"w":300,"h":300,"assets":[],"layers":[]}
```

## File: assets/data/questions_american.json
```json
{
    "1": [
        {
            "id": "ame_1_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong kasunduan ang nilagdaan noong Disyembre 1898 kung saan ipinagbili ng Espanya ang Pilipinas sa Amerika sa halagang \\$20 Milyon?",
            "options": [
                {
                    "label": "A",
                    "text": "Kasunduan sa Paris"
                },
                {
                    "label": "B",
                    "text": "Kasunduan sa Biak-na-Bato"
                },
                {
                    "label": "C",
                    "text": "Batas Tydings-McDuffie"
                },
                {
                    "label": "D",
                    "text": "Kasunduang Bates"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Treaty of Paris (1898) ang pormal na naglipat ng kontrol sa Pilipinas mula Espanya tungo sa US."
        },
        {
            "id": "ame_1_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Pangulo ng Unang Republikang Pilipino sa Malolos noong 1899?",
            "options": [
                {
                    "label": "A",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "B",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "C",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "D",
                    "text": "Apolinario Mabini"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naging unang Pangulo ng Unang Republikang Pilipino si Emilio Aguinaldo, na pinasinayaan sa Malolos, Bulacan noong 1899."
        },
        {
            "id": "ame_1_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong digmaan ang naganap sa pagitan ng mga Pilipino at Amerikano matapos ang Kasunduan sa Paris?",
            "options": [
                {
                    "label": "A",
                    "text": "Digmaang Pilipino-Amerikano"
                },
                {
                    "label": "B",
                    "text": "Ikalawang Digmaang Pandaigdig"
                },
                {
                    "label": "C",
                    "text": "Digmaan sa Mactan"
                },
                {
                    "label": "D",
                    "text": "Rebolusyong Pilipino"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Digmaang Pilipino-Amerikano (1899-1902) ay sumiklab matapos hindi kilalanin ng Amerika ang kalayaan ng Unang Republika."
        },
        {
            "id": "ame_1_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Civil Governor ng Pilipinas sa ilalim ng pamahalaang Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "William Howard Taft"
                },
                {
                    "label": "B",
                    "text": "Douglas MacArthur"
                },
                {
                    "label": "C",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "D",
                    "text": "Frank Murphy"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si William Howard Taft ang naging unang Civil Governor ng Pilipinas noong 1901."
        },
        {
            "id": "ame_1_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa unang anyo ng pamahalaang itinatag ng mga Amerikano sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Insular Government"
                },
                {
                    "label": "B",
                    "text": "Commonwealth"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Republika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Insular Government ang naging unang anyo ng pamahalaang sibil na itinatag ng Amerika sa Pilipinas."
        }
    ],
    "2": [
        {
            "id": "ame_2_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saang isla naganap ang kilalang labanan sa pagitan ng mga Pilipino at Amerikano sa Balangiga?",
            "options": [
                {
                    "label": "A",
                    "text": "Samar"
                },
                {
                    "label": "B",
                    "text": "Cebu"
                },
                {
                    "label": "C",
                    "text": "Bohol"
                },
                {
                    "label": "D",
                    "text": "Palawan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap sa Balangiga, Samar ang isang kilalang labanan sa pagitan ng mga Pilipino at tropang Amerikano."
        },
        {
            "id": "ame_2_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong estratehiya ng pakikidigma ang ginamit ng mga Pilipino laban sa mas malakas na hukbong Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Gerilyang pakikidigma (guerilla warfare)"
                },
                {
                    "label": "B",
                    "text": "Direktang labanan sa bukas na patlang"
                },
                {
                    "label": "C",
                    "text": "Pananalakay sa dagat gamit ang malalaking barko"
                },
                {
                    "label": "D",
                    "text": "Diplomasya lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Gumamit ang mga Pilipino ng gerilyang taktika, gaya ng biglaang atake at pagtago sa kabundukan, dahil mas mahina ang kanilang armas kumpara sa Amerikano."
        },
        {
            "id": "ame_2_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan nahuli si Emilio Aguinaldo ng mga Amerikano noong 1901?",
            "options": [
                {
                    "label": "A",
                    "text": "Palanan, Isabela"
                },
                {
                    "label": "B",
                    "text": "Malolos, Bulacan"
                },
                {
                    "label": "C",
                    "text": "Cavite"
                },
                {
                    "label": "D",
                    "text": "Bataan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nahuli ng mga Amerikano si Emilio Aguinaldo sa Palanan, Isabela noong Marso 1901, na nagpahina sa paglaban ng mga Pilipino."
        },
        {
            "id": "ame_2_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas ang ipinatupad ng Amerika upang parusahan ang sinumang lumalaban sa awtoridad nito?",
            "options": [
                {
                    "label": "A",
                    "text": "Batas Sedition"
                },
                {
                    "label": "B",
                    "text": "Batas Tydings-McDuffie"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Batas Organic"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Batas Sedition ay ipinatupad upang parusahan ang sinumang nagtataguyod ng kalayaan o lumalaban sa pamahalaang Amerikano."
        },
        {
            "id": "ame_2_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na idineklara ng Amerika ang katapusan ng Digmaang Pilipino-Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "1902"
                },
                {
                    "label": "B",
                    "text": "1898"
                },
                {
                    "label": "C",
                    "text": "1935"
                },
                {
                    "label": "D",
                    "text": "1946"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Opisyal na idineklara ng Amerika ang katapusan ng digmaan noong 1902, bagamat may patuloy pa ring paglaban sa ilang lugar."
        }
    ],
    "3": [
        {
            "id": "ame_3_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mga gurong Amerikanong ipinadala sa Pilipinas upang magturo?",
            "options": [
                {
                    "label": "A",
                    "text": "Thomasites"
                },
                {
                    "label": "B",
                    "text": "Pensionados"
                },
                {
                    "label": "C",
                    "text": "Ilustrados"
                },
                {
                    "label": "D",
                    "text": "Katipuneros"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga Thomasites ay mga gurong Amerikano na dumating sakay ng barkong USS Thomas upang magpalaganap ng edukasyon."
        },
        {
            "id": "ame_3_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong wika ang ginamit bilang pangunahing midyum ng pagtuturo sa mga paaralang itinatag ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Ingles"
                },
                {
                    "label": "B",
                    "text": "Espanyol"
                },
                {
                    "label": "C",
                    "text": "Hapon"
                },
                {
                    "label": "D",
                    "text": "Baybayin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Ingles ang ginamit bilang midyum ng pagtuturo sa sistema ng pampublikong edukasyon na itinatag ng mga Amerikano."
        },
        {
            "id": "ame_3_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pambansang unibersidad ang itinatag noong 1908 sa panahon ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "University of the Philippines"
                },
                {
                    "label": "B",
                    "text": "Ateneo de Manila"
                },
                {
                    "label": "C",
                    "text": "University of Santo Tomas"
                },
                {
                    "label": "D",
                    "text": "De La Salle University"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ang University of the Philippines noong 1908 bilang pambansang unibersidad ng bansa."
        },
        {
            "id": "ame_3_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa programang nagpapadala ng mga batang Pilipino upang mag-aral sa Estados Unidos?",
            "options": [
                {
                    "label": "A",
                    "text": "Pensionado Program"
                },
                {
                    "label": "B",
                    "text": "Thomasite Program"
                },
                {
                    "label": "C",
                    "text": "Katipunan Program"
                },
                {
                    "label": "D",
                    "text": "Propaganda Movement"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Pensionado Program ay nagbigay-pagkakataon sa mga piling estudyanteng Pilipino na mag-aral sa Amerika at bumalik bilang eksperto sa iba't ibang larangan."
        },
        {
            "id": "ame_3_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing bunga ng sistema ng pampublikong edukasyon na itinatag ng mga Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagtaas ng bilang ng marunong bumasa at sumulat na Pilipino"
                },
                {
                    "label": "B",
                    "text": "Pagbaba ng bilang ng estudyante"
                },
                {
                    "label": "C",
                    "text": "Pagsasara ng lahat ng paaralan"
                },
                {
                    "label": "D",
                    "text": "Walang naging epekto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang malawakang pagtatayo ng pampublikong paaralan ay nagdulot ng pagtaas ng literacy rate ng mga Pilipino."
        }
    ],
    "4": [
        {
            "id": "ame_4_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng patakarang pangkalakalan ang ipinatupad sa pagitan ng Pilipinas at Estados Unidos?",
            "options": [
                {
                    "label": "A",
                    "text": "Free Trade (walang taripa)"
                },
                {
                    "label": "B",
                    "text": "Barter system"
                },
                {
                    "label": "C",
                    "text": "Bandala"
                },
                {
                    "label": "D",
                    "text": "Walang kalakalan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang patakarang free trade sa pagitan ng Pilipinas at Estados Unidos, na nagpalago sa export ngunit nagpataas din ng dependensiya sa Amerika."
        },
        {
            "id": "ame_4_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isa sa mga pangunahing inieksport na produkto ng Pilipinas sa panahon ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Asukal"
                },
                {
                    "label": "B",
                    "text": "Kotse"
                },
                {
                    "label": "C",
                    "text": "Elektroniks"
                },
                {
                    "label": "D",
                    "text": "Bakal"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang asukal, abaka, at niyog ay ilan sa mga pangunahing produktong inieksport ng Pilipinas sa Estados Unidos."
        },
        {
            "id": "ame_4_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang pinaunlad ng mga Amerikano bilang bahagi ng imprastraktura ng bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga kalsada, tulay, at riles"
                },
                {
                    "label": "B",
                    "text": "Mga simbahan lamang"
                },
                {
                    "label": "C",
                    "text": "Mga bilangguan lamang"
                },
                {
                    "label": "D",
                    "text": "Wala silang itinayo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtayo ang mga Amerikano ng mga kalsada, tulay, at riles bilang bahagi ng modernisasyon ng bansa."
        },
        {
            "id": "ame_4_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang pagbabagong idinulot ng mga Amerikano sa larangan ng kalusugan?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagpapabuti ng sanitasyon at pampublikong ospital"
                },
                {
                    "label": "B",
                    "text": "Pagsasara ng lahat ng ospital"
                },
                {
                    "label": "C",
                    "text": "Walang binago sa kalusugan"
                },
                {
                    "label": "D",
                    "text": "Pagpapalaganap ng sakit"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagpakilala ang mga Amerikano ng mga hakbang sa pampublikong kalusugan at sanitasyon na nagpababa ng dami ng maysakit."
        },
        {
            "id": "ame_4_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong salapi ang ipinakilala ng Amerika na nakabatay sa dolyar ng Estados Unidos?",
            "options": [
                {
                    "label": "A",
                    "text": "Peso na nakabatay sa dolyar"
                },
                {
                    "label": "B",
                    "text": "Piloncitos"
                },
                {
                    "label": "C",
                    "text": "Yen"
                },
                {
                    "label": "D",
                    "text": "Real de a ocho"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagpakilala ang mga Amerikano ng bagong sistemang salapi na nakabatay sa dolyar upang mapadali ang kalakalan."
        }
    ],
    "5": [
        {
            "id": "ame_5_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa unang lehislatibong katawan na binubuo ng mga Amerikanong opisyal at itinatag noong 1900?",
            "options": [
                {
                    "label": "A",
                    "text": "Philippine Commission"
                },
                {
                    "label": "B",
                    "text": "Philippine Assembly"
                },
                {
                    "label": "C",
                    "text": "Katipunan"
                },
                {
                    "label": "D",
                    "text": "Malolos Congress"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Philippine Commission, na binubuo ng mga Amerikano, ang naunang lehislatibong katawan na itinatag ng Amerika sa Pilipinas."
        },
        {
            "id": "ame_5_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan naganap ang unang pambansang halalan para sa Philippine Assembly?",
            "options": [
                {
                    "label": "A",
                    "text": "1907"
                },
                {
                    "label": "B",
                    "text": "1898"
                },
                {
                    "label": "C",
                    "text": "1935"
                },
                {
                    "label": "D",
                    "text": "1946"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Noong 1907, ginanap ang unang pambansang halalan para sa Philippine Assembly, ang unang katawang binubuo ng mga Pilipinong halal."
        },
        {
            "id": "ame_5_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas ang nangako ng kalayaan ng Pilipinas mula sa Estados Unidos noong 1916?",
            "options": [
                {
                    "label": "A",
                    "text": "Jones Law"
                },
                {
                    "label": "B",
                    "text": "Tydings-McDuffie Act"
                },
                {
                    "label": "C",
                    "text": "Batas Sedition"
                },
                {
                    "label": "D",
                    "text": "Hare-Hawes-Cutting Act"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Jones Law (1916) ang unang batas na nangako ng kalayaan sa Pilipinas kapag handa na itong mamahala sa sarili."
        },
        {
            "id": "ame_5_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong partido pampulitika ang itinatag na naging pangunahing puwersa sa pamahalaan noong panahong ito?",
            "options": [
                {
                    "label": "A",
                    "text": "Nacionalista Party"
                },
                {
                    "label": "B",
                    "text": "Liberal Party"
                },
                {
                    "label": "C",
                    "text": "Katipunan Party"
                },
                {
                    "label": "D",
                    "text": "Kilusang Bagong Lipunan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Nacionalista Party ang naging pangunahing partido pampulitika na nangunguna sa kilusan tungo sa kalayaan."
        },
        {
            "id": "ame_5_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino sa mga sumusunod ang mga lider ng Nacionalista Party at kilalang tagapagtaguyod ng kalayaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Manuel Quezon at Sergio Osmena"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio at Emilio Jacinto"
                },
                {
                    "label": "C",
                    "text": "Jose Rizal at Marcelo del Pilar"
                },
                {
                    "label": "D",
                    "text": "Lapu-Lapu at Sikatuna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sina Manuel L. Quezon at Sergio Osmena ang naging mga pangunahing lider ng Nacionalista Party at ng kilusan tungo sa kalayaan."
        }
    ],
    "6": [
        {
            "id": "ame_6_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mga delegasyong ipinadala ng Pilipinas sa Kongreso ng Estados Unidos upang isulong ang kalayaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Independence Missions"
                },
                {
                    "label": "B",
                    "text": "Pensionado Program"
                },
                {
                    "label": "C",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "D",
                    "text": "Katipunan Mission"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagpadala ang Pilipinas ng ilang Independence Missions sa Kongreso ng US upang direktang isulong ang kalayaan ng bansa."
        },
        {
            "id": "ame_6_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas noong 1932 ang unang nagbigay ng balangkas para sa kalayaan ngunit tinutulan ni Quezon?",
            "options": [
                {
                    "label": "A",
                    "text": "Hare-Hawes-Cutting Act"
                },
                {
                    "label": "B",
                    "text": "Tydings-McDuffie Act"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Batas Organic"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Hare-Hawes-Cutting Act (1932) ay unang batas na naglatag ng balangkas para sa kalayaan ngunit tinutulan ni Quezon dahil sa ilang probisyon."
        },
        {
            "id": "ame_6_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas noong 1934 ang nagtatag ng Commonwealth of the Philippines at naglatag ng 10 taong transisyon patungo sa kalayaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Tydings-McDuffie Act"
                },
                {
                    "label": "B",
                    "text": "Hare-Hawes-Cutting Act"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Batas Sedition"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Tydings-McDuffie Act (1934) ang nagtatag ng Commonwealth of the Philippines at naglatag ng sampung taong panahon bago ganap na maging malaya."
        },
        {
            "id": "ame_6_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ilang taon ang inilaang panahon ng transisyon bago ganap na makamit ang kalayaan sa ilalim ng Tydings-McDuffie Act?",
            "options": [
                {
                    "label": "A",
                    "text": "10 taon"
                },
                {
                    "label": "B",
                    "text": "5 taon"
                },
                {
                    "label": "C",
                    "text": "20 taon"
                },
                {
                    "label": "D",
                    "text": "1 taon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naglatag ang Tydings-McDuffie Act ng sampung taong panahon ng paghahanda (Commonwealth period) bago ganap na kalayaan."
        },
        {
            "id": "ame_6_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na itinatag ang Commonwealth of the Philippines?",
            "options": [
                {
                    "label": "A",
                    "text": "1935"
                },
                {
                    "label": "B",
                    "text": "1946"
                },
                {
                    "label": "C",
                    "text": "1898"
                },
                {
                    "label": "D",
                    "text": "1902"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ang Commonwealth of the Philippines noong 1935 bilang paghahanda tungo sa ganap na kalayaan."
        }
    ],
    "7": [
        {
            "id": "ame_7_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Pangulo ng Commonwealth of the Philippines?",
            "options": [
                {
                    "label": "A",
                    "text": "Manuel L. Quezon"
                },
                {
                    "label": "B",
                    "text": "Sergio Osmena"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Manuel Roxas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Manuel L. Quezon ang naging unang Pangulo ng Commonwealth of the Philippines noong 1935."
        },
        {
            "id": "ame_7_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong Saligang Batas ang pinagtibay noong 1935 para gabayan ang Commonwealth?",
            "options": [
                {
                    "label": "A",
                    "text": "1935 Constitution"
                },
                {
                    "label": "B",
                    "text": "1987 Constitution"
                },
                {
                    "label": "C",
                    "text": "Malolos Constitution"
                },
                {
                    "label": "D",
                    "text": "1973 Constitution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinagtibay ang 1935 Constitution bilang batayang batas ng Commonwealth of the Philippines."
        },
        {
            "id": "ame_7_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong programa ni Pangulong Quezon ang naglalayong tulungan ang mahihirap at manggagawa?",
            "options": [
                {
                    "label": "A",
                    "text": "Social Justice Program"
                },
                {
                    "label": "B",
                    "text": "Bagong Lipunan Program"
                },
                {
                    "label": "C",
                    "text": "Martial Law"
                },
                {
                    "label": "D",
                    "text": "Pensionado Program"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ni Quezon ang Social Justice Program upang tulungan ang mga magsasaka at manggagawa sa panahon ng Commonwealth."
        },
        {
            "id": "ame_7_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong wika ang itinatag na batayan ng Wikang Pambansa noong panahon ng Commonwealth?",
            "options": [
                {
                    "label": "A",
                    "text": "Tagalog"
                },
                {
                    "label": "B",
                    "text": "Ingles"
                },
                {
                    "label": "C",
                    "text": "Espanyol"
                },
                {
                    "label": "D",
                    "text": "Cebuano"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Tagalog ang pinili bilang batayan ng Wikang Pambansa sa panahon ng Commonwealth."
        },
        {
            "id": "ame_7_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon inaasahang bibigyan ng ganap na kalayaan ang Pilipinas ayon sa Tydings-McDuffie Act?",
            "options": [
                {
                    "label": "A",
                    "text": "1946"
                },
                {
                    "label": "B",
                    "text": "1935"
                },
                {
                    "label": "C",
                    "text": "1941"
                },
                {
                    "label": "D",
                    "text": "1902"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ayon sa Tydings-McDuffie Act, dapat sanang makamit ng Pilipinas ang ganap na kalayaan noong 1946."
        }
    ],
    "8": [
        {
            "id": "ame_8_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na palakasan ang ipinakilala ng mga Amerikano sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Basketball"
                },
                {
                    "label": "B",
                    "text": "Sipa"
                },
                {
                    "label": "C",
                    "text": "Arnis"
                },
                {
                    "label": "D",
                    "text": "Sabong"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinakilala ng mga Amerikano ang basketball na naging isa sa mga pinakapopular na palakasan sa Pilipinas."
        },
        {
            "id": "ame_8_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa proseso ng pagbibigay ng mas maraming posisyon sa gobyerno sa mga Pilipino sa halip na Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Filipinization"
                },
                {
                    "label": "B",
                    "text": "Americanization"
                },
                {
                    "label": "C",
                    "text": "Reduccion"
                },
                {
                    "label": "D",
                    "text": "Colonization"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Filipinization ay ang unti-unting pagbibigay ng higit pang tungkulin sa gobyerno sa mga Pilipino sa halip na sa mga Amerikano."
        },
        {
            "id": "ame_8_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng pamahalaan ang isinulong ng mga Amerikano bilang modelo para sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Demokrasya"
                },
                {
                    "label": "B",
                    "text": "Monarkiya"
                },
                {
                    "label": "C",
                    "text": "Diktadura"
                },
                {
                    "label": "D",
                    "text": "Teokrasya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinulong ng mga Amerikano ang mga institusyong demokratiko bilang bahagi ng kanilang sistema ng pamamahala sa Pilipinas."
        },
        {
            "id": "ame_8_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano naiimpluwensyahan ang uri ng pananamit ng mga Pilipino noong panahon ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging popular ang estilong \"Amerikana\" o kasuotang Kanluranin"
                },
                {
                    "label": "B",
                    "text": "Bumalik sila sa bahag"
                },
                {
                    "label": "C",
                    "text": "Walang nagbago"
                },
                {
                    "label": "D",
                    "text": "Nagbawal ang gobyerno ng pananamit"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naging popular ang estilong Kanluranin o \"Amerikana\" na kasuotan bilang impluwensya ng kulturang Amerikano."
        },
        {
            "id": "ame_8_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang anyo ng libangan na ipinakilala sa Pilipinas sa panahong ito?",
            "options": [
                {
                    "label": "A",
                    "text": "Panonood ng sine (cinema)"
                },
                {
                    "label": "B",
                    "text": "Pagsayaw ng tinikling lamang"
                },
                {
                    "label": "C",
                    "text": "Karera ng kalabaw"
                },
                {
                    "label": "D",
                    "text": "Wala"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinakilala ang sine bilang bagong uri ng libangan sa panahon ng Amerikano."
        }
    ],
    "9": [
        {
            "id": "ame_9_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang positibong naiwang epekto ng panahon ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Malawakang sistema ng pampublikong edukasyon"
                },
                {
                    "label": "B",
                    "text": "Kabuuang pagkasira ng ekonomiya"
                },
                {
                    "label": "C",
                    "text": "Pagbabawal sa lahat ng wika ng Pilipino"
                },
                {
                    "label": "D",
                    "text": "Kawalan ng anumang imprastraktura"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang malawakang sistema ng pampublikong edukasyon ay isa sa mga pinakamalaking positibong naiwan ng panahong Amerikano."
        },
        {
            "id": "ame_9_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang hamon o negatibong epekto na dulot ng free trade sa Amerika?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging umasa ang ekonomiya ng Pilipinas sa Estados Unidos"
                },
                {
                    "label": "B",
                    "text": "Naging ganap na malaya ang ekonomiya"
                },
                {
                    "label": "C",
                    "text": "Wala itong idinulot na epekto"
                },
                {
                    "label": "D",
                    "text": "Bumagsak ang Estados Unidos"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang free trade policy, bagamat nagpalago ng eksport, ay lumikha rin ng malaking dependensiya ng ekonomiya ng Pilipinas sa Estados Unidos."
        },
        {
            "id": "ame_9_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang naging bunga ng malawakang paggamit ng Ingles sa edukasyon?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging bihasa sa Ingles ang maraming Pilipino, na nakatulong sa internasyunal na komunikasyon"
                },
                {
                    "label": "B",
                    "text": "Nawala ang lahat ng katutubong wika"
                },
                {
                    "label": "C",
                    "text": "Nawala ang interes sa edukasyon"
                },
                {
                    "label": "D",
                    "text": "Walang naging epekto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang paggamit ng Ingles bilang midyum ng edukasyon ay naging isang malaking bahagi ng kultura at kakayahang pang-internasyunal ng mga Pilipino."
        },
        {
            "id": "ame_9_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naganap sa hukbong Pilipino habang paghahanda tungo sa kalayaan noong panahon ng Commonwealth?",
            "options": [
                {
                    "label": "A",
                    "text": "Itinatag ang Philippine Army sa ilalim ni Heneral Douglas MacArthur bilang tagapayo"
                },
                {
                    "label": "B",
                    "text": "Ganap na natigil ang hukbo"
                },
                {
                    "label": "C",
                    "text": "Nawalan ng militar ang bansa"
                },
                {
                    "label": "D",
                    "text": "Naipasa agad ang kalayaan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtatag ng pambansang hukbo sa ilalim ng Commonwealth, kasama si Heneral Douglas MacArthur bilang tagapayo, bilang paghahanda sa depensa ng bansa."
        },
        {
            "id": "ame_9_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangyayari ang biglang naganap noong 1941 na nakaabala sa balak na kalayaan ng Pilipinas noong 1946?",
            "options": [
                {
                    "label": "A",
                    "text": "Pananalakay ng Hapon sa Pilipinas"
                },
                {
                    "label": "B",
                    "text": "Pagbagsak ng ekonomiya ng US"
                },
                {
                    "label": "C",
                    "text": "Bagong rebolusyon ng mga Pilipino"
                },
                {
                    "label": "D",
                    "text": "Pagbabalik ng mga Kastila"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sinalakay ng Hapon ang Pilipinas noong Disyembre 1941, na nagsimula ng Ikalawang Digmaang Pandaigdig sa bansa at nagpaantala sa plano ng kalayaan."
        }
    ],
    "10": [
        {
            "id": "ame_10_1",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong kasunduan ang nilagdaan noong 1898 kung saan ipinagbili ng Espanya ang Pilipinas sa Amerika?",
            "options": [
                {
                    "label": "A",
                    "text": "Kasunduan sa Paris"
                },
                {
                    "label": "B",
                    "text": "Kasunduan sa Biak-na-Bato"
                },
                {
                    "label": "C",
                    "text": "Batas Tydings-McDuffie"
                },
                {
                    "label": "D",
                    "text": "Kasunduang Bates"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Treaty of Paris (1898) ang naglipat ng kontrol sa Pilipinas mula Espanya tungo sa US."
        },
        {
            "id": "ame_10_2",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Pangulo ng Unang Republikang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "B",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "C",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "D",
                    "text": "Apolinario Mabini"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naging unang Pangulo ng Unang Republikang Pilipino si Emilio Aguinaldo."
        },
        {
            "id": "ame_10_3",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mga gurong Amerikanong ipinadala upang magturo sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Thomasites"
                },
                {
                    "label": "B",
                    "text": "Pensionados"
                },
                {
                    "label": "C",
                    "text": "Ilustrados"
                },
                {
                    "label": "D",
                    "text": "Katipuneros"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga Thomasites ay mga gurong Amerikano na dumating upang magturo sa Pilipinas."
        },
        {
            "id": "ame_10_4",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pambansang unibersidad ang itinatag noong 1908?",
            "options": [
                {
                    "label": "A",
                    "text": "University of the Philippines"
                },
                {
                    "label": "B",
                    "text": "Ateneo de Manila"
                },
                {
                    "label": "C",
                    "text": "University of Santo Tomas"
                },
                {
                    "label": "D",
                    "text": "De La Salle University"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ang University of the Philippines noong 1908."
        },
        {
            "id": "ame_10_5",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas noong 1934 ang nagtatag ng Commonwealth of the Philippines?",
            "options": [
                {
                    "label": "A",
                    "text": "Tydings-McDuffie Act"
                },
                {
                    "label": "B",
                    "text": "Hare-Hawes-Cutting Act"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Batas Sedition"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Tydings-McDuffie Act (1934) ang nagtatag ng Commonwealth of the Philippines."
        },
        {
            "id": "ame_10_6",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Pangulo ng Commonwealth of the Philippines?",
            "options": [
                {
                    "label": "A",
                    "text": "Manuel L. Quezon"
                },
                {
                    "label": "B",
                    "text": "Sergio Osmena"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Manuel Roxas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Manuel L. Quezon ang naging unang Pangulo ng Commonwealth of the Philippines."
        },
        {
            "id": "ame_10_7",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong wika ang itinatag na batayan ng Wikang Pambansa noong panahon ng Commonwealth?",
            "options": [
                {
                    "label": "A",
                    "text": "Tagalog"
                },
                {
                    "label": "B",
                    "text": "Ingles"
                },
                {
                    "label": "C",
                    "text": "Espanyol"
                },
                {
                    "label": "D",
                    "text": "Cebuano"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Tagalog ang pinili bilang batayan ng Wikang Pambansa."
        },
        {
            "id": "ame_10_8",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na palakasan ang ipinakilala ng mga Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Basketball"
                },
                {
                    "label": "B",
                    "text": "Sipa"
                },
                {
                    "label": "C",
                    "text": "Arnis"
                },
                {
                    "label": "D",
                    "text": "Sabong"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinakilala ng mga Amerikano ang basketball sa Pilipinas."
        },
        {
            "id": "ame_10_9",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan nahuli si Emilio Aguinaldo ng mga Amerikano noong 1901?",
            "options": [
                {
                    "label": "A",
                    "text": "Palanan, Isabela"
                },
                {
                    "label": "B",
                    "text": "Malolos, Bulacan"
                },
                {
                    "label": "C",
                    "text": "Cavite"
                },
                {
                    "label": "D",
                    "text": "Bataan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nahuli si Aguinaldo sa Palanan, Isabela noong 1901."
        },
        {
            "id": "ame_10_10",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon inaasahang bibigyan ng ganap na kalayaan ang Pilipinas ayon sa Tydings-McDuffie Act?",
            "options": [
                {
                    "label": "A",
                    "text": "1946"
                },
                {
                    "label": "B",
                    "text": "1935"
                },
                {
                    "label": "C",
                    "text": "1941"
                },
                {
                    "label": "D",
                    "text": "1902"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ayon sa batas, dapat sanang makamit ang kalayaan noong 1946."
        },
        {
            "id": "ame_10_11",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong digmaan ang naganap sa pagitan ng mga Pilipino at Amerikano matapos ang Kasunduan sa Paris?",
            "options": [
                {
                    "label": "A",
                    "text": "Digmaang Pilipino-Amerikano"
                },
                {
                    "label": "B",
                    "text": "Ikalawang Digmaang Pandaigdig"
                },
                {
                    "label": "C",
                    "text": "Digmaan sa Mactan"
                },
                {
                    "label": "D",
                    "text": "Rebolusyong Pilipino"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Digmaang Pilipino-Amerikano ay sumiklab matapos hindi kilalanin ng Amerika ang kalayaan ng Unang Republika."
        },
        {
            "id": "ame_10_12",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong estratehiya ng pakikidigma ang ginamit ng mga Pilipino laban sa mas malakas na hukbong Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Gerilyang pakikidigma"
                },
                {
                    "label": "B",
                    "text": "Direktang labanan sa bukas na patlang"
                },
                {
                    "label": "C",
                    "text": "Pananalakay sa dagat lamang"
                },
                {
                    "label": "D",
                    "text": "Diplomasya lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Gumamit ang mga Pilipino ng gerilyang taktika dahil mas mahina ang kanilang armas."
        },
        {
            "id": "ame_10_13",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa programang nagpapadala ng mga batang Pilipino upang mag-aral sa Estados Unidos?",
            "options": [
                {
                    "label": "A",
                    "text": "Pensionado Program"
                },
                {
                    "label": "B",
                    "text": "Thomasite Program"
                },
                {
                    "label": "C",
                    "text": "Katipunan Program"
                },
                {
                    "label": "D",
                    "text": "Propaganda Movement"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Pensionado Program ay nagpadala ng mga estudyanteng Pilipino upang mag-aral sa Amerika."
        },
        {
            "id": "ame_10_14",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng patakarang pangkalakalan ang ipinatupad sa pagitan ng Pilipinas at Estados Unidos?",
            "options": [
                {
                    "label": "A",
                    "text": "Free Trade"
                },
                {
                    "label": "B",
                    "text": "Barter system"
                },
                {
                    "label": "C",
                    "text": "Bandala"
                },
                {
                    "label": "D",
                    "text": "Walang kalakalan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang free trade sa pagitan ng Pilipinas at Estados Unidos."
        },
        {
            "id": "ame_10_15",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas ang nangako ng kalayaan ng Pilipinas mula sa Estados Unidos noong 1916?",
            "options": [
                {
                    "label": "A",
                    "text": "Jones Law"
                },
                {
                    "label": "B",
                    "text": "Tydings-McDuffie Act"
                },
                {
                    "label": "C",
                    "text": "Batas Sedition"
                },
                {
                    "label": "D",
                    "text": "Hare-Hawes-Cutting Act"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Jones Law (1916) ang unang batas na nangako ng kalayaan sa Pilipinas."
        },
        {
            "id": "ame_10_16",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino sa mga sumusunod ang mga lider ng Nacionalista Party?",
            "options": [
                {
                    "label": "A",
                    "text": "Manuel Quezon at Sergio Osmena"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio at Emilio Jacinto"
                },
                {
                    "label": "C",
                    "text": "Jose Rizal at Marcelo del Pilar"
                },
                {
                    "label": "D",
                    "text": "Lapu-Lapu at Sikatuna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sina Quezon at Osmena ang naging mga pangunahing lider ng Nacionalista Party."
        },
        {
            "id": "ame_10_17",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong Saligang Batas ang pinagtibay noong 1935 para gabayan ang Commonwealth?",
            "options": [
                {
                    "label": "A",
                    "text": "1935 Constitution"
                },
                {
                    "label": "B",
                    "text": "1987 Constitution"
                },
                {
                    "label": "C",
                    "text": "Malolos Constitution"
                },
                {
                    "label": "D",
                    "text": "1973 Constitution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinagtibay ang 1935 Constitution bilang batayang batas ng Commonwealth."
        },
        {
            "id": "ame_10_18",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa proseso ng pagbibigay ng mas maraming posisyon sa gobyerno sa mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Filipinization"
                },
                {
                    "label": "B",
                    "text": "Americanization"
                },
                {
                    "label": "C",
                    "text": "Reduccion"
                },
                {
                    "label": "D",
                    "text": "Colonization"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Filipinization ay ang unti-unting pagbibigay ng higit pang tungkulin sa gobyerno sa mga Pilipino."
        },
        {
            "id": "ame_10_19",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang positibong naiwang epekto ng panahon ng Amerikano?",
            "options": [
                {
                    "label": "A",
                    "text": "Malawakang sistema ng pampublikong edukasyon"
                },
                {
                    "label": "B",
                    "text": "Kabuuang pagkasira ng ekonomiya"
                },
                {
                    "label": "C",
                    "text": "Pagbabawal sa lahat ng wika ng Pilipino"
                },
                {
                    "label": "D",
                    "text": "Kawalan ng anumang imprastraktura"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang malawakang sistema ng pampublikong edukasyon ay isa sa mga pinakamalaking positibong naiwan."
        },
        {
            "id": "ame_10_20",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang hamon na dulot ng free trade sa Amerika?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging umasa ang ekonomiya ng Pilipinas sa Estados Unidos"
                },
                {
                    "label": "B",
                    "text": "Naging ganap na malaya ang ekonomiya"
                },
                {
                    "label": "C",
                    "text": "Wala itong idinulot na epekto"
                },
                {
                    "label": "D",
                    "text": "Bumagsak ang Estados Unidos"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang free trade policy ay lumikha ng malaking dependensiya ng ekonomiya ng Pilipinas sa Estados Unidos."
        },
        {
            "id": "ame_10_21",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naganap sa hukbong Pilipino habang paghahanda tungo sa kalayaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Itinatag ang Philippine Army sa ilalim ni Heneral Douglas MacArthur bilang tagapayo"
                },
                {
                    "label": "B",
                    "text": "Ganap na natigil ang hukbo"
                },
                {
                    "label": "C",
                    "text": "Nawalan ng militar ang bansa"
                },
                {
                    "label": "D",
                    "text": "Naipasa agad ang kalayaan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtatag ng pambansang hukbo sa ilalim ng Commonwealth, kasama si Heneral Douglas MacArthur bilang tagapayo."
        },
        {
            "id": "ame_10_22",
            "era": "american",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangyayari ang biglang naganap noong 1941 na nakaabala sa balak na kalayaan ng Pilipinas noong 1946?",
            "options": [
                {
                    "label": "A",
                    "text": "Pananalakay ng Hapon sa Pilipinas"
                },
                {
                    "label": "B",
                    "text": "Pagbagsak ng ekonomiya ng US"
                },
                {
                    "label": "C",
                    "text": "Bagong rebolusyon ng mga Pilipino"
                },
                {
                    "label": "D",
                    "text": "Pagbabalik ng mga Kastila"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sinalakay ng Hapon ang Pilipinas noong 1941, na nagpaantala sa plano ng kalayaan."
        }
    ]
}
```

## File: assets/data/questions_modern.json
```json
{
    "1": [
        {
            "id": "mod_1_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na ipinagkaloob ng Estados Unidos ang ganap na kalayaan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Hulyo 4, 1946"
                },
                {
                    "label": "B",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "C",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "D",
                    "text": "Pebrero 25, 1986"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagkaloob ng Estados Unidos ang ganap na kalayaan ng Pilipinas noong Hulyo 4, 1946."
        },
        {
            "id": "mod_1_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang Pangulo ng ganap na malayang Republika ng Pilipinas noong 1946?",
            "options": [
                {
                    "label": "A",
                    "text": "Manuel Roxas"
                },
                {
                    "label": "B",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "C",
                    "text": "Sergio Osmena"
                },
                {
                    "label": "D",
                    "text": "Jose P. Laurel"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Manuel Roxas ang naging unang Pangulo ng ganap na malayang Republika ng Pilipinas noong 1946."
        },
        {
            "id": "mod_1_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing gawain ng pamahalaan matapos makamit ang kalayaan noong 1946?",
            "options": [
                {
                    "label": "A",
                    "text": "Rehabilitasyon at muling pagtatayo ng bansa"
                },
                {
                    "label": "B",
                    "text": "Bagong pananakop sa ibang bansa"
                },
                {
                    "label": "C",
                    "text": "Pagsasara ng lahat ng paaralan"
                },
                {
                    "label": "D",
                    "text": "Pagbabalik sa pamahalaang Espanyol"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nakatuon ang unang mga taon ng malayang republika sa rehabilitasyon matapos ang pinsalang dulot ng digmaan."
        },
        {
            "id": "mod_1_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong internasyunal na organisasyon ang sinapian ng Pilipinas bilang isa sa mga unang kasapi?",
            "options": [
                {
                    "label": "A",
                    "text": "United Nations"
                },
                {
                    "label": "B",
                    "text": "ASEAN"
                },
                {
                    "label": "C",
                    "text": "European Union"
                },
                {
                    "label": "D",
                    "text": "NATO"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naging isa sa mga unang kasapi ang Pilipinas ng United Nations, na itinatag noong 1945."
        },
        {
            "id": "mod_1_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang taong 1946 sa kasaysayan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Ito ang taon ng ganap na kalayaan mula sa Estados Unidos"
                },
                {
                    "label": "B",
                    "text": "Ito ang taon ng pagdating ni Magellan"
                },
                {
                    "label": "C",
                    "text": "Ito ang taon ng Rebolusyong Pilipino"
                },
                {
                    "label": "D",
                    "text": "Ito ang taon ng EDSA Revolution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang 1946 ay mahalaga dahil ito ang taon ng ganap na kalayaan ng Pilipinas mula sa Estados Unidos."
        }
    ],
    "2": [
        {
            "id": "mod_2_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang Pangulo ng Pilipinas na nagdeklara ng Batas Militar noong 1972?",
            "options": [
                {
                    "label": "A",
                    "text": "Ferdinand Marcos"
                },
                {
                    "label": "B",
                    "text": "Manuel Roxas"
                },
                {
                    "label": "C",
                    "text": "Corazon Aquino"
                },
                {
                    "label": "D",
                    "text": "Diosdado Macapagal"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Idineklara ni Pangulong Ferdinand Marcos ang Batas Militar noong Setyembre 1972 sa pamamagitan ng Proclamation No. 1081."
        },
        {
            "id": "mod_2_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon idineklara ang Batas Militar sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "1972"
                },
                {
                    "label": "B",
                    "text": "1946"
                },
                {
                    "label": "C",
                    "text": "1986"
                },
                {
                    "label": "D",
                    "text": "1987"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Idineklara ang Batas Militar noong 1972, na nagsimula ng mahigit isang dekadang pamumuno ni Marcos sa ilalim ng espesyal na kapangyarihan."
        },
        {
            "id": "mod_2_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isa sa mga naging epekto ng Batas Militar sa karapatan ng mga mamamayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Paghihigpit sa kalayaan sa pamamahayag at pagpupulong"
                },
                {
                    "label": "B",
                    "text": "Pagpapalawak ng kalayaan ng bawat mamamayan"
                },
                {
                    "label": "C",
                    "text": "Walang epekto sa karapatan ng mga tao"
                },
                {
                    "label": "D",
                    "text": "Kaagad na demokrasya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa ilalim ng Batas Militar, nagkaroon ng paghihigpit sa kalayaan sa pamamahayag, pagpupulong, at iba pang karapatang sibil."
        },
        {
            "id": "mod_2_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa oras kung kailan bawal lumabas ng bahay na ipinatupad sa panahon ng Batas Militar?",
            "options": [
                {
                    "label": "A",
                    "text": "Curfew"
                },
                {
                    "label": "B",
                    "text": "Fiesta"
                },
                {
                    "label": "C",
                    "text": "Siesta"
                },
                {
                    "label": "D",
                    "text": "Recess"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang curfew bilang isa sa mga hakbang ng gobyerno sa panahon ng Batas Militar."
        },
        {
            "id": "mod_2_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Gaano katagal ang pamumuno ni Pangulong Marcos sa Pilipinas, mula 1965 hanggang 1986?",
            "options": [
                {
                    "label": "A",
                    "text": "Mahigit dalawang dekada"
                },
                {
                    "label": "B",
                    "text": "Isang taon lamang"
                },
                {
                    "label": "C",
                    "text": "Limang taon lamang"
                },
                {
                    "label": "D",
                    "text": "Isang buwan lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Namuno si Marcos sa Pilipinas mula 1965 hanggang 1986, mahigit dalawang dekada, kabilang ang panahon ng Batas Militar."
        }
    ],
    "3": [
        {
            "id": "mod_3_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong senador ang pinaslang noong 1983 sa paliparan ng Maynila, na naging isa sa mga dahilan ng malawakang protesta?",
            "options": [
                {
                    "label": "A",
                    "text": "Benigno \"Ninoy\" Aquino Jr."
                },
                {
                    "label": "B",
                    "text": "Jose W. Diokno"
                },
                {
                    "label": "C",
                    "text": "Lorenzo Tanada"
                },
                {
                    "label": "D",
                    "text": "Jovito Salonga"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinaslang si Senador Benigno \"Ninoy\" Aquino Jr. noong 1983 sa paliparan ng Maynila matapos siyang bumalik mula sa pagkatapon."
        },
        {
            "id": "mod_3_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon naganap ang EDSA People Power Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "1986"
                },
                {
                    "label": "B",
                    "text": "1972"
                },
                {
                    "label": "C",
                    "text": "1946"
                },
                {
                    "label": "D",
                    "text": "1998"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap ang EDSA People Power Revolution noong Pebrero 1986, na nagtapos sa mahigit dalawang dekadang pamumuno ni Marcos."
        },
        {
            "id": "mod_3_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang babaeng Pangulo ng Pilipinas matapos ang EDSA Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Corazon Aquino"
                },
                {
                    "label": "B",
                    "text": "Gloria Macapagal-Arroyo"
                },
                {
                    "label": "C",
                    "text": "Imelda Marcos"
                },
                {
                    "label": "D",
                    "text": "Leni Robredo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Corazon Aquino, biyuda ni Ninoy Aquino, ang naging unang babaeng Pangulo ng Pilipinas matapos ang EDSA Revolution."
        },
        {
            "id": "mod_3_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang natatanging katangian ng EDSA People Power Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging mapayapa at walang dahas (peaceful/non-violent)"
                },
                {
                    "label": "B",
                    "text": "Puno ito ng armadong labanan"
                },
                {
                    "label": "C",
                    "text": "Isinagawa sa loob ng ibang bansa"
                },
                {
                    "label": "D",
                    "text": "Tumagal ng maraming taon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang EDSA People Power Revolution ay kilala sa buong mundo bilang isang mapayapa at walang-dahas na paraan ng pagpapabagsak sa isang pamahalaan."
        },
        {
            "id": "mod_3_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saang lansangan naganap ang malawakang protesta noong 1986 na nagbigay ng pangalan sa \"EDSA Revolution\"?",
            "options": [
                {
                    "label": "A",
                    "text": "Epifanio de los Santos Avenue (EDSA)"
                },
                {
                    "label": "B",
                    "text": "Roxas Boulevard"
                },
                {
                    "label": "C",
                    "text": "Ayala Avenue"
                },
                {
                    "label": "D",
                    "text": "Quezon Avenue"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap ang malawakang protesta sa Epifanio de los Santos Avenue (EDSA), kung saan hango ang pangalan ng rebolusyon."
        }
    ],
    "4": [
        {
            "id": "mod_4_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bagong Saligang Batas ang pinagtibay noong 1987 matapos ang EDSA Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "1987 Constitution"
                },
                {
                    "label": "B",
                    "text": "1935 Constitution"
                },
                {
                    "label": "C",
                    "text": "1973 Constitution"
                },
                {
                    "label": "D",
                    "text": "Malolos Constitution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinagtibay ang 1987 Constitution matapos ang EDSA Revolution, na siyang kasalukuyang Saligang Batas ng Pilipinas."
        },
        {
            "id": "mod_4_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang naibalik matapos ang EDSA Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Malayang halalan at malayang pamamahayag"
                },
                {
                    "label": "B",
                    "text": "Batas Militar"
                },
                {
                    "label": "C",
                    "text": "Pamahalaang Espanyol"
                },
                {
                    "label": "D",
                    "text": "Kolonyalismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naibalik ang mga demokratikong institusyon gaya ng malayang halalan at malayang pamamahayag matapos ang EDSA Revolution."
        },
        {
            "id": "mod_4_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bahagi ng 1987 Constitution ang nagpoprotekta sa mga karapatan ng bawat mamamayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Bill of Rights"
                },
                {
                    "label": "B",
                    "text": "Preamble lamang"
                },
                {
                    "label": "C",
                    "text": "Batas Militar"
                },
                {
                    "label": "D",
                    "text": "Local Government Code"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Bill of Rights sa 1987 Constitution ang nagpoprotekta sa mga saligang karapatan ng bawat mamamayan."
        },
        {
            "id": "mod_4_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas noong 1991 ang nagbigay ng mas malaking kapangyarihan sa mga lokal na pamahalaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Local Government Code"
                },
                {
                    "label": "B",
                    "text": "Batas Militar"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Batas Sedition"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Local Government Code of 1991 ay nagbigay ng mas malaking kapangyarihan at pananagutan sa mga lokal na pamahalaan (decentralization)."
        },
        {
            "id": "mod_4_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang muling pagtatatag ng demokrasya matapos ang Batas Militar?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang maibalik ang karapatan at partisipasyon ng mga mamamayan sa pamahalaan"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Para lang sa mga pulitiko"
                },
                {
                    "label": "D",
                    "text": "Hindi ito kailangan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang muling pagtatatag ng demokrasya ay mahalaga upang maibalik ang tinig at partisipasyon ng mga mamamayan sa pamamahala ng bansa."
        }
    ],
    "5": [
        {
            "id": "mod_5_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mga Pilipinong nagtatrabaho sa ibang bansa upang tumulong sa kanilang pamilya at ekonomiya ng bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Overseas Filipino Workers (OFW)"
                },
                {
                    "label": "B",
                    "text": "Ilustrado"
                },
                {
                    "label": "C",
                    "text": "Pensionado"
                },
                {
                    "label": "D",
                    "text": "Encomendero"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga Overseas Filipino Workers (OFW) ay malaking bahagi ng modernong lipunan at ekonomiya ng Pilipinas."
        },
        {
            "id": "mod_5_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa programa ng pamahalaan na naglalayong ipamahagi ang lupang agrikultural sa mga magsasaka?",
            "options": [
                {
                    "label": "A",
                    "text": "Comprehensive Agrarian Reform Program (CARP)"
                },
                {
                    "label": "B",
                    "text": "Bandala"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Reduccion"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Comprehensive Agrarian Reform Program (CARP) ay naglalayong ipamahagi ang lupang agrikultural sa mga magsasakang walang lupa."
        },
        {
            "id": "mod_5_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang malaking kontribusyon ng mga OFW sa ekonomiya ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Remittances o padalang salapi sa kanilang pamilya"
                },
                {
                    "label": "B",
                    "text": "Walang naitutulong"
                },
                {
                    "label": "C",
                    "text": "Nagpapahina lamang ng ekonomiya"
                },
                {
                    "label": "D",
                    "text": "Hindi sila bahagi ng ekonomiya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang remittances o padalang salapi ng mga OFW sa kanilang pamilya ay isa sa pangunahing saligan ng ekonomiya ng Pilipinas."
        },
        {
            "id": "mod_5_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang patuloy na hamon sa lipunan ng modernong Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kahirapan at hindi pantay na pamamahagi ng yaman"
                },
                {
                    "label": "B",
                    "text": "Kasaganaan para sa lahat"
                },
                {
                    "label": "C",
                    "text": "Walang problema sa lipunan"
                },
                {
                    "label": "D",
                    "text": "Ganap nang nalutas ang lahat ng suliranin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang kahirapan at hindi pantay na pamamahagi ng yaman ay patuloy na hamon sa modernong lipunang Pilipino."
        },
        {
            "id": "mod_5_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong industriya ang lumago nang malaki sa Pilipinas dahil sa mahusay na kasanayan sa Ingles ng mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Business Process Outsourcing (BPO)/Call Center"
                },
                {
                    "label": "B",
                    "text": "Pagmimina ng ginto lamang"
                },
                {
                    "label": "C",
                    "text": "Barter trade"
                },
                {
                    "label": "D",
                    "text": "Encomienda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Lumago ang industriya ng Business Process Outsourcing (BPO) sa Pilipinas dahil sa mahusay na kasanayan sa Ingles ng mga manggagawa."
        }
    ],
    "6": [
        {
            "id": "mod_6_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bulkan ang sumabog noong 1991 at itinuring na isa sa pinakamalaking pagsabog sa ika-20 siglo?",
            "options": [
                {
                    "label": "A",
                    "text": "Mount Pinatubo"
                },
                {
                    "label": "B",
                    "text": "Mayon Volcano"
                },
                {
                    "label": "C",
                    "text": "Taal Volcano"
                },
                {
                    "label": "D",
                    "text": "Kanlaon Volcano"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sumabog ang Mount Pinatubo noong 1991 at itinuring na isa sa pinakamalaking pagsabog ng bulkan sa buong mundo sa ika-20 siglo."
        },
        {
            "id": "mod_6_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang paghahanda laban sa mga bagyo at kalamidad sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Madalas ang bagyo at iba pang kalamidad sa bansa"
                },
                {
                    "label": "B",
                    "text": "Walang bagyo sa Pilipinas"
                },
                {
                    "label": "C",
                    "text": "Hindi apektado ang bansa ng kalamidad"
                },
                {
                    "label": "D",
                    "text": "Hindi na kailangan ang paghahanda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Pilipinas ay madalas na dinadaanan ng bagyo at iba pang sakuna dahil sa kinaroroonang lokasyon nito, kaya mahalaga ang paghahanda."
        },
        {
            "id": "mod_6_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang pangunahing epekto ng pagbabago ng klima (climate change) sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Mas matinding bagyo at pagtaas ng antas ng dagat"
                },
                {
                    "label": "B",
                    "text": "Walang epekto"
                },
                {
                    "label": "C",
                    "text": "Bumababa ang temperatura"
                },
                {
                    "label": "D",
                    "text": "Wala nang bagyo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pagbabago ng klima ay nagdudulot ng mas matinding bagyo at pagtaas ng antas ng dagat, na nakakaapekto sa Pilipinas."
        },
        {
            "id": "mod_6_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong ahensya ng pamahalaan ang responsable sa pamamahala ng sakuna at kalamidad sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "NDRRMC (National Disaster Risk Reduction and Management Council)"
                },
                {
                    "label": "B",
                    "text": "DepEd"
                },
                {
                    "label": "C",
                    "text": "DFA"
                },
                {
                    "label": "D",
                    "text": "BIR"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang NDRRMC ang pangunahing ahensyang namamahala sa pagtugon at paghahanda para sa mga sakuna at kalamidad sa bansa."
        },
        {
            "id": "mod_6_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang mahalagang papel ng mga batas pangkapaligiran sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Proteksyon ng kalikasan para sa kasalukuyan at susunod na henerasyon"
                },
                {
                    "label": "B",
                    "text": "Wala itong papel"
                },
                {
                    "label": "C",
                    "text": "Para lamang pahirapan ang negosyo"
                },
                {
                    "label": "D",
                    "text": "Walang epekto sa kalikasan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga batas pangkapaligiran ay mahalaga upang maprotektahan ang kalikasan para sa kasalukuyan at susunod na henerasyon."
        }
    ],
    "7": [
        {
            "id": "mod_7_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong teknolohiya ang malaking gumanap sa pagpapabilis ng komunikasyon noong EDSA 2 protests noong 2001?",
            "options": [
                {
                    "label": "A",
                    "text": "Text messaging/SMS"
                },
                {
                    "label": "B",
                    "text": "Telegrama"
                },
                {
                    "label": "C",
                    "text": "Radyo lamang"
                },
                {
                    "label": "D",
                    "text": "Sulat"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ginamit ang text messaging upang mabilis na maipalaganap ang mga impormasyon at mapatawag ang mga tao sa EDSA 2 noong 2001."
        },
        {
            "id": "mod_7_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano nagbago ang paraan ng komunikasyon ng mga Pilipino sa makabagong panahon?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging mas mabilis at malawak sa pamamagitan ng internet at social media"
                },
                {
                    "label": "B",
                    "text": "Nawala ang lahat ng paraan ng komunikasyon"
                },
                {
                    "label": "C",
                    "text": "Bumalik sa paggamit ng baybayin lamang"
                },
                {
                    "label": "D",
                    "text": "Walang nagbago"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naging mas mabilis at malawak ang komunikasyon ng mga Pilipino sa pamamagitan ng internet at social media sa makabagong panahon."
        },
        {
            "id": "mod_7_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang isang hamon na dulot ng malawakang paggamit ng internet at social media?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagkalat ng maling impormasyon (fake news)"
                },
                {
                    "label": "B",
                    "text": "Wala itong hamon"
                },
                {
                    "label": "C",
                    "text": "Ganap na tumpak na impormasyon lamang ang lumalabas"
                },
                {
                    "label": "D",
                    "text": "Nawala ang lahat ng problema"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pagkalat ng maling impormasyon o fake news ay isa sa mga hamon ng malawakang paggamit ng internet at social media."
        },
        {
            "id": "mod_7_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalagang maging mapanuri (critical) ang mga mamamayan sa impormasyong nakikita nila online?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang maiwasan ang paniniwala sa maling impormasyon"
                },
                {
                    "label": "B",
                    "text": "Wala itong kahalagahan"
                },
                {
                    "label": "C",
                    "text": "Dapat paniwalaan ang lahat ng nakikita online"
                },
                {
                    "label": "D",
                    "text": "Hindi kailangan mag-isip nang mabuti"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Mahalagang maging mapanuri ang mga mamamayan upang maiwasan ang paniniwala at pagkalat ng maling impormasyon."
        },
        {
            "id": "mod_7_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano makatutulong ang teknolohiya sa pagpapabuti ng edukasyon ng mga Pilipino ngayon?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng mas madaling access sa impormasyon at online learning"
                },
                {
                    "label": "B",
                    "text": "Wala itong maitutulong"
                },
                {
                    "label": "C",
                    "text": "Pinapahirap lamang nito ang pag-aaral"
                },
                {
                    "label": "D",
                    "text": "Hindi ito ginagamit sa edukasyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nakatutulong ang teknolohiya sa edukasyon sa pamamagitan ng mas madaling access sa impormasyon at online learning resources."
        }
    ],
    "8": [
        {
            "id": "mod_8_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa maling paggamit ng kapangyarihan o pondo ng gobyerno para sa personal na interes?",
            "options": [
                {
                    "label": "A",
                    "text": "Katiwalian (Corruption)"
                },
                {
                    "label": "B",
                    "text": "Transparency"
                },
                {
                    "label": "C",
                    "text": "Accountability"
                },
                {
                    "label": "D",
                    "text": "Reporma"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang katiwalian (corruption) ay ang maling paggamit ng kapangyarihan o pondo ng gobyerno para sa personal na kapakinabangan."
        },
        {
            "id": "mod_8_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong ahensya ng gobyerno ang responsable sa pag-iimbestiga sa mga reklamo laban sa mga opisyal ng gobyerno?",
            "options": [
                {
                    "label": "A",
                    "text": "Ombudsman"
                },
                {
                    "label": "B",
                    "text": "DepEd"
                },
                {
                    "label": "C",
                    "text": "DSWD"
                },
                {
                    "label": "D",
                    "text": "NDRRMC"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Ombudsman ang ahensyang responsable sa pag-iimbestiga at paglutas ng mga reklamo laban sa mga opisyal ng gobyerno."
        },
        {
            "id": "mod_8_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang transparency (kalinawan) sa pamahalaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang malaman ng mamamayan kung paano ginagamit ang kanilang buwis"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Para lang sa mga pulitiko"
                },
                {
                    "label": "D",
                    "text": "Hindi ito kailangan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Mahalaga ang transparency upang malaman ng mga mamamayan kung paano ginagamit ang pondo mula sa kanilang buwis."
        },
        {
            "id": "mod_8_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas ang naglalayong labanan ang katiwalian sa gobyerno ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Anti-Graft and Corrupt Practices Act"
                },
                {
                    "label": "B",
                    "text": "Batas Sedition"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Bandala"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Anti-Graft and Corrupt Practices Act (Republic Act 3019) ay isa sa mga batas na naglalayong sugpuin ang katiwalian sa gobyerno."
        },
        {
            "id": "mod_8_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano makatutulong ang mga ordinaryong mamamayan sa paglaban sa katiwalian?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng responsableng pagboto at pagbabantay sa gobyerno"
                },
                {
                    "label": "B",
                    "text": "Wala silang magagawa"
                },
                {
                    "label": "C",
                    "text": "Sa pamamagitan ng pananahimik lamang"
                },
                {
                    "label": "D",
                    "text": "Hindi na kailangan ang partisipasyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Makatutulong ang mga mamamayan sa paglaban sa katiwalian sa pamamagitan ng responsableng pagboto at aktibong pagbabantay sa mga opisyal ng gobyerno."
        }
    ],
    "9": [
        {
            "id": "mod_9_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano nakatutulong ang mga kabataan sa pagpapaunlad ng bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng edukasyon, disiplina, at aktibong partisipasyon sa lipunan"
                },
                {
                    "label": "B",
                    "text": "Wala silang maitutulong"
                },
                {
                    "label": "C",
                    "text": "Dapat sila ay manahimik lamang"
                },
                {
                    "label": "D",
                    "text": "Hindi na kailangan ang kanilang partisipasyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Malaki ang maitutulong ng mga kabataan sa pagpapaunlad ng bansa sa pamamagitan ng edukasyon, disiplina, at aktibong partisipasyon."
        },
        {
            "id": "mod_9_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang aral na maaaring matutunan mula sa kasaysayan ng Pilipinas patungkol sa pagbabantay sa gobyerno?",
            "options": [
                {
                    "label": "A",
                    "text": "Mahalagang maging mapanuri at aktibo ang mga mamamayan upang mapanatili ang demokrasya"
                },
                {
                    "label": "B",
                    "text": "Dapat manahimik na lamang ang mga mamamayan"
                },
                {
                    "label": "C",
                    "text": "Walang aral na matutunan"
                },
                {
                    "label": "D",
                    "text": "Hindi mahalaga ang boto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinapakita ng kasaysayan ng Pilipinas, lalo na ang EDSA Revolution, ang kahalagahan ng aktibong pagbabantay ng mga mamamayan sa kanilang gobyerno."
        },
        {
            "id": "mod_9_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang pagkakaisa ng iba't ibang rehiyon at kultura sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Nagpapatibay ito sa bansa bilang isang malakas at magkakaisang lipunan"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Mas mabuti kung magkakahiwalay ang bawat rehiyon"
                },
                {
                    "label": "D",
                    "text": "Hindi mahalaga ang pagkakaisa"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pagkakaisa sa gitna ng pagkakaiba-iba ng kultura at rehiyon ay nagpapatibay sa Pilipinas bilang isang malakas na bansa."
        },
        {
            "id": "mod_9_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano magagamit ng mga Pilipino ang mga aral ng nakaraan upang bumuo ng mas magandang kinabukasan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng pagpapahalaga sa demokrasya, mabuting pamamahala, at pagkakaisa"
                },
                {
                    "label": "B",
                    "text": "Sa pamamagitan ng pagkalimot sa kasaysayan"
                },
                {
                    "label": "C",
                    "text": "Sa pag-uulit ng mga nakaraang pagkakamali"
                },
                {
                    "label": "D",
                    "text": "Wala itong magagawa"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa pamamagitan ng pagpapahalaga sa demokrasya, mabuting pamamahala, at pagkakaisa, magagamit ng mga Pilipino ang mga aral ng kasaysayan tungo sa mas magandang kinabukasan."
        },
        {
            "id": "mod_9_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing mensahe ng pag-aaral ng buong kasaysayan ng Pilipinas mula sinaunang panahon hanggang ngayon?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang pagpapahalaga sa kalayaan, pagkakaisa, at patuloy na pagpapaunlad ng bansa"
                },
                {
                    "label": "B",
                    "text": "Walang mahalagang matututunan"
                },
                {
                    "label": "C",
                    "text": "Dapat kalimutan na lamang ang nakaraan"
                },
                {
                    "label": "D",
                    "text": "Hindi mahalaga ang kasaysayan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinuturo ng buong kasaysayan ng Pilipinas ang kahalagahan ng pagpapahalaga sa kalayaan, pagkakaisa, at patuloy na pagsisikap tungo sa pag-unlad ng bansa."
        }
    ],
    "10": [
        {
            "id": "mod_10_1",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na ipinagkaloob ng Estados Unidos ang ganap na kalayaan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Hulyo 4, 1946"
                },
                {
                    "label": "B",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "C",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "D",
                    "text": "Pebrero 25, 1986"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagkaloob ng Estados Unidos ang ganap na kalayaan ng Pilipinas noong Hulyo 4, 1946."
        },
        {
            "id": "mod_10_2",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang Pangulo ng Pilipinas na nagdeklara ng Batas Militar noong 1972?",
            "options": [
                {
                    "label": "A",
                    "text": "Ferdinand Marcos"
                },
                {
                    "label": "B",
                    "text": "Manuel Roxas"
                },
                {
                    "label": "C",
                    "text": "Corazon Aquino"
                },
                {
                    "label": "D",
                    "text": "Diosdado Macapagal"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Idineklara ni Pangulong Ferdinand Marcos ang Batas Militar noong 1972."
        },
        {
            "id": "mod_10_3",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong senador ang pinaslang noong 1983 sa paliparan ng Maynila?",
            "options": [
                {
                    "label": "A",
                    "text": "Benigno \"Ninoy\" Aquino Jr."
                },
                {
                    "label": "B",
                    "text": "Jose W. Diokno"
                },
                {
                    "label": "C",
                    "text": "Lorenzo Tanada"
                },
                {
                    "label": "D",
                    "text": "Jovito Salonga"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinaslang si Senador Benigno \"Ninoy\" Aquino Jr. noong 1983."
        },
        {
            "id": "mod_10_4",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon naganap ang EDSA People Power Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "1986"
                },
                {
                    "label": "B",
                    "text": "1972"
                },
                {
                    "label": "C",
                    "text": "1946"
                },
                {
                    "label": "D",
                    "text": "1998"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap ang EDSA People Power Revolution noong 1986."
        },
        {
            "id": "mod_10_5",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging unang babaeng Pangulo ng Pilipinas matapos ang EDSA Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Corazon Aquino"
                },
                {
                    "label": "B",
                    "text": "Gloria Macapagal-Arroyo"
                },
                {
                    "label": "C",
                    "text": "Imelda Marcos"
                },
                {
                    "label": "D",
                    "text": "Leni Robredo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Corazon Aquino ang naging unang babaeng Pangulo ng Pilipinas."
        },
        {
            "id": "mod_10_6",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bagong Saligang Batas ang pinagtibay noong 1987?",
            "options": [
                {
                    "label": "A",
                    "text": "1987 Constitution"
                },
                {
                    "label": "B",
                    "text": "1935 Constitution"
                },
                {
                    "label": "C",
                    "text": "1973 Constitution"
                },
                {
                    "label": "D",
                    "text": "Malolos Constitution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinagtibay ang 1987 Constitution matapos ang EDSA Revolution."
        },
        {
            "id": "mod_10_7",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mga Pilipinong nagtatrabaho sa ibang bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Overseas Filipino Workers (OFW)"
                },
                {
                    "label": "B",
                    "text": "Ilustrado"
                },
                {
                    "label": "C",
                    "text": "Pensionado"
                },
                {
                    "label": "D",
                    "text": "Encomendero"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga Overseas Filipino Workers (OFW) ay malaking bahagi ng modernong ekonomiya ng Pilipinas."
        },
        {
            "id": "mod_10_8",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bulkan ang sumabog noong 1991?",
            "options": [
                {
                    "label": "A",
                    "text": "Mount Pinatubo"
                },
                {
                    "label": "B",
                    "text": "Mayon Volcano"
                },
                {
                    "label": "C",
                    "text": "Taal Volcano"
                },
                {
                    "label": "D",
                    "text": "Kanlaon Volcano"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sumabog ang Mount Pinatubo noong 1991."
        },
        {
            "id": "mod_10_9",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong teknolohiya ang malaking gumanap sa EDSA 2 protests noong 2001?",
            "options": [
                {
                    "label": "A",
                    "text": "Text messaging/SMS"
                },
                {
                    "label": "B",
                    "text": "Telegrama"
                },
                {
                    "label": "C",
                    "text": "Radyo lamang"
                },
                {
                    "label": "D",
                    "text": "Sulat"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ginamit ang text messaging upang mapatawag ang mga tao sa EDSA 2 noong 2001."
        },
        {
            "id": "mod_10_10",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang natatanging katangian ng EDSA People Power Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Naging mapayapa at walang dahas"
                },
                {
                    "label": "B",
                    "text": "Puno ito ng armadong labanan"
                },
                {
                    "label": "C",
                    "text": "Isinagawa sa loob ng ibang bansa"
                },
                {
                    "label": "D",
                    "text": "Tumagal ng maraming taon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang EDSA People Power Revolution ay kilala bilang isang mapayapa at walang-dahas na rebolusyon."
        },
        {
            "id": "mod_10_11",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa maling paggamit ng kapangyarihan o pondo ng gobyerno para sa personal na interes?",
            "options": [
                {
                    "label": "A",
                    "text": "Katiwalian (Corruption)"
                },
                {
                    "label": "B",
                    "text": "Transparency"
                },
                {
                    "label": "C",
                    "text": "Accountability"
                },
                {
                    "label": "D",
                    "text": "Reporma"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang katiwalian ay ang maling paggamit ng kapangyarihan o pondo ng gobyerno para sa personal na kapakinabangan."
        },
        {
            "id": "mod_10_12",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong ahensya ng gobyerno ang responsable sa pag-iimbestiga sa mga reklamo laban sa mga opisyal ng gobyerno?",
            "options": [
                {
                    "label": "A",
                    "text": "Ombudsman"
                },
                {
                    "label": "B",
                    "text": "DepEd"
                },
                {
                    "label": "C",
                    "text": "DSWD"
                },
                {
                    "label": "D",
                    "text": "NDRRMC"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Ombudsman ang ahensyang responsable sa pag-iimbestiga sa mga reklamo laban sa mga opisyal ng gobyerno."
        },
        {
            "id": "mod_10_13",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang transparency (kalinawan) sa pamahalaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang malaman ng mamamayan kung paano ginagamit ang kanilang buwis"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Para lang sa mga pulitiko"
                },
                {
                    "label": "D",
                    "text": "Hindi ito kailangan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Mahalaga ang transparency upang malaman ng mga mamamayan kung paano ginagamit ang pondo mula sa kanilang buwis."
        },
        {
            "id": "mod_10_14",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong batas ang naglalayong labanan ang katiwalian sa gobyerno ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Anti-Graft and Corrupt Practices Act"
                },
                {
                    "label": "B",
                    "text": "Batas Sedition"
                },
                {
                    "label": "C",
                    "text": "Jones Law"
                },
                {
                    "label": "D",
                    "text": "Bandala"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Anti-Graft and Corrupt Practices Act ay naglalayong sugpuin ang katiwalian sa gobyerno."
        },
        {
            "id": "mod_10_15",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano makatutulong ang mga ordinaryong mamamayan sa paglaban sa katiwalian?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng responsableng pagboto at pagbabantay sa gobyerno"
                },
                {
                    "label": "B",
                    "text": "Wala silang magagawa"
                },
                {
                    "label": "C",
                    "text": "Sa pamamagitan ng pananahimik lamang"
                },
                {
                    "label": "D",
                    "text": "Hindi na kailangan ang partisipasyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Makatutulong ang mga mamamayan sa paglaban sa katiwalian sa pamamagitan ng responsableng pagboto at pagbabantay."
        },
        {
            "id": "mod_10_16",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang naibalik matapos ang EDSA Revolution?",
            "options": [
                {
                    "label": "A",
                    "text": "Malayang halalan at malayang pamamahayag"
                },
                {
                    "label": "B",
                    "text": "Batas Militar"
                },
                {
                    "label": "C",
                    "text": "Pamahalaang Espanyol"
                },
                {
                    "label": "D",
                    "text": "Kolonyalismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naibalik ang malayang halalan at malayang pamamahayag matapos ang EDSA Revolution."
        },
        {
            "id": "mod_10_17",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong bahagi ng 1987 Constitution ang nagpoprotekta sa mga karapatan ng bawat mamamayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Bill of Rights"
                },
                {
                    "label": "B",
                    "text": "Preamble lamang"
                },
                {
                    "label": "C",
                    "text": "Batas Militar"
                },
                {
                    "label": "D",
                    "text": "Local Government Code"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Bill of Rights ang nagpoprotekta sa mga saligang karapatan ng bawat mamamayan."
        },
        {
            "id": "mod_10_18",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang patuloy na hamon sa lipunan ng modernong Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kahirapan at hindi pantay na pamamahagi ng yaman"
                },
                {
                    "label": "B",
                    "text": "Kasaganaan para sa lahat"
                },
                {
                    "label": "C",
                    "text": "Walang problema sa lipunan"
                },
                {
                    "label": "D",
                    "text": "Ganap nang nalutas ang lahat ng suliranin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang kahirapan at hindi pantay na pamamahagi ng yaman ay patuloy na hamon sa modernong lipunang Pilipino."
        },
        {
            "id": "mod_10_19",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang isang hamon na dulot ng malawakang paggamit ng internet at social media?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagkalat ng maling impormasyon (fake news)"
                },
                {
                    "label": "B",
                    "text": "Wala itong hamon"
                },
                {
                    "label": "C",
                    "text": "Ganap na tumpak na impormasyon lamang ang lumalabas"
                },
                {
                    "label": "D",
                    "text": "Nawala ang lahat ng problema"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pagkalat ng fake news ay isa sa mga hamon ng malawakang paggamit ng internet."
        },
        {
            "id": "mod_10_20",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang aral na maaaring matutunan mula sa kasaysayan ng Pilipinas patungkol sa pagbabantay sa gobyerno?",
            "options": [
                {
                    "label": "A",
                    "text": "Mahalagang maging mapanuri at aktibo ang mga mamamayan upang mapanatili ang demokrasya"
                },
                {
                    "label": "B",
                    "text": "Dapat manahimik na lamang ang mga mamamayan"
                },
                {
                    "label": "C",
                    "text": "Walang aral na matutunan"
                },
                {
                    "label": "D",
                    "text": "Hindi mahalaga ang boto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinapakita ng kasaysayan ng Pilipinas ang kahalagahan ng aktibong pagbabantay ng mga mamamayan sa kanilang gobyerno."
        },
        {
            "id": "mod_10_21",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano nakatutulong ang mga kabataan sa pagpapaunlad ng bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng edukasyon, disiplina, at aktibong partisipasyon sa lipunan"
                },
                {
                    "label": "B",
                    "text": "Wala silang maitutulong"
                },
                {
                    "label": "C",
                    "text": "Dapat sila ay manahimik lamang"
                },
                {
                    "label": "D",
                    "text": "Hindi na kailangan ang kanilang partisipasyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Malaki ang maitutulong ng mga kabataan sa pagpapaunlad ng bansa sa pamamagitan ng edukasyon at partisipasyon."
        },
        {
            "id": "mod_10_22",
            "era": "modern",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing mensahe ng pag-aaral ng buong kasaysayan ng Pilipinas mula sinaunang panahon hanggang ngayon?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang pagpapahalaga sa kalayaan, pagkakaisa, at patuloy na pagpapaunlad ng bansa"
                },
                {
                    "label": "B",
                    "text": "Walang mahalagang matututunan"
                },
                {
                    "label": "C",
                    "text": "Dapat kalimutan na lamang ang nakaraan"
                },
                {
                    "label": "D",
                    "text": "Hindi mahalaga ang kasaysayan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinuturo ng buong kasaysayan ng Pilipinas ang kahalagahan ng pagpapahalaga sa kalayaan, pagkakaisa, at patuloy na pag-unlad."
        }
    ]
}
```

## File: assets/data/questions_pre-colonial.json
```json
{
    "1": [
        {
            "id": "pre_1_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa teoryang nagsasabing ang mga sinaunang Pilipino ay nagmula sa Timog-Silangang Asya gamit ang mga bangka?",
            "options": [
                {
                    "label": "A",
                    "text": "Teoryang Austronesian"
                },
                {
                    "label": "B",
                    "text": "Teoryang Land Bridges"
                },
                {
                    "label": "C",
                    "text": "Teoryang Continental Drift"
                },
                {
                    "label": "D",
                    "text": "Teoryang Evolution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ayon kay Peter Bellwood, ang mga Austronesian ay nagmula sa Timog Tsina at Taiwan bago nakarating sa Pilipinas."
        },
        {
            "id": "pre_1_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ilang isla ang bumubuo sa kapuluan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Mahigit 7,000"
                },
                {
                    "label": "B",
                    "text": "Mahigit 500"
                },
                {
                    "label": "C",
                    "text": "Mahigit 1,000"
                },
                {
                    "label": "D",
                    "text": "Mahigit 3,000"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Pilipinas ay binubuo ng mahigit 7,000 isla na nahahati sa tatlong pangkat: Luzon, Visayas, at Mindanao."
        },
        {
            "id": "pre_1_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang itinuturing na kauna-unahang naninirahan sa Pilipinas bago dumating ang mga Austronesian?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga Negrito/Aeta"
                },
                {
                    "label": "B",
                    "text": "Mga Kastila"
                },
                {
                    "label": "C",
                    "text": "Mga Intsik"
                },
                {
                    "label": "D",
                    "text": "Mga Indones"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga Negrito o Aeta ay itinuturing na kabilang sa mga pinakaunang naninirahan sa kapuluan ng Pilipinas."
        },
        {
            "id": "pre_1_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan nagmula ang salitang \"barangay\"?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa salitang \"balangay\" na tumutukoy sa bangka"
                },
                {
                    "label": "B",
                    "text": "Sa salitang Kastila na \"barrio\""
                },
                {
                    "label": "C",
                    "text": "Sa salitang Intsik na \"barang\""
                },
                {
                    "label": "D",
                    "text": "Walang kaugnayan sa alinman"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang salitang \"barangay\" ay hango sa \"balangay,\" ang uri ng bangkang ginamit ng mga sinaunang Pilipino sa paglalayag."
        },
        {
            "id": "pre_1_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang katawagan sa pinakamaliit na yunit ng pamayanan sa sinaunang Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Barangay"
                },
                {
                    "label": "B",
                    "text": "Bayan"
                },
                {
                    "label": "C",
                    "text": "Probinsya"
                },
                {
                    "label": "D",
                    "text": "Purok"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang barangay ang pinakapangunahing yunit ng pamayanan, na binubuo ng ilang pamilya at pinamumunuan ng isang datu."
        }
    ],
    "2": [
        {
            "id": "pre_2_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang nagsisilbing pinuno at tagapagtanggol ng isang sinaunang barangay?",
            "options": [
                {
                    "label": "A",
                    "text": "Datu"
                },
                {
                    "label": "B",
                    "text": "Babaylan"
                },
                {
                    "label": "C",
                    "text": "Alipin"
                },
                {
                    "label": "D",
                    "text": "Maharlika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Datu ang pinuno ng barangay na namamahala sa lipunan, batas, at pagtatanggol."
        },
        {
            "id": "pre_2_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng mamamayan ang mga \"maharlika\" sa sinaunang lipunan?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga mandirigma at maimpluwensyang pamilya"
                },
                {
                    "label": "B",
                    "text": "Mga alipin"
                },
                {
                    "label": "C",
                    "text": "Mga dayuhang mangangalakal"
                },
                {
                    "label": "D",
                    "text": "Mga saserdote lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga maharlika ay malayang mamamayan, kadalasang mandirigma, na may mataas na katayuan sa lipunan."
        },
        {
            "id": "pre_2_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa malayang mamamayan na hindi kabilang sa maharlika o alipin?",
            "options": [
                {
                    "label": "A",
                    "text": "Timawa"
                },
                {
                    "label": "B",
                    "text": "Babaylan"
                },
                {
                    "label": "C",
                    "text": "Panday"
                },
                {
                    "label": "D",
                    "text": "Datu"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga timawa ay malayang mamamayan na maaaring magmay-ari ng lupa at hindi inaalipin."
        },
        {
            "id": "pre_2_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng alipin ang naninirahan sa bahay ng kanyang panginoon?",
            "options": [
                {
                    "label": "A",
                    "text": "Alipin na sagigilid"
                },
                {
                    "label": "B",
                    "text": "Alipin na namamahay"
                },
                {
                    "label": "C",
                    "text": "Timawa"
                },
                {
                    "label": "D",
                    "text": "Maharlika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang alipin na sagigilid ay naninirahan sa bahay ng kanyang panginoon at wala nang sariling tahanan, kaiba sa alipin na namamahay na may sariling tahanan."
        },
        {
            "id": "pre_2_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang tinatawag na \"babaylan\" sa sinaunang lipunan?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang pinuno ng seremonyang panrelihiyon"
                },
                {
                    "label": "B",
                    "text": "Ang mandirigma ng barangay"
                },
                {
                    "label": "C",
                    "text": "Ang mangangalakal"
                },
                {
                    "label": "D",
                    "text": "Ang mananayaw"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang babaylan ay ang pinuno ng mga ritwal at seremonyang panrelihiyon, madalas ay babae."
        }
    ],
    "3": [
        {
            "id": "pre_3_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing paraan ng ikinabubuhay ng mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagsasaka at pangingisda"
                },
                {
                    "label": "B",
                    "text": "Pagmimina ng ginto lamang"
                },
                {
                    "label": "C",
                    "text": "Pagmamanupaktura"
                },
                {
                    "label": "D",
                    "text": "Turismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Karamihan sa mga sinaunang Pilipino ay umaasa sa pagsasaka, pangingisda, at pangangaso bilang pangunahing hanapbuhay."
        },
        {
            "id": "pre_3_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong sistema ng pangangalakal ang ginamit ng mga sinaunang Pilipino kung saan pinagpapalitan ang mga produkto?",
            "options": [
                {
                    "label": "A",
                    "text": "Barter/Palitan"
                },
                {
                    "label": "B",
                    "text": "Online shopping"
                },
                {
                    "label": "C",
                    "text": "Credit system"
                },
                {
                    "label": "D",
                    "text": "Auction"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bago dumating ang salapi, ginamit ng mga sinaunang Pilipino ang sistemang barter kung saan pinagpapalitan ang mga produkto."
        },
        {
            "id": "pre_3_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na bansa ang nakipagkalakalan sa mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Tsina"
                },
                {
                    "label": "B",
                    "text": "Estados Unidos"
                },
                {
                    "label": "C",
                    "text": "Inglatera"
                },
                {
                    "label": "D",
                    "text": "Pransya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nakipagkalakalan ang mga sinaunang Pilipino sa Tsina, India, Borneo, at Siam bago pa man dumating ang mga Kastila."
        },
        {
            "id": "pre_3_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isa sa mga produktong ipinagpapalit ng mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Ginto at perlas"
                },
                {
                    "label": "B",
                    "text": "Plastik"
                },
                {
                    "label": "C",
                    "text": "Bakal na inimport"
                },
                {
                    "label": "D",
                    "text": "Kotse"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang ginto, perlas, at abaka ay ilan sa mga produktong ipinagpapalit ng mga sinaunang Pilipino sa mga dayuhang mangangalakal."
        },
        {
            "id": "pre_3_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa maliliit na piraso ng ginto na ginamit bilang isang uri ng salapi ng sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Piloncitos"
                },
                {
                    "label": "B",
                    "text": "Barya"
                },
                {
                    "label": "C",
                    "text": "Peso"
                },
                {
                    "label": "D",
                    "text": "Sentimo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang piloncitos ay maliliit na piraso ng ginto na ginamit bilang maagang anyo ng salapi sa sinaunang Pilipinas."
        }
    ],
    "4": [
        {
            "id": "pre_4_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sinaunang sistema ng pagsulat ng mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Baybayin"
                },
                {
                    "label": "B",
                    "text": "Alpabeto"
                },
                {
                    "label": "C",
                    "text": "Hiragana"
                },
                {
                    "label": "D",
                    "text": "Kanji"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang baybayin ay isang katutubong sistema ng pagsulat na ginamit ng mga sinaunang Pilipino bago dumating ang mga Kastila."
        },
        {
            "id": "pre_4_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mahabang tulang bayan na naglalarawan sa kabayanihan, tulad ng \"Biag ni Lam-ang\"?",
            "options": [
                {
                    "label": "A",
                    "text": "Epiko"
                },
                {
                    "label": "B",
                    "text": "Tanaga"
                },
                {
                    "label": "C",
                    "text": "Sanaysay"
                },
                {
                    "label": "D",
                    "text": "Talumpati"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang epiko ay mahabang tulang bayan na naglalarawan ng kabayanihan at kaugalian ng isang pangkat etniko, tulad ng \"Biag ni Lam-ang\" ng mga Ilokano."
        },
        {
            "id": "pre_4_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang katutubong instrumentong pangmusika ng sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Kudyapi"
                },
                {
                    "label": "B",
                    "text": "Piano"
                },
                {
                    "label": "C",
                    "text": "Gitara elektrika"
                },
                {
                    "label": "D",
                    "text": "Byolin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang kudyapi ay isang katutubong instrumentong may kwerdas na ginamit ng mga sinaunang Pilipino."
        },
        {
            "id": "pre_4_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kaugaliang pagtatattoo ng katawan na malawakang ginawa noong sinaunang panahon, lalo na sa mga Visaya?",
            "options": [
                {
                    "label": "A",
                    "text": "Pintados"
                },
                {
                    "label": "B",
                    "text": "Tapis"
                },
                {
                    "label": "C",
                    "text": "Bahag"
                },
                {
                    "label": "D",
                    "text": "Baro"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang \"pintados\" ay ang katawagan ng mga Kastila sa mga taga-Visayas dahil sa kanilang kaugaliang pagpinta o pagtatattoo sa katawan."
        },
        {
            "id": "pre_4_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade4",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong kasuotan ang karaniwang isinusuot ng mga lalaki sa sinaunang Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Bahag"
                },
                {
                    "label": "B",
                    "text": "Barong tagalog"
                },
                {
                    "label": "C",
                    "text": "Amerikana"
                },
                {
                    "label": "D",
                    "text": "Tsinelas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang bahag ay ang tradisyunal na kasuotan ng mga lalaking sinaunang Pilipino, na nakabalot sa baywang."
        }
    ],
    "5": [
        {
            "id": "pre_5_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa paniniwala ng mga sinaunang Pilipino na may diyos o espiritu ang kalikasan?",
            "options": [
                {
                    "label": "A",
                    "text": "Animismo"
                },
                {
                    "label": "B",
                    "text": "Katolisismo"
                },
                {
                    "label": "C",
                    "text": "Islam"
                },
                {
                    "label": "D",
                    "text": "Budismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang animismo ay ang paniniwalang may kaluluwa o espiritu ang mga bagay sa kalikasan gaya ng puno, bato, at ilog."
        },
        {
            "id": "pre_5_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang itinuturing na pinakamataas na diyos ng mga sinaunang Tagalog?",
            "options": [
                {
                    "label": "A",
                    "text": "Bathala"
                },
                {
                    "label": "B",
                    "text": "Sidapa"
                },
                {
                    "label": "C",
                    "text": "Amanikable"
                },
                {
                    "label": "D",
                    "text": "Diyan Masalanta"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Bathala ang itinuturing na pinakamataas na diyos ng mga sinaunang Tagalog, na lumikha ng mundo at tao."
        },
        {
            "id": "pre_5_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing tungkulin ng babaylan sa mga ritwal ng sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Pamamagitan sa mga diyos at espiritu"
                },
                {
                    "label": "B",
                    "text": "Paglikom ng buwis"
                },
                {
                    "label": "C",
                    "text": "Pamumuno sa digmaan"
                },
                {
                    "label": "D",
                    "text": "Pangangalakal"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang babaylan ang tagapamagitan sa pagitan ng mga tao at ng mundo ng mga diyos at espiritu sa pamamagitan ng mga ritwal."
        },
        {
            "id": "pre_5_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang paniniwala ng mga sinaunang Pilipino tungkol sa buhay pagkatapos mamatay?",
            "options": [
                {
                    "label": "A",
                    "text": "May buhay pagkatapos ng kamatayan, kaya sinasamahan ng gamit ang bangkay"
                },
                {
                    "label": "B",
                    "text": "Walang paniniwala tungkol dito"
                },
                {
                    "label": "C",
                    "text": "Ang kamatayan ay katapusan ng lahat"
                },
                {
                    "label": "D",
                    "text": "Ang kaluluwa ay nawawala kaagad"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naniniwala ang mga sinaunang Pilipino sa buhay pagkatapos mamatay, kaya isinasama sa libingan ang mga gamit ng namatay."
        },
        {
            "id": "pre_5_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang kalikasan sa paniniwalang panrelihiyon ng mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Pinaniniwalaang tirahan ito ng mga diwata at espiritu"
                },
                {
                    "label": "B",
                    "text": "Walang kinalaman sa relihiyon"
                },
                {
                    "label": "C",
                    "text": "Ginagamit lamang para sa kalakalan"
                },
                {
                    "label": "D",
                    "text": "Hindi ito pinahahalagahan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinaniniwalaang may naninirahang diwata at espiritu sa mga puno, ilog, at bundok kaya ginagalang ang kalikasan."
        }
    ],
    "6": [
        {
            "id": "pre_6_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pangunahing tagapagpatupad ng batas sa isang sinaunang barangay?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang Datu"
                },
                {
                    "label": "B",
                    "text": "Ang mga Alipin"
                },
                {
                    "label": "C",
                    "text": "Ang mga dayuhan"
                },
                {
                    "label": "D",
                    "text": "Walang tagapagpatupad"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Datu ang nagsisilbing pinuno, tagapaghatol, at tagapagpatupad ng batas sa loob ng barangay."
        },
        {
            "id": "pre_6_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kaugaliang pagsusubok kung saan ipinapasa ang isang tao sa isang mapanganib na gawain upang malaman kung siya ay nagkasala?",
            "options": [
                {
                    "label": "A",
                    "text": "Subok o Trial by Ordeal"
                },
                {
                    "label": "B",
                    "text": "Sanduguan"
                },
                {
                    "label": "C",
                    "text": "Barter"
                },
                {
                    "label": "D",
                    "text": "Kasal"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang \"subok\" o trial by ordeal ay isang paraan ng paglutas ng usapin kung saan sinusuri ang pagkakasala sa pamamagitan ng mapanganib na pagsubok."
        },
        {
            "id": "pre_6_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kaugaliang pakikipagkaibigan sa pagitan ng dalawang pinuno kung saan sila ay uumin ng dugo bilang tanda ng katapatan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sanduguan"
                },
                {
                    "label": "B",
                    "text": "Subok"
                },
                {
                    "label": "C",
                    "text": "Pamanhikan"
                },
                {
                    "label": "D",
                    "text": "Bayanihan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang sanduguan o blood compact ay ritwal ng pakikipagkaibigan kung saan ang dalawang panig ay uminom ng kaunting dugo ng isa't isa bilang tanda ng tiwala."
        },
        {
            "id": "pre_6_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang maaaring maging parusa sa isang taong nagkasala ng malaking pagkakamali sa sinaunang barangay?",
            "options": [
                {
                    "label": "A",
                    "text": "Multa o pagiging alipin"
                },
                {
                    "label": "B",
                    "text": "Libreng biyahe"
                },
                {
                    "label": "C",
                    "text": "Karangalan"
                },
                {
                    "label": "D",
                    "text": "Regalo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang karaniwang parusa sa sinaunang lipunan ay maaaring multa, at sa malalang kaso, pagiging alipin ng nagkasala."
        },
        {
            "id": "pre_6_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang pagkakaroon ng alyansa sa pagitan ng mga barangay?",
            "options": [
                {
                    "label": "A",
                    "text": "Para sa magkakasamang pagtatanggol laban sa banta"
                },
                {
                    "label": "B",
                    "text": "Para lang sa libangan"
                },
                {
                    "label": "C",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "D",
                    "text": "Para pahirapan ang ibang barangay"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga alyansa sa pagitan ng barangay ay nagbibigay ng lakas para sa sama-samang pagtatanggol at kalakalan."
        }
    ],
    "7": [
        {
            "id": "pre_7_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang explorer na pinamunuan ang unang ekspedisyong Espanyol na nakarating sa Pilipinas noong 1521?",
            "options": [
                {
                    "label": "A",
                    "text": "Ferdinand Magellan"
                },
                {
                    "label": "B",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "C",
                    "text": "Christopher Columbus"
                },
                {
                    "label": "D",
                    "text": "Juan Sebastian Elcano"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Ferdinand Magellan, sa ilalim ng bandila ng Espanya, ang unang Europeong nakarating sa Pilipinas noong 1521."
        },
        {
            "id": "pre_7_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan unang lumapag ang ekspedisyon ni Magellan bago siya napatay sa Mactan?",
            "options": [
                {
                    "label": "A",
                    "text": "Limasawa"
                },
                {
                    "label": "B",
                    "text": "Maynila"
                },
                {
                    "label": "C",
                    "text": "Cebu lamang"
                },
                {
                    "label": "D",
                    "text": "Palawan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ayon sa maraming kasaysayan, unang dumaong ang ekspedisyon ni Magellan sa Limasawa bago sila nagtuloy sa Cebu."
        },
        {
            "id": "pre_7_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang Italyanong kasama ni Magellan na nagtala ng kanilang paglalakbay?",
            "options": [
                {
                    "label": "A",
                    "text": "Antonio Pigafetta"
                },
                {
                    "label": "B",
                    "text": "Juan Sebastian Elcano"
                },
                {
                    "label": "C",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "D",
                    "text": "Rajah Humabon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Antonio Pigafetta ang naging kasama ni Magellan at siyang nagtala ng detalyadong salaysay ng ekspedisyon."
        },
        {
            "id": "pre_7_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangyayaring naganap sa Limasawa na itinuturing na simula ng Kristiyanismo sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Unang Misa"
                },
                {
                    "label": "B",
                    "text": "Labanan sa Mactan"
                },
                {
                    "label": "C",
                    "text": "Sanduguan kay Rajah Humabon"
                },
                {
                    "label": "D",
                    "text": "Pagpapaalipin sa mga katutubo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinagawa ang Unang Misa sa Limasawa noong 1521, na itinuturing na simula ng Kristiyanismo sa bansa."
        },
        {
            "id": "pre_7_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinuno ng Cebu na nakipag-alyansa kay Magellan?",
            "options": [
                {
                    "label": "A",
                    "text": "Rajah Humabon"
                },
                {
                    "label": "B",
                    "text": "Lapu-Lapu"
                },
                {
                    "label": "C",
                    "text": "Rajah Sulayman"
                },
                {
                    "label": "D",
                    "text": "Datu Sikatuna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Rajah Humabon, pinuno ng Cebu, ang nakipag-alyansa kay Magellan at tumanggap ng binyag na Kristiyano."
        }
    ],
    "8": [
        {
            "id": "pre_8_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan naganap ang Labanan sa Mactan?",
            "options": [
                {
                    "label": "A",
                    "text": "Abril 27, 1521"
                },
                {
                    "label": "B",
                    "text": "Marso 16, 1521"
                },
                {
                    "label": "C",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "D",
                    "text": "Disyembre 8, 1941"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Labanan sa Mactan ay naganap noong Abril 27, 1521, kung saan napatay si Ferdinand Magellan."
        },
        {
            "id": "pre_8_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit tumanggi si Lapu-Lapu na sumuko sa mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Ayaw niyang mawalan ng kapangyarihan at kalayaan ang kanyang barangay"
                },
                {
                    "label": "B",
                    "text": "Wala siyang alam sa mga Kastila"
                },
                {
                    "label": "C",
                    "text": "Kaibigan niya si Magellan"
                },
                {
                    "label": "D",
                    "text": "Gusto niyang sumama sa Espanya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagtanggol ni Lapu-Lapu ang kalayaan ng Mactan at ayaw niyang pasukin ang kapangyarihan ng mga dayuhan."
        },
        {
            "id": "pre_8_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging kinalabasan ng Labanan sa Mactan para kay Ferdinand Magellan?",
            "options": [
                {
                    "label": "A",
                    "text": "Napatay siya sa labanan"
                },
                {
                    "label": "B",
                    "text": "Nanalo siya at nasakop ang Mactan"
                },
                {
                    "label": "C",
                    "text": "Bumalik siya sa Espanya"
                },
                {
                    "label": "D",
                    "text": "Nakipagkaibigan siya kay Lapu-Lapu"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Napatay si Ferdinand Magellan sa Labanan sa Mactan noong Abril 27, 1521, kasama ang ilan sa kanyang mga tauhan."
        },
        {
            "id": "pre_8_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang Labanan sa Mactan sa kasaysayan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Ito ang unang matagumpay na paglaban ng mga Pilipino sa mananakop na dayuhan"
                },
                {
                    "label": "B",
                    "text": "Ito ang huling labanan sa Pilipinas"
                },
                {
                    "label": "C",
                    "text": "Nagsimula rito ang kalakalang barter"
                },
                {
                    "label": "D",
                    "text": "Doon nagsimula ang Baybayin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Labanan sa Mactan ay simbolo ng unang matagumpay na paglaban ng mga katutubong Pilipino laban sa dayuhang mananakop."
        },
        {
            "id": "pre_8_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging simbolo ni Lapu-Lapu sa kasalukuyang Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Unang bayani ng Pilipinas na lumaban sa dayuhan"
                },
                {
                    "label": "B",
                    "text": "Unang pari sa Pilipinas"
                },
                {
                    "label": "C",
                    "text": "Tagapagtatag ng Maynila"
                },
                {
                    "label": "D",
                    "text": "Unang Pangulo ng Pilipinas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kinikilala si Lapu-Lapu bilang isa sa mga unang bayani ng Pilipinas dahil sa kanyang paglaban sa dayuhang mananakop."
        }
    ],
    "9": [
        {
            "id": "pre_9_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pinakamahalagang katangian ng sistemang barangay bago dumating ang mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Bawat barangay ay may sariling pamumuno at kasarinlan"
                },
                {
                    "label": "B",
                    "text": "Iisa lang ang pinuno ng buong kapuluan"
                },
                {
                    "label": "C",
                    "text": "Walang batas na sinusunod"
                },
                {
                    "label": "D",
                    "text": "Walang kalakalan sa ibang bansa"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bawat barangay noong sinaunang panahon ay malaya at may sariling pamumuno, hindi ito bahagi ng isang sentralisadong bansa."
        },
        {
            "id": "pre_9_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang pagkakaisa ng mga barangay para sa kanilang kaligtasan?",
            "options": [
                {
                    "label": "A",
                    "text": "Nagbibigay ito ng lakas laban sa banta ng ibang pangkat o dayuhan"
                },
                {
                    "label": "B",
                    "text": "Wala itong epekto sa kaligtasan"
                },
                {
                    "label": "C",
                    "text": "Nagpapahina lamang ito sa bawat barangay"
                },
                {
                    "label": "D",
                    "text": "Ginagamit lamang ito sa kalakalan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pagkakaisa at alyansa ng mga barangay, gaya ng sanduguan, ay nagpapatibay sa kanilang kakayahang magtanggol laban sa panganib."
        },
        {
            "id": "pre_9_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na yaman ng kulturang Pilipino ang nagmula pa sa sinaunang panahon?",
            "options": [
                {
                    "label": "A",
                    "text": "Baybayin at mga epikong bayan"
                },
                {
                    "label": "B",
                    "text": "Barong tagalog na gawa ng Kastila"
                },
                {
                    "label": "C",
                    "text": "Wikang Espanyol"
                },
                {
                    "label": "D",
                    "text": "Simbahang Katoliko"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang baybayin at mga epikong bayan gaya ng \"Biag ni Lam-ang\" ay bahagi ng katutubong kulturang Pilipino bago pa dumating ang mga Kastila."
        },
        {
            "id": "pre_9_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano naiimpluwensyahan ng kalakalan sa Tsina at India ang buhay ng mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Nagdulot ito ng bagong produkto, ideya, at yaman sa kanilang lipunan"
                },
                {
                    "label": "B",
                    "text": "Wala itong idinulot na pagbabago"
                },
                {
                    "label": "C",
                    "text": "Ito ang nagpasimula ng Kristiyanismo"
                },
                {
                    "label": "D",
                    "text": "Ito ang nagbigay ng baybayin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang kalakalan sa mga karatig-bansa ay nagdulot ng bagong produkto, kulturang impluwensya, at karagdagang yaman sa lipunan ng mga sinaunang Pilipino."
        },
        {
            "id": "pre_9_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging simula ng pagbabago sa buhay ng mga Pilipino matapos ang 1521?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagdating ng mga Kastila at pananakop sa Pilipinas"
                },
                {
                    "label": "B",
                    "text": "Pagkatapos ng Ikalawang Digmaang Pandaigdig"
                },
                {
                    "label": "C",
                    "text": "Pagdating ng mga Amerikano"
                },
                {
                    "label": "D",
                    "text": "People Power Revolution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang taong 1521 ang naging pasimula ng malawakang pakikipag-ugnayan ng mga Pilipino sa mga Kastila, na sa bandang huli ay hahantong sa pananakop."
        }
    ],
    "10": [
        {
            "id": "pre_10_1",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang teoryang nagsasabing ang mga sinaunang Pilipino ay nagmula sa Timog-Silangang Asya?",
            "options": [
                {
                    "label": "A",
                    "text": "Teoryang Austronesian"
                },
                {
                    "label": "B",
                    "text": "Teoryang Continental Drift"
                },
                {
                    "label": "C",
                    "text": "Big Bang Theory"
                },
                {
                    "label": "D",
                    "text": "Teoryang Evolution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang teoryang Austronesian ang kasalukuyang tinatanggap na paliwanag sa pinagmulan ng mga sinaunang Pilipino."
        },
        {
            "id": "pre_10_2",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinuno ng isang sinaunang barangay?",
            "options": [
                {
                    "label": "A",
                    "text": "Datu"
                },
                {
                    "label": "B",
                    "text": "Alipin"
                },
                {
                    "label": "C",
                    "text": "Timawa"
                },
                {
                    "label": "D",
                    "text": "Babaylan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Datu ang pinuno ng barangay, tagapagtanggol, at tagapaghatol ng batas."
        },
        {
            "id": "pre_10_3",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong sistema ng pangangalakal ang ginamit bago dumating ang salapi?",
            "options": [
                {
                    "label": "A",
                    "text": "Barter"
                },
                {
                    "label": "B",
                    "text": "E-wallet"
                },
                {
                    "label": "C",
                    "text": "Kredito"
                },
                {
                    "label": "D",
                    "text": "Installment"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang barter ay ang pagpapalitan ng produkto na ginamit bago pa may salapi."
        },
        {
            "id": "pre_10_4",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang katutubong sistema ng pagsulat ng mga sinaunang Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Baybayin"
                },
                {
                    "label": "B",
                    "text": "Hiragana"
                },
                {
                    "label": "C",
                    "text": "Cyrillic"
                },
                {
                    "label": "D",
                    "text": "Latin"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang baybayin ang katutubong sistema ng pagsulat ng mga sinaunang Pilipino."
        },
        {
            "id": "pre_10_5",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang itinuturing na pinakamataas na diyos ng mga sinaunang Tagalog?",
            "options": [
                {
                    "label": "A",
                    "text": "Bathala"
                },
                {
                    "label": "B",
                    "text": "Sidapa"
                },
                {
                    "label": "C",
                    "text": "Amanikable"
                },
                {
                    "label": "D",
                    "text": "Bakunawa"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Bathala ang pinakamataas na diyos ng mga sinaunang Tagalog ayon sa kanilang paniniwala."
        },
        {
            "id": "pre_10_6",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa ritwal ng pakikipagkaibigan kung saan uminom ng dugo ang dalawang panig?",
            "options": [
                {
                    "label": "A",
                    "text": "Sanduguan"
                },
                {
                    "label": "B",
                    "text": "Subok"
                },
                {
                    "label": "C",
                    "text": "Bayanihan"
                },
                {
                    "label": "D",
                    "text": "Pamamanhikan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang sanduguan ay ritwal ng katapatan sa pagitan ng dalawang panig."
        },
        {
            "id": "pre_10_7",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang explorer na pinamunuan ang unang ekspedisyong Espanyol na nakarating sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Ferdinand Magellan"
                },
                {
                    "label": "B",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "C",
                    "text": "Christopher Columbus"
                },
                {
                    "label": "D",
                    "text": "Marco Polo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Ferdinand Magellan ang pinuno ng unang ekspedisyong Espanyol na nakarating sa Pilipinas noong 1521."
        },
        {
            "id": "pre_10_8",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan isinagawa ang Unang Misa noong 1521?",
            "options": [
                {
                    "label": "A",
                    "text": "Limasawa"
                },
                {
                    "label": "B",
                    "text": "Maynila"
                },
                {
                    "label": "C",
                    "text": "Mactan"
                },
                {
                    "label": "D",
                    "text": "Palawan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinagawa ang Unang Misa sa Limasawa bago nagtungo ang ekspedisyon sa Cebu."
        },
        {
            "id": "pre_10_9",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinuno ng Cebu na nakipag-alyansa kay Magellan?",
            "options": [
                {
                    "label": "A",
                    "text": "Rajah Humabon"
                },
                {
                    "label": "B",
                    "text": "Lapu-Lapu"
                },
                {
                    "label": "C",
                    "text": "Rajah Sulayman"
                },
                {
                    "label": "D",
                    "text": "Datu Sikatuna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Rajah Humabon ng Cebu ang nakipag-alyansa kay Magellan at tumanggap ng binyag."
        },
        {
            "id": "pre_10_10",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang katutubong instrumentong pangmusika?",
            "options": [
                {
                    "label": "A",
                    "text": "Kudyapi"
                },
                {
                    "label": "B",
                    "text": "Piano"
                },
                {
                    "label": "C",
                    "text": "Byolin"
                },
                {
                    "label": "D",
                    "text": "Trumpeta"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang kudyapi ay isang katutubong instrumentong may kwerdas."
        },
        {
            "id": "pre_10_11",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan naganap ang Labanan sa Mactan?",
            "options": [
                {
                    "label": "A",
                    "text": "Abril 27, 1521"
                },
                {
                    "label": "B",
                    "text": "Marso 16, 1521"
                },
                {
                    "label": "C",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "D",
                    "text": "Mayo 1, 1521"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Labanan sa Mactan ay naganap noong Abril 27, 1521."
        },
        {
            "id": "pre_10_12",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit tumanggi si Lapu-Lapu na sumuko sa mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Ayaw niyang mawalan ng kalayaan ang kanyang barangay"
                },
                {
                    "label": "B",
                    "text": "Kaibigan niya si Magellan"
                },
                {
                    "label": "C",
                    "text": "Wala siyang alam sa mga Kastila"
                },
                {
                    "label": "D",
                    "text": "Gusto niyang sumama sa Espanya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagtanggol ni Lapu-Lapu ang kalayaan ng kanyang barangay laban sa dayuhang kapangyarihan."
        },
        {
            "id": "pre_10_13",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging kinalabasan ng Labanan sa Mactan para kay Magellan?",
            "options": [
                {
                    "label": "A",
                    "text": "Napatay siya sa labanan"
                },
                {
                    "label": "B",
                    "text": "Nanalo siya"
                },
                {
                    "label": "C",
                    "text": "Bumalik siya sa Espanya"
                },
                {
                    "label": "D",
                    "text": "Naging kaibigan ni Lapu-Lapu"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Napatay si Ferdinand Magellan sa Labanan sa Mactan."
        },
        {
            "id": "pre_10_14",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang Labanan sa Mactan sa kasaysayan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Ito ang unang matagumpay na paglaban sa mananakop na dayuhan"
                },
                {
                    "label": "B",
                    "text": "Ito ang huling labanan sa Pilipinas"
                },
                {
                    "label": "C",
                    "text": "Doon nagsimula ang baybayin"
                },
                {
                    "label": "D",
                    "text": "Doon nagsimula ang kalakalang barter"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Labanan sa Mactan ay simbolo ng unang matagumpay na paglaban ng mga Pilipino laban sa dayuhang mananakop."
        },
        {
            "id": "pre_10_15",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng mamamayan ang mga \"maharlika\"?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga mandirigma at maimpluwensyang pamilya"
                },
                {
                    "label": "B",
                    "text": "Mga alipin"
                },
                {
                    "label": "C",
                    "text": "Mga dayuhang mangangalakal"
                },
                {
                    "label": "D",
                    "text": "Mga bata"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga maharlika ay malayang mamamayan na may mataas na katayuan sa lipunan."
        },
        {
            "id": "pre_10_16",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa malayang mamamayan na hindi kabilang sa maharlika o alipin?",
            "options": [
                {
                    "label": "A",
                    "text": "Timawa"
                },
                {
                    "label": "B",
                    "text": "Babaylan"
                },
                {
                    "label": "C",
                    "text": "Panday"
                },
                {
                    "label": "D",
                    "text": "Datu"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga timawa ay malayang mamamayan na maaaring magmay-ari ng lupa."
        },
        {
            "id": "pre_10_17",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang produktong ipinagpalit ng mga sinaunang Pilipino sa mga dayuhan?",
            "options": [
                {
                    "label": "A",
                    "text": "Ginto at perlas"
                },
                {
                    "label": "B",
                    "text": "Plastik"
                },
                {
                    "label": "C",
                    "text": "Bakal na inimport"
                },
                {
                    "label": "D",
                    "text": "Kotse"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang ginto, perlas, at abaka ay ilan sa mga produktong ipinagpalit sa mga dayuhang mangangalakal."
        },
        {
            "id": "pre_10_18",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang Italyanong kasama ni Magellan na nagtala ng kanilang paglalakbay?",
            "options": [
                {
                    "label": "A",
                    "text": "Antonio Pigafetta"
                },
                {
                    "label": "B",
                    "text": "Juan Sebastian Elcano"
                },
                {
                    "label": "C",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "D",
                    "text": "Rajah Humabon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Antonio Pigafetta ang nagtala ng detalyadong salaysay ng ekspedisyon ni Magellan."
        },
        {
            "id": "pre_10_19",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kaugaliang pagtatattoo ng katawan na malawakang ginawa lalo na sa mga Visaya?",
            "options": [
                {
                    "label": "A",
                    "text": "Pintados"
                },
                {
                    "label": "B",
                    "text": "Bahag"
                },
                {
                    "label": "C",
                    "text": "Tapis"
                },
                {
                    "label": "D",
                    "text": "Baro"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang \"pintados\" ay ang katawagan ng mga Kastila sa mga taga-Visayas dahil sa kanilang pagtatattoo."
        },
        {
            "id": "pre_10_20",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging simbolo ni Lapu-Lapu sa kasalukuyang Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Unang bayani ng Pilipinas na lumaban sa dayuhan"
                },
                {
                    "label": "B",
                    "text": "Unang pari sa Pilipinas"
                },
                {
                    "label": "C",
                    "text": "Tagapagtatag ng Maynila"
                },
                {
                    "label": "D",
                    "text": "Unang Pangulo ng Pilipinas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kinikilala si Lapu-Lapu bilang isa sa mga unang bayani ng Pilipinas."
        },
        {
            "id": "pre_10_21",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pinakamahalagang katangian ng sistemang barangay bago dumating ang mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Bawat barangay ay may sariling pamumuno at kasarinlan"
                },
                {
                    "label": "B",
                    "text": "Iisa lang ang pinuno ng buong kapuluan"
                },
                {
                    "label": "C",
                    "text": "Walang batas na sinusunod"
                },
                {
                    "label": "D",
                    "text": "Walang kalakalan sa ibang bansa"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bawat barangay ay malaya at may sariling pamumuno bago pa man ang pananakop ng Espanya."
        },
        {
            "id": "pre_10_22",
            "era": "pre-colonial",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging simula ng pagbabago sa buhay ng mga Pilipino matapos ang 1521?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagdating ng mga Kastila at pananakop sa Pilipinas"
                },
                {
                    "label": "B",
                    "text": "Pagkatapos ng Ikalawang Digmaang Pandaigdig"
                },
                {
                    "label": "C",
                    "text": "Pagdating ng mga Amerikano"
                },
                {
                    "label": "D",
                    "text": "People Power Revolution"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang taong 1521 ang naging simula ng malawakang pakikipag-ugnayan ng mga Pilipino sa mga Kastila."
        }
    ]
}
```

## File: assets/data/questions_spanish.json
```json
{
    "1": [
        {
            "id": "spa_1_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang manlalakbay na Espanyol na nakarating sa Homonhon, Pilipinas noong Marso 1521?",
            "options": [
                {
                    "label": "A",
                    "text": "Ferdinand Magellan"
                },
                {
                    "label": "B",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "C",
                    "text": "Ruy Lopez de Villalobos"
                },
                {
                    "label": "D",
                    "text": "Juan de Salcedo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Magellan ang namuno sa ekspedisyong Espanyol na unang nakarating sa Kapuluan."
        },
        {
            "id": "spa_1_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang Kastilang nakipagsanduguan kay Datu Sikatuna sa Bohol noong 1565?",
            "options": [
                {
                    "label": "A",
                    "text": "Miguel Lopez de Legazpi"
                },
                {
                    "label": "B",
                    "text": "Ferdinand Magellan"
                },
                {
                    "label": "C",
                    "text": "Juan de Salcedo"
                },
                {
                    "label": "D",
                    "text": "Simon de Anda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nakipagsanduguan si Legazpi kay Datu Sikatuna bilang tanda ng pakikipagkaibigan noong 1565."
        },
        {
            "id": "spa_1_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saang lugar itinatag ni Legazpi ang unang pamayanang Kastila noong 1565?",
            "options": [
                {
                    "label": "A",
                    "text": "Cebu"
                },
                {
                    "label": "B",
                    "text": "Maynila"
                },
                {
                    "label": "C",
                    "text": "Bohol"
                },
                {
                    "label": "D",
                    "text": "Iloilo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtatag si Legazpi ng unang permanenteng pamayanang Kastila sa Cebu noong 1565."
        },
        {
            "id": "spa_1_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon nasakop ng mga Kastila ang Maynila?",
            "options": [
                {
                    "label": "A",
                    "text": "1571"
                },
                {
                    "label": "B",
                    "text": "1521"
                },
                {
                    "label": "C",
                    "text": "1898"
                },
                {
                    "label": "D",
                    "text": "1896"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nasakop ng mga Kastila ang Maynila noong 1571, at ito ay naging kabisera ng kolonya."
        },
        {
            "id": "spa_1_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang huling pinuno ng Maynila bago ito sakupin ng mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Rajah Sulayman"
                },
                {
                    "label": "B",
                    "text": "Rajah Humabon"
                },
                {
                    "label": "C",
                    "text": "Lapu-Lapu"
                },
                {
                    "label": "D",
                    "text": "Datu Sikatuna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Rajah Sulayman ang pinuno ng Maynila na lumaban ngunit natalo sa mga puwersang Kastila noong 1571."
        }
    ],
    "2": [
        {
            "id": "spa_2_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinakamataas na opisyal ng pamahalaang Espanyol sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Gobernador Heneral"
                },
                {
                    "label": "B",
                    "text": "Datu"
                },
                {
                    "label": "C",
                    "text": "Cabeza de Barangay"
                },
                {
                    "label": "D",
                    "text": "Alkalde"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Gobernador Heneral ang kinatawan ng Hari ng Espanya at pinakamataas na opisyal sa kolonya."
        },
        {
            "id": "spa_2_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sistemang nagbigay sa mga Kastila ng karapatang mangolekta ng buwis mula sa mga katutubo sa isang lugar?",
            "options": [
                {
                    "label": "A",
                    "text": "Encomienda"
                },
                {
                    "label": "B",
                    "text": "Polo y servicio"
                },
                {
                    "label": "C",
                    "text": "Bandala"
                },
                {
                    "label": "D",
                    "text": "Galleon Trade"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang encomienda system ay nagbigay-kapangyarihan sa mga encomendero na mangolekta ng buwis sa ngalan ng Espanya."
        },
        {
            "id": "spa_2_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang katutubong opisyal na namuno sa isang barangay sa ilalim ng pamahalaang Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Cabeza de Barangay"
                },
                {
                    "label": "B",
                    "text": "Gobernador Heneral"
                },
                {
                    "label": "C",
                    "text": "Alkalde Mayor"
                },
                {
                    "label": "D",
                    "text": "Encomendero"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Cabeza de Barangay ang katutubong pinuno na responsable sa pagkolekta ng buwis sa antas ng barangay."
        },
        {
            "id": "spa_2_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sapilitang paggawa na iniatas ng mga Kastila sa mga katutubong Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Polo y servicio"
                },
                {
                    "label": "B",
                    "text": "Bandala"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Tributo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang polo y servicio ay sapilitang paggawa (forced labor) na iniatas sa mga lalaking Pilipino, karaniwan sa konstruksyon."
        },
        {
            "id": "spa_2_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sapilitang pagbebenta ng ani ng mga magsasaka sa gobyernong Kastila sa mababang presyo?",
            "options": [
                {
                    "label": "A",
                    "text": "Bandala"
                },
                {
                    "label": "B",
                    "text": "Polo y servicio"
                },
                {
                    "label": "C",
                    "text": "Tributo"
                },
                {
                    "label": "D",
                    "text": "Encomienda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang bandala ay sapilitang pagbebenta ng ani sa gobyerno sa halagang mas mababa sa nararapat."
        }
    ],
    "3": [
        {
            "id": "spa_3_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong relihiyon ang ipinakilala at pinalaganap ng mga Kastila sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Katolisismo"
                },
                {
                    "label": "B",
                    "text": "Islam"
                },
                {
                    "label": "C",
                    "text": "Budismo"
                },
                {
                    "label": "D",
                    "text": "Hinduismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinalaganap ng mga misyonerong Kastila ang relihiyong Katoliko sa buong kapuluan."
        },
        {
            "id": "spa_3_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang tawag sa mga paring Kastila na naging isa sa pinakamakapangyarihang grupo sa lipunang kolonyal?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga Prayle (Friars)"
                },
                {
                    "label": "B",
                    "text": "Mga Encomendero"
                },
                {
                    "label": "C",
                    "text": "Mga Ilustrado"
                },
                {
                    "label": "D",
                    "text": "Mga Katipunero"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga prayle ay nagkaroon ng malaking kapangyarihang panlipunan, pampulitika, at pang-ekonomiya sa buong kolonyal na panahon."
        },
        {
            "id": "spa_3_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagtitipon ng mga katutubo mula sa nakakalat na barangay papunta sa isang bayang malapit sa simbahan?",
            "options": [
                {
                    "label": "A",
                    "text": "Reduccion"
                },
                {
                    "label": "B",
                    "text": "Bandala"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Tributo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa ilalim ng patakarang reduccion, pinagsama-sama ang mga katutubo sa \"bajo la campana\" o malapit sa simbahan para mas madaling paganahin at kontrolin."
        },
        {
            "id": "spa_3_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong gusali ang naging sentro ng bawat bayan noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Simbahan"
                },
                {
                    "label": "B",
                    "text": "Palasyo"
                },
                {
                    "label": "C",
                    "text": "Kwartel"
                },
                {
                    "label": "D",
                    "text": "Palengke"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang simbahan ang naging sentro ng buhay panlipunan, pampulitika, at pang-relihiyon ng bawat bayan."
        },
        {
            "id": "spa_3_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano ginamit ang relihiyon bilang paraan ng pagkontrol sa mga katutubo?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng edukasyon, pagsamba, at kapangyarihan ng mga prayle sa pang-araw-araw na buhay"
                },
                {
                    "label": "B",
                    "text": "Wala itong ginamit na kapangyarihan"
                },
                {
                    "label": "C",
                    "text": "Sa pamamagitan ng puwersahang digmaan lamang"
                },
                {
                    "label": "D",
                    "text": "Sa pamamagitan ng kalakalan lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang simbahan, sa pamamagitan ng mga prayle, ay may malaking impluwensya sa edukasyon, batas, at pang-araw-araw na buhay ng mga Pilipino."
        }
    ],
    "4": [
        {
            "id": "spa_4_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kalakalan sa pagitan ng Maynila at Acapulco, Mexico gamit ang malalaking barko?",
            "options": [
                {
                    "label": "A",
                    "text": "Galleon Trade"
                },
                {
                    "label": "B",
                    "text": "Barter System"
                },
                {
                    "label": "C",
                    "text": "Bandala"
                },
                {
                    "label": "D",
                    "text": "Encomienda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Galleon Trade (Manila-Acapulco) ay naging pangunahing pinagmumulan ng kita ng kolonyal na pamahalaan sa loob ng mahigit 200 taon."
        },
        {
            "id": "spa_4_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino lamang ang pinahihintulutang makilahok sa Galleon Trade?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga piniling mangangalakal na Kastila"
                },
                {
                    "label": "B",
                    "text": "Lahat ng Pilipino"
                },
                {
                    "label": "C",
                    "text": "Mga Intsik lamang"
                },
                {
                    "label": "D",
                    "text": "Sinuman"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Galleon Trade ay monopolisado, kaya iilang piniling mangangalakal na Kastila lamang ang nakikinabang dito."
        },
        {
            "id": "spa_4_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pananim ang naging monopolyo ng gobyernong Kastila sa huling bahagi ng kolonisasyon?",
            "options": [
                {
                    "label": "A",
                    "text": "Tabako"
                },
                {
                    "label": "B",
                    "text": "Palay"
                },
                {
                    "label": "C",
                    "text": "Mais"
                },
                {
                    "label": "D",
                    "text": "Kamote"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang Tobacco Monopoly kung saan sapilitang nagtanim ang mga magsasaka ng tabako para sa gobyerno."
        },
        {
            "id": "spa_4_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano nagdulot ng paghihirap ang encomienda system sa mga katutubo?",
            "options": [
                {
                    "label": "A",
                    "text": "Napipilitan silang magbayad ng buwis at magtrabaho para sa encomendero"
                },
                {
                    "label": "B",
                    "text": "Libre silang lahat"
                },
                {
                    "label": "C",
                    "text": "Sila ang namamahala sa lupa"
                },
                {
                    "label": "D",
                    "text": "Wala itong epekto sa kanila"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang mga katutubo sa ilalim ng encomienda ay obligadong magbayad ng buwis at kadalasa'y inaabuso ng mga encomendero."
        },
        {
            "id": "spa_4_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa malalaking lupaing pag-aari ng mga prayle o mayayamang pamilya noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Hacienda"
                },
                {
                    "label": "B",
                    "text": "Barangay"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Bandala"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang hacienda ay malawak na lupaing sakahan na pag-aari ng mga prayle o mayayamang pamilya, kung saan nagtatrabaho ang mga kasama o magsasaka."
        }
    ],
    "5": [
        {
            "id": "spa_5_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinuno ng pinakamatagal na rebelyon laban sa mga Kastila sa Bohol?",
            "options": [
                {
                    "label": "A",
                    "text": "Francisco Dagohoy"
                },
                {
                    "label": "B",
                    "text": "Diego Silang"
                },
                {
                    "label": "C",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "D",
                    "text": "Sumoroy"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinamunuan ni Francisco Dagohoy ang isang rebelyon sa Bohol na tumagal nang mahigit walumpung taon."
        },
        {
            "id": "spa_5_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sinong mag-asawa ang namuno sa rebelyon sa Ilocos laban sa mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Diego at Gabriela Silang"
                },
                {
                    "label": "B",
                    "text": "Andres at Gregoria Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Emilio at Hilaria Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Francisco at Maria Dagohoy"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sina Diego at Gabriela Silang ang namuno sa rebelyon sa Ilocos, at ipinagpatuloy ni Gabriela ang laban matapos mapatay si Diego."
        },
        {
            "id": "spa_5_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang dahilan ng maraming rebelyon laban sa mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Polo y servicio at bandala na nagpapahirap sa mga katutubo"
                },
                {
                    "label": "B",
                    "text": "Sobrang kaginhawahan ng buhay"
                },
                {
                    "label": "C",
                    "text": "Kakulangan ng pagkain sa Espanya"
                },
                {
                    "label": "D",
                    "text": "Pagkakaroon ng masaganang trabaho"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang sapilitang paggawa (polo y servicio) at sapilitang pagbebenta ng ani (bandala) ay ilan sa mga pangunahing dahilan ng mga rebelyon."
        },
        {
            "id": "spa_5_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang namuno sa isang rebelyon sa Samar noong ika-17 siglo?",
            "options": [
                {
                    "label": "A",
                    "text": "Sumoroy"
                },
                {
                    "label": "B",
                    "text": "Dagohoy"
                },
                {
                    "label": "C",
                    "text": "Diego Silang"
                },
                {
                    "label": "D",
                    "text": "Rajah Sulayman"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinamunuan ni Sumoroy ang isang rebelyon sa Samar bilang pagtutol sa polo y servicio."
        },
        {
            "id": "spa_5_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalaga ang mga unang rebelyong ito sa kasaysayan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Ipinakita nila ang unang mga hakbang ng paglaban laban sa mapang-aping sistema"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Sila ang nagtatag ng Katipunan"
                },
                {
                    "label": "D",
                    "text": "Nagtapos ang kolonisasyon dahil dito"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bagamat hindi nagtagumpay ang mga unang rebelyon, ipinakita nito ang diwa ng paglaban na naging inspirasyon sa mga susunod na kilusan."
        }
    ],
    "6": [
        {
            "id": "spa_6_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong wika ang ipinakilala at ginamit sa opisyal na pamahalaan noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Espanyol"
                },
                {
                    "label": "B",
                    "text": "Ingles"
                },
                {
                    "label": "C",
                    "text": "Hapon"
                },
                {
                    "label": "D",
                    "text": "Intsik"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang wikang Espanyol ang naging opisyal na wika ng pamahalaan sa buong panahon ng kolonisasyon."
        },
        {
            "id": "spa_6_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang unti-unting nangyari sa paggamit ng baybayin noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Unti-unti itong napalitan ng alpabetong Romano"
                },
                {
                    "label": "B",
                    "text": "Lalo itong kumalat"
                },
                {
                    "label": "C",
                    "text": "Naging opisyal na wika ito"
                },
                {
                    "label": "D",
                    "text": "Walang nagbago rito"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Unti-unting napalitan ang baybayin ng alpabetong Romano na ginamit ng mga Kastila sa pagsulat."
        },
        {
            "id": "spa_6_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong uri ng paaralan ang itinatag ng mga prayle noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Paaralang pang-parokya (parochial schools)"
                },
                {
                    "label": "B",
                    "text": "Pampublikong paaralan ng estado"
                },
                {
                    "label": "C",
                    "text": "Online na klase"
                },
                {
                    "label": "D",
                    "text": "Walang itinatag na paaralan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ng mga prayle ang mga paaralang pang-parokya na nagturo ng relihiyon at batayang kaalaman."
        },
        {
            "id": "spa_6_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang isang kasuotang naimpluwensyahan ng panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Baro't saya"
                },
                {
                    "label": "B",
                    "text": "Bahag"
                },
                {
                    "label": "C",
                    "text": "T-shirt"
                },
                {
                    "label": "D",
                    "text": "Kimono"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang baro't saya ay isang tradisyunal na kasuotang babae na umusbong sa panahon ng Espanyol."
        },
        {
            "id": "spa_6_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagsanib ng katutubong paniniwala at Katolisismo na umusbong noong panahong iyon?",
            "options": [
                {
                    "label": "A",
                    "text": "Folk Catholicism"
                },
                {
                    "label": "B",
                    "text": "Animismo"
                },
                {
                    "label": "C",
                    "text": "Islam"
                },
                {
                    "label": "D",
                    "text": "Budismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang folk Catholicism ay ang pagsasanib ng mga katutubong paniniwala (tulad ng paggamit ng anting-anting) sa mga gawaing Katoliko."
        }
    ],
    "7": [
        {
            "id": "spa_7_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kilusan ng mga ilustradong Pilipino na naglalayong isulong ang reporma sa gobyernong Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "B",
                    "text": "Katipunan"
                },
                {
                    "label": "C",
                    "text": "Batas Militar"
                },
                {
                    "label": "D",
                    "text": "Reduccion"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kilusang Propaganda ay isang kampanyang pampanitikan at pampulitika na naglalayong isulong ang reporma, hindi rebolusyon."
        },
        {
            "id": "spa_7_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang sumulat ng mga nobelang Noli Me Tangere at El Filibusterismo?",
            "options": [
                {
                    "label": "A",
                    "text": "Jose Rizal"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Marcelo H. del Pilar"
                },
                {
                    "label": "D",
                    "text": "Emilio Aguinaldo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinulat ni Jose Rizal ang Noli Me Tangere at El Filibusterismo upang ilantad ang mga kalupitan sa ilalim ng kolonyal na sistema."
        },
        {
            "id": "spa_7_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang tagapagtatag ng pahayagang La Solidaridad na sumusulong ng reporma?",
            "options": [
                {
                    "label": "A",
                    "text": "Marcelo H. del Pilar"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Apolinario Mabini"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Marcelo H. del Pilar ang naging patnugot ng La Solidaridad, ang opisyal na pahayagan ng Kilusang Propaganda."
        },
        {
            "id": "spa_7_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang manunulat na Pilipino na kilala sa sanaysay na \"Fray Botod\" na kumukondena sa pang-aabuso ng mga prayle?",
            "options": [
                {
                    "label": "A",
                    "text": "Graciano Lopez Jaena"
                },
                {
                    "label": "B",
                    "text": "Jose Rizal"
                },
                {
                    "label": "C",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "D",
                    "text": "Emilio Jacinto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Graciano Lopez Jaena ay kilalang manunulat at tagapagtatag ng La Solidaridad na kumondena sa pang-aabuso ng mga prayle."
        },
        {
            "id": "spa_7_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang pangunahing layunin ng Kilusang Propaganda?",
            "options": [
                {
                    "label": "A",
                    "text": "Reporma sa loob ng sistemang kolonyal, hindi kalayaan sa pamamagitan ng armas"
                },
                {
                    "label": "B",
                    "text": "Agarang paghihimagsik gamit ang armas"
                },
                {
                    "label": "C",
                    "text": "Pakikipagkalakalan sa Amerika"
                },
                {
                    "label": "D",
                    "text": "Pagtatatag ng bagong relihiyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naniniwala ang mga ilustrado sa Kilusang Propaganda na maaaring baguhin ang sistema sa pamamagitan ng mapayapang reporma, hindi armadong himagsikan."
        }
    ],
    "8": [
        {
            "id": "spa_8_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang nagtatag ng Katipunan noong 1892?",
            "options": [
                {
                    "label": "A",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "B",
                    "text": "Jose Rizal"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Marcelo H. del Pilar"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ni Andres Bonifacio ang Katipunan noong 1892 bilang lihim na samahang naglalayong makamit ang kalayaan sa pamamagitan ng armadong pakikibaka."
        },
        {
            "id": "spa_8_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagpunit ng mga sedula bilang simbolo ng simula ng Rebolusyong Pilipino noong 1896?",
            "options": [
                {
                    "label": "A",
                    "text": "Sigaw ng Pugad Lawin"
                },
                {
                    "label": "B",
                    "text": "Kasunduan sa Biak-na-Bato"
                },
                {
                    "label": "C",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "D",
                    "text": "Kasunduan sa Paris"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Sigaw ng Pugad Lawin, pinunit ng mga Katipunero ang kanilang mga sedula bilang simbolo ng paghihimagsik laban sa Espanya."
        },
        {
            "id": "spa_8_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan binaril si Jose Rizal sa Bagumbayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Disyembre 30, 1896"
                },
                {
                    "label": "B",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "C",
                    "text": "Agosto 23, 1896"
                },
                {
                    "label": "D",
                    "text": "Mayo 1, 1935"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Binaril si Jose Rizal sa Bagumbayan (ngayon ay Rizal Park) noong Disyembre 30, 1896."
        },
        {
            "id": "spa_8_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong titulo ang ginamit ni Andres Bonifacio bilang pinuno ng Katipunan?",
            "options": [
                {
                    "label": "A",
                    "text": "Supremo"
                },
                {
                    "label": "B",
                    "text": "Pangulo"
                },
                {
                    "label": "C",
                    "text": "Datu"
                },
                {
                    "label": "D",
                    "text": "Gobernador Heneral"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kilala si Andres Bonifacio bilang \"Supremo\" o pinakamataas na pinuno ng Katipunan."
        },
        {
            "id": "spa_8_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sinong pinuno ng pangkat Magdalo sa Cavite ang naging kalaban sa pamumuno ni Bonifacio?",
            "options": [
                {
                    "label": "A",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "B",
                    "text": "Apolinario Mabini"
                },
                {
                    "label": "C",
                    "text": "Marcelo H. del Pilar"
                },
                {
                    "label": "D",
                    "text": "Antonio Luna"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Emilio Aguinaldo ang pinuno ng pangkat Magdalo sa Cavite na kalaunan ay naging pangulo ng unang republika."
        }
    ],
    "9": [
        {
            "id": "spa_9_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan at kailan ipinahayag ni Emilio Aguinaldo ang kalayaan ng Pilipinas mula sa Espanya?",
            "options": [
                {
                    "label": "A",
                    "text": "Kawit, Cavite noong Hunyo 12, 1898"
                },
                {
                    "label": "B",
                    "text": "Maynila noong 1896"
                },
                {
                    "label": "C",
                    "text": "Bohol noong 1565"
                },
                {
                    "label": "D",
                    "text": "Bagumbayan noong 1896"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Kawit, Cavite, ipinahayag ni Emilio Aguinaldo ang kalayaan ng Pilipinas mula sa Espanya noong Hunyo 12, 1898."
        },
        {
            "id": "spa_9_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang kasunduang nagpapahinto pansamantala sa labanan sa pagitan ng Katipunan at gobyernong Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Kasunduan sa Biak-na-Bato"
                },
                {
                    "label": "B",
                    "text": "Kasunduan sa Paris"
                },
                {
                    "label": "C",
                    "text": "Batas Tydings-McDuffie"
                },
                {
                    "label": "D",
                    "text": "Kasunduang Bates"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kasunduan sa Biak-na-Bato (1897) ay pansamantalang katigilan sa labanan sa pagitan ng mga Pilipino at Kastila."
        },
        {
            "id": "spa_9_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong labanang pandagat ang nagpapahina sa kapangyarihan ng Espanya sa Pilipinas at nagpapasok sa Amerika?",
            "options": [
                {
                    "label": "A",
                    "text": "Labanan sa Manila Bay"
                },
                {
                    "label": "B",
                    "text": "Labanan sa Mactan"
                },
                {
                    "label": "C",
                    "text": "Labanan sa Tirad Pass"
                },
                {
                    "label": "D",
                    "text": "Labanan sa Pearl Harbor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Labanan sa Manila Bay noong 1898, tinalo ng Estados Unidos ang armada ng Espanya, na nagpapahina sa kontrol nito sa Pilipinas."
        },
        {
            "id": "spa_9_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang legacy na iniwan ng mga Kastila sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Katolisismo, maraming salitang Espanyol, at mga pangalang Kastila"
                },
                {
                    "label": "B",
                    "text": "Wikang Ingles bilang opisyal na wika"
                },
                {
                    "label": "C",
                    "text": "Sistemang demokrasya"
                },
                {
                    "label": "D",
                    "text": "Pederalismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Katolisismo, maraming salitang Espanyol sa Filipino, at mga apelyidong Kastila ay ilan sa mga pinakamalaking naiwang impluwensya ng 333 taong kolonisasyon."
        },
        {
            "id": "spa_9_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit itinuturing na mahalagang yugto ang panahon ng Espanyol sa kasaysayan ng pambansang pagkakakilanlan ng mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Dito unang nabuo ang diwa ng pagkakaisa at pambansang pagkakakilanlan laban sa mananakop"
                },
                {
                    "label": "B",
                    "text": "Walang pagbabagong naganap"
                },
                {
                    "label": "C",
                    "text": "Nawala ang lahat ng kultura ng Pilipino"
                },
                {
                    "label": "D",
                    "text": "Naging bahagi agad ang Pilipinas ng Amerika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa panahon ng Espanyol nabuo ang diwa ng nasyonalismo at pambansang pagkakaisa na naging saligan ng Rebolusyong Pilipino."
        }
    ],
    "10": [
        {
            "id": "spa_10_1",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saang lugar itinatag ni Legazpi ang unang pamayanang Kastila noong 1565?",
            "options": [
                {
                    "label": "A",
                    "text": "Cebu"
                },
                {
                    "label": "B",
                    "text": "Maynila"
                },
                {
                    "label": "C",
                    "text": "Bohol"
                },
                {
                    "label": "D",
                    "text": "Iloilo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtatag si Legazpi ng unang permanenteng pamayanang Kastila sa Cebu noong 1565."
        },
        {
            "id": "spa_10_2",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinakamataas na opisyal ng pamahalaang Espanyol sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Gobernador Heneral"
                },
                {
                    "label": "B",
                    "text": "Datu"
                },
                {
                    "label": "C",
                    "text": "Cabeza de Barangay"
                },
                {
                    "label": "D",
                    "text": "Alkalde"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Gobernador Heneral ang kinatawan ng Hari ng Espanya sa kolonya."
        },
        {
            "id": "spa_10_3",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sapilitang paggawa na iniatas ng mga Kastila sa mga katutubo?",
            "options": [
                {
                    "label": "A",
                    "text": "Polo y servicio"
                },
                {
                    "label": "B",
                    "text": "Bandala"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Tributo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang polo y servicio ay sapilitang paggawa na iniatas sa mga lalaking Pilipino."
        },
        {
            "id": "spa_10_4",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong relihiyon ang ipinakilala at pinalaganap ng mga Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Katolisismo"
                },
                {
                    "label": "B",
                    "text": "Islam"
                },
                {
                    "label": "C",
                    "text": "Budismo"
                },
                {
                    "label": "D",
                    "text": "Hinduismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinalaganap ng mga misyonerong Kastila ang relihiyong Katoliko."
        },
        {
            "id": "spa_10_5",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kalakalan sa pagitan ng Maynila at Acapulco?",
            "options": [
                {
                    "label": "A",
                    "text": "Galleon Trade"
                },
                {
                    "label": "B",
                    "text": "Barter System"
                },
                {
                    "label": "C",
                    "text": "Bandala"
                },
                {
                    "label": "D",
                    "text": "Encomienda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Galleon Trade ay ang kalakalan sa pagitan ng Maynila at Acapulco, Mexico."
        },
        {
            "id": "spa_10_6",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang pinuno ng pinakamatagal na rebelyon laban sa mga Kastila sa Bohol?",
            "options": [
                {
                    "label": "A",
                    "text": "Francisco Dagohoy"
                },
                {
                    "label": "B",
                    "text": "Diego Silang"
                },
                {
                    "label": "C",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "D",
                    "text": "Sumoroy"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Pinamunuan ni Francisco Dagohoy ang isang matagal na rebelyon sa Bohol."
        },
        {
            "id": "spa_10_7",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa kilusan ng mga ilustradong naglalayong isulong ang reporma?",
            "options": [
                {
                    "label": "A",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "B",
                    "text": "Katipunan"
                },
                {
                    "label": "C",
                    "text": "Batas Militar"
                },
                {
                    "label": "D",
                    "text": "Reduccion"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kilusang Propaganda ay naglalayong isulong ang reporma sa pamamagitan ng panitikan at pahayagan."
        },
        {
            "id": "spa_10_8",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang sumulat ng Noli Me Tangere at El Filibusterismo?",
            "options": [
                {
                    "label": "A",
                    "text": "Jose Rizal"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Marcelo H. del Pilar"
                },
                {
                    "label": "D",
                    "text": "Emilio Aguinaldo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinulat ni Jose Rizal ang dalawang nobelang naglantad ng kalupitan ng sistemang kolonyal."
        },
        {
            "id": "spa_10_9",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang nagtatag ng Katipunan noong 1892?",
            "options": [
                {
                    "label": "A",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "B",
                    "text": "Jose Rizal"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Marcelo H. del Pilar"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Itinatag ni Andres Bonifacio ang Katipunan noong 1892."
        },
        {
            "id": "spa_10_10",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan binaril si Jose Rizal sa Bagumbayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Disyembre 30, 1896"
                },
                {
                    "label": "B",
                    "text": "Hunyo 12, 1898"
                },
                {
                    "label": "C",
                    "text": "Agosto 23, 1896"
                },
                {
                    "label": "D",
                    "text": "Mayo 1, 1935"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Binaril si Jose Rizal noong Disyembre 30, 1896."
        },
        {
            "id": "spa_10_11",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong taon nasakop ng mga Kastila ang Maynila?",
            "options": [
                {
                    "label": "A",
                    "text": "1571"
                },
                {
                    "label": "B",
                    "text": "1521"
                },
                {
                    "label": "C",
                    "text": "1898"
                },
                {
                    "label": "D",
                    "text": "1896"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nasakop ng mga Kastila ang Maynila noong 1571."
        },
        {
            "id": "spa_10_12",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa sapilitang pagbebenta ng ani sa gobyerno sa mababang presyo?",
            "options": [
                {
                    "label": "A",
                    "text": "Bandala"
                },
                {
                    "label": "B",
                    "text": "Polo y servicio"
                },
                {
                    "label": "C",
                    "text": "Tributo"
                },
                {
                    "label": "D",
                    "text": "Encomienda"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang bandala ay sapilitang pagbebenta ng ani sa gobyerno sa halagang mas mababa sa nararapat."
        },
        {
            "id": "spa_10_13",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagtitipon ng mga katutubo malapit sa simbahan?",
            "options": [
                {
                    "label": "A",
                    "text": "Reduccion"
                },
                {
                    "label": "B",
                    "text": "Bandala"
                },
                {
                    "label": "C",
                    "text": "Encomienda"
                },
                {
                    "label": "D",
                    "text": "Tributo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa reduccion, pinagsama-sama ang mga katutubo malapit sa simbahan para mas madaling kontrolin."
        },
        {
            "id": "spa_10_14",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pananim ang naging monopolyo ng gobyernong Kastila?",
            "options": [
                {
                    "label": "A",
                    "text": "Tabako"
                },
                {
                    "label": "B",
                    "text": "Palay"
                },
                {
                    "label": "C",
                    "text": "Mais"
                },
                {
                    "label": "D",
                    "text": "Kamote"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang Tobacco Monopoly sa mga magsasaka."
        },
        {
            "id": "spa_10_15",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sinong mag-asawa ang namuno sa rebelyon sa Ilocos?",
            "options": [
                {
                    "label": "A",
                    "text": "Diego at Gabriela Silang"
                },
                {
                    "label": "B",
                    "text": "Andres at Gregoria Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Emilio at Hilaria Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Francisco at Maria Dagohoy"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sina Diego at Gabriela Silang ang namuno sa rebelyon sa Ilocos."
        },
        {
            "id": "spa_10_16",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang unti-unting nangyari sa paggamit ng baybayin noong panahon ng Espanyol?",
            "options": [
                {
                    "label": "A",
                    "text": "Unti-unti itong napalitan ng alpabetong Romano"
                },
                {
                    "label": "B",
                    "text": "Lalo itong kumalat"
                },
                {
                    "label": "C",
                    "text": "Naging opisyal na wika ito"
                },
                {
                    "label": "D",
                    "text": "Walang nagbago rito"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Unti-unting napalitan ang baybayin ng alpabetong Romano."
        },
        {
            "id": "spa_10_17",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang tagapagtatag ng La Solidaridad?",
            "options": [
                {
                    "label": "A",
                    "text": "Marcelo H. del Pilar"
                },
                {
                    "label": "B",
                    "text": "Andres Bonifacio"
                },
                {
                    "label": "C",
                    "text": "Emilio Aguinaldo"
                },
                {
                    "label": "D",
                    "text": "Apolinario Mabini"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Marcelo H. del Pilar ang naging patnugot ng La Solidaridad."
        },
        {
            "id": "spa_10_18",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagpunit ng mga sedula na simbolo ng simula ng Rebolusyon?",
            "options": [
                {
                    "label": "A",
                    "text": "Sigaw ng Pugad Lawin"
                },
                {
                    "label": "B",
                    "text": "Kasunduan sa Biak-na-Bato"
                },
                {
                    "label": "C",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "D",
                    "text": "Kasunduan sa Paris"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Sigaw ng Pugad Lawin, pinunit ng mga Katipunero ang kanilang mga sedula."
        },
        {
            "id": "spa_10_19",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan at kailan ipinahayag ni Aguinaldo ang kalayaan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kawit, Cavite noong Hunyo 12, 1898"
                },
                {
                    "label": "B",
                    "text": "Maynila noong 1896"
                },
                {
                    "label": "C",
                    "text": "Bohol noong 1565"
                },
                {
                    "label": "D",
                    "text": "Bagumbayan noong 1896"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Kawit, Cavite, ipinahayag ang kalayaan noong Hunyo 12, 1898."
        },
        {
            "id": "spa_10_20",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong labanang pandagat ang nagpapahina sa kapangyarihan ng Espanya sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Labanan sa Manila Bay"
                },
                {
                    "label": "B",
                    "text": "Labanan sa Mactan"
                },
                {
                    "label": "C",
                    "text": "Labanan sa Tirad Pass"
                },
                {
                    "label": "D",
                    "text": "Labanan sa Pearl Harbor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sa Labanan sa Manila Bay, tinalo ng Estados Unidos ang armada ng Espanya."
        },
        {
            "id": "spa_10_21",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong titulo ang ginamit ni Andres Bonifacio bilang pinuno ng Katipunan?",
            "options": [
                {
                    "label": "A",
                    "text": "Supremo"
                },
                {
                    "label": "B",
                    "text": "Pangulo"
                },
                {
                    "label": "C",
                    "text": "Datu"
                },
                {
                    "label": "D",
                    "text": "Gobernador Heneral"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kilala si Bonifacio bilang \"Supremo\" ng Katipunan."
        },
        {
            "id": "spa_10_22",
            "era": "spanish",
            "subTopic": "",
            "gradeLevel": "grade5",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang legacy na iniwan ng mga Kastila sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Katolisismo, maraming salitang Espanyol, at mga pangalang Kastila"
                },
                {
                    "label": "B",
                    "text": "Wikang Ingles bilang opisyal na wika"
                },
                {
                    "label": "C",
                    "text": "Sistemang demokrasya"
                },
                {
                    "label": "D",
                    "text": "Pederalismo"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Katolisismo, maraming salitang Espanyol, at mga apelyidong Kastila ay ilan sa naiwang impluwensya."
        }
    ]
}
```

## File: assets/data/questions_ww2.json
```json
{
    "1": [
        {
            "id": "ww2_1_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangyayari sa Pearl Harbor noong Disyembre 1941 ang nagbunsod sa Estados Unidos na sumali sa Ikalawang Digmaang Pandaigdig?",
            "options": [
                {
                    "label": "A",
                    "text": "Sinalakay ng Hapon ang Pearl Harbor"
                },
                {
                    "label": "B",
                    "text": "Sinalakay ng Alemanya ang Pearl Harbor"
                },
                {
                    "label": "C",
                    "text": "Nagdeklara ng digmaan ang Espanya"
                },
                {
                    "label": "D",
                    "text": "Sumuko ang Estados Unidos"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang biglaang pananalakay ng Hapon sa Pearl Harbor noong Disyembre 7, 1941 ang nagtulak sa Estados Unidos na sumali sa digmaan, kasabay ng pagsalakay sa Pilipinas."
        },
        {
            "id": "ww2_1_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan unang lumapag ang malaking hukbong Hapon sa Luzon noong 1941?",
            "options": [
                {
                    "label": "A",
                    "text": "Lingayen Gulf"
                },
                {
                    "label": "B",
                    "text": "Manila Bay"
                },
                {
                    "label": "C",
                    "text": "Leyte Gulf"
                },
                {
                    "label": "D",
                    "text": "Subic Bay"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Lumapag ang malaking bahagi ng hukbong Hapon sa Lingayen Gulf noong Disyembre 1941 bago sumulong patungong Maynila."
        },
        {
            "id": "ww2_1_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang ginawa ni Heneral Douglas MacArthur sa Maynila upang maiwasan ang labis na pagkasira nito?",
            "options": [
                {
                    "label": "A",
                    "text": "Idineklara ang Maynila bilang \"Open City\""
                },
                {
                    "label": "B",
                    "text": "Sinunog ang buong lungsod"
                },
                {
                    "label": "C",
                    "text": "Ipinagtanggol ang Maynila hanggang sa huli"
                },
                {
                    "label": "D",
                    "text": "Umatras patungong Australia agad"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Idineklara ni MacArthur ang Maynila bilang \"Open City\" upang maiwasan ang pagkasira nito, bagamat sinakop pa rin ito ng Hapon."
        },
        {
            "id": "ww2_1_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan bumagsak ang Bataan sa mga puwersang Hapon, na kilala bilang Araw ng Kagitingan?",
            "options": [
                {
                    "label": "A",
                    "text": "Abril 9, 1942"
                },
                {
                    "label": "B",
                    "text": "Disyembre 7, 1941"
                },
                {
                    "label": "C",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "D",
                    "text": "Oktubre 20, 1944"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumagsak ang Bataan noong Abril 9, 1942, taunang ginugunita bilang Araw ng Kagitingan sa Pilipinas."
        },
        {
            "id": "ww2_1_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 1,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mahabang at mapanganib na paglalakad ng mga bihag na sundalong Pilipino at Amerikano matapos bumagsak ang Bataan?",
            "options": [
                {
                    "label": "A",
                    "text": "Bataan Death March"
                },
                {
                    "label": "B",
                    "text": "Long Walk to Freedom"
                },
                {
                    "label": "C",
                    "text": "March to Corregidor"
                },
                {
                    "label": "D",
                    "text": "Trail of Tears"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Bataan Death March ay ang mahirap at mapanganib na paglalakad ng libu-libong bihag mula Bataan patungo sa mga kampo ng Hapon."
        }
    ],
    "2": [
        {
            "id": "ww2_2_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong isla-tanggulan ang huling bumagsak sa Hapon noong Mayo 1942?",
            "options": [
                {
                    "label": "A",
                    "text": "Corregidor"
                },
                {
                    "label": "B",
                    "text": "Leyte"
                },
                {
                    "label": "C",
                    "text": "Mindanao"
                },
                {
                    "label": "D",
                    "text": "Palawan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumagsak ang Corregidor sa Hapon noong Mayo 1942, kasunod ng pagbagsak ng Bataan."
        },
        {
            "id": "ww2_2_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangakong sinabi ni Heneral MacArthur nang umatras siya papuntang Australia noong 1942?",
            "options": [
                {
                    "label": "A",
                    "text": "\"I shall return\""
                },
                {
                    "label": "B",
                    "text": "\"Give me liberty or give me death\""
                },
                {
                    "label": "C",
                    "text": "\"We shall never surrender\""
                },
                {
                    "label": "D",
                    "text": "\"Remember Pearl Harbor\""
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kilalang sinabi ni Heneral MacArthur ang \"I shall return\" bilang pangako na babalik siya upang palayain ang Pilipinas."
        },
        {
            "id": "ww2_2_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging Pangulo ng pamahalaang itinatag ng Hapon (Second Republic) sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Jose P. Laurel"
                },
                {
                    "label": "B",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "C",
                    "text": "Sergio Osmena"
                },
                {
                    "label": "D",
                    "text": "Manuel Roxas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Jose P. Laurel ang naging Pangulo ng Second Republic, ang pamahalaang itinatag ng Hapon sa Pilipinas noong panahon ng Okupasyon."
        },
        {
            "id": "ww2_2_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa organisasyong itinatag ng Hapon upang isulong ang kanilang layunin sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kalibapi"
                },
                {
                    "label": "B",
                    "text": "Katipunan"
                },
                {
                    "label": "C",
                    "text": "Hukbalahap"
                },
                {
                    "label": "D",
                    "text": "Nacionalista Party"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kalibapi (Kapisanan sa Paglilingkod sa Bagong Pilipinas) ang naging opisyal na organisasyong pampulitika sa ilalim ng pamahalaang Hapon."
        },
        {
            "id": "ww2_2_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 2,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang katangian ng pamahalaang itinatag ng Hapon sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Puppet government o pamahalaang kontrolado ng Hapon"
                },
                {
                    "label": "B",
                    "text": "Ganap na malayang pamahalaan"
                },
                {
                    "label": "C",
                    "text": "Pamahalaang kolonyal ng Espanya"
                },
                {
                    "label": "D",
                    "text": "Walang pamahalaan noong panahong iyon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pamahalaan sa ilalim ni Laurel ay kilala bilang \"puppet government\" dahil kontrolado at ginagabayan ito ng Hapon."
        }
    ],
    "3": [
        {
            "id": "ww2_3_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong hirap ang karaniwang naranasan ng mga Pilipino sa larangan ng pagkain noong Okupasyong Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Matinding kakulangan sa bigas at pagkain"
                },
                {
                    "label": "B",
                    "text": "Sobrang dami ng pagkain"
                },
                {
                    "label": "C",
                    "text": "Walang naranasang paghihirap"
                },
                {
                    "label": "D",
                    "text": "Libreng pagkain sa lahat"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nakaranas ng matinding kakulangan sa pagkain, lalo na bigas, ang mga Pilipino sa panahon ng Okupasyong Hapon."
        },
        {
            "id": "ww2_3_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tinawag na palayaw sa salaping inilabas ng gobyernong Hapon dahil sa mababang halaga nito?",
            "options": [
                {
                    "label": "A",
                    "text": "Mickey Mouse money"
                },
                {
                    "label": "B",
                    "text": "Piloncitos"
                },
                {
                    "label": "C",
                    "text": "Peso Fuerte"
                },
                {
                    "label": "D",
                    "text": "Real de a ocho"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Tinawag na \"Mickey Mouse money\" ang salaping inilabas ng gobyernong Hapon dahil bumagsak ang halaga nito noong panahon ng digmaan."
        },
        {
            "id": "ww2_3_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang ipinatupad na oras kung kailan bawal lumabas ng bahay sa panahon ng Okupasyong Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Curfew"
                },
                {
                    "label": "B",
                    "text": "Fiesta"
                },
                {
                    "label": "C",
                    "text": "Siesta"
                },
                {
                    "label": "D",
                    "text": "Recess"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinatupad ang curfew, isang takdang oras kung saan bawal lumabas ang mga tao, bilang bahagi ng kontrol ng Hapon."
        },
        {
            "id": "ww2_3_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa hukbong pangkapulisan ng Hapon na kilala sa kanilang mahigpit na pagpapatupad ng batas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kempeitai"
                },
                {
                    "label": "B",
                    "text": "Kalibapi"
                },
                {
                    "label": "C",
                    "text": "Hukbalahap"
                },
                {
                    "label": "D",
                    "text": "USAFFE"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kempeitai ang hukbong pangkapulisan ng militar ng Hapon na kilala sa kanilang mahigpit na disiplina at pagpapatupad ng batas."
        },
        {
            "id": "ww2_3_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 3,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalagang malaman ang mga karanasan ng mga Pilipino noong Okupasyong Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang maunawaan ang kahalagahan ng kapayapaan at karapatang pantao"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan sa kasalukuyan"
                },
                {
                    "label": "C",
                    "text": "Para lang malaman ang mga pangalan ng heneral"
                },
                {
                    "label": "D",
                    "text": "Walang dapat matutunan dito"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pag-aaral ng mga karanasan noong digmaan ay nagpapaalala sa kahalagahan ng kapayapaan, karapatang pantao, at pagkakaisa."
        }
    ],
    "4": [
        {
            "id": "ww2_4_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa hukbong gerilyang itinatag upang lumaban sa mga Hapon, lalo na sa Gitnang Luzon?",
            "options": [
                {
                    "label": "A",
                    "text": "Hukbalahap"
                },
                {
                    "label": "B",
                    "text": "Katipunan"
                },
                {
                    "label": "C",
                    "text": "Kalibapi"
                },
                {
                    "label": "D",
                    "text": "Kempeitai"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Hukbalahap (Hukbong Bayan Laban sa Hapon) ay isang kilalang kilusang gerilya na lumaban sa mga Hapon, lalo na sa Gitnang Luzon."
        },
        {
            "id": "ww2_4_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa opisyal na hukbo ng Estados Unidos at Pilipinas noong panahon ng digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "USAFFE"
                },
                {
                    "label": "B",
                    "text": "Kalibapi"
                },
                {
                    "label": "C",
                    "text": "Kempeitai"
                },
                {
                    "label": "D",
                    "text": "Hukbalahap"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang USAFFE (United States Army Forces in the Far East) ang naging pinagsamang hukbo ng Estados Unidos at Pilipinas."
        },
        {
            "id": "ww2_4_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging mahalagang tungkulin ng mga gerilya sa buong digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagbibigay ng impormasyon (intelligence) sa mga Allied Forces"
                },
                {
                    "label": "B",
                    "text": "Pakikipagtulungan sa Hapon"
                },
                {
                    "label": "C",
                    "text": "Walang tungkuling ginampanan"
                },
                {
                    "label": "D",
                    "text": "Pagbebenta ng armas sa Hapon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagbigay ang mga gerilya ng mahalagang impormasyon sa mga Allied Forces tungkol sa mga galaw ng hukbong Hapon."
        },
        {
            "id": "ww2_4_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saang bahagi ng Pilipinas nagkaroon din ng malalakas na kilusang gerilya bukod sa Luzon?",
            "options": [
                {
                    "label": "A",
                    "text": "Visayas at Mindanao"
                },
                {
                    "label": "B",
                    "text": "Wala sa ibang lugar"
                },
                {
                    "label": "C",
                    "text": "Espanya"
                },
                {
                    "label": "D",
                    "text": "Estados Unidos"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagkaroon din ng malalakas na kilusang gerilya sa Visayas at Mindanao, hindi lamang sa Luzon."
        },
        {
            "id": "ww2_4_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 4,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang isa sa mga kilalang lider ng kilusang Hukbalahap?",
            "options": [
                {
                    "label": "A",
                    "text": "Luis Taruc"
                },
                {
                    "label": "B",
                    "text": "Jose P. Laurel"
                },
                {
                    "label": "C",
                    "text": "Manuel Roxas"
                },
                {
                    "label": "D",
                    "text": "Douglas MacArthur"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Luis Taruc ay isa sa mga kilalang lider ng Hukbalahap sa panahon ng digmaan."
        }
    ],
    "5": [
        {
            "id": "ww2_5_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong labanang pandagat noong Oktubre 1944 ang itinuturing na pinakamalaking labanang pandagat sa kasaysayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Battle of Leyte Gulf"
                },
                {
                    "label": "B",
                    "text": "Battle of Manila Bay"
                },
                {
                    "label": "C",
                    "text": "Battle of Mactan"
                },
                {
                    "label": "D",
                    "text": "Battle of Corregidor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Battle of Leyte Gulf ay itinuturing na isa sa pinakamalaking labanang pandagat sa kasaysayan, na naganap noong Oktubre 1944."
        },
        {
            "id": "ww2_5_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan bumalik si Heneral MacArthur upang simulan ang paglaya ng Pilipinas noong 1944?",
            "options": [
                {
                    "label": "A",
                    "text": "Leyte"
                },
                {
                    "label": "B",
                    "text": "Bataan"
                },
                {
                    "label": "C",
                    "text": "Maynila"
                },
                {
                    "label": "D",
                    "text": "Corregidor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumalik si Heneral MacArthur sa Leyte noong Oktubre 1944 upang simulan ang paglaya ng Pilipinas mula sa Hapon."
        },
        {
            "id": "ww2_5_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan sinimulang palayain ang Maynila mula sa kontrol ng Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Pebrero 1945"
                },
                {
                    "label": "B",
                    "text": "Disyembre 1941"
                },
                {
                    "label": "C",
                    "text": "Oktubre 1944"
                },
                {
                    "label": "D",
                    "text": "Setyembre 1945"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap ang Labanan sa Maynila noong Pebrero 1945, kung saan nagsimulang mapalaya ang lungsod mula sa Hapon."
        },
        {
            "id": "ww2_5_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na taon saklaw ang panahon ng paglaya ng Pilipinas mula sa Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "1944-1945"
                },
                {
                    "label": "B",
                    "text": "1898-1902"
                },
                {
                    "label": "C",
                    "text": "1521-1565"
                },
                {
                    "label": "D",
                    "text": "1935-1941"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang panahon ng paglaya ng Pilipinas mula sa Hapon ay saklaw ng 1944-1945."
        },
        {
            "id": "ww2_5_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 5,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino-sino ang nagtulungan upang palayain ang Pilipinas mula sa Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Mga puwersang Pilipino, Amerikano, at gerilya"
                },
                {
                    "label": "B",
                    "text": "Mga puwersang Kastila lamang"
                },
                {
                    "label": "C",
                    "text": "Walang tumulong sa Pilipinas"
                },
                {
                    "label": "D",
                    "text": "Mga puwersang Hapon lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtulungan ang mga puwersang Pilipino, Amerikano, at gerilya sa pagpapalaya sa Pilipinas mula sa Hapon."
        }
    ],
    "6": [
        {
            "id": "ww2_6_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong lungsod ang isa sa pinakamalubhang nasira sa Labanan sa Maynila noong 1945?",
            "options": [
                {
                    "label": "A",
                    "text": "Maynila"
                },
                {
                    "label": "B",
                    "text": "Cebu"
                },
                {
                    "label": "C",
                    "text": "Davao"
                },
                {
                    "label": "D",
                    "text": "Baguio"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Labis na nasira ang Maynila sa Labanan sa Maynila noong 1945, isa sa pinakamalubhang labanan sa digmaan."
        },
        {
            "id": "ww2_6_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang epekto ng digmaan sa ekonomiya ng Pilipinas noong 1945?",
            "options": [
                {
                    "label": "A",
                    "text": "Labis na pagkasira ng imprastraktura at kabuhayan"
                },
                {
                    "label": "B",
                    "text": "Lumago ang ekonomiya"
                },
                {
                    "label": "C",
                    "text": "Walang naapektuhan"
                },
                {
                    "label": "D",
                    "text": "Bumuti kaagad"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Labis na naapektuhan ang ekonomiya ng Pilipinas dahil sa pagkasira ng mga imprastraktura at kabuhayan noong digmaan."
        },
        {
            "id": "ww2_6_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod ang naging epekto ng digmaan sa mga imprastraktura tulad ng tulay at gusali?",
            "options": [
                {
                    "label": "A",
                    "text": "Maraming nasira na kailangang muling itayo"
                },
                {
                    "label": "B",
                    "text": "Walang nasira"
                },
                {
                    "label": "C",
                    "text": "Naging mas malakas ang lahat"
                },
                {
                    "label": "D",
                    "text": "Wala itong naging epekto"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Maraming imprastraktura tulad ng tulay, gusali, at kalsada ang nasira noong digmaan at kailangang muling itayo."
        },
        {
            "id": "ww2_6_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa pagsisimula ng muling pagtatayo ng bansa matapos ang digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Rehabilitasyon"
                },
                {
                    "label": "B",
                    "text": "Reduccion"
                },
                {
                    "label": "C",
                    "text": "Kolonisasyon"
                },
                {
                    "label": "D",
                    "text": "Digmaan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang rehabilitasyon ay ang proseso ng muling pagtatayo ng bansa matapos ang pagkasira dulot ng digmaan."
        },
        {
            "id": "ww2_6_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 6,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalagang tandaan ang kabuuang epekto ng digmaan sa buhay ng mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Para maunawaan ang halaga ng kapayapaan at ang gastos ng digmaan"
                },
                {
                    "label": "B",
                    "text": "Wala itong halaga sa kasalukuyan"
                },
                {
                    "label": "C",
                    "text": "Para lang sa pagsusulit"
                },
                {
                    "label": "D",
                    "text": "Walang dapat pag-aralan dito"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pag-unawa sa epekto ng digmaan ay tumutulong sa mga mag-aaral na pahalagahan ang kapayapaan at ang gastos ng armadong labanan."
        }
    ],
    "7": [
        {
            "id": "ww2_7_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na sumuko ang Hapon upang tapusin ang Ikalawang Digmaang Pandaigdig?",
            "options": [
                {
                    "label": "A",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "B",
                    "text": "Disyembre 7, 1941"
                },
                {
                    "label": "C",
                    "text": "Abril 9, 1942"
                },
                {
                    "label": "D",
                    "text": "Oktubre 1944"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Opisyal na sumuko ang Hapon noong Setyembre 2, 1945, na tumapos sa Ikalawang Digmaang Pandaigdig."
        },
        {
            "id": "ww2_7_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Alin sa mga sumusunod na pangyayari ang nagtulak sa Hapon na sumuko noong 1945?",
            "options": [
                {
                    "label": "A",
                    "text": "Pagbagsak ng Hapon matapos ang malubhang pinsala sa kanilang bansa"
                },
                {
                    "label": "B",
                    "text": "Kusang-loob na pagsuko dahil sa pagod na lamang"
                },
                {
                    "label": "C",
                    "text": "Pananalakay ng Pilipinas sa Hapon"
                },
                {
                    "label": "D",
                    "text": "Kasunduan sa Espanya"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Sumuko ang Hapon noong 1945 matapos dumanas ng malubhang pinsala at pagkatalo sa iba't ibang larangan ng digmaan."
        },
        {
            "id": "ww2_7_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang isinagawa matapos ang digmaan upang panagutin ang mga responsable sa mga krimen sa digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "War Crimes Trials"
                },
                {
                    "label": "B",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "C",
                    "text": "Batas Sedition"
                },
                {
                    "label": "D",
                    "text": "Reduccion"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinagawa ang mga War Crimes Trials matapos ang digmaan upang panagutin ang mga heneral at opisyal na responsable sa mga krimen sa digmaan."
        },
        {
            "id": "ww2_7_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pamahalaan ang ibinalik matapos ang digmaan noong 1945?",
            "options": [
                {
                    "label": "A",
                    "text": "Commonwealth Government"
                },
                {
                    "label": "B",
                    "text": "Pamahalaang Espanyol"
                },
                {
                    "label": "C",
                    "text": "Pamahalaang Hapon"
                },
                {
                    "label": "D",
                    "text": "Unang Republika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ibinalik ang Commonwealth Government matapos ang digmaan bilang paghahanda muli tungo sa ganap na kalayaan."
        },
        {
            "id": "ww2_7_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 7,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging susunod na hakbang matapos ang digmaan patungo sa kalayaan ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Muling paghahanda para sa deklarasyon ng kalayaan noong 1946"
                },
                {
                    "label": "B",
                    "text": "Pagbabalik sa pamahalaang kolonyal ng Espanya"
                },
                {
                    "label": "C",
                    "text": "Pananatiling kolonya ng Hapon"
                },
                {
                    "label": "D",
                    "text": "Walang susunod na hakbang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Matapos ang digmaan, muling naghanda ang Pilipinas para sa ipinangakong kalayaan noong 1946."
        }
    ],
    "8": [
        {
            "id": "ww2_8_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano ipinakita ng mga gerilyang Pilipino ang kanilang kabayanihan noong digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng patuloy na paglaban at pagtulong sa mga Allied Forces"
                },
                {
                    "label": "B",
                    "text": "Sa pagsuko sa Hapon"
                },
                {
                    "label": "C",
                    "text": "Sa pananahimik lamang"
                },
                {
                    "label": "D",
                    "text": "Wala silang ginawang tulong"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinakita ng mga gerilyang Pilipino ang kanilang kabayanihan sa pamamagitan ng patuloy na paglaban laban sa Hapon at pagtulong sa mga Allied Forces."
        },
        {
            "id": "ww2_8_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong tungkulin ang ginampanan ng maraming babaeng Pilipino noong digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Nagsilbing nars at nagbigay ng tulong medikal sa mga sugatan"
                },
                {
                    "label": "B",
                    "text": "Wala silang ginampanang tungkulin"
                },
                {
                    "label": "C",
                    "text": "Nanatili lamang sa bahay"
                },
                {
                    "label": "D",
                    "text": "Sumali sa hukbong Hapon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Maraming babaeng Pilipino ang nagsilbing nars at tumulong sa pag-aalaga ng mga sugatang sundalo noong digmaan."
        },
        {
            "id": "ww2_8_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong katangian ang ipinakita ng mga nakaligtas sa Bataan Death March?",
            "options": [
                {
                    "label": "A",
                    "text": "Lakas ng loob at determinasyon na mabuhay"
                },
                {
                    "label": "B",
                    "text": "Kawalan ng pag-asa"
                },
                {
                    "label": "C",
                    "text": "Pagsuko sa lahat"
                },
                {
                    "label": "D",
                    "text": "Walang ipinakitang katangian"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinakita ng mga nakaligtas sa Bataan Death March ang matinding lakas ng loob at pagnanais na mabuhay sa kabila ng matinding hirap."
        },
        {
            "id": "ww2_8_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang taunang pagdiriwang bilang pag-alala sa kabayanihan ng mga sundalong Pilipino at Amerikano sa Bataan?",
            "options": [
                {
                    "label": "A",
                    "text": "Araw ng Kagitingan"
                },
                {
                    "label": "B",
                    "text": "Araw ng Kalayaan"
                },
                {
                    "label": "C",
                    "text": "Bonifacio Day"
                },
                {
                    "label": "D",
                    "text": "Rizal Day"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagdiriwang taun-taon ang Araw ng Kagitingan tuwing Abril 9 bilang pag-alala sa mga bayaning lumaban sa Bataan."
        },
        {
            "id": "ww2_8_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 8,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Bakit mahalagang gunitain ang kabayanihan ng mga Pilipino noong digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Upang alalahanin ang kanilang sakripisyo at pahalagahan ang kapayapaan"
                },
                {
                    "label": "B",
                    "text": "Wala itong kabuluhan"
                },
                {
                    "label": "C",
                    "text": "Para lang sa piyesta"
                },
                {
                    "label": "D",
                    "text": "Para ipagmalaki lamang"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pag-alala sa kabayanihan ng mga Pilipino ay nagpapaalala sa kahalagahan ng kanilang sakripisyo para sa kalayaan at kapayapaan."
        }
    ],
    "9": [
        {
            "id": "ww2_9_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano naipakita ang pagkakaisa ng mga Pilipino at Amerikano sa panahon ng digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng magkasamang paglaban laban sa karaniwang kaaway na Hapon"
                },
                {
                    "label": "B",
                    "text": "Hindi sila nagtulungan"
                },
                {
                    "label": "C",
                    "text": "Nagkalaban sila sa isa't isa"
                },
                {
                    "label": "D",
                    "text": "Walang naganap na pagtutulungan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtulungan ang mga Pilipino at Amerikano sa pagtatanggol laban sa Hapon, na nagpakita ng matibay na pagkakaisa sa panahon ng digmaan."
        },
        {
            "id": "ww2_9_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging tugon ng pamahalaan matapos ang digmaan para sa muling pagtatayo ng bansa?",
            "options": [
                {
                    "label": "A",
                    "text": "Programa ng rehabilitasyon at rekonstruksyon"
                },
                {
                    "label": "B",
                    "text": "Walang ginawang hakbang"
                },
                {
                    "label": "C",
                    "text": "Ipinagpatuloy ang digmaan"
                },
                {
                    "label": "D",
                    "text": "Bumalik sa pamumuno ng Hapon"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagsagawa ng mga programa ng rehabilitasyon at rekonstruksyon ang pamahalaan upang muling itayo ang bansa matapos ang digmaan."
        },
        {
            "id": "ww2_9_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano naiimpluwensyahan ng digmaan ang pambansang pagkakakilanlan ng mga Pilipino?",
            "options": [
                {
                    "label": "A",
                    "text": "Napatibay ang diwa ng pagkakaisa, tapang, at pagmamahal sa bayan"
                },
                {
                    "label": "B",
                    "text": "Nawala ang pagmamahal sa bayan"
                },
                {
                    "label": "C",
                    "text": "Walang naging epekto"
                },
                {
                    "label": "D",
                    "text": "Nawalan ng interes sa kasaysayan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Napatibay ang diwa ng nasyonalismo, tapang, at pagkakaisa ng mga Pilipino bunga ng kanilang karanasan noong digmaan."
        },
        {
            "id": "ww2_9_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong aral ang maaaring matutunan mula sa karanasan ng mga Pilipino noong Ikalawang Digmaang Pandaigdig?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang halaga ng kapayapaan, pagkakaisa, at karapatang pantao"
                },
                {
                    "label": "B",
                    "text": "Walang aral na matutunan"
                },
                {
                    "label": "C",
                    "text": "Mainam ang digmaan"
                },
                {
                    "label": "D",
                    "text": "Hindi kailangan ang kalayaan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang karanasan ng mga Pilipino noong digmaan ay nagtuturo ng halaga ng kapayapaan, pagkakaisa, at paggalang sa karapatang pantao."
        },
        {
            "id": "ww2_9_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 9,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging susunod na malaking pangyayari sa kasaysayan ng Pilipinas matapos ang digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang pagkamit ng ganap na kalayaan noong 1946"
                },
                {
                    "label": "B",
                    "text": "Bagong pananakop ng Hapon"
                },
                {
                    "label": "C",
                    "text": "Pagbabalik ng mga Kastila"
                },
                {
                    "label": "D",
                    "text": "Walang naganap pang pagbabago"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Matapos ang digmaan, ang susunod na malaking pangyayari ay ang pagkamit ng Pilipinas ng ganap na kalayaan noong 1946."
        }
    ],
    "10": [
        {
            "id": "ww2_10_1",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangyayari sa Pearl Harbor noong Disyembre 1941 ang nagbunsod sa Estados Unidos na sumali sa digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sinalakay ng Hapon ang Pearl Harbor"
                },
                {
                    "label": "B",
                    "text": "Sinalakay ng Alemanya ang Pearl Harbor"
                },
                {
                    "label": "C",
                    "text": "Nagdeklara ng digmaan ang Espanya"
                },
                {
                    "label": "D",
                    "text": "Sumuko ang Estados Unidos"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang pananalakay ng Hapon sa Pearl Harbor ang nagtulak sa Estados Unidos na sumali sa digmaan."
        },
        {
            "id": "ww2_10_2",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan bumagsak ang Bataan sa mga puwersang Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Abril 9, 1942"
                },
                {
                    "label": "B",
                    "text": "Disyembre 7, 1941"
                },
                {
                    "label": "C",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "D",
                    "text": "Oktubre 20, 1944"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumagsak ang Bataan noong Abril 9, 1942."
        },
        {
            "id": "ww2_10_3",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa mahabang at mapanganib na paglalakad ng mga bihag matapos bumagsak ang Bataan?",
            "options": [
                {
                    "label": "A",
                    "text": "Bataan Death March"
                },
                {
                    "label": "B",
                    "text": "Long Walk to Freedom"
                },
                {
                    "label": "C",
                    "text": "March to Corregidor"
                },
                {
                    "label": "D",
                    "text": "Trail of Tears"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Bataan Death March ang mahirap na paglalakad ng mga bihag matapos bumagsak ang Bataan."
        },
        {
            "id": "ww2_10_4",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang naging Pangulo ng pamahalaang itinatag ng Hapon sa Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Jose P. Laurel"
                },
                {
                    "label": "B",
                    "text": "Manuel Quezon"
                },
                {
                    "label": "C",
                    "text": "Sergio Osmena"
                },
                {
                    "label": "D",
                    "text": "Manuel Roxas"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Jose P. Laurel ang naging Pangulo ng Second Republic sa ilalim ng Hapon."
        },
        {
            "id": "ww2_10_5",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa hukbong gerilyang itinatag laban sa mga Hapon sa Gitnang Luzon?",
            "options": [
                {
                    "label": "A",
                    "text": "Hukbalahap"
                },
                {
                    "label": "B",
                    "text": "Katipunan"
                },
                {
                    "label": "C",
                    "text": "Kalibapi"
                },
                {
                    "label": "D",
                    "text": "Kempeitai"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Hukbalahap ang kilalang hukbong gerilya laban sa Hapon sa Gitnang Luzon."
        },
        {
            "id": "ww2_10_6",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong labanang pandagat noong Oktubre 1944 ang itinuturing na pinakamalaki sa kasaysayan?",
            "options": [
                {
                    "label": "A",
                    "text": "Battle of Leyte Gulf"
                },
                {
                    "label": "B",
                    "text": "Battle of Manila Bay"
                },
                {
                    "label": "C",
                    "text": "Battle of Mactan"
                },
                {
                    "label": "D",
                    "text": "Battle of Corregidor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Battle of Leyte Gulf ay itinuturing na pinakamalaking labanang pandagat sa kasaysayan."
        },
        {
            "id": "ww2_10_7",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan bumalik si Heneral MacArthur upang simulan ang paglaya ng Pilipinas?",
            "options": [
                {
                    "label": "A",
                    "text": "Leyte"
                },
                {
                    "label": "B",
                    "text": "Bataan"
                },
                {
                    "label": "C",
                    "text": "Maynila"
                },
                {
                    "label": "D",
                    "text": "Corregidor"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumalik si MacArthur sa Leyte noong 1944 upang simulan ang paglaya ng Pilipinas."
        },
        {
            "id": "ww2_10_8",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan opisyal na sumuko ang Hapon upang tapusin ang Ikalawang Digmaang Pandaigdig?",
            "options": [
                {
                    "label": "A",
                    "text": "Setyembre 2, 1945"
                },
                {
                    "label": "B",
                    "text": "Disyembre 7, 1941"
                },
                {
                    "label": "C",
                    "text": "Abril 9, 1942"
                },
                {
                    "label": "D",
                    "text": "Oktubre 1944"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Opisyal na sumuko ang Hapon noong Setyembre 2, 1945."
        },
        {
            "id": "ww2_10_9",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang taunang pagdiriwang bilang pag-alala sa kabayanihan sa Bataan?",
            "options": [
                {
                    "label": "A",
                    "text": "Araw ng Kagitingan"
                },
                {
                    "label": "B",
                    "text": "Araw ng Kalayaan"
                },
                {
                    "label": "C",
                    "text": "Bonifacio Day"
                },
                {
                    "label": "D",
                    "text": "Rizal Day"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ipinagdiriwang ang Araw ng Kagitingan tuwing Abril 9."
        },
        {
            "id": "ww2_10_10",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pangakong sinabi ni Heneral MacArthur nang umatras siya papuntang Australia?",
            "options": [
                {
                    "label": "A",
                    "text": "\"I shall return\""
                },
                {
                    "label": "B",
                    "text": "\"Give me liberty or give me death\""
                },
                {
                    "label": "C",
                    "text": "\"We shall never surrender\""
                },
                {
                    "label": "D",
                    "text": "\"Remember Pearl Harbor\""
                }
            ],
            "correctAnswer": "A",
            "explanation": "Kilalang sinabi ni MacArthur ang \"I shall return\"."
        },
        {
            "id": "ww2_10_11",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Saan unang lumapag ang malaking hukbong Hapon sa Luzon noong 1941?",
            "options": [
                {
                    "label": "A",
                    "text": "Lingayen Gulf"
                },
                {
                    "label": "B",
                    "text": "Manila Bay"
                },
                {
                    "label": "C",
                    "text": "Leyte Gulf"
                },
                {
                    "label": "D",
                    "text": "Subic Bay"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Lumapag ang malaking bahagi ng hukbong Hapon sa Lingayen Gulf noong 1941."
        },
        {
            "id": "ww2_10_12",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong isla-tanggulan ang huling bumagsak sa Hapon noong Mayo 1942?",
            "options": [
                {
                    "label": "A",
                    "text": "Corregidor"
                },
                {
                    "label": "B",
                    "text": "Leyte"
                },
                {
                    "label": "C",
                    "text": "Mindanao"
                },
                {
                    "label": "D",
                    "text": "Palawan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Bumagsak ang Corregidor sa Hapon noong Mayo 1942."
        },
        {
            "id": "ww2_10_13",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tinawag na palayaw sa salaping inilabas ng gobyernong Hapon dahil sa mababang halaga nito?",
            "options": [
                {
                    "label": "A",
                    "text": "Mickey Mouse money"
                },
                {
                    "label": "B",
                    "text": "Piloncitos"
                },
                {
                    "label": "C",
                    "text": "Peso Fuerte"
                },
                {
                    "label": "D",
                    "text": "Real de a ocho"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Tinawag na \"Mickey Mouse money\" ang salaping inilabas ng gobyernong Hapon."
        },
        {
            "id": "ww2_10_14",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa hukbong pangkapulisan ng Hapon na kilala sa kanilang mahigpit na pagpapatupad ng batas?",
            "options": [
                {
                    "label": "A",
                    "text": "Kempeitai"
                },
                {
                    "label": "B",
                    "text": "Kalibapi"
                },
                {
                    "label": "C",
                    "text": "Hukbalahap"
                },
                {
                    "label": "D",
                    "text": "USAFFE"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang Kempeitai ang hukbong pangkapulisan ng militar ng Hapon."
        },
        {
            "id": "ww2_10_15",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang tawag sa opisyal na hukbo ng Estados Unidos at Pilipinas noong panahon ng digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "USAFFE"
                },
                {
                    "label": "B",
                    "text": "Kalibapi"
                },
                {
                    "label": "C",
                    "text": "Kempeitai"
                },
                {
                    "label": "D",
                    "text": "Hukbalahap"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang USAFFE ang naging pinagsamang hukbo ng Estados Unidos at Pilipinas."
        },
        {
            "id": "ww2_10_16",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Sino ang isa sa mga kilalang lider ng kilusang Hukbalahap?",
            "options": [
                {
                    "label": "A",
                    "text": "Luis Taruc"
                },
                {
                    "label": "B",
                    "text": "Jose P. Laurel"
                },
                {
                    "label": "C",
                    "text": "Manuel Roxas"
                },
                {
                    "label": "D",
                    "text": "Douglas MacArthur"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Si Luis Taruc ay isa sa mga kilalang lider ng Hukbalahap."
        },
        {
            "id": "ww2_10_17",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Kailan sinimulang palayain ang Maynila mula sa kontrol ng Hapon?",
            "options": [
                {
                    "label": "A",
                    "text": "Pebrero 1945"
                },
                {
                    "label": "B",
                    "text": "Disyembre 1941"
                },
                {
                    "label": "C",
                    "text": "Oktubre 1944"
                },
                {
                    "label": "D",
                    "text": "Setyembre 1945"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Naganap ang Labanan sa Maynila noong Pebrero 1945."
        },
        {
            "id": "ww2_10_18",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang isinagawa matapos ang digmaan upang panagutin ang mga responsable sa mga krimen sa digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "War Crimes Trials"
                },
                {
                    "label": "B",
                    "text": "Kilusang Propaganda"
                },
                {
                    "label": "C",
                    "text": "Batas Sedition"
                },
                {
                    "label": "D",
                    "text": "Reduccion"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Isinagawa ang War Crimes Trials matapos ang digmaan."
        },
        {
            "id": "ww2_10_19",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong pamahalaan ang ibinalik matapos ang digmaan noong 1945?",
            "options": [
                {
                    "label": "A",
                    "text": "Commonwealth Government"
                },
                {
                    "label": "B",
                    "text": "Pamahalaang Espanyol"
                },
                {
                    "label": "C",
                    "text": "Pamahalaang Hapon"
                },
                {
                    "label": "D",
                    "text": "Unang Republika"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ibinalik ang Commonwealth Government matapos ang digmaan."
        },
        {
            "id": "ww2_10_20",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Paano naipakita ang pagkakaisa ng mga Pilipino at Amerikano sa panahon ng digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Sa pamamagitan ng magkasamang paglaban laban sa karaniwang kaaway na Hapon"
                },
                {
                    "label": "B",
                    "text": "Hindi sila nagtulungan"
                },
                {
                    "label": "C",
                    "text": "Nagkalaban sila sa isa't isa"
                },
                {
                    "label": "D",
                    "text": "Walang naganap na pagtutulungan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtulungan ang mga Pilipino at Amerikano laban sa Hapon."
        },
        {
            "id": "ww2_10_21",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Anong aral ang maaaring matutunan mula sa karanasan ng mga Pilipino noong Ikalawang Digmaang Pandaigdig?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang halaga ng kapayapaan, pagkakaisa, at karapatang pantao"
                },
                {
                    "label": "B",
                    "text": "Walang aral na matutunan"
                },
                {
                    "label": "C",
                    "text": "Mainam ang digmaan"
                },
                {
                    "label": "D",
                    "text": "Hindi kailangan ang kalayaan"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Nagtuturo ang karanasan sa digmaan ng halaga ng kapayapaan at karapatang pantao."
        },
        {
            "id": "ww2_10_22",
            "era": "ww2",
            "subTopic": "",
            "gradeLevel": "grade6",
            "level": 10,
            "difficulty": "medium",
            "questionType": "multiple_choice",
            "questionText": "Ano ang naging susunod na malaking pangyayari sa kasaysayan ng Pilipinas matapos ang digmaan?",
            "options": [
                {
                    "label": "A",
                    "text": "Ang pagkamit ng ganap na kalayaan noong 1946"
                },
                {
                    "label": "B",
                    "text": "Bagong pananakop ng Hapon"
                },
                {
                    "label": "C",
                    "text": "Pagbabalik ng mga Kastila"
                },
                {
                    "label": "D",
                    "text": "Walang naganap pang pagbabago"
                }
            ],
            "correctAnswer": "A",
            "explanation": "Ang susunod na malaking pangyayari ay ang pagkamit ng kalayaan noong 1946."
        }
    ]
}
```

## File: lib/core/dio_client.dart
```dart
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'constants.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await StorageService.clearToken();
            // The router redirect will handle navigation to login
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Reset the Dio instance (useful after logout)
  static void reset() {
    _instance = null;
  }
}
```

## File: lib/game/components/ground_component.dart
```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

/// Flat ground component — single rectangle at the bottom of the screen.
/// Used as the base ground. Gaps are handled by GroundSection segments.
class GroundComponent extends PositionComponent with HasGameReference<ChronoGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(game.size.x, 60);
    position = Vector2(0, game.size.y - 60);
    // No hitbox here — ground sections handle collision
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _groundColorForEra(game.currentEra);
    canvas.drawRect(size.toRect(), paint);
  }

  Color _groundColorForEra(String era) {
    const colors = {
      'pre-colonial': Color(0xFF5D4E37),
      'spanish': Color(0xFF808080),
      'american': Color(0xFF8B6914),
      'ww2': Color(0xFF4A4A3A),
      'modern': Color(0xFF555555),
    };
    return colors[era] ?? const Color(0xFF5D4E37);
  }

  void updateSize() {
    size = Vector2(game.size.x, 60);
  }
}
```

## File: lib/models/quiz_result.dart
```dart
class QuestionSnapshot {
  final String questionId;
  final String studentAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int timeTaken;

  const QuestionSnapshot({
    required this.questionId,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeTaken,
  });

  factory QuestionSnapshot.fromJson(Map<String, dynamic> json) {
    return QuestionSnapshot(
      questionId: json['questionId'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeTaken: json['timeTaken'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'studentAnswer': studentAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'timeTaken': timeTaken,
      };
}

class QuizResult {
  final String? id;
  final String era;
  final int level;
  final String type; // cold_pre_test | pre_test | post_test
  final int correctAnswersCount;
  final int totalQuestions;
  final int percentage;
  final int timeTakenTotal;
  final List<QuestionSnapshot> questionSnapshots;
  final String? testDate;

  const QuizResult({
    this.id,
    required this.era,
    required this.level,
    required this.type,
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTakenTotal,
    required this.questionSnapshots,
    this.testDate,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['_id'] as String? ?? json['id'] as String?,
      era: json['era'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      type: json['type'] as String? ?? 'pre_test',
      correctAnswersCount: json['correctAnswersCount'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
      timeTakenTotal: json['timeTakenTotal'] as int? ?? 0,
      questionSnapshots: (json['questionSnapshots'] as List<dynamic>?)
              ?.map(
                  (s) => QuestionSnapshot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      testDate: json['testDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'era': era,
        'level': level,
        'type': type,
        'correctAnswersCount': correctAnswersCount,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'timeTakenTotal': timeTakenTotal,
        'questionSnapshots':
            questionSnapshots.map((s) => s.toJson()).toList(),
      };
}
```

## File: lib/providers/progress_provider.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/era_progress.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProgressState {
  final Map<String, EraProgress> eraProgress;
  final bool isLoading;
  final String? error;

  const ProgressState({
    this.eraProgress = const {},
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    Map<String, EraProgress>? eraProgress,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      eraProgress: eraProgress ?? this.eraProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier() : super(const ProgressState());

  final _api = ApiService();

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final progress = await _api.getEraProgress();
      state = ProgressState(eraProgress: progress);
    } catch (e) {
      // Try loading from cache
      final Map<String, EraProgress> cached = {};
      for (final eraId
          in ['pre-colonial', 'spanish', 'american', 'ww2', 'modern']) {
        final data = StorageService.getCachedEraProgress(eraId);
        if (data != null) {
          cached[eraId] = EraProgress.fromJson(data);
        }
      }
      state = ProgressState(
        eraProgress: cached,
        error: cached.isEmpty ? e.toString() : null,
      );
    }
  }

  EraProgress getEraProgress(String eraId) {
    return state.eraProgress[eraId] ?? EraProgress(eraId: eraId);
  }

  bool isEraUnlocked(String eraId, List<String> visibleEraIds) {
    final index = visibleEraIds.indexOf(eraId);
    if (index <= 0) return true; // First era always unlocked
    final prevEraId = visibleEraIds[index - 1];
    final prevProgress = getEraProgress(prevEraId);
    return prevProgress.isCompleted;
  }

  void markLevelCompleted(String eraId, int level, int stars) {
    StorageService.saveLevelCompleted(eraId, level, stars);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>(
        (ref) => ProgressNotifier());
```

## File: lib/screens/game/background_history_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class BackgroundHistoryScreen extends StatefulWidget {
  final String eraId;
  const BackgroundHistoryScreen({super.key, required this.eraId});

  @override
  State<BackgroundHistoryScreen> createState() =>
      _BackgroundHistoryScreenState();
}

class _BackgroundHistoryScreenState extends State<BackgroundHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_hasReachedBottom) {
        setState(() => _hasReachedBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId).withValues(alpha: 0.9),
              _getEraColor(widget.eraId).withValues(alpha: 0.7),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Era title
                      Text(
                        era.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        era.subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Historical text
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          era.historicalText,
                          style: GoogleFonts.sourceSans3(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Key terms
                      Text(
                        'Mga Mahahalagang Termino',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getKeyTerms(widget.eraId)
                            .map((term) => _KeyTermChip(term: term))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Guide character
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.accent, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                era.guide[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  era.guide,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Iyong gabay sa panahong ito',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Bottom button
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _hasReachedBottom ? 1.0 : 0.3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasReachedBottom
                          ? () =>
                              context.go('/level-select/${widget.eraId}')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _hasReachedBottom
                            ? 'HANDA NA AKO!'
                            : '↓ Mag-scroll pababa para magpatuloy',
                        style: GoogleFonts.sourceSans3(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
        return const Color(0xFF4E342E);
      case 'american':
        return const Color(0xFF0D47A1);
      case 'ww2':
        return const Color(0xFF37474F);
      case 'modern':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF4E342E);
    }
  }

  List<Map<String, String>> _getKeyTerms(String eraId) {
    switch (eraId) {
      case 'pre-colonial':
        return [
          {'term': 'Barangay', 'def': 'Maliit na komunidad na pinamumunuan ng datu'},
          {'term': 'Baybayin', 'def': 'Sistema ng pagsulat ng sinaunang Pilipino'},
          {'term': 'Datu', 'def': 'Pinuno ng barangay'},
        ];
      case 'spanish':
        return [
          {'term': 'Encomienda', 'def': 'Sistema ng pagbibigay ng lupain sa mga Espanyol'},
          {'term': 'Katipunan', 'def': 'Lihim na samahan laban sa Espanya'},
          {'term': 'Himagsikan', 'def': 'Rebolusyon ng mga Pilipino'},
        ];
      case 'american':
        return [
          {'term': 'Thomasites', 'def': 'Mga gurong Amerikano na dumating sa Pilipinas'},
          {'term': 'Commonwealth', 'def': 'Pamahalaan bago ang ganap na kalayaan'},
          {'term': 'Malolos', 'def': 'Lugar kung saan itinatag ang unang republika'},
        ];
      case 'ww2':
        return [
          {'term': 'Bataan Death March', 'def': 'Malupit na martsa ng mga bihag ng Hapon'},
          {'term': 'Gerilya', 'def': 'Mga lihim na mandirigma laban sa Hapon'},
          {'term': 'Liberation', 'def': 'Pagpapalaya ng Pilipinas'},
        ];
      case 'modern':
        return [
          {'term': 'EDSA Revolution', 'def': 'People Power na nagpabagsak sa diktadura'},
          {'term': 'Martial Law', 'def': 'Batas militar na idineklara ni Marcos'},
          {'term': 'Demokrasya', 'def': 'Pamahalaan ng mamamayan'},
        ];
      default:
        return [];
    }
  }
}

class _KeyTermChip extends StatelessWidget {
  final Map<String, String> term;
  const _KeyTermChip({required this.term});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(term['term']!),
            content: Text(term['def']!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              term['term']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## File: lib/screens/game/game_screen.dart
```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/chrono_game.dart';
import '../../game/overlays/hud_overlay.dart';
import '../../game/overlays/question_overlay.dart';
import '../../game/overlays/pause_overlay.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String eraId;
  final int level;
  const GameScreen({super.key, required this.eraId, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ChronoGame game;

  @override
  void initState() {
    super.initState();
    final gameState = ref.read(gameProvider);

    game = ChronoGame()
      ..currentEra = widget.eraId
      ..currentLevel = widget.level
      ..selectedCharacterId = gameState.selectedCharacterId
      ..playerPowerUps = gameState.powerUps;

    // Set callbacks for navigation
    game.onLevelComplete = (score, correct, total, answers) {
      // Save level completion
      final percentage = total > 0 ? (correct / total * 100).round() : 0;
      final stars = percentage >= 90
          ? 3
          : percentage >= 70
              ? 2
              : 1;
      StorageService.saveLevelCompleted(widget.eraId, widget.level, stars);

      // Award powerup at milestones
      ref.read(gameProvider.notifier).awardPowerUp(widget.level);

      // Navigate
      if (widget.level == 10) {
        context.go('/era-complete/${widget.eraId}');
      } else {
        context.go('/level-complete/${widget.eraId}/${widget.level}');
      }
    };

    game.onLevelFailed = () {
      context.go('/level-failed/${widget.eraId}/${widget.level}');
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!game.questionShowing) {
            game.onPlayerJump();
          }
        },
        child: GameWidget(
          game: game,
          overlayBuilderMap: {
            'HudOverlay': (context, game) =>
                HudOverlayWidget(game: game as ChronoGame),
            'QuestionOverlay': (context, chronoGame) {
                final g = chronoGame as ChronoGame;
                return QuestionOverlayWidget(
                  game: g,
                  onAnswer: g.handleAnswer,
                );
              },
            'BossHealthOverlay': (context, game) =>
                BossHealthOverlayWidget(game: game as ChronoGame),
            'PauseOverlay': (context, game) =>
                PauseOverlayWidget(game: game as ChronoGame),
          },
          initialActiveOverlays: const ['HudOverlay'],
          loadingBuilder: (context) => Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
      ),
    );
  }
}
```

## File: lib/services/audio_service.dart
```dart
/// Stub audio service — plays no audio but provides the same API.
/// Replace with a real implementation (e.g. flame_audio) when audio assets
/// are ready and the audioplayers Kotlin compatibility issue is resolved.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
  }

  // ─── GAME SFX (stubs) ─────────────────────────────────────────────────────
  Future<void> playJump() async {}
  Future<void> playCorrect() async {}
  Future<void> playWrong() async {}
  Future<void> playCoin() async {}
  Future<void> playHurt() async {}
  Future<void> playEnemyDefeat() async {}
  Future<void> playPowerup() async {}
  Future<void> playLevelComplete() async {}
  Future<void> playLevelFailed() async {}
  Future<void> playBossAppear() async {}
  Future<void> playBossDefeat() async {}
  Future<void> playEraComplete() async {}

  // ─── BACKGROUND MUSIC (stub) ──────────────────────────────────────────────
  Future<void> playBgm(String eraId) async {}
  Future<void> stopBgm() async {}
  Future<void> dispose() async {}
}
```

## File: lib/widgets/pixel_ui.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Shared retro pixel-art UI kit. Every screen builds panels, buttons, and
/// bars from these instead of raw Material widgets, so the whole app reads
/// as one consistent game rather than a pile of differently-styled screens.
///
/// Signature look: solid fill, thick dark pixel border, and a hard-edged
/// offset shadow (blurRadius: 0) instead of Material's soft blurred
/// elevation shadow — that's what reads as "pixel game panel" rather than
/// "phone app card".

/// A solid panel with a thick pixel border and hard offset shadow.
/// Use this instead of Container+BoxDecoration for any card, dialog, or
/// grouped content block.
class PixelPanel extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const PixelPanel({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.primaryDark,
    this.borderWidth = 3,
    this.shadowOffset = 5,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                  color: borderColor,
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A chunky pixel-game button — flat fill, thick border, hard offset
/// shadow that visibly "presses in" on tap. Meets the 48px minimum touch
/// target by default.
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final double minHeight;
  final double? width;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.accent,
    this.textColor = AppColors.primaryDark,
    this.icon,
    this.fontSize = 13,
    this.minHeight = 52,
    this.width,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final shadowOffset = _pressed ? 0.0 : 4.0;
    final fillColor = disabled ? Colors.grey.shade400 : widget.color;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        width: widget.width,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryDark, width: 3),
          boxShadow: shadowOffset > 0
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark,
                    offset: Offset(shadowOffset, shadowOffset),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.fontSize + 6, color: widget.textColor),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.pressStart2p(
                  fontSize: widget.fontSize,
                  height: 1.4,
                  color: disabled ? Colors.grey.shade700 : widget.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pixel-styled label chip — level numbers, tags, counters.
class PixelBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;

  const PixelBadge({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.textColor = AppColors.primaryDark,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Text(
        text,
        style: GoogleFonts.pressStart2p(
          fontSize: fontSize,
          height: 1.4,
          color: textColor,
        ),
      ),
    );
  }
}

/// Chunky segmented progress bar — quiz scores, boss health, learning
/// gain — pixel-blocky fill instead of a smooth Material gradient.
class PixelProgressBar extends StatelessWidget {
  final double value; // 0.0–1.0
  final Color fillColor;
  final Color backgroundColor;
  final double height;
  final int segments;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.fillColor = AppColors.success,
    this.backgroundColor = AppColors.surfaceAlt,
    this.height = 18,
    this.segments = 10,
  });

  @override
  Widget build(BuildContext context) {
    final filledSegments = (value.clamp(0.0, 1.0) * segments).round();
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.primaryDark, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: List.generate(segments, (i) {
          final filled = i < filledSegments;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 2),
              color: filled ? fillColor : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }
}

/// Full-bleed backdrop used by menu screens — a base color plus an
/// optional scenic image with a scrim so text stays readable on top.
class PixelBackdrop extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final Color baseColor;
  final double scrimOpacity;

  const PixelBackdrop({
    super.key,
    required this.child,
    this.imagePath,
    this.baseColor = AppColors.background,
    this.scrimOpacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        image: imagePath != null
            ? DecorationImage(
                image: AssetImage(imagePath!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      foregroundDecoration: imagePath != null
          ? BoxDecoration(color: Colors.black.withValues(alpha: scrimOpacity))
          : null,
      child: child,
    );
  }
}
```

## File: lib/app.dart
```dart
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/router.dart';

class ChronoQuestApp extends StatelessWidget {
  const ChronoQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChronoQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
```

## File: windows/flutter/generated_plugin_registrant.cc
```cpp
//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
}
```

## File: windows/flutter/generated_plugin_registrant.h
```c
//
//  Generated file. Do not edit.
//

// clang-format off

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#include <flutter/plugin_registry.h>

// Registers Flutter plugins.
void RegisterPlugins(flutter::PluginRegistry* registry);

#endif  // GENERATED_PLUGIN_REGISTRANT_
```

## File: windows/flutter/generated_plugins.cmake
```cmake
#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  flutter_secure_storage_windows
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  jni
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
```

## File: windows/runner/CMakeLists.txt
```
cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
```

## File: windows/runner/flutter_window.cpp
```cpp
#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
```

## File: windows/runner/flutter_window.h
```c
#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
```

## File: windows/runner/main.cpp
```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"chronoquest", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
```

## File: windows/runner/resource.h
```c
//{{NO_DEPENDENCIES}}
// Microsoft Visual C++ generated include file.
// Used by Runner.rc
//
#define IDI_APP_ICON                    101

// Next default values for new objects
//
#ifdef APSTUDIO_INVOKED
#ifndef APSTUDIO_READONLY_SYMBOLS
#define _APS_NEXT_RESOURCE_VALUE        102
#define _APS_NEXT_COMMAND_VALUE         40001
#define _APS_NEXT_CONTROL_VALUE         1001
#define _APS_NEXT_SYMED_VALUE           101
#endif
#endif
```

## File: windows/runner/runner.exe.manifest
```
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 and Windows 11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
</assembly>
```

## File: windows/runner/Runner.rc
```
// Microsoft Visual C++ generated resource script.
//
#pragma code_page(65001)
#include "resource.h"

#define APSTUDIO_READONLY_SYMBOLS
/////////////////////////////////////////////////////////////////////////////
//
// Generated from the TEXTINCLUDE 2 resource.
//
#include "winres.h"

/////////////////////////////////////////////////////////////////////////////
#undef APSTUDIO_READONLY_SYMBOLS

/////////////////////////////////////////////////////////////////////////////
// English (United States) resources

#if !defined(AFX_RESOURCE_DLL) || defined(AFX_TARG_ENU)
LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US

#ifdef APSTUDIO_INVOKED
/////////////////////////////////////////////////////////////////////////////
//
// TEXTINCLUDE
//

1 TEXTINCLUDE
BEGIN
    "resource.h\0"
END

2 TEXTINCLUDE
BEGIN
    "#include ""winres.h""\r\n"
    "\0"
END

3 TEXTINCLUDE
BEGIN
    "\r\n"
    "\0"
END

#endif    // APSTUDIO_INVOKED


/////////////////////////////////////////////////////////////////////////////
//
// Icon
//

// Icon with lowest ID value placed first to ensure application icon
// remains consistent on all systems.
IDI_APP_ICON            ICON                    "resources\\app_icon.ico"


/////////////////////////////////////////////////////////////////////////////
//
// Version
//

#if defined(FLUTTER_VERSION_MAJOR) && defined(FLUTTER_VERSION_MINOR) && defined(FLUTTER_VERSION_PATCH) && defined(FLUTTER_VERSION_BUILD)
#define VERSION_AS_NUMBER FLUTTER_VERSION_MAJOR,FLUTTER_VERSION_MINOR,FLUTTER_VERSION_PATCH,FLUTTER_VERSION_BUILD
#else
#define VERSION_AS_NUMBER 1,0,0,0
#endif

#if defined(FLUTTER_VERSION)
#define VERSION_AS_STRING FLUTTER_VERSION
#else
#define VERSION_AS_STRING "1.0.0"
#endif

VS_VERSION_INFO VERSIONINFO
 FILEVERSION VERSION_AS_NUMBER
 PRODUCTVERSION VERSION_AS_NUMBER
 FILEFLAGSMASK VS_FFI_FILEFLAGSMASK
#ifdef _DEBUG
 FILEFLAGS VS_FF_DEBUG
#else
 FILEFLAGS 0x0L
#endif
 FILEOS VOS__WINDOWS32
 FILETYPE VFT_APP
 FILESUBTYPE 0x0L
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904e4"
        BEGIN
            VALUE "CompanyName", "com.chronoquest" "\0"
            VALUE "FileDescription", "chronoquest" "\0"
            VALUE "FileVersion", VERSION_AS_STRING "\0"
            VALUE "InternalName", "chronoquest" "\0"
            VALUE "LegalCopyright", "Copyright (C) 2026 com.chronoquest. All rights reserved." "\0"
            VALUE "OriginalFilename", "chronoquest.exe" "\0"
            VALUE "ProductName", "chronoquest" "\0"
            VALUE "ProductVersion", VERSION_AS_STRING "\0"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1252
    END
END

#endif    // English (United States) resources
/////////////////////////////////////////////////////////////////////////////



#ifndef APSTUDIO_INVOKED
/////////////////////////////////////////////////////////////////////////////
//
// Generated from the TEXTINCLUDE 3 resource.
//


/////////////////////////////////////////////////////////////////////////////
#endif    // not APSTUDIO_INVOKED
```

## File: windows/runner/utils.cpp
```cpp
#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  // First, find the length of the string with a safe upper bound (CWE-126).
  // UNICODE_STRING_MAX_CHARS (32767) is the maximum length of a UNICODE_STRING.
  int input_length = static_cast<int>(wcsnlen(utf16_string, UNICODE_STRING_MAX_CHARS));
  // Now use that bounded length to determine the required buffer size.
  // When an explicit length is passed, WideCharToMultiByte does not include
  // the null terminator in its returned size.
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, nullptr, 0, nullptr, nullptr);
  std::string utf8_string;
  if (target_length == 0 || static_cast<size_t>(target_length) > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
```

## File: windows/runner/utils.h
```c
#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
```

## File: windows/runner/win32_window.cpp
```cpp
#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

/// Window attribute that enables dark mode window decorations.
///
/// Redefined in case the developer's machine has a Windows SDK older than
/// version 10.0.22000.0.
/// See: https://docs.microsoft.com/windows/win32/api/dwmapi/ne-dwmapi-dwmwindowattribute
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

/// Registry key for app theme preference.
///
/// A value of 0 indicates apps should use dark mode. A non-zero or missing
/// value indicates apps should use light mode.
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
  L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

}  // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registrar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  UpdateTheme(window);

  return OnCreate();
}

bool Win32Window::Show() {
  return ShowWindow(window_handle_, SW_SHOWNORMAL);
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy() {
  // No-op; provided for subclasses.
}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  if (result == ERROR_SUCCESS) {
    BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}
```

## File: windows/runner/win32_window.h
```c
#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with |title| that is positioned and sized using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, hence to ensure a
  // consistent size this function will scale the inputted width and height as
  // as appropriate for the default monitor. The window is invisible until
  // |Show| is called. Returns true if the window was created successfully.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Show the current window. Returns true if the window was successfully shown.
  bool Show();

  // Release OS resources associated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle();

  // If true, closing this window will quit the application.
  void SetQuitOnClose(bool quit_on_close);

  // Return a RECT representing the bounds of the current client area.
  RECT GetClientArea();

 protected:
  // Processes and route salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclass window-related
  // setup. Subclasses should return false if setup fails.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Update the window frame's theme to match the system theme.
  static void UpdateTheme(HWND const window);

  bool quit_on_close_ = false;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
```

## File: windows/.gitignore
```
flutter/ephemeral/

# Visual Studio user-specific files.
*.suo
*.user
*.userosscache
*.sln.docstates

# Visual Studio build-related files.
x64/
x86/

# Visual Studio cache files
# files ending in .cache can be ignored
*.[Cc]ache
# but keep track of directories ending in .cache
!*.[Cc]ache/
```

## File: windows/CMakeLists.txt
```
# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(chronoquest LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "chronoquest")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
```

## File: .gitignore
```
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.build/
.buildlog/
.history
.svn/
.swiftpm/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/
/coverage/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# AI Generated Context
repomix-output.md
```

## File: .metadata
```
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled and should not be manually edited.

version:
  revision: "924134a44c189315be2148659913dda1671cbe99"
  channel: "stable"

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: 924134a44c189315be2148659913dda1671cbe99
      base_revision: 924134a44c189315be2148659913dda1671cbe99
    - platform: windows
      create_revision: 924134a44c189315be2148659913dda1671cbe99
      base_revision: 924134a44c189315be2148659913dda1671cbe99

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
```

## File: analysis_options.yaml
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
```

## File: generate_assets.ps1
```powershell
# PowerShell script to generate placeholder asset files for ChronoQuest
# Creates minimal PNG files (1x1 pixel colored rectangles) and empty sound files

$base = "c:\Users\PC\Documents\CHRONO GAME APP\assets"

# Create directories
$dirs = @(
    "backgrounds", "characters", "enemies", "bosses",
    "obstacles", "collectibles", "powerups", "ui", "sounds", "animations"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path "$base\$d" -Force | Out-Null
}

# Function to create a minimal 1x1 PNG file (smallest valid PNG)
function Create-PlaceholderPng {
    param([string]$path)
    # Minimal valid 1x1 red pixel PNG (67 bytes)
    $bytes = [byte[]]@(
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, # PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, # IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, # 1x1
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, # 8-bit RGB
        0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, # IDAT chunk
        0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, # compressed data
        0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, # 
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, # IEND chunk
        0xAE, 0x42, 0x60, 0x82
    )
    [System.IO.File]::WriteAllBytes($path, $bytes)
}

# Backgrounds
$bgFiles = @(
    "login_bg", "character_select_bg", "bookshelf_bg",
    "precolonial_far", "precolonial_near",
    "spanish_far", "spanish_near",
    "american_far", "american_near",
    "ww2_far", "ww2_near",
    "modern_far", "modern_near"
)
foreach ($f in $bgFiles) { Create-PlaceholderPng "$base\backgrounds\$f.png" }

# Characters (5 chars x 6 images)
$chars = @("lapu", "rizal", "luna", "bonifacio", "delpilar")
foreach ($c in $chars) {
    for ($i = 1; $i -le 4; $i++) { Create-PlaceholderPng "$base\characters\${c}_walk_$i.png" }
    Create-PlaceholderPng "$base\characters\${c}_jump.png"
    Create-PlaceholderPng "$base\characters\${c}_hurt.png"
}

# Enemies (10 types x 2 frames)
$enemies = @(
    "tribal_warrior", "dark_spirit", "spanish_soldier", "tax_collector",
    "american_soldier", "propaganda", "japanese_soldier", "tank",
    "corruption_figure", "misinfo_cloud"
)
foreach ($e in $enemies) {
    Create-PlaceholderPng "$base\enemies\${e}_1.png"
    Create-PlaceholderPng "$base\enemies\${e}_2.png"
}

# Bosses (5 x 3 images)
$bosses = @("bakunawa", "governor", "general", "commander", "corruption_boss")
foreach ($b in $bosses) {
    Create-PlaceholderPng "$base\bosses\${b}_idle.png"
    Create-PlaceholderPng "$base\bosses\${b}_attack.png"
    Create-PlaceholderPng "$base\bosses\${b}_defeated.png"
}

# Obstacles
$eras = @("precolonial", "spanish", "american", "ww2", "modern")
foreach ($e in $eras) { Create-PlaceholderPng "$base\obstacles\${e}_wall.png" }

# Collectibles
Create-PlaceholderPng "$base\collectibles\coin.png"
for ($i = 1; $i -le 5; $i++) { Create-PlaceholderPng "$base\collectibles\artifact_$i.png" }

# Powerups
Create-PlaceholderPng "$base\powerups\fifty_fifty.png"
Create-PlaceholderPng "$base\powerups\time_freeze.png"
Create-PlaceholderPng "$base\powerups\shield.png"

# UI
$uiFiles = @("heart_full", "heart_empty", "star_full", "star_empty", "lock_icon")
foreach ($u in $uiFiles) { Create-PlaceholderPng "$base\ui\$u.png" }

# Sounds - create empty MP3 files (just needs to exist)
$sounds = @(
    "correct", "wrong", "jump", "enemy_defeat", "player_hurt",
    "coin", "powerup", "level_complete", "level_failed",
    "boss_appear", "boss_defeat", "era_complete", "footsteps",
    "bgm_precolonial", "bgm_spanish", "bgm_american", "bgm_ww2", "bgm_modern"
)
foreach ($s in $sounds) {
    # Create minimal valid MP3 (MPEG frame header + silence)
    $mp3bytes = [byte[]]@(0xFF, 0xFB, 0x90, 0x00)
    [System.IO.File]::WriteAllBytes("$base\sounds\$s.mp3", $mp3bytes)
}

# Lottie animation placeholder
$lottie = '{"v":"5.5.7","fr":30,"ip":0,"op":60,"w":300,"h":300,"assets":[],"layers":[]}'
Set-Content -Path "$base\animations\fireworks.json" -Value $lottie

Write-Host "Created all placeholder assets!"
Write-Host "  - Backgrounds: $($bgFiles.Count)"
Write-Host "  - Characters: $($chars.Count * 6)"
Write-Host "  - Enemies: $($enemies.Count * 2)"
Write-Host "  - Bosses: $($bosses.Count * 3)"
Write-Host "  - Obstacles: $($eras.Count)"
Write-Host "  - Collectibles: 6"
Write-Host "  - Powerups: 3"
Write-Host "  - UI: $($uiFiles.Count)"
Write-Host "  - Sounds: $($sounds.Count)"
Write-Host "  - Animations: 1"
```

## File: pubspec.lock
```
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  _fe_analyzer_shared:
    dependency: transitive
    description:
      name: _fe_analyzer_shared
      sha256: "0b2f2bd91ba804e53a61d757b986f89f1f9eaed5b11e4b2f5a2468d86d6c9fc7"
      url: "https://pub.dev"
    source: hosted
    version: "67.0.0"
  analyzer:
    dependency: transitive
    description:
      name: analyzer
      sha256: "37577842a27e4338429a1cbc32679d508836510b056f1eedf0c8d20e39c1383d"
      url: "https://pub.dev"
    source: hosted
    version: "6.4.1"
  analyzer_plugin:
    dependency: transitive
    description:
      name: analyzer_plugin
      sha256: "9661b30b13a685efaee9f02e5d01ed9f2b423bd889d28a304d02d704aee69161"
      url: "https://pub.dev"
    source: hosted
    version: "0.11.3"
  archive:
    dependency: transitive
    description:
      name: archive
      sha256: a96e8b390886ee8abb49b7bd3ac8df6f451c621619f52a26e815fdcf568959ff
      url: "https://pub.dev"
    source: hosted
    version: "4.0.9"
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37
      url: "https://pub.dev"
    source: hosted
    version: "2.13.1"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  build:
    dependency: transitive
    description:
      name: build
      sha256: "80184af8b6cb3e5c1c4ec6d8544d27711700bc3e6d2efad04238c7b5290889f0"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  build_config:
    dependency: transitive
    description:
      name: build_config
      sha256: "4ae2de3e1e67ea270081eaee972e1bd8f027d459f249e0f1186730784c2e7e33"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  build_daemon:
    dependency: transitive
    description:
      name: build_daemon
      sha256: fd754058c342243718d5171a95f352cfc9fcf0cba8cfa26df67cb13a5836db78
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  build_resolvers:
    dependency: transitive
    description:
      name: build_resolvers
      sha256: "339086358431fa15d7eca8b6a36e5d783728cf025e559b834f4609a1fcfb7b0a"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  build_runner:
    dependency: "direct dev"
    description:
      name: build_runner
      sha256: "028819cfb90051c6b5440c7e574d1896f8037e3c96cf17aaeb054c9311cfbf4d"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.13"
  build_runner_core:
    dependency: transitive
    description:
      name: build_runner_core
      sha256: f8126682b87a7282a339b871298cc12009cb67109cfa1614d6436fb0289193e0
      url: "https://pub.dev"
    source: hosted
    version: "7.3.2"
  built_collection:
    dependency: transitive
    description:
      name: built_collection
      sha256: "376e3dd27b51ea877c28d525560790aee2e6fbb5f20e2f85d5081027d94e2100"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.1"
  built_value:
    dependency: transitive
    description:
      name: built_value
      sha256: "34e4067d30ce212937df995f03b69992eea683539ceeac7f679a1f1eba055b56"
      url: "https://pub.dev"
    source: hosted
    version: "8.12.6"
  cached_network_image:
    dependency: "direct main"
    description:
      name: cached_network_image
      sha256: "7c1183e361e5c8b0a0f21a28401eecdbde252441106a9816400dd4c2b2424916"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  cached_network_image_platform_interface:
    dependency: transitive
    description:
      name: cached_network_image_platform_interface
      sha256: "35814b016e37fbdc91f7ae18c8caf49ba5c88501813f73ce8a07027a395e2829"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.1"
  cached_network_image_web:
    dependency: transitive
    description:
      name: cached_network_image_web
      sha256: "980842f4e8e2535b8dbd3d5ca0b1f0ba66bf61d14cc3a17a9b4788a3685ba062"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.1"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: faf38497bda5ead2a8c7615f4f7939df04333478bf32e4173fcb06d428b5716b
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  checked_yaml:
    dependency: transitive
    description:
      name: checked_yaml
      sha256: "959525d3162f249993882720d52b7e0c833978df229be20702b33d48d91de70f"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.4"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  code_assets:
    dependency: transitive
    description:
      name: code_assets
      sha256: bf394f466ba9205f1812a0433b392d6af280f155f56651eda7c18cc32ed493b8
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  code_builder:
    dependency: transitive
    description:
      name: code_builder
      sha256: "6a6cab2ba4680d6423f34a9b972a4c9a94ebe1b62ecec4e1a1f2cba91fd1319d"
      url: "https://pub.dev"
    source: hosted
    version: "4.11.1"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  convert:
    dependency: transitive
    description:
      name: convert
      sha256: b30acd5944035672bc15c6b7a8b47d773e41e2f17de064350988c5d02adb1c68
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  crypto:
    dependency: transitive
    description:
      name: crypto
      sha256: c8ea0233063ba03258fbcf2ca4d6dadfefe14f02fab57702265467a19f27fadf
      url: "https://pub.dev"
    source: hosted
    version: "3.0.7"
  custom_lint_core:
    dependency: transitive
    description:
      name: custom_lint_core
      sha256: a85e8f78f4c52f6c63cdaf8c872eb573db0231dcdf3c3a5906d493c1f8bc20e6
      url: "https://pub.dev"
    source: hosted
    version: "0.6.3"
  dart_style:
    dependency: transitive
    description:
      name: dart_style
      sha256: "99e066ce75c89d6b29903d788a7bb9369cf754f7b24bf70bf4b6d6d6b26853b9"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.6"
  dio:
    dependency: "direct main"
    description:
      name: dio
      sha256: ea2bad3c89a27635ce2d85cce4d6b199da49a5a48ec77b03e45b65a3b90922b0
      url: "https://pub.dev"
    source: hosted
    version: "5.10.0"
  dio_web_adapter:
    dependency: transitive
    description:
      name: dio_web_adapter
      sha256: dd58dc3861eb36edb13b217efc006a1c21e5bbc341de8c229b85634fa5e362e4
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "5368f224a74523e8d2e7399ea1638b37aecfca824a3cc4dfdf77bf1fa905ac44"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.3"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "6d7fd89431262d8f3125e81b50d3847a091d846eafcd4fdb88dd06f36d705a45"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  file:
    dependency: transitive
    description:
      name: file
      sha256: a3b4f84adafef897088c160faf7dfffb7696046cb13ae90b508c2cbc95d3b8d4
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  fixnum:
    dependency: transitive
    description:
      name: fixnum
      sha256: b6dc7065e46c974bc7c5f143080a6764ec7a4be6da1285ececdc37be96de53be
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  flame:
    dependency: "direct main"
    description:
      name: flame
      sha256: b9e65f6d7d06a301d6ea3cde03731cad3cdc255d56e0fb53c56c1e7806aaaf6a
      url: "https://pub.dev"
    source: hosted
    version: "1.37.0"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_cache_manager:
    dependency: transitive
    description:
      name: flutter_cache_manager
      sha256: "400b6592f16a4409a7f2bb929a9a7e38c72cceb8ffb99ee57bbf2cb2cecf8386"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: "5398f14efa795ffb7a33e9b6a08798b26a180edac4ad7db3f231e40f82ce11e1"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  flutter_riverpod:
    dependency: "direct main"
    description:
      name: flutter_riverpod
      sha256: "9532ee6db4a943a1ed8383072a2e3eeda041db5657cdf6d2acecf3c21ecbe7e1"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  flutter_secure_storage:
    dependency: "direct main"
    description:
      name: flutter_secure_storage
      sha256: "9cad52d75ebc511adfae3d447d5d13da15a55a92c9410e50f67335b6d21d16ea"
      url: "https://pub.dev"
    source: hosted
    version: "9.2.4"
  flutter_secure_storage_linux:
    dependency: transitive
    description:
      name: flutter_secure_storage_linux
      sha256: be76c1d24a97d0b98f8b54bce6b481a380a6590df992d0098f868ad54dc8f688
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  flutter_secure_storage_macos:
    dependency: transitive
    description:
      name: flutter_secure_storage_macos
      sha256: "6c0a2795a2d1de26ae202a0d78527d163f4acbb11cde4c75c670f3a0fc064247"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
  flutter_secure_storage_platform_interface:
    dependency: transitive
    description:
      name: flutter_secure_storage_platform_interface
      sha256: cf91ad32ce5adef6fba4d736a542baca9daf3beac4db2d04be350b87f69ac4a8
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  flutter_secure_storage_web:
    dependency: transitive
    description:
      name: flutter_secure_storage_web
      sha256: f4ebff989b4f07b2656fb16b47852c0aab9fed9b4ec1c70103368337bc1886a9
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  flutter_secure_storage_windows:
    dependency: transitive
    description:
      name: flutter_secure_storage_windows
      sha256: b20b07cb5ed4ed74fc567b78a72936203f587eba460af1df11281c9326cd3709
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_web_plugins:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  freezed_annotation:
    dependency: transitive
    description:
      name: freezed_annotation
      sha256: c2e2d632dd9b8a2b7751117abcfc2b4888ecfe181bd9fca7170d9ef02e595fe2
      url: "https://pub.dev"
    source: hosted
    version: "2.4.4"
  frontend_server_client:
    dependency: transitive
    description:
      name: frontend_server_client
      sha256: f64a0333a82f30b0cca061bc3d143813a486dc086b574bfb233b7c1372427694
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
  glob:
    dependency: transitive
    description:
      name: glob
      sha256: c3f1ee72c96f8f78935e18aa8cecced9ab132419e8625dc187e1c2408efc20de
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  go_router:
    dependency: "direct main"
    description:
      name: go_router
      sha256: b465e99ce64ba75e61c8c0ce3d87b66d8ac07f0b35d0a7e0263fcfc10f99e836
      url: "https://pub.dev"
    source: hosted
    version: "13.2.5"
  google_fonts:
    dependency: "direct main"
    description:
      name: google_fonts
      sha256: ba03d03bcaa2f6cb7bd920e3b5027181db75ab524f8891c8bc3aa603885b8055
      url: "https://pub.dev"
    source: hosted
    version: "6.3.3"
  graphs:
    dependency: transitive
    description:
      name: graphs
      sha256: "741bbf84165310a68ff28fe9e727332eef1407342fca52759cb21ad8177bb8d0"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.2"
  hive:
    dependency: "direct main"
    description:
      name: hive
      sha256: "8dcf6db979d7933da8217edcec84e9df1bdb4e4edc7fc77dbd5aa74356d6d941"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.3"
  hive_flutter:
    dependency: "direct main"
    description:
      name: hive_flutter
      sha256: dca1da446b1d808a51689fb5d0c6c9510c0a2ba01e22805d492c73b68e33eecc
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  hive_generator:
    dependency: "direct dev"
    description:
      name: hive_generator
      sha256: "06cb8f58ace74de61f63500564931f9505368f45f98958bd7a6c35ba24159db4"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.1"
  hooks:
    dependency: transitive
    description:
      name: hooks
      sha256: "9a62a50b50b769a737bc0a8ff381f333529df3ab746b2f6b02e83760231455ba"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.2"
  http:
    dependency: transitive
    description:
      name: http
      sha256: "87721a4a50b19c7f1d49001e51409bddc46303966ce89a65af4f4e6004896412"
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  http_multi_server:
    dependency: transitive
    description:
      name: http_multi_server
      sha256: aa6199f908078bb1c5efb8d8638d4ae191aac11b311132c3ef48ce352fb52ef8
      url: "https://pub.dev"
    source: hosted
    version: "3.2.2"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "178d74305e7866013777bab2c3d8726205dc5a4dd935297175b19a23a2e66571"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  io:
    dependency: transitive
    description:
      name: io
      sha256: dfd5a80599cf0165756e3181807ed3e77daf6dd4137caaad72d0b7931597650b
      url: "https://pub.dev"
    source: hosted
    version: "1.0.5"
  jni:
    dependency: transitive
    description:
      name: jni
      sha256: c2230682d5bc2362c1c9e8d3c7f406d9cbba23ab3f2e203a025dd47e0fb2e68f
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  jni_flutter:
    dependency: transitive
    description:
      name: jni_flutter
      sha256: "8b59e590786050b1cd866677dddaf76b1ade5e7bc751abe04b86e84d379d3ba6"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.1"
  js:
    dependency: transitive
    description:
      name: js
      sha256: f2c445dce49627136094980615a031419f7f3eb393237e4ecd97ac15dea343f3
      url: "https://pub.dev"
    source: hosted
    version: "0.6.7"
  json_annotation:
    dependency: transitive
    description:
      name: json_annotation
      sha256: "2a743920d81b7910627f68ee2c9ac1fc0bfee32b9fc3403587d7c6791ca12f80"
      url: "https://pub.dev"
    source: hosted
    version: "4.12.0"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: "33e2e26bdd85a0112ec15400c8cbffea70d0f9c3407491f672a2fad47915e2de"
      url: "https://pub.dev"
    source: hosted
    version: "11.0.2"
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: "1dbc140bb5a23c75ea9c4811222756104fbcd1a27173f0c34ca01e16bea473c1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.10"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "8d5a2d49f4a66b49744b23b018848400d23e54caf9463f4eb20df3eb8acb2eb1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: c35bb79562d980e9a453fc715854e1ed39e24e7d0297a880ef54e17f9874a9d7
      url: "https://pub.dev"
    source: hosted
    version: "5.1.1"
  logging:
    dependency: transitive
    description:
      name: logging
      sha256: c8245ada5f1717ed44271ed1c26b8ce85ca3228fd2ffdb75468ab01979309d61
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  lottie:
    dependency: "direct main"
    description:
      name: lottie
      sha256: "58dda9eee3f1b1fb9d490b0161635cffe93022b3b8ca0687e3df33a53620ead2"
      url: "https://pub.dev"
    source: hosted
    version: "3.5.1"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc0b7dc7651697ea4ff3e69ef44b0407ea32c487a39fff6a4004fa585e901861
      url: "https://pub.dev"
    source: hosted
    version: "0.12.19"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: "9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b"
      url: "https://pub.dev"
    source: hosted
    version: "0.13.0"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: "1741988757a65eb6b36abe716829688cf01910bbf91c34354ff7ec1c3de2b349"
      url: "https://pub.dev"
    source: hosted
    version: "1.18.0"
  mime:
    dependency: transitive
    description:
      name: mime
      sha256: "41a20518f0cb1256669420fdba0cd90d21561e560ac240f26ef8322e45bb7ed6"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.0"
  objective_c:
    dependency: transitive
    description:
      name: objective_c
      sha256: "6cb691c686fa2838c6deb34980d426145c2a5d537491cb83d463c33cdbc726ed"
      url: "https://pub.dev"
    source: hosted
    version: "9.4.1"
  octo_image:
    dependency: transitive
    description:
      name: octo_image
      sha256: "34faa6639a78c7e3cbe79be6f9f96535867e879748ade7d17c9b1ae7536293bd"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  ordered_set:
    dependency: transitive
    description:
      name: ordered_set
      sha256: d6c1d053a533e84931a388cbf03f1ad21a0543bf06c7a281859d3ffacd8e15f2
      url: "https://pub.dev"
    source: hosted
    version: "8.0.0"
  package_config:
    dependency: transitive
    description:
      name: package_config
      sha256: f096c55ebb7deb7e384101542bfba8c52696c1b56fca2eb62827989ef2353bbc
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  path:
    dependency: transitive
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider:
    dependency: transitive
    description:
      name: path_provider
      sha256: a7f4874f987173da295a61c181b8ee71dab59b332a486b391babf26a1b884825
      url: "https://pub.dev"
    source: hosted
    version: "2.1.6"
  path_provider_android:
    dependency: transitive
    description:
      name: path_provider_android
      sha256: "69cbd515a62b94d32a7944f086b2f82b4ac40a1d45bebfc00813a430ab2dabcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.1"
  path_provider_foundation:
    dependency: transitive
    description:
      name: path_provider_foundation
      sha256: "2a376b7d6392d80cd3705782d2caa734ca4727776db0b6ec36ef3f1855197699"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.0"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: "58c2005f147315b11e9b4a7bc889cd5203e250cba8e3f012dae259b4972b5c16"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.2"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "484838772624c3a4b94f1e44a3e19897fee738f2d5c4ce448443b0417f7c9dda"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  pool:
    dependency: transitive
    description:
      name: pool
      sha256: "978783255c543aa3586a1b3c21f6e9d720eb315376a915872c61ef8b5c20177d"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.2"
  posix:
    dependency: transitive
    description:
      name: posix
      sha256: "185ef7606574f789b40f289c233efa52e96dead518aed988e040a10737febb07"
      url: "https://pub.dev"
    source: hosted
    version: "6.5.0"
  pub_semver:
    dependency: transitive
    description:
      name: pub_semver
      sha256: "5bfcf68ca79ef689f8990d1160781b4bad40a3bd5e5218ad4076ddb7f4081585"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  pubspec_parse:
    dependency: transitive
    description:
      name: pubspec_parse
      sha256: "0560ba233314abbed0a48a2956f7f022cce7c3e1e73df540277da7544cad4082"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.0"
  record_use:
    dependency: transitive
    description:
      name: record_use
      sha256: "2551bd8eecfe95d14ae75f6021ad0248be5c27f138c2ec12fcb52b500b3ba1ed"
      url: "https://pub.dev"
    source: hosted
    version: "0.6.0"
  riverpod:
    dependency: transitive
    description:
      name: riverpod
      sha256: "59062512288d3056b2321804332a13ffdd1bf16df70dcc8e506e411280a72959"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  riverpod_analyzer_utils:
    dependency: transitive
    description:
      name: riverpod_analyzer_utils
      sha256: "8b71f03fc47ae27d13769496a1746332df4cec43918aeba9aff1e232783a780f"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.1"
  riverpod_annotation:
    dependency: "direct main"
    description:
      name: riverpod_annotation
      sha256: e14b0bf45b71326654e2705d462f21b958f987087be850afd60578fcd502d1b8
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  riverpod_generator:
    dependency: "direct dev"
    description:
      name: riverpod_generator
      sha256: d451608bf17a372025fc36058863737636625dfdb7e3cbf6142e0dfeb366ab22
      url: "https://pub.dev"
    source: hosted
    version: "2.4.0"
  rxdart:
    dependency: transitive
    description:
      name: rxdart
      sha256: "5c3004a4a8dbb94bd4bf5412a4def4acdaa12e12f269737a5751369e12d1a962"
      url: "https://pub.dev"
    source: hosted
    version: "0.28.0"
  shelf:
    dependency: transitive
    description:
      name: shelf
      sha256: e7dd780a7ffb623c57850b33f43309312fc863fb6aa3d276a754bb299839ef12
      url: "https://pub.dev"
    source: hosted
    version: "1.4.2"
  shelf_web_socket:
    dependency: transitive
    description:
      name: shelf_web_socket
      sha256: cc36c297b52866d203dbf9332263c94becc2fe0ceaa9681d07b6ef9807023b67
      url: "https://pub.dev"
    source: hosted
    version: "2.0.1"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  source_gen:
    dependency: transitive
    description:
      name: source_gen
      sha256: "14658ba5f669685cd3d63701d01b31ea748310f7ab854e471962670abcf57832"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.0"
  source_helper:
    dependency: transitive
    description:
      name: source_helper
      sha256: "86d247119aedce8e63f4751bd9626fc9613255935558447569ad42f9f5b48b3c"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.5"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "56a02f1f4cd1a2d96303c0144c93bd6d909eea6bee6bf5a0e0b685edbd4c47ab"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.2"
  sqflite:
    dependency: transitive
    description:
      name: sqflite
      sha256: "58a799e6ac17dd32fbab93813d39ed835a75ccc0f8f85b8955fe318c6712b082"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3"
  sqflite_android:
    dependency: transitive
    description:
      name: sqflite_android
      sha256: d0548f9d7422a2dae99ec6f8b0a3074463b132d216fa5ba0d230eeefc901983b
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3"
  sqflite_common:
    dependency: transitive
    description:
      name: sqflite_common
      sha256: "5bf6a55c166e73bf651ba7ec3ed486e577620e3dc8f3a9c6a258a8031b624590"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.11"
  sqflite_darwin:
    dependency: transitive
    description:
      name: sqflite_darwin
      sha256: c86ca18b8f666bbf903924687fe21cc16fc385d086005067e26619ca530bef9f
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3+1"
  sqflite_platform_interface:
    dependency: transitive
    description:
      name: sqflite_platform_interface
      sha256: f84939f84350d92d04416f8bc4dc52d3896aec7716cc9e80cf0146342139dc50
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  state_notifier:
    dependency: transitive
    description:
      name: state_notifier
      sha256: b8677376aa54f2d7c58280d5a007f9e8774f1968d1fb1c096adcb4792fba29bb
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  stream_transform:
    dependency: transitive
    description:
      name: stream_transform
      sha256: ad47125e588cfd37a9a7f86c7d6356dde8dfe89d071d293f80ca9e9273a33871
      url: "https://pub.dev"
    source: hosted
    version: "2.1.1"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  synchronized:
    dependency: transitive
    description:
      name: synchronized
      sha256: "93b153dcb6a26dcddee6ca087dd634b53e38c10b5aa163e8e49501a776456153"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: "949a932224383300f01be9221c39180316445ecb8e7547f70a41a35bf421fb9e"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.11"
  timing:
    dependency: transitive
    description:
      name: timing
      sha256: "62ee18aca144e4a9f29d212f5a4c6a053be252b895ab14b5821996cff4ed90fe"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.2"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  uuid:
    dependency: transitive
    description:
      name: uuid
      sha256: "1fef9e8e11e2991bb773070d4656b7bd5d850967a2456cfc83cf47925ba79489"
      url: "https://pub.dev"
    source: hosted
    version: "4.5.3"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: d530bd74fea330e6e364cda7a85019c434070188383e1cd8d9777ee586914c5b
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: "0016aef94fc66495ac78af5859181e3f3bf2026bd8eecc72b9565601e19ab360"
      url: "https://pub.dev"
    source: hosted
    version: "15.2.0"
  watcher:
    dependency: transitive
    description:
      name: watcher
      sha256: "1398c9f081a753f9226febe8900fce8f7d0a67163334e1c94a2438339d79d635"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  web_socket:
    dependency: transitive
    description:
      name: web_socket
      sha256: "34d64019aa8e36bf9842ac014bb5d2f5586ca73df5e4d9bf5c936975cae6982c"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.1"
  web_socket_channel:
    dependency: transitive
    description:
      name: web_socket_channel
      sha256: d645757fb0f4773d602444000a8131ff5d48c9e47adfe9772652dd1a4f2d45c8
      url: "https://pub.dev"
    source: hosted
    version: "3.0.3"
  win32:
    dependency: transitive
    description:
      name: win32
      sha256: d7cb55e04cd34096cd3a79b3330245f54cb96a370a1c27adb3c84b917de8b08e
      url: "https://pub.dev"
    source: hosted
    version: "5.15.0"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: b9da305ac7c39faa3f030eccd175340f968459dae4af175130b3fc47e40d76ce
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
sdks:
  dart: ">=3.12.0 <4.0.0"
  flutter: ">=3.44.0"
```

## File: README.md
```markdown
# chronoquest

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
```

## File: android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="chronoquest"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

## File: android/app/build.gradle.kts
```kotlin
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.chronoquest.chronoquest"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.chronoquest.chronoquest"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {

            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

## File: lib/core/router.dart
```dart
// Destination in your repo: lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/character_selection_screen.dart';
import '../screens/home/era_selection_screen.dart';
import '../screens/game/background_history_screen.dart';
import '../screens/game/level_select_screen.dart';
import '../screens/game/game_screen.dart';
import '../screens/game/level_complete_screen.dart';
import '../screens/game/level_failed_screen.dart';
import '../screens/game/era_complete_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/leaderboard_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) async {
    final hasToken = await StorageService.hasToken();
    final isLoginRoute = state.matchedLocation == '/login';

    if (!hasToken && !isLoginRoute) return '/login';
    if (hasToken && isLoginRoute) return '/character-selection';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/character-selection',
      builder: (context, state) => const CharacterSelectionScreen(),
    ),
    GoRoute(
      path: '/era-selection',
      builder: (context, state) => const EraSelectionScreen(),
    ),
    GoRoute(
      path: '/background/:eraId',
      builder: (context, state) => BackgroundHistoryScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/level-select/:eraId',
      builder: (context, state) => LevelSelectScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/game/:eraId/:level',
      builder: (context, state) => GameScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/level-complete/:eraId/:level',
      builder: (context, state) => LevelCompleteScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/level-failed/:eraId/:level',
      builder: (context, state) => LevelFailedScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/era-complete/:eraId',
      builder: (context, state) => EraCompleteScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(fontSize: 16),
      ),
    ),
  ),
);
```

## File: lib/core/theme.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.pixelifySansTextTheme().copyWith(
        displayLarge: GoogleFonts.pressStart2p(
          fontSize: 26,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.pressStart2p(
          fontSize: 18,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.pressStart2p(
          fontSize: 14,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.pixelifySans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.pixelifySans(
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.pixelifySans(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.pressStart2p(
          fontSize: 11,
          height: 1.4,
          color: Colors.white,
        ),
      ),
      // Pixel-game buttons: square-ish corners, thick dark outline, flat
      // fill instead of a soft Material elevation shadow — elevation is
      // handled by hard-edged BoxShadow in the bespoke Pixel widgets, but
      // this keeps any screen still using a plain ElevatedButton on-theme.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.primaryDark, width: 3),
          ),
          textStyle: GoogleFonts.pressStart2p(fontSize: 12, height: 1.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryDark, width: 3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.pressStart2p(fontSize: 11, height: 1.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.accent, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: GoogleFonts.pixelifySans(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.pressStart2p(
          fontSize: 14,
          height: 1.4,
          color: Colors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
```

## File: lib/game/components/coin_component.dart
```dart
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Collectible coin rendered using the collectible image.
class CoinComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  bool collected = false;

  final Vector2 _velocity = Vector2.zero();
  double _bobTime = 0;
  late final double _baseY;

  CoinComponent({Vector2? spawnPosition}) {
    if (spawnPosition != null) {
      position = spawnPosition;
    }
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('collectibles/coin.png');
    size = Vector2(28, 28);
    if (position.isZero()) {
      position = Vector2(
        game.size.x + 20,
        game.groundY - 32 - (Random().nextDouble() * 80),
      );
    }
    _baseY = position.y;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;

    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);

    _bobTime += dt * 3;
    position.y = _baseY + (sin(_bobTime) * 4);

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void collect() {
    collected = true;
    removeFromParent();
  }
}
```

## File: lib/game/components/enemy_component.dart
```dart
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../models/question.dart';
import '../chrono_game.dart';

/// Enemy that walks left toward the player.
/// Renders 2-frame walk cycle from image files.
class EnemyComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Question question;
  final String eraId;
  static const double moveSpeed = 90.0;
  bool defeated = false;

  late final String _enemyType;

  // Cached velocity for zero-allocation updates
  final Vector2 _velocity = Vector2.zero();

  EnemyComponent({required this.question, required this.eraId});

  @override
  Future<void> onLoad() async {
    _enemyType = _getEnemyTypeForEra(eraId);
    
    // Load the 2-frame walking cycle
    final frame1 = await game.loadSprite('enemies/${_enemyType}_1.png');
    final frame2 = await game.loadSprite('enemies/${_enemyType}_2.png');
    
    animation = SpriteAnimation.spriteList(
      [frame1, frame2],
      stepTime: 0.3,
    );

    size = Vector2(60, 72);
    position = Vector2(
      game.size.x + 60,
      game.groundY - size.y,
    );
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!defeated) {
      _velocity.setValues(-moveSpeed, 0);
      position.addScaled(_velocity, dt);
      if (position.x < -size.x) {
        removeFromParent();
      }
    }
  }

  void defeat() {
    defeated = true;
    game.audioService.playEnemyDefeat();
    removeFromParent();
  }

  String _getEnemyTypeForEra(String era) {
    final enemies = {
      'pre-colonial': ['tribal_warrior', 'dark_spirit'],
      'spanish':      ['spanish_soldier', 'tax_collector'],
      'american':     ['american_soldier', 'propaganda'],
      'ww2':          ['japanese_soldier', 'tank'],
      'modern':       ['corruption_figure', 'misinfo_cloud'],
    };
    final list = enemies[era] ?? ['spanish_soldier'];
    return list[Random().nextInt(list.length)];
  }
}
```

## File: lib/game/components/enemy_spawner.dart
```dart
import 'dart:math';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'wall_component.dart';
import 'coin_component.dart';

/// Spawns enemies, walls, and coins at intervals as the world scrolls.
/// Each enemy carries one quiz question from the pre-fetched list.
class EnemySpawner {
  final ChronoGame game;
  final List<Question> questions;
  double distanceTraveled = 0.0;
  double spawnInterval = 300.0; // spawn every ~2 seconds at 150px/s
  int nextIndex = 0;
  bool allEnemiesSpawned = false;

  /// How many enemies have been spawned so far.
  int get spawnedCount => nextIndex;

  /// Total number of enemies (questions) for this level.
  int get totalEnemies => questions.length;

  final Random _random = Random();
  double _wallTimer = 0;
  double _coinTimer = 0;

  EnemySpawner({required this.game, required this.questions});

  void update(double dt) {
    distanceTraveled += ChronoGame.worldScrollSpeed * dt;

    // Spawn enemy at interval
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }

    if (nextIndex >= questions.length) {
      allEnemiesSpawned = true;
    }

    // Spawn walls periodically
    _wallTimer += dt;
    if (_wallTimer > 3.0 + _random.nextDouble() * 4.0) {
      _wallTimer = 0;
      if (!game.questionShowing) {
        _spawnWall();
      }
    }

    // Spawn coins periodically
    _coinTimer += dt;
    if (_coinTimer > 1.5 + _random.nextDouble() * 2.0) {
      _coinTimer = 0;
      if (!game.questionShowing) {
        _spawnCoin();
      }
    }
  }

  void _spawnEnemy() {
    final enemy = EnemyComponent(
      question: questions[nextIndex],
      eraId: game.currentEra,
    );
    game.add(enemy);
    nextIndex++;
  }

  void _spawnWall() {
    final wall = WallComponent();
    game.add(wall);
  }

  void _spawnCoin() {
    final coin = CoinComponent();
    game.add(coin);
  }
}
```

## File: lib/game/components/gap_component.dart
```dart
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

/// A section of ground that scrolls left. Gaps are created by NOT placing
/// a GroundSection in a stretch — when the player falls through, they
/// lose a heart and respawn.
class GroundSection extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final double sectionWidth;
  final Color color;

  // Cached for zero-allocation update loop (Flame performance skill)
  final Vector2 _velocity = Vector2.zero();

  GroundSection({
    required this.sectionWidth,
    required this.color,
    required Vector2 sectionPosition,
  }) {
    position = sectionPosition;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(sectionWidth, 60);
    add(RectangleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    game.groundSections.add(this);
  }

  @override
  void onRemove() {
    game.groundSections.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);
    if (position.x < -sectionWidth) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
  }
}

/// Spawns ground sections with gaps between them.
class GroundSpawner {
  final ChronoGame game;
  double _timeSinceLastSpawn = 0;
  double _spawnInterval = 2.0; // seconds between new sections
  final Random _random = Random();

  GroundSpawner({required this.game});

  Color get _groundColor {
    const colors = {
      'pre-colonial': Color(0xFF5D4E37),
      'spanish': Color(0xFF808080),
      'american': Color(0xFF8B6914),
      'ww2': Color(0xFF4A4A3A),
      'modern': Color(0xFF555555),
    };
    return colors[game.currentEra] ?? const Color(0xFF5D4E37);
  }

  void spawnInitialGround() {
    // Fill screen with ground initially
    final section = GroundSection(
      sectionWidth: game.size.x + 200,
      color: _groundColor,
      sectionPosition: Vector2(-100, game.groundY),
    );
    game.add(section);
  }

  void update(double dt) {
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawnSection();
      // Randomize next interval (gap or no gap)
      _spawnInterval = 1.5 + _random.nextDouble() * 2.0;
    }
  }

  void _spawnSection() {
    // 25% chance of a gap
    final hasGap = _random.nextDouble() < 0.25;

    if (hasGap) {
      // Gap width between 80-120px
      final gapWidth = 80.0 + _random.nextDouble() * 40.0;

      // Section after the gap
      final sectionWidth = 200.0 + _random.nextDouble() * 300.0;
      final section = GroundSection(
        sectionWidth: sectionWidth,
        color: _groundColor,
        sectionPosition: Vector2(
          game.size.x + gapWidth,
          game.groundY,
        ),
      );
      game.add(section);
    } else {
      final sectionWidth = 300.0 + _random.nextDouble() * 400.0;
      final section = GroundSection(
        sectionWidth: sectionWidth,
        color: _groundColor,
        sectionPosition: Vector2(game.size.x, game.groundY),
      );
      game.add(section);
    }
  }
}
```

## File: lib/models/question.dart
```dart
class QuestionOption {
  final String label;
  final String text;

  const QuestionOption({required this.label, required this.text});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      label: json['label'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'text': text};
}

class Question {
  final String id;
  final String era;
  final String subTopic;
  final String gradeLevel;
  final int level;
  final String difficulty;
  final String questionType;
  final String questionText;
  late final List<QuestionOption> options;
  late final String correctAnswer;
  final String explanation;
  int elapsedSeconds;

  Question({
    required this.id,
    required this.era,
    this.subTopic = '',
    this.gradeLevel = '',
    this.level = 1,
    this.difficulty = 'medium',
    this.questionType = 'multiple_choice',
    required this.questionText,
    required List<QuestionOption> options,
    required String correctAnswer,
    this.explanation = '',
    this.elapsedSeconds = 0,
  }) {
    if (options.isEmpty) {
      this.options = [];
      this.correctAnswer = correctAnswer;
      return;
    }

    // Find the text of the correct answer before shuffling
    final correctOpt = options.firstWhere(
      (o) => o.label == correctAnswer,
      orElse: () => options.first,
    );
    final correctText = correctOpt.text;

    // Shuffle the options
    final shuffled = List<QuestionOption>.from(options)..shuffle();
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    final newOptions = <QuestionOption>[];
    String newCorrect = correctAnswer;

    // Reassign labels A, B, C, D...
    for (int i = 0; i < shuffled.length; i++) {
      final label = i < labels.length ? labels[i] : String.fromCharCode(65 + i);
      newOptions.add(QuestionOption(label: label, text: shuffled[i].text));
      if (shuffled[i].text == correctText) {
        newCorrect = label;
      }
    }
    
    this.options = newOptions;
    this.correctAnswer = newCorrect;
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      era: json['era'] as String? ?? '',
      subTopic: json['subTopic'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionType: json['questionType'] as String? ?? 'multiple_choice',
      questionText: json['questionText'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) =>
                  QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'era': era,
        'subTopic': subTopic,
        'gradeLevel': gradeLevel,
        'level': level,
        'difficulty': difficulty,
        'questionType': questionType,
        'questionText': questionText,
        'options': options.map((o) => o.toJson()).toList(),
        'correctAnswer': correctAnswer,
        'explanation': explanation,
      };
}
```

## File: lib/models/student.dart
```dart
class PowerUps {
  int fiftyFifty;
  int timeFreeze;
  int shield;

  PowerUps({
    this.fiftyFifty = 0,
    this.timeFreeze = 0,
    this.shield = 0,
  });

  factory PowerUps.fromJson(Map<String, dynamic> json) {
    return PowerUps(
      fiftyFifty: json['fiftyFifty'] as int? ?? 0,
      timeFreeze: json['timeFreeze'] as int? ?? 0,
      shield: json['shield'] as int? ?? json['extraLife'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fiftyFifty': fiftyFifty,
        'timeFreeze': timeFreeze,
        'shield': shield,
      };
}

class Student {
  final String id;
  final String username;
  final String name;
  final String classCode;
  final String schoolName;
  final String gradeLevel;
  int score;
  String levelReached;
  int coins;
  PowerUps powerUps;
  final bool isActive;
  final String? lastActive;

  Student({
    required this.id,
    required this.username,
    required this.name,
    required this.classCode,
    this.schoolName = '',
    required this.gradeLevel,
    this.score = 0,
    this.levelReached = 'pre-colonial',
    this.coins = 0,
    PowerUps? powerUps,
    this.isActive = true,
    this.lastActive,
  }) : powerUps = powerUps ?? PowerUps();

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      classCode: json['classCode'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? 'grade5',
      score: json['score'] as int? ?? 0,
      levelReached: json['levelReached'] as String? ?? 'pre-colonial',
      coins: json['coins'] as int? ?? 0,
      powerUps: json['powerUps'] != null
          ? PowerUps.fromJson(json['powerUps'] as Map<String, dynamic>)
          : PowerUps(),
      isActive: json['isActive'] as bool? ?? true,
      lastActive: json['lastActive'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'classCode': classCode,
        'schoolName': schoolName,
        'gradeLevel': gradeLevel,
        'score': score,
        'levelReached': levelReached,
        'coins': coins,
        'powerUps': powerUps.toJson(),
      };
}
```

## File: lib/providers/game_provider.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/storage_service.dart';

class GameState {
  final String selectedCharacterId;
  final String currentEraId;
  final int currentLevel;
  final PowerUps powerUps;
  final int coins;

  GameState({
    this.selectedCharacterId = 'rizal',
    this.currentEraId = 'pre-colonial',
    this.currentLevel = 1,
    PowerUps? powerUps,
    this.coins = 0,
  }) : powerUps = powerUps ?? PowerUps();

  GameState copyWith({
    String? selectedCharacterId,
    String? currentEraId,
    int? currentLevel,
    PowerUps? powerUps,
    int? coins,
  }) {
    return GameState(
      selectedCharacterId:
          selectedCharacterId ?? this.selectedCharacterId,
      currentEraId: currentEraId ?? this.currentEraId,
      currentLevel: currentLevel ?? this.currentLevel,
      powerUps: powerUps ?? this.powerUps,
      coins: coins ?? this.coins,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState()) {
    _loadCharacter();
  }

  void _loadCharacter() {
    final char = StorageService.getCharacter();
    state = state.copyWith(selectedCharacterId: char);
  }

  void selectCharacter(String characterId) {
    StorageService.saveCharacter(characterId);
    state = state.copyWith(selectedCharacterId: characterId);
  }

  void setEra(String eraId) {
    state = state.copyWith(currentEraId: eraId);
  }

  void setLevel(int level) {
    state = state.copyWith(currentLevel: level);
  }

  void updatePowerUps(PowerUps powerUps) {
    state = state.copyWith(powerUps: powerUps);
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  void useFiftyFifty() {
    if (state.powerUps.fiftyFifty > 0) {
      state.powerUps.fiftyFifty--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void useTimeFreeze() {
    if (state.powerUps.timeFreeze > 0) {
      state.powerUps.timeFreeze--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void useShield() {
    if (state.powerUps.shield > 0) {
      state.powerUps.shield--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void awardPowerUp(int level) {
    // Powerup earned at milestones
    // NOTE: level 5 used to award Time Freeze, which has no working use in the
    // game (see question_overlay.dart). Removed rather than left dead — if you
    // want a level-5 reward, consider granting an extra fiftyFifty or shield here.
    if (level == 3) {
      state.powerUps.fiftyFifty++;
    } else if (level == 7) {
      state.powerUps.shield++;
    }
    state = state.copyWith(powerUps: state.powerUps);
  }
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
```

## File: lib/screens/game/level_failed_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';

class LevelFailedScreen extends StatelessWidget {
  final String eraId;
  final int level;
  const LevelFailedScreen({
    super.key,
    required this.eraId,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            // SingleChildScrollView is the actual bug fix here — this
            // screen has two stacked buttons at the bottom, and without a
            // scroll view, short landscape phones would push "BUMALIK SA
            // LEVEL SELECT" off the bottom of the visible screen entirely.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: PixelPanel(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Failed icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.danger,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: AppColors.danger,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'SUBUKAN MULI!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Level $level — Naubusan ng puso',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hearts display (all empty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.favorite_border,
                              color: AppColors.danger,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hint / encouragement
                      PixelPanel(
                        color: AppColors.surfaceAlt,
                        borderWidth: 2,
                        shadowOffset: 0,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tip: Basahin muli ang kasaysayan bago '
                                'subukan ulit. Makakatulong ito sa '
                                'pagsagot!',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Retry button
                      PixelButton(
                        label: 'ULIT',
                        icon: Icons.refresh,
                        color: AppColors.accent,
                        width: double.infinity,
                        onPressed: () {
                          context.go('/game/$eraId/$level');
                        },
                      ),
                      const SizedBox(height: 10),

                      // Back to level select
                      PixelButton(
                        label: 'BUMALIK',
                        icon: Icons.arrow_back,
                        color: AppColors.surfaceAlt,
                        textColor: AppColors.textSecondary,
                        width: double.infinity,
                        onPressed: () {
                          context.go('/level-select/$eraId');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## File: lib/screens/profile/leaderboard_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> classLeaderboard = [];
  List<Map<String, dynamic>> schoolLeaderboard = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final classData = await ApiService().getLeaderboard('class');
      final schoolData = await ApiService().getLeaderboard('school');
      setState(() {
        classLeaderboard = classData;
        schoolLeaderboard = schoolData;
        isLoading = false;
      });
    } catch (_) {
      // Don't fabricate fake student rankings — show a real error state
      // so students never mistake placeholder names for actual classmates.
      setState(() {
        classLeaderboard = [];
        schoolLeaderboard = [];
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      tooltip: 'Bumalik',
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadLeaderboards,
                      tooltip: 'I-refresh',
                      icon:
                          const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Aking Klase'),
                    Tab(text: 'Aming Paaralan'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : hasError
                        ? _ErrorState(onRetry: _loadLeaderboards)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _LeaderboardList(data: classLeaderboard),
                              _LeaderboardList(data: schoolLeaderboard),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Hindi ma-load ang leaderboard.\nSubukang muli.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: AppColors.accent),
              label: const Text('Subukang Muli',
                  style: TextStyle(color: AppColors.accent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _LeaderboardList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Walang data pa',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Top 3 podium
          if (data.length >= 3)
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  _PodiumItem(
                    entry: data[1],
                    rank: 2,
                    height: 90,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  // 1st place
                  _PodiumItem(
                    entry: data[0],
                    rank: 1,
                    height: 120,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  // 3rd place
                  _PodiumItem(
                    entry: data.length > 2 ? data[2] : {},
                    rank: 3,
                    height: 70,
                    color: const Color(0xFFCD7F32),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Remaining ranks
          ...data.skip(3).toList().asMap().entries.map((entry) {
            final i = entry.key + 4;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$i',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (item['name'] as String? ?? '?')[0],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${item['score'] ?? 0}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '?';
    final score = entry['score'] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        CircleAvatar(
          radius: rank == 1 ? 22 : 18,
          backgroundColor: color,
          child: Text(
            name[0],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 18 : 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Podium block
        Container(
          width: rank == 1 ? 80 : 65,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$score pts',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## File: lib/screens/profile/profile_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final student = authState.student;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Character + info
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.accent, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  student?.name.isNotEmpty == true
                                      ? student!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              student?.name ?? 'Student',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student?.classCode ?? '',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.accent,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              student?.schoolName ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stats row
                            _StatBox(
                              label: 'Puntos',
                              value: '${student?.score ?? 0}',
                              icon: Icons.star,
                            ),
                            const SizedBox(height: 8),
                            _StatBox(
                              label: 'Coins',
                              value: '${student?.coins ?? 0}',
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Era progress + powerups
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Era progress
                            ...allEras.map((era) {
                              final levels =
                                  StorageService.getCompletedLevels(era.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: levels.length >= 10
                                            ? AppColors.success
                                            : levels.isNotEmpty
                                                ? AppColors.warning
                                                : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        era.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${levels.length}/10',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 12),

                            // Powerups
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Powerups',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _PowerupDisplay(
                                        icon: Icons.filter_2,
                                        label: '50/50',
                                        count: student
                                                ?.powerUps.fiftyFifty ??
                                            0,
                                      ),
                                      _PowerupDisplay(
                                        icon: Icons.shield,
                                        label: 'Shield',
                                        count:
                                            student?.powerUps.shield ?? 0,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Logout
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('I-LOGOUT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.5)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerupDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _PowerupDisplay({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(height: 4),
        Text(
          '×$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
```

## File: windows/flutter/CMakeLists.txt
```
# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)


# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Set fallback configurations for older versions of the flutter tool.
if (NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/windows/app.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

# === Wrapper ===
list(APPEND CPP_WRAPPER_SOURCES_CORE
  "core_implementations.cc"
  "standard_codec.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_CORE PREPEND "${WRAPPER_ROOT}/")
list(APPEND CPP_WRAPPER_SOURCES_PLUGIN
  "plugin_registrar.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_PLUGIN PREPEND "${WRAPPER_ROOT}/")
list(APPEND CPP_WRAPPER_SOURCES_APP
  "flutter_engine.cc"
  "flutter_view_controller.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_APP PREPEND "${WRAPPER_ROOT}/")

# Wrapper sources needed for a plugin.
add_library(flutter_wrapper_plugin STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_PLUGIN}
)
apply_standard_settings(flutter_wrapper_plugin)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)
target_include_directories(flutter_wrapper_plugin PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_plugin flutter_assemble)

# Wrapper sources needed for the runner.
add_library(flutter_wrapper_app STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_APP}
)
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
set(PHONY_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/_phony_")
set_source_files_properties("${PHONY_OUTPUT}" PROPERTIES SYMBOLIC TRUE)
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_PLUGIN}
    ${CPP_WRAPPER_SOURCES_APP}
    ${PHONY_OUTPUT}
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat"
      ${FLUTTER_TARGET_PLATFORM} $<CONFIG>
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_PLUGIN}
  ${CPP_WRAPPER_SOURCES_APP}
)
```

## File: pubspec.yaml
```yaml
name: chronoquest
description: ChronoQuest - Philippine History Auto-Runner Platformer Game
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flame: ^1.17.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  go_router: ^13.0.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  lottie: ^3.1.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true

  assets:
    - assets/backgrounds/
    - assets/characters/
    - assets/enemies/
    - assets/bosses/
    - assets/obstacles/
    - assets/collectibles/
    - assets/powerups/
    - assets/ui/
    - assets/sounds/
    - assets/animations/
    - assets/data/
```

## File: lib/game/components/wall_component.dart
```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Visible low wall obstacle — rendered using real asset file.
class WallComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Vector2 _velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(
        'obstacles/${_obstacleAssetKeyForEra(game.currentEra)}_wall.png');
    size = Vector2(40, 50);
    position = Vector2(game.size.x + 20, game.groundY - size.y);
    add(RectangleHitbox());
  }

  /// Obstacle PNGs are named without the hyphen used in era ids
  /// (e.g. 'precolonial_wall.png' for the 'pre-colonial' era) — same
  /// mismatch as the background art, fixed the same way here.
  String _obstacleAssetKeyForEra(String era) {
    if (era == 'pre-colonial') return 'precolonial';
    return era;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}
```

## File: lib/models/era_progress.dart
```dart
// Destination in your repo: lib/models/era_progress.dart
class EraProgress {
  final String eraId;
  final int levelsCompleted;
  final Map<int, LevelResult> levelResults;
  final bool bossDefeated;
  final int postTestScore;

  const EraProgress({
    required this.eraId,
    this.levelsCompleted = 0,
    this.levelResults = const {},
    this.bossDefeated = false,
    this.postTestScore = 0,
  });

  bool get isCompleted => bossDefeated;
  bool get isInProgress => levelsCompleted > 0 && !bossDefeated;
  bool get isNotStarted => levelsCompleted == 0 && !bossDefeated;

  bool isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 10) {
      // Boss level — all 9 levels must be done
      return levelsCompleted >= 9;
    }
    return levelsCompleted >= level - 1;
  }

  int getLevelStars(int level) {
    final result = levelResults[level];
    if (result == null) return 0;
    if (result.percentage >= 90) return 3;
    if (result.percentage >= 70) return 2;
    return 1;
  }

  double get averageLevelScore {
    if (levelResults.isEmpty) return 0;
    final scores = levelResults.values
        .where((r) => r.level < 10)
        .map((r) => r.percentage.toDouble());
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory EraProgress.fromJson(Map<String, dynamic> json) {
    final completed = (json['completedLevels'] as List?)?.cast<num>() ?? const [];
    return EraProgress(
      eraId: json['era'] as String? ?? '',
      levelsCompleted: completed.length,
      bossDefeated: json['isComplete'] as bool? ?? false,
      postTestScore: (json['postTestScore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'eraId': eraId,
        'levelsCompleted': levelsCompleted,
        'levelResults': levelResults
            .map((k, v) => MapEntry(k.toString(), v.toJson())),
        'bossDefeated': bossDefeated,
        'postTestScore': postTestScore,
      };
}

class LevelResult {
  final int level;
  final int percentage;
  final int stars;
  final int score;

  const LevelResult({
    required this.level,
    required this.percentage,
    required this.stars,
    this.score = 0,
  });

  factory LevelResult.fromJson(Map<String, dynamic> json) {
    final pct = json['percentage'] as int? ?? 0;
    return LevelResult(
      level: json['level'] as int? ?? 1,
      percentage: pct,
      stars: pct >= 90
          ? 3
          : pct >= 70
              ? 2
              : 1,
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'percentage': percentage,
        'stars': stars,
        'score': score,
      };
}
```

## File: lib/providers/auth_provider.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final Student? student;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.student,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    Student? student,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingLogin();
  }

  final _api = ApiService();

  Future<void> _checkExistingLogin() async {
    final hasToken = await StorageService.hasToken();
    if (hasToken) {
      final student = StorageService.getStudent();
      if (student != null) {
        state = AuthState(student: student, isLoggedIn: true);
      }
    }
  }

  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(
        classCode: classCode,
        username: username,
        name: name,
        password: password,
      );
      final student =
          Student.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(
        student: student,
        isLoggedIn: true,
        isLoading: false,
      );
      // Retry any results that were queued while logged out or with an
      // expired token — now that we have a fresh one, this should succeed.
      _api.flushPendingResults();
      return {'success': true, 'isNewStudent': data['isNewStudent'] ?? false};
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return {'success': false};
    }
  }

  Future<void> refreshProfile() async {
    try {
      final student = await _api.getProfile();
      state = state.copyWith(student: student);
    } catch (_) {
      // Use cached data
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
```

## File: lib/screens/auth/login_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _classCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  bool _isNewStudent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).login(
          classCode: _classCodeController.text.trim(),
          username: _usernameController.text.trim(),
          name: _isNewStudent ? _nameController.text.trim() : null,
          password: _passwordController.text,
        );

    if (result['success'] == true && mounted) {
      context.go('/character-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (screenSize.width > 700) ...[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_stories,
                                size: 44,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'CHRONOQUEST',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 22,
                                height: 1.4,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tuklasin ang Kasaysayan\nng Pilipinas',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 17,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],

                    Container(
                      width: screenSize.width > 700 ? 380 : 340,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.primaryDark, width: 3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark,
                            offset: Offset(5, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                border: Border.all(
                                    color: AppColors.primaryDark, width: 2),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isNewStudent = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        color: _isNewStudent ? AppColors.primary : Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Bago',
                                          style: GoogleFonts.pixelifySans(
                                            color: _isNewStudent ? Colors.white : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isNewStudent = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        color: !_isNewStudent ? AppColors.primary : Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Babalik',
                                          style: GoogleFonts.pixelifySans(
                                            color: !_isNewStudent ? Colors.white : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('Class Code'),
                            TextFormField(
                              controller: _classCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _inputDeco(Icons.class_, 'e.g. CQ-G5A1'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang class code' : null,
                            ),
                            const SizedBox(height: 12),

                            _buildLabel('Username'),
                            TextFormField(
                              controller: _usernameController,
                              decoration: _inputDeco(Icons.alternate_email, 'e.g. JuanNinja99'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang username' : null,
                            ),
                            const SizedBox(height: 12),

                            if (_isNewStudent) ...[
                              _buildLabel('Tunay na Pangalan'),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDeco(Icons.person, 'Buong pangalan para kay titser'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang tunay na pangalan' : null,
                              ),
                              const SizedBox(height: 12),
                            ],

                            _buildLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _inputDeco(Icons.lock, 'Lagyan ng password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Kailangan ang password';
                                if (v.length < 6) return 'Hindi bababa sa 6 na characters';
                                return null;
                              },
                            ),

                            if (_isNewStudent) ...[
                              const SizedBox(height: 12),
                              _buildLabel('Kumpirmahin ang Password'),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                decoration: _inputDeco(Icons.lock_outline, 'Ulitin ang password').copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Kailangan kumpirmahin ang password';
                                  if (v != _passwordController.text) return 'Hindi magkatugma ang password';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 8),

                            if (authState.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 16),

                            authState.isLoading
                                ? const SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  )
                                : PixelButton(
                                    label: _isNewStudent
                                        ? 'SUMALI SA KLASE'
                                        : 'MAG-LOGIN',
                                    fontSize: 11,
                                    width: double.infinity,
                                    onPressed: _login,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.pixelifySans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accent, width: 3),
      ),
      errorStyle: const TextStyle(height: 0.8),
    );
  }
}
```

## File: lib/screens/game/era_complete_screen.dart
```dart
// Destination in your repo: lib/screens/game/era_complete_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/pixel_ui.dart';

class EraCompleteScreen extends StatefulWidget {
  final String eraId;
  const EraCompleteScreen({super.key, required this.eraId});

  @override
  State<EraCompleteScreen> createState() => _EraCompleteScreenState();
}

class _EraCompleteScreenState extends State<EraCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Baseline is now the average of Levels 1-9 ("pre_test" type results),
  // not a separate cold pre-test. Both are nullable so we can tell the
  // difference between "0%" and "no data yet" instead of faking numbers.
  double? levelsAverage;
  int? postTestScore;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _loadScores();
  }

  Future<void> _loadScores() async {
    try {
      final results = await ApiService().getResults();
      final eraResults =
          results.where((r) => r.era == widget.eraId).toList();

      final levels = eraResults.where((r) => r.type == 'pre_test');
      final post = eraResults.where((r) => r.type == 'post_test');

      setState(() {
        levelsAverage = levels.isNotEmpty
            ? levels
                    .map((r) => r.percentage.toDouble())
                    .reduce((a, b) => a + b) /
                levels.length
            : null;
        postTestScore = post.isNotEmpty ? post.first.percentage : null;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get hasCompleteData => levelsAverage != null && postTestScore != null;

  // Learning Gain = Boss (Level 10) score - Average(Levels 1-9)
  int get learningGain =>
      hasCompleteData ? (postTestScore! - levelsAverage!.round()) : 0;

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fireworks placeholder (animated particles)
                      SizedBox(
                        height: 60,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (i) {
                                final offset =
                                    ((_controller.value + i * 0.2) % 1.0) *
                                        40;
                                return Transform.translate(
                                  offset: Offset(0, -offset),
                                  child: Opacity(
                                    opacity: 1.0 -
                                        (_controller.value + i * 0.2) %
                                            1.0,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: i.isEven
                                          ? AppColors.accent
                                          : Colors.orangeAccent,
                                      size: 20,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),

                      // Title
                      Text(
                        'ERA TAPOS NA!',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 20,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        era.name,
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (!hasCompleteData) ...[
                        // Honest empty/error state instead of fake numbers
                        PixelPanel(
                          color: AppColors.surface,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.all(20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.textMuted, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  hasError
                                      ? 'Hindi ma-load ang iyong mga score ngayon. Subukang buksan muli ang page na ito.'
                                      : 'Kulang pa ang datos para makita ang iyong Learning Gain.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.pixelifySans(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Score comparison card
                        PixelPanel(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                            children: [
                              // Levels 1-9 average (the real pre-test baseline)
                              _ScoreRow(
                                label: 'Average sa mga Level (1–9):',
                                percentage: levelsAverage!.round(),
                                color: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              // Boss level (post-test)
                              _ScoreRow(
                                label: 'Panghuling Pagsubok (Boss):',
                                percentage: postTestScore!,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 20),

                              // Learning gain
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: learningGain >= 20
                                      ? AppColors.success
                                          .withValues(alpha: 0.1)
                                      : learningGain >= 10
                                          ? AppColors.success
                                              .withValues(alpha: 0.08)
                                          : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: learningGain >= 20
                                        ? AppColors.success
                                            .withValues(alpha: 0.3)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      learningGain >= 20
                                          ? Icons.emoji_events
                                          : learningGain >= 10
                                              ? Icons.thumb_up
                                              : Icons.trending_up,
                                      color: learningGain >= 20
                                          ? AppColors.accent
                                          : AppColors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${learningGain >= 0 ? '+' : ''}$learningGain% Natuto Ka!',
                                          style: GoogleFonts.pressStart2p(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        Text(
                                          learningGain >= 20
                                              ? 'Napakagaling! 🏆'
                                              : learningGain >= 10
                                                  ? 'Magaling ka! 👍'
                                                  : 'Patuloy lang! 💪',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color:
                                                AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Next era button
                      PixelButton(
                        label: 'SUSUNOD NA PANAHON',
                        fontSize: 11,
                        width: 280,
                        onPressed: () {
                          context.go('/era-selection');
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
        return const Color(0xFF4E342E);
      case 'american':
        return const Color(0xFF0D47A1);
      case 'ww2':
        return const Color(0xFF37474F);
      case 'modern':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF4E342E);
    }
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.pixelifySans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: PixelProgressBar(
            value: percentage / 100,
            fillColor: color,
            height: 14,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
```

## File: lib/screens/game/level_complete_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';

class LevelCompleteScreen extends StatefulWidget {
  final String eraId;
  final int level;
  const LevelCompleteScreen({
    super.key,
    required this.eraId,
    required this.level,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // These would come from game state in a real scenario
  int get _correct => 7 + (widget.level % 3);
  int get _total => 10;
  int get _percentage => (_correct / _total * 100).round();
  int get _stars => _percentage >= 90 ? 3 : _percentage >= 70 ? 2 : 1;
  int get _points => _correct * 10 + (_percentage >= 90 ? 50 : 0);

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            // SingleChildScrollView fixes the overflow bug — this card's
            // content (badge + stars + score + points + era + optional
            // powerup badge + button) could exceed a short landscape
            // phone's height and push the SUSUNOD button off-screen.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: PixelPanel(
                  color: AppColors.surface,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.accent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Level Complete" header
                        PixelBadge(
                          text: 'LEVEL ${widget.level} TAPOS!',
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                        const SizedBox(height: 18),

                        // Stars animation
                        AnimatedBuilder(
                          animation: _starController,
                          builder: (context, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final delay = i * 0.3;
                                final progress =
                                    ((_starController.value - delay) / 0.4)
                                        .clamp(0.0, 1.0);
                                final show = i < _stars && progress > 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Transform.scale(
                                    scale: show ? progress : 0.5,
                                    child: Icon(
                                      show ? Icons.star : Icons.star_border,
                                      color: show
                                          ? AppColors.accent
                                          : AppColors.textMuted,
                                      size: 40,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Score
                        Text(
                          '$_correct/$_total TAMA',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Points earned
                        PixelBadge(
                          text: '+$_points PUNTOS',
                          color: AppColors.success,
                          textColor: Colors.white,
                          fontSize: 10,
                        ),
                        const SizedBox(height: 10),

                        // Era info
                        Text(
                          era.name,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),

                        // Powerup earned indicator
                        if (widget.level == 3 || widget.level == 7)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: PixelPanel(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderWidth: 2,
                              shadowOffset: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_giftcard,
                                      color: AppColors.accent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getPowerupName(widget.level),
                                    style: GoogleFonts.pixelifySans(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 22),

                        // Next button
                        PixelButton(
                          label: 'SUSUNOD',
                          width: double.infinity,
                          onPressed: () {
                            context.go('/level-select/${widget.eraId}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPowerupName(int level) {
    switch (level) {
      case 3:
        return 'Nakakuha ng 50/50!';
      case 7:
        return 'Nakakuha ng Shield!';
      default:
        return '';
    }
  }
}
```

## File: lib/screens/game/level_select_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/storage_service.dart';

class LevelSelectScreen extends StatefulWidget {
  final String eraId;
  const LevelSelectScreen({super.key, required this.eraId});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Map<int, int> completedLevels = {};

  @override
  void initState() {
    super.initState();
    completedLevels = StorageService.getCompletedLevels(widget.eraId);
  }

  bool _isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 10) return completedLevels.length >= 9;
    return completedLevels.containsKey(level - 1);
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId).withValues(alpha: 0.6),
              _getEraColor(widget.eraId).withValues(alpha: 0.3),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/era-selection'),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        era.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              // Level milestones
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(10, (i) {
                        final level = i + 1;
                        final isUnlocked = _isLevelUnlocked(level);
                        final isCompleted =
                            completedLevels.containsKey(level);
                        final stars = completedLevels[level] ?? 0;
                        final isBoss = level == 10;

                        return Row(
                          children: [
                            // Road connector
                            if (i > 0)
                              Container(
                                width: 30,
                                height: 4,
                                color: isCompleted || isUnlocked
                                    ? AppColors.accent.withValues(alpha: 0.6)
                                    : Colors.white24,
                              ),
                            // Level node
                            GestureDetector(
                              onTap: isUnlocked
                                  ? () => context.go(
                                      '/game/${widget.eraId}/$level')
                                  : null,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Stars
                                  if (isCompleted)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        3,
                                        (s) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          child: Image.asset(
                                            s < stars
                                                ? 'assets/ui/star_full.png'
                                                : 'assets/ui/star_empty.png',
                                            width: 14,
                                            height: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 14),
                                  const SizedBox(height: 4),
                                  // Node circle
                                  Container(
                                    width: isBoss ? 60 : 48,
                                    height: isBoss ? 60 : 48,
                                    decoration: BoxDecoration(
                                      shape: isBoss
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                      borderRadius: isBoss
                                          ? BorderRadius.circular(12)
                                          : null,
                                      color: isCompleted
                                          ? AppColors.accent
                                          : isUnlocked
                                              ? AppColors.primary
                                              : Colors.grey.shade700,
                                      border: Border.all(
                                        color: isCompleted
                                            ? AppColors.accent
                                            : isUnlocked
                                                ? Colors.white54
                                                : Colors.grey,
                                        width: 2.5,
                                      ),
                                      boxShadow: isUnlocked
                                          ? [
                                              BoxShadow(
                                                color: (isCompleted
                                                        ? AppColors.accent
                                                        : AppColors.primary)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 22)
                                          : !isUnlocked
                                              ? Image.asset(
                                                  'assets/ui/lock_icon.png',
                                                  color: Colors.white38,
                                                  width: 18,
                                                  height: 18,
                                                )
                                              : Text(
                                                  isBoss ? 'BOSS' : '$level',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        isBoss ? 12 : 16,
                                                  ),
                                                ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBoss ? 'Level 10' : 'Level $level',
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? Colors.white70
                                          : Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // Bottom info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${completedLevels.length}/10 Levels Tapos',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
        return const Color(0xFF4E342E);
      case 'american':
        return const Color(0xFF0D47A1);
      case 'ww2':
        return const Color(0xFF37474F);
      case 'modern':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF4E342E);
    }
  }
}
```

## File: lib/screens/home/character_selection_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/pixel_ui.dart';

class CharacterSelectionScreen extends ConsumerStatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  ConsumerState<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState
    extends ConsumerState<CharacterSelectionScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.55, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showMechanics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: AppColors.primaryDark, width: 3),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paano Maglaro',
              style: GoogleFonts.pressStart2p(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _mechanicRow(Icons.touch_app, 'I-tap ang screen para tumalon sa mga hadlang'),
            _mechanicRow(Icons.quiz, 'Talunin ang kaaway sa pamamagitan ng tamang sagot'),
            _mechanicRow(Icons.favorite, 'Maling sagot = mawawalan ng puso'),
            _mechanicRow(Icons.bolt, 'Gumamit ng powerups para sa mahirap na tanong'),
            _mechanicRow(Icons.flag, 'Tapusin lahat ng 10 level para makumpleto ang era'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _mechanicRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.pixelifySans(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          // Column instead of a Stack of fixed top/bottom-offset
          // Positioned widgets — the old layout assumed a fixed screen
          // height and the character cards could overflow their
          // allotted band on shorter landscape phones. A Column with
          // Expanded lets the carousel take exactly whatever space is
          // actually left after the header and footer, on any screen.
          child: Column(
            children: [
              // Header row: side buttons + title
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    _SideIconButton(
                      icon: Icons.menu_book,
                      tooltip: 'Mechanics',
                      onTap: _showMechanics,
                    ),
                    const SizedBox(width: 6),
                    _SideIconButton(
                      icon: Icons.emoji_events,
                      tooltip: 'Leaderboard',
                      onTap: () => context.push('/leaderboard'),
                    ),
                    Expanded(
                      child: Text(
                        'PILIIN ANG IYONG BAYANI',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    // Spacer matching the two side buttons' width so the
                    // title stays visually centered.
                    const SizedBox(width: 84),
                  ],
                ),
              ),

              // Character carousel — takes whatever vertical space is
              // left, on any screen size.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _selectedIndex = i),
                  itemCount: allCharacters.length,
                  itemBuilder: (context, index) {
                    final char = allCharacters[index];
                    final isSelected = index == _selectedIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isSelected ? 6 : 18,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.primaryDark,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.primaryDark,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Character avatar — real sprite, falls back
                            // to an initial if the asset is ever missing.
                            Container(
                              width: 64,
                              height: 64,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: _getCharColor(char.id),
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/characters/${char.id}_walk_1.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Center(
                                  child: Text(
                                    char.name[0],
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              char.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              char.era,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  char.description,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Footer: dots + start button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: List.generate(
                        allCharacters.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _selectedIndex ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _selectedIndex
                                ? AppColors.accent
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    PixelButton(
                      label: 'SIMULA!',
                      fontSize: 12,
                      onPressed: () {
                        ref
                            .read(gameProvider.notifier)
                            .selectCharacter(allCharacters[_selectedIndex].id);
                        context.go('/era-selection');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCharColor(String id) {
    switch (id) {
      case 'lapu':
        return const Color(0xFF6B3A1F);
      case 'rizal':
        return const Color(0xFF2C3E50);
      case 'mabini':
        return const Color(0xFF1A5276);
      case 'escoda':
        return const Color(0xFFC0392B);
      case 'aquino':
        return const Color(0xFFD4AC0D);
      default:
        return const Color(0xFF2C3E50);
    }
  }
}

class _SideIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SideIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
      ),
    );
  }
}
```

## File: lib/services/storage_service.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/student.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'student_token';
  static const _studentKey = 'student_data';
  static const _characterKey = 'selected_character';

  // ─── JWT TOKEN ─────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ─── STUDENT DATA (Hive) ──────────────────────────────────────────────────
  static Box? _appBox;

  static Future<void> initHive() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox('chronoquest');
  }

  static Box get appBox {
    _appBox ??= Hive.box('chronoquest');
    return _appBox!;
  }

  static Future<void> saveStudent(Student student) async {
    await appBox.put(_studentKey, student.toJson());
  }

  static Student? getStudent() {
    final data = appBox.get(_studentKey);
    if (data == null) return null;
    return Student.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── CHARACTER SELECTION ──────────────────────────────────────────────────
  static Future<void> saveCharacter(String characterId) async {
    await appBox.put(_characterKey, characterId);
  }

  static String getCharacter() {
    return appBox.get(_characterKey, defaultValue: 'rizal') as String;
  }

  // ─── ERA PROGRESS CACHE ───────────────────────────────────────────────────
  static Future<void> cacheEraProgress(
      String eraId, Map<String, dynamic> progress) async {
    await appBox.put('era_progress_$eraId', progress);
  }

  static Map<String, dynamic>? getCachedEraProgress(String eraId) {
    final data = appBox.get('era_progress_$eraId');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // ─── LEVEL PROGRESS ──────────────────────────────────────────────────────
  static Future<void> saveLevelCompleted(
      String eraId, int level, int stars) async {
    final key = 'levels_$eraId';
    final Map<dynamic, dynamic> levels =
        Map<dynamic, dynamic>.from(appBox.get(key, defaultValue: {}) as Map);
    levels[level.toString()] = stars;
    await appBox.put(key, levels);
  }

  static Map<int, int> getCompletedLevels(String eraId) {
    final key = 'levels_$eraId';
    final data = appBox.get(key);
    if (data == null) return {};
    final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(data as Map);
    return raw.map(
        (k, v) => MapEntry(int.parse(k.toString()), v as int));
  }

  // ─── PENDING RESULTS (offline queue) ──────────────────────────────────────
  static const _pendingResultsKey = 'pending_results';

  static Future<void> queuePendingResult(Map<String, dynamic> resultJson) async {
    final List<dynamic> pending =
        List<dynamic>.from(appBox.get(_pendingResultsKey, defaultValue: []) as List);
    pending.add(resultJson);
    await appBox.put(_pendingResultsKey, pending);
  }

  static List<Map<String, dynamic>> getPendingResults() {
    final List<dynamic> pending =
        List<dynamic>.from(appBox.get(_pendingResultsKey, defaultValue: []) as List);
    return pending.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> clearPendingResults() async {
    await appBox.put(_pendingResultsKey, []);
  }

  // ─── CLEAR ALL ────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    await appBox.clear();
  }
}
```

## File: lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'data/question_bank.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape for game experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar for immersive game
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive for local storage
  await StorageService.initHive();

  // Load quiz questions from assets/data/*.json before any screen can ask
  // QuestionBank for questions. This replaced a ~5,300-line hardcoded Dart
  // literal, so it's no longer instant/synchronous — it must complete
  // before the first level starts.
  await QuestionBank.loadAll();

  // Retry any quiz results that failed to submit while offline last session.
  // Fire-and-forget: don't block app launch on network access, and any
  // still-unsent results just stay queued for the next attempt.
  ApiService().flushPendingResults();

  runApp(
    const ProviderScope(
      child: ChronoQuestApp(),
    ),
  );
}
```

## File: lib/game/components/boss_component.dart
```dart
import 'package:flame/components.dart';
import '../chrono_game.dart';
import '../../core/constants.dart';

/// Boss component — displays actual images for idle, attack, and defeated states.
class BossComponent extends SpriteComponent with HasGameReference<ChronoGame> {
  final String eraId;
  int health = GameConstants.bossHealth;
  int maxHealth = GameConstants.bossHealth;
  bool reachedCenter = false;
  static const double walkSpeed = 50.0;
  bool isDefeated = false;

  late Sprite idleSprite;
  late Sprite attackSprite;
  late Sprite defeatedSprite;

  // Cached velocity
  final Vector2 _velocity = Vector2.zero();
  int _bossQuestionIndex = 0;

  BossComponent({required this.eraId});

  @override
  Future<void> onLoad() async {
    final bossName = _getBossNameForEra(eraId);
    idleSprite     = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');

    sprite = idleSprite;
    size = Vector2(120, 140);
    position = Vector2(game.size.x + 20, game.groundY - size.y);
    game.audioService.playBossAppear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (!reachedCenter) {
      _velocity.setValues(-walkSpeed, 0);
      position.addScaled(_velocity, dt);
      final centerX = game.size.x / 2 - size.x / 2;
      if (position.x <= centerX) {
        position.x = centerX;
        reachedCenter = true;
        _showBossQuestion();
      }
    }
  }

  void takeDamage() {
    health--;
    sprite = attackSprite;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!isDefeated) {
        sprite = idleSprite;
      }
    });

    if (health <= 0) {
      defeat();
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!isDefeated) {
          _showBossQuestion();
        }
      });
    }
  }

  void defeat() {
    isDefeated = true;
    sprite = defeatedSprite;
    game.audioService.playBossDefeat();
    game.overlays.remove('BossHealthOverlay');
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
      game.levelComplete();
    });
  }

  void _showBossQuestion() {
    if (_bossQuestionIndex >= game.bossQuestions.length) return;
    final q = game.bossQuestions[_bossQuestionIndex];
    _bossQuestionIndex++;
    game.showBossQuestion(q, this);
  }

  String _getBossNameForEra(String era) {
    const names = {
      'pre-colonial': 'bakunawa',
      'spanish':      'governor',
      'american':     'general',
      'ww2':          'commander',
      'modern':       'corruption_boss',
    };
    return names[era] ?? 'governor';
  }
}
```

## File: lib/game/components/player_component.dart
```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'wall_component.dart';
/// Player character — runs at fixed X position, student taps to jump.
/// Displays real walk, jump, and hurt sprite animations.
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;

  double velocityY = 0.0;
  bool isOnGround = false;
  bool isHurt = false;
  final String characterId;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation jumpAnim;
  late SpriteAnimation hurtAnim;

  PlayerComponent({required this.characterId});

  @override
  Future<void> onLoad() async {
    size = Vector2(64, 80);
    position = Vector2(80, game.groundY - size.y);

    // Load walk frames as individual sprites and build the animation sequence
    final walkSprites = <Sprite>[];
    for (int i = 1; i <= 4; i++) {
      try {
        walkSprites.add(await game.loadSprite('characters/${characterId}_walk_$i.png'));
      } catch (e) {
        // Safe fallback placeholder if asset fails to load
        debugPrint('Failed to load character walk frame $i: $e');
      }
    }

    if (walkSprites.isNotEmpty) {
      walkAnimation = SpriteAnimation.spriteList(walkSprites, stepTime: 0.15);
    } else {
      // Emergency blank animation fallback
      walkAnimation = SpriteAnimation.spriteList([], stepTime: 1.0);
    }

    // Load single jump and hurt frames
    jumpAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_jump.png')],
      stepTime: 1.0,
    );
    hurtAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_hurt.png')],
      stepTime: 0.3,
    );

    animation = walkAnimation;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    // Check if on any ground section
    bool onGround = false;
    for (final section in game.groundSections) {
      if (position.x + size.x > section.position.x &&
          position.x < section.position.x + section.size.x &&
          position.y + size.y >= section.position.y &&
          position.y + size.y <= section.position.y + 20) {
        position.y = section.position.y - size.y;
        velocityY = 0;
        onGround = true;
        break;
      }
    }
    // Landed after a jump — swap back from the jump pose to the running
    // animation. Without this, the player stayed frozen in the jump frame
    // for the rest of the level after the first jump.
    if (onGround && !isOnGround && !isHurt) {
      animation = walkAnimation;
    }
    isOnGround = onGround;

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }

    // Ground clamp fallback
    if (position.y >= game.groundY - size.y && !isOnGround) {
      position.y = game.groundY - size.y;
      velocityY = 0;
      if (!isHurt) animation = walkAnimation;
      isOnGround = true;
    }
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      game.audioService.playJump();
    }
  }

  void triggerHurt() {
    isHurt = true;
    animation = hurtAnim;
    game.audioService.playHurt();
    Future.delayed(const Duration(milliseconds: 600), () {
      isHurt = false;
      if (isOnGround) {
        animation = walkAnimation;
      }
    });
  }

  void respawn() {
    position = Vector2(80, game.groundY - size.y);
    velocityY = 0;
    isOnGround = true;
    animation = walkAnimation;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyComponent && !game.questionShowing && !other.defeated) {
      game.showQuestion(other.question, other);
    }
    if (other is CoinComponent && !other.collected) {
      other.collect();
      game.collectCoin();
    }
    if (other is WallComponent && !isHurt) {
      // Player failed to jump over the wall in time — this used to snap
      // the player's position up onto the wall (looked like an automatic,
      // unintended jump) with no actual consequence. Now it deals damage,
      // consistent with falling in a gap, and the wall is removed so it
      // can't linger and double-hit on subsequent frames.
      other.removeFromParent();
      game.playerHitObstacle();
    }
  }
}
```

## File: lib/game/overlays/pause_overlay.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
import '../chrono_game.dart';

/// Pause menu overlay — resume or quit.
class PauseOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const PauseOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PixelPanel(
              color: AppColors.surface,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PAUSE',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 20,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resume button
                  PixelButton(
                    label: 'ITULOY',
                    icon: Icons.play_arrow,
                    color: AppColors.success,
                    textColor: Colors.white,
                    width: 220,
                    onPressed: () {
                      game.overlays.remove('PauseOverlay');
                      game.resumeEngine();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quit button
                  PixelButton(
                    label: 'UMALIS',
                    icon: Icons.exit_to_app,
                    color: AppColors.surfaceAlt,
                    textColor: AppColors.danger,
                    width: 220,
                    onPressed: () => _confirmQuit(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
        title: Text(
          'Umalis sa Level?',
          style: GoogleFonts.pressStart2p(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Mawawala ang iyong progress sa level na ito kung aalis ka ngayon.',
          style: GoogleFonts.pixelifySans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Kanselahin',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.overlays.remove('PauseOverlay');
              game.resumeEngine();
              Navigator.of(game.buildContext!).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              'Umalis',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
```

## File: lib/game/overlays/question_overlay.dart
```dart
import 'dart:async' as async;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
import '../chrono_game.dart';

/// Question overlay — pure Flutter widget displayed over Flame canvas.
/// Shows quiz question with 2×2 answer grid, timer, and powerup buttons.
class QuestionOverlayWidget extends StatefulWidget {
  final ChronoGame game;
  final Function(String answer) onAnswer;
  const QuestionOverlayWidget({
    super.key,
    required this.game,
    required this.onAnswer,
  });

  @override
  State<QuestionOverlayWidget> createState() => _QuestionOverlayWidgetState();
}

class _QuestionOverlayWidgetState extends State<QuestionOverlayWidget>
    with SingleTickerProviderStateMixin {
  bool answered = false;
  String? selectedAnswer;
  int secondsElapsed = 0;
  late async.Timer timer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Track which options are hidden by 50/50
  List<String> hiddenOptions = [];

  @override
  void initState() {
    super.initState();
    widget.game.currentQuestion?.elapsedSeconds = 0;
    timer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !answered) {
        setState(() {
          secondsElapsed++;
          widget.game.currentQuestion?.elapsedSeconds = secondsElapsed;
        });
      }
    });

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    timer.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void handleTap(String answer) {
    if (answered) return;
    setState(() {
      answered = true;
      selectedAnswer = answer;
    });

    final isCorrect =
        answer == widget.game.currentQuestion!.correctAnswer;
    if (isCorrect) {
      widget.game.audioService.playCorrect();
      // Correct answers keep the game moving at a brisk pace.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onAnswer(answer);
      });
    } else {
      widget.game.audioService.playWrong();
      // Wrong answers show the explanation inline (see build()) and wait
      // for the player to tap "Susunod" — don't force-pace text they
      // can't control by auto-advancing.
    }
  }

  void _continueAfterWrongAnswer() {
    final answer = selectedAnswer;
    if (answer == null) return;
    widget.onAnswer(answer);
  }

  void _useFiftyFifty() {
    final question = widget.game.currentQuestion;
    if (question == null) return;
    if (widget.game.playerPowerUps.fiftyFifty <= 0) return;

    widget.game.playerPowerUps.fiftyFifty--;
    widget.game.audioService.playPowerup();

    // Hide 2 wrong options
    final wrongOptions = question.options
        .where((o) => o.label != question.correctAnswer)
        .toList();
    wrongOptions.shuffle();
    setState(() {
      hiddenOptions = wrongOptions.take(2).map((o) => o.label).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return GestureDetector(
      // Block tap-to-jump while question is showing
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.primaryDark, width: 3),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: AppColors.accent, width: 2),
                          ),
                          child: Text(
                            'HAMON',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 9,
                              height: 1.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: secondsElapsed > 15
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: secondsElapsed > 15
                                  ? AppColors.danger
                                  : AppColors.primaryDark,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: secondsElapsed > 15
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${secondsElapsed}s',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 10,
                                  height: 1.4,
                                  color: secondsElapsed > 15
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question text
                    Text(
                      question.questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Answer buttons — 2×2 grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: question.options.map((option) {
                        if (hiddenOptions.contains(option.label)) {
                          return const SizedBox.shrink();
                        }

                        Color buttonColor = AppColors.surface;
                        Color borderColor = AppColors.border;

                        if (answered) {
                          if (option.label == question.correctAnswer) {
                            buttonColor =
                                AppColors.success.withValues(alpha: 0.15);
                            borderColor = AppColors.success;
                          } else if (option.label == selectedAnswer) {
                            buttonColor =
                                AppColors.danger.withValues(alpha: 0.15);
                            borderColor = AppColors.danger;
                          }
                        }

                        return Semantics(
                          button: true,
                          label: 'Sagot ${option.label}: ${option.text}',
                          selected: answered && option.label == selectedAnswer,
                          child: GestureDetector(
                          onTap: () => handleTap(option.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              border:
                                  Border.all(color: borderColor, width: 2.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${option.label}) ${option.text}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: answered &&
                                        option.label ==
                                            question.correctAnswer
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Explanation — shown inline after a wrong answer so the
                    // player sees *why* before the game moves on. They tap
                    // Continue when ready, rather than it auto-advancing.
                    if (answered && selectedAnswer != question.correctAnswer)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    size: 18, color: AppColors.accent),
                                const SizedBox(width: 6),
                                const Text(
                                  'Paliwanag',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.explanation.isNotEmpty
                                  ? question.explanation
                                  : 'Ang tamang sagot ay ${question.correctAnswer}.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PixelButton(
                              label: 'SUSUNOD',
                              fontSize: 11,
                              width: double.infinity,
                              onPressed: _continueAfterWrongAnswer,
                            ),
                          ],
                        ),
                      )
                    else if (!widget.game.bossPhase)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PowerupButton(
                            icon: Icons.filter_2,
                            label: '50/50',
                            count: widget.game.playerPowerUps.fiftyFifty,
                            onTap: _useFiftyFifty,
                            enabled: !answered &&
                                hiddenOptions.isEmpty,
                          ),
                          const SizedBox(width: 16),
                          _PowerupButton(
                            icon: Icons.shield,
                            label: 'Shield',
                            count: widget.game.playerPowerUps.shield,
                            onTap: () {
                              if (widget.game.playerPowerUps.shield > 0) {
                                widget.game.shieldActive = true;
                                widget.game.playerPowerUps.shield--;
                                widget.game.audioService.playPowerup();
                                setState(() {});
                              }
                            },
                            enabled: !answered &&
                                widget.game.playerPowerUps.shield > 0 &&
                                !widget.game.shieldActive,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool enabled;

  const _PowerupButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isUsable = enabled && count > 0;
    return GestureDetector(
      onTap: isUsable ? onTap : null,
      child: Opacity(
        opacity: isUsable ? 1.0 : 0.4,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUsable ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                '$label ×$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## File: lib/screens/home/era_selection_screen.dart
```dart
// Destination in your repo: lib/screens/home/era_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  @override
  ConsumerState<EraSelectionScreen> createState() =>
      _EraSelectionScreenState();
}

class _EraSelectionScreenState extends ConsumerState<EraSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(progressProvider.notifier).loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final progressState = ref.watch(progressProvider);
    final student = authState.student;
    final gradeLevel = student?.gradeLevel ?? 'grade5';

    // Filter eras by grade level
    final visibleEras = allEras
        .where((era) =>
            eraGradeMap[era.id]?.contains(gradeLevel) ?? false)
        .toList();

    final visibleEraIds = visibleEras.map((e) => e.id).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bookshelf_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/character-selection'),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        'PILIIN ANG PANAHON',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Era books shelf
              Expanded(
                child: progressState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: visibleEras.asMap().entries.map((entry) {
                            final index = entry.key;
                            final era = entry.value;
                            final progress = ref
                                .read(progressProvider.notifier)
                                .getEraProgress(era.id);
                            final isUnlocked = ref
                                .read(progressProvider.notifier)
                                .isEraUnlocked(era.id, visibleEraIds);

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: _EraBook(
                                  era: era,
                                  progress: progress,
                                  isUnlocked: isUnlocked,
                                  index: index,
                                  onTap: isUnlocked
                                      ? () {
                                          // No more separate cold pre-test —
                                          // first visit goes straight to the
                                          // background reading, then into
                                          // Level 1 (which doubles as the
                                          // real pre-test baseline).
                                          if (progress.levelsCompleted > 0) {
                                            context.go(
                                                '/level-select/${era.id}');
                                          } else {
                                            context.go(
                                                '/background/${era.id}');
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),

              // Student info bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (student?.name.isNotEmpty ?? false)
                            ? student!.name[0]
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      student?.name ?? 'Student',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Image.asset('assets/ui/star_full.png',
                        width: 18, height: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${student?.score ?? 0} pts',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EraBook extends StatelessWidget {
  final EraData era;
  final dynamic progress;
  final bool isUnlocked;
  final int index;
  final VoidCallback? onTap;

  const _EraBook({
    required this.era,
    required this.progress,
    required this.isUnlocked,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isCompleted;
    final isInProgress = progress.isInProgress;
    final levelsCompleted = progress.levelsCompleted as int;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Book spine
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: (isCompleted
                        ? const Color(0xFFD4AF37)
                        : isUnlocked
                            ? _getEraBookColor(era.id)
                            : Colors.grey.shade700)
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : Colors.grey,
                  width: 1.5,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: _getEraBookColor(era.id)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Book content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompleted)
                          Image.asset('assets/ui/star_full.png',
                              width: 28, height: 28)
                        else if (!isUnlocked)
                          Image.asset('assets/ui/lock_icon.png',
                              width: 26, height: 26)
                        else
                          Icon(Icons.auto_stories,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 28),
                        const SizedBox(height: 6),
                        Text(
                          era.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  if (isInProgress)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$levelsCompleted/10',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              era.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Color _getEraBookColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF2E7D32);
      case 'spanish':
        return const Color(0xFF8B4513);
      case 'american':
        return const Color(0xFF1565C0);
      case 'ww2':
        return const Color(0xFF424242);
      case 'modern':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF8B4513);
    }
  }
}
```

## File: lib/core/constants.dart
```dart
import 'package:flutter/material.dart';

// ─── COLORS ─────────────────────────────────────────────────────────────────
// Retro pixel-adventure palette. Field names are unchanged from the old
// Material palette on purpose — every existing AppColors.xxx reference
// across the app picks up the new look automatically, no call sites needed
// touching just for color.
class AppColors {
  static const Color primary = Color(0xFF6B3A1F); // wood-brown UI chrome
  static const Color primaryDark = Color(0xFF2E1608); // thick pixel borders
  static const Color primaryLight = Color(0xFFB8763E);
  static const Color accent = Color(0xFFFFC531); // quest gold
  static const Color background = Color(0xFF140E1F); // night-map backdrop
  static const Color surface = Color(0xFFF5E3BE); // parchment panels
  static const Color surfaceAlt = Color(0xFFE8CE9C); // deeper parchment
  static const Color border = Color(0xFF2E1608); // pixel outline color
  static const Color textPrimary = Color(0xFF2A1707); // ink on parchment
  static const Color textSecondary = Color(0xFF6B4423);
  static const Color textMuted = Color(0xFFA9855C);
  static const Color success = Color(0xFF43A83E);
  static const Color danger = Color(0xFFE8433A);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF3D8FD1);
}

// ─── FONTS ──────────────────────────────────────────────────────────────────
// Press Start 2P: chunky pixel-game display face — titles, buttons, HUD
// numbers, short labels only (wide letterforms, hard to read in long
// lines). Pixelify Sans: a pixel-styled but far more readable face for
// anything a grade 4-5 student needs to actually read — quiz questions,
// explanations, paragraphs.
class AppFonts {
  static const String display = 'Press Start 2P';
  static const String body = 'Pixelify Sans';
}

// ─── API ────────────────────────────────────────────────────────────────────
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.43:5000/api/v1',
  );
}

// ─── GAME CONSTANTS ─────────────────────────────────────────────────────────
class GameConstants {
  static const double groundY = 520.0;
  static const double playerX = 80.0;
  static const double worldScrollSpeed = 150.0;
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;
  static const double enemySpeed = 90.0;
  static const double spawnInterval = 500.0;
  static const int livesPerLevel = 3;
  static const int questionsPerLevel = 5;       // levels 1-9
  static const int bossWarmupQuestions = 10;    // level 10, phase 1
  static const int bossFightQuestions = 12;     // level 10, phase 2
  static const int bossHealth = 12;             // one hit per boss-phase question
}

// ─── POINTS ─────────────────────────────────────────────────────────────────
class PointValues {
  static const int correctAnswer = 10;
  static const int speedBonus = 5;
  static const int coinCollected = 5;
  static const int artifactCollected = 15;
  static const int perfectLevel = 50;
  static const int completeEra = 100;
  static const int learningGainBonus = 75;
}

// ─── ERA-GRADE MAP ──────────────────────────────────────────────────────────
const Map<String, List<String>> eraGradeMap = {
  'pre-colonial': ['grade4', 'grade5'],
  'spanish': ['grade5'],
  'american': ['grade5', 'grade6'],
  'ww2': ['grade6'],
  'modern': ['grade6'],
};

// ─── ERA DATA ───────────────────────────────────────────────────────────────
class EraData {
  final String id;
  final String name;
  final String subtitle;
  final String guide;
  final List<String> enemyTypes;
  final String bossName;
  final String bossDialogue;
  final Color groundColor;
  final String historicalText;

  const EraData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.guide,
    required this.enemyTypes,
    required this.bossName,
    required this.bossDialogue,
    required this.groundColor,
    required this.historicalText,
  });
}

const List<EraData> allEras = [
  EraData(
    id: 'pre-colonial',
    name: 'Sinaunang Panahon',
    subtitle: 'Pre-colonial',
    guide: 'Datu Lapu-Lapu',
    enemyTypes: ['tribal_warrior', 'dark_spirit'],
    bossName: 'bakunawa',
    bossDialogue: 'Patunayan mo ang iyong karunungan!',
    groundColor: Color(0xFF5D4E37),
    historicalText:
        'Bago dumating ang mga mananakop, ang mga Pilipino ay nabuhay sa mga '
        'barangay — maliliit na komunidad na pinamumunuan ng isang datu. Ang bawat barangay '
        'ay may sariling kaugalian, tradisyon, at sistema ng pamahalaan. Ang mga sinaunang '
        'Pilipino ay mahusay na mangangalakal — nakipagpalakasan sila sa China, India, at '
        'iba pang bansa sa Asya. Gumamit sila ng baybayin, isang sistema ng pagsulat na '
        'orihinal na Filipino. Ang Labanan sa Mactan noong 1521 ay nagpakita ng lakas ng '
        'loob ng mga Pilipino nang ipagtanggol ni Datu Lapu-Lapu ang kanyang lupain.',
  ),
  EraData(
    id: 'spanish',
    name: 'Panahon ng Kastila',
    subtitle: 'Spanish Colonial 1565–1898',
    guide: 'Jose Rizal',
    enemyTypes: ['spanish_soldier', 'tax_collector'],
    bossName: 'governor',
    bossDialogue: 'Kaya mo bang harapin ang kapangyarihan ng Espanya?',
    groundColor: Color(0xFF808080),
    historicalText:
        'Noong 1565, nagsimula ang pananakop ng Espanya sa Pilipinas sa ilalim '
        'ni Miguel Lopez de Legazpi. Itinayo nila ang Intramuros sa Maynila bilang sentro '
        'ng kanilang kapangyarihan. Sa loob ng mahigit tatlong daang taon, kinontrol ng '
        'Espanya ang relihiyon, kalakalan, at pamahalaan ng bansa. Ang sistemang encomienda '
        'ay nagbigay ng lupain sa mga Espanyol. Naglunsad ng mga rebolusyon ang mga Pilipino '
        'laban sa pananakop — mula sa Dagohoy Rebellion hanggang sa Himagsikan ng 1896 '
        'na pinamunuan ni Andres Bonifacio at ang Katipunan.',
  ),
  EraData(
    id: 'american',
    name: 'Panahon ng Amerikano',
    subtitle: 'American Period 1898–1946',
    guide: 'Apolinario Mabini',
    enemyTypes: ['american_soldier', 'propaganda'],
    bossName: 'general',
    bossDialogue: 'Ipakita mo na hindi ka mabibili ng pangako ng kalayaan!',
    groundColor: Color(0xFF8B6914),
    historicalText:
        'Noong 1898, pagkatapos ng Digmaang Espanyol-Amerikano, inilipat ang '
        'Pilipinas sa Estados Unidos. Itinatag ng mga Amerikano ang sistema ng edukasyong '
        'pampubliko at nagpadala ng mga Thomasites — mga guro mula Amerika. Nagtagal ang '
        'pananakop ng Amerika at naglunsad ng Philippine-American War na nagkahalaga ng '
        'maraming buhay ng Pilipino. Noong 1935, naitatag ang Commonwealth ng Pilipinas na '
        'may Manuel Quezon bilang unang Pangulo, at noong Hulyo 4, 1946, opisyal na nakamit '
        'ng Pilipinas ang kalayaan.',
  ),
  EraData(
    id: 'ww2',
    name: 'Ikalawang Digmaang Pandaigdig',
    subtitle: 'World War II 1941–1945',
    guide: 'Josefa Llanes Escoda',
    enemyTypes: ['japanese_soldier', 'tank'],
    bossName: 'commander',
    bossDialogue: 'Ang kalayaan ay hindi ipinagkakaloob — kinukuha!',
    groundColor: Color(0xFF4A4A3A),
    historicalText:
        'Noong Disyembre 8, 1941, sinalakay ng Hapon ang Pilipinas. Naganap ang '
        'malupit na Bataan Death March noong Abril 1942. Sa ilalim ng pananakop ng Hapon, '
        'naghirap ang mga Pilipino. Nabuo ang mga gerilya na lumaban sa Hapon — kabilang '
        'ang Hukbalahap. Noong Oktubre 1944, bumalik si General Douglas MacArthur at '
        'nagsimula ang Labanan para sa Pilipinas. Ang Labanan ng Maynila noong 1945 ay '
        'isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig.',
  ),
  EraData(
    id: 'modern',
    name: 'Makabagong Panahon',
    subtitle: 'Modern 1946–present',
    guide: 'Corazon Aquino',
    enemyTypes: ['corruption_figure', 'misinfo_cloud'],
    bossName: 'corruption_boss',
    bossDialogue: 'Ang katotohanan ang iyong sandata!',
    groundColor: Color(0xFF555555),
    historicalText:
        'Noong Hulyo 4, 1946, opisyal na naging malaya ang Pilipinas. Sa mga '
        'sumunod na dekada, hinarap ng bansa ang maraming pagsubok — mula sa Marcos '
        'diktadura (1972–1986) hanggang sa People Power Revolution na nagluklok kay Corazon '
        'Aquino bilang Pangulo noong 1986. Ang EDSA Revolution ay naging simbolo ng '
        'kapangyarihan ng mamamayan sa buong mundo. Patuloy na lumalago ang Pilipinas '
        'bilang isang demokratikong bansa na nagtataguyod ng kalayaan, katarungan, at '
        'pagkakapantay-pantay para sa lahat ng Pilipino.',
  ),
];

// ─── CHARACTER DATA ─────────────────────────────────────────────────────────
class CharacterData {
  final String id;
  final String name;
  final String era;
  final String description;
  final int unlockCost;

  const CharacterData({
    required this.id,
    required this.name,
    required this.era,
    required this.description,
    this.unlockCost = 0,
  });
}

const List<CharacterData> allCharacters = [
  CharacterData(
    id: 'lapu',
    name: 'Datu Lapu-Lapu',
    era: 'Sinaunang Panahon',
    description: 'Bayani ng Mactan',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'rizal',
    name: 'Jose Rizal',
    era: 'Panahon ng Kastila',
    description: 'Pambansang Bayani',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'luna',
    name: 'Heneral Antonio Luna',
    era: 'Panahon ng Amerikano',
    description: 'Heneral ng Hukbong Pilipino',
    unlockCost: 100,
  ),
  CharacterData(
    id: 'bonifacio',
    name: 'Andres Bonifacio',
    era: 'Panahon ng Kastila',
    description: 'Ama ng Katipunan',
    unlockCost: 200,
  ),
  CharacterData(
    id: 'delpilar',
    name: 'Gregorio Del Pilar',
    era: 'Panahon ng Amerikano',
    description: 'Batang Heneral ng Tirad Pass',
    unlockCost: 300,
  ),
];

// Helper to look up era data by ID
EraData getEraById(String eraId) {
  return allEras.firstWhere(
    (e) => e.id == eraId,
    orElse: () => allEras[1], // default to spanish
  );
}
```

## File: lib/data/question_bank.dart
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';
import '../core/constants.dart';

/// Loads MELC-aligned quiz questions from JSON assets
/// (`assets/data/questions_<era>.json`) instead of hardcoding them as Dart
/// literals. Content edits now only require updating the JSON files, not
/// touching or recompiling Dart code.
///
/// Call [QuestionBank.loadAll] once during app startup (e.g. in main() before
/// runApp, or in a loading screen) before any call to [getQuestions].
class QuestionBank {
  static final Map<String, Map<int, List<Question>>> _bank = {};
  static bool _loaded = false;

  /// The eras with a corresponding `assets/data/questions_<era>.json` file.
  static const List<String> _eraIds = [
    'pre-colonial',
    'spanish',
    'american',
    'ww2',
    'modern',
  ];

  /// Loads and parses every era's question JSON into memory. Safe to call
  /// more than once — subsequent calls are a no-op.
  static Future<void> loadAll() async {
    if (_loaded) return;

    for (final eraId in _eraIds) {
      try {
        final raw = await rootBundle
            .loadString('assets/data/questions_$eraId.json');
        final Map<String, dynamic> decoded = json.decode(raw);

        final Map<int, List<Question>> levelMap = {};
        decoded.forEach((levelKey, questionsJson) {
          final level = int.parse(levelKey);
          levelMap[level] = (questionsJson as List<dynamic>)
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList();
        });

        _bank[eraId] = levelMap;
      } catch (e) {
        // Missing/corrupt JSON for an era shouldn't crash the whole app —
        // getQuestions() falls back to generated placeholder questions
        // for any era/level that didn't load.
        // ignore: avoid_print
        print('QuestionBank: failed to load questions for $eraId: $e');
      }
    }

    _loaded = true;
  }

  /// Retrieves local MELC-aligned questions for a given Era and Level.
  ///
  /// Requires [loadAll] to have completed first; if it hasn't, this falls
  /// back to generated placeholder questions rather than throwing, since a
  /// quiz should never hard-crash the game.
  static List<Question> getQuestions(String era, int level) {
    final eraMap = _bank[era];
    if (eraMap == null) return _fallbackQuestions(era, level);

    final questions = eraMap[level];
    if (questions == null || questions.isEmpty) {
      return _fallbackQuestions(era, level);
    }

    final targetCount = level == 10
        ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions // 22
        : GameConstants.questionsPerLevel; // 5

    if (questions.length < targetCount) {
      final padded = List<Question>.from(questions);
      final startIndex = padded.length;
      final grade = questions.isNotEmpty ? questions.first.gradeLevel : 'grade5';

      padded.addAll(List.generate(targetCount - startIndex, (i) {
        final qNum = startIndex + i + 1;
        return Question(
          id: '${era}_${level}_$qNum',
          era: era,
          level: level,
          gradeLevel: grade,
          questionText: 'Dagdag na tanong $qNum para sa $era antas $level. (Kailangang palitan ng totoong tanong)',
          options: const [
            QuestionOption(label: 'A', text: 'Tamang Sagot'),
            QuestionOption(label: 'B', text: 'Maling Sagot 1'),
            QuestionOption(label: 'C', text: 'Maling Sagot 2'),
            QuestionOption(label: 'D', text: 'Maling Sagot 3'),
          ],
          correctAnswer: 'A',
          explanation: 'Paliwanag ng placeholder.',
        );
      }));
      return padded;
    }

    return questions;
  }

  static List<Question> _fallbackQuestions(String era, int level) {
    final targetCount = level == 10
        ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions // 22
        : GameConstants.questionsPerLevel; // 5
    return List.generate(
      targetCount,
      (i) => Question(
        id: '${era}_${level}_$i',
        era: era,
        level: level,
        questionText: 'Tanong ${i + 1}: Sino ang pambansang bayani ng Pilipinas?',
        options: const [
          QuestionOption(label: 'A', text: 'Dr. Jose Rizal'),
          QuestionOption(label: 'B', text: 'Andres Bonifacio'),
          QuestionOption(label: 'C', text: 'Apolinario Mabini'),
          QuestionOption(label: 'D', text: 'Emilio Aguinaldo'),
        ],
        correctAnswer: 'A',
        explanation: 'Si Dr. Jose Rizal ang ating Pambansang Bayani.',
      ),
    );
  }
}
```

## File: lib/game/overlays/hud_overlay.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
import '../chrono_game.dart';

/// HUD overlay — shows hearts, level, score over Flame canvas.
class HudOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const HudOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Hearts
              Row(
                children: List.generate(
                  GameConstants.livesPerLevel,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Image.asset(
                      i < game.lives
                          ? 'assets/ui/heart_full.png'
                          : 'assets/ui/heart_empty.png',
                      width: 26,
                      height: 26,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Level indicator
              PixelBadge(
                text: game.currentLevel == 10
                    ? 'BOSS'
                    : 'LVL ${game.currentLevel}',
                color: AppColors.primary,
                textColor: Colors.white,
                fontSize: 10,
              ),
              const Spacer(),
              // Score
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/ui/star_full.png',
                        width: 16, height: 16),
                    const SizedBox(width: 5),
                    Text(
                      '${game.score}',
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coins
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/collectibles/coin.png',
                        width: 16, height: 16),
                    const SizedBox(width: 5),
                    Text(
                      '${game.playerCoins}',
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pause button
              Semantics(
                button: true,
                label: 'I-pause ang laro',
                child: GestureDetector(
                  onTap: () {
                    game.pauseEngine();
                    game.overlays.add('PauseOverlay');
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boss health bar overlay shown during Level 10 boss fight.
class BossHealthOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const BossHealthOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final boss = game.boss;
        if (boss == null) return const SizedBox.shrink();

        return Positioned(
          bottom: 80,
          left: 40,
          right: 40,
          child: Column(
            children: [
              Text(
                _getBossDialogue(game.currentEra),
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: Colors.yellowAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 8),
              // Health bar
              PixelProgressBar(
                value: boss.health / boss.maxHealth,
                fillColor:
                    boss.health > 2 ? AppColors.danger : Colors.orange,
                backgroundColor: Colors.grey.shade800,
                height: 18,
                segments: boss.maxHealth,
              ),
              const SizedBox(height: 4),
              Text(
                '${boss.health}/${boss.maxHealth}',
                style: GoogleFonts.pressStart2p(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getBossDialogue(String era) {
    final eraData = getEraById(era);
    return '"${eraData.bossDialogue}"';
  }
}
```

## File: lib/services/api_service.dart
```dart
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/student.dart';
import '../models/quiz_result.dart';
import '../models/era_progress.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio get _dio => DioClient.instance;

  // ─── AUTH ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{
        'classCode': classCode,
        'username': username,
        'password': password,
      };
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }

      final response = await _dio.post('/student/login', data: body);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await StorageService.saveToken(token);

      final user = Student.fromJson(data['user'] as Map<String, dynamic>);
      await StorageService.saveStudent(user);

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────
  Future<Student> getProfile() async {
    try {
      final response = await _dio.get('/student/profile');
      final envelope = response.data as Map<String, dynamic>;
      final student = Student.fromJson(envelope['data'] as Map<String, dynamic>);
      await StorageService.saveStudent(student);
      return student;
    } on DioException catch (e) {
      // Fallback to cached student
      final cached = StorageService.getStudent();
      if (cached != null) return cached;
      throw _handleError(e);
    }
  }



  // ─── RESULTS ──────────────────────────────────────────────────────────────
  Future<void> submitResult(QuizResult result) async {
    try {
      await _dio.post('/student/results', data: result.toJson());
    } on DioException catch (e) {
      await StorageService.queuePendingResult(result.toJson());
      throw _handleError(e);
    }
  }

  /// Call on app launch and after any successful network call to flush
  /// results that failed to submit while offline.
  Future<void> flushPendingResults() async {
    final pending = StorageService.getPendingResults();
    if (pending.isEmpty) return;

    final stillFailed = <Map<String, dynamic>>[];
    for (final json in pending) {
      try {
        await _dio.post('/student/results', data: json);
      } catch (_) {
        stillFailed.add(json);
      }
    }

    if (stillFailed.isEmpty) {
      await StorageService.clearPendingResults();
    } else {
      await StorageService.clearPendingResults();
      for (final json in stillFailed) {
        await StorageService.queuePendingResult(json);
      }
    }
  }

  Future<List<QuizResult>> getResults() async {
    try {
      final response = await _dio.get('/student/results');
      final data = (response.data as Map<String, dynamic>)['data'];
      final List<dynamic> list = data is List ? data : [];
      return list.map((r) => QuizResult.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERA PROGRESS ─────────────────────────────────────────────────────────
  Future<Map<String, EraProgress>> getEraProgress() async {
    try {
      final response = await _dio.get('/student/era-progress');
      final data = (response.data as Map<String, dynamic>)['data']['progress'];

      final Map<String, EraProgress> progress = {};

      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            progress[key] = EraProgress.fromJson(value);
            StorageService.cacheEraProgress(key, value);
          }
        });
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final eraId = item['eraId'] as String? ?? '';
            if (eraId.isNotEmpty) {
              progress[eraId] = EraProgress.fromJson(item);
              StorageService.cacheEraProgress(eraId, item);
            }
          }
        }
      }

      return progress;
    } on DioException catch (e) {
      // Fallback to cached progress
      final Map<String, EraProgress> cached = {};
      for (final eraId in ['pre-colonial', 'spanish', 'american', 'ww2', 'modern']) {
        final data = StorageService.getCachedEraProgress(eraId);
        if (data != null) {
          cached[eraId] = EraProgress.fromJson(data);
        }
      }
      if (cached.isNotEmpty) return cached;
      throw _handleError(e);
    }
  }

  // ─── POWERUPS ─────────────────────────────────────────────────────────────
  Future<void> updatePowerUps(Map<String, int> powerUps) async {
    try {
      await _dio.patch('/student/power-ups', data: powerUps);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── LEADERBOARD ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLeaderboard(String scope) async {
    try {
      final response = await _dio.get(
        '/student/leaderboard',
        queryParameters: {'scope': scope},
      );
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data']['leaders'];
      final List<dynamic> list = data is List ? data : [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERROR HANDLING ───────────────────────────────────────────────────────
  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Walang internet connection. Subukan muli.';
    }
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Error ${e.response?.statusCode}';
    }
    return 'Hindi makakonekta sa server. Subukan muli.';
  }
}
```

## File: lib/game/chrono_game.dart
```dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../data/question_bank.dart';
import 'components/player_component.dart';
import 'components/enemy_component.dart';
import 'components/boss_component.dart';
import 'components/ground_component.dart';
import 'components/gap_component.dart';
import 'components/enemy_spawner.dart';

/// Main Flame game class for ChronoQuest.
/// Manages the game loop, player, enemies, questions, and level state.
///
/// Mixes in ChangeNotifier so HUD/boss-health overlay widgets can react to
/// state changes (lives, score, coins, boss health) via ListenableBuilder —
/// without this, those Flutter overlays are only built once when added and
/// never update again, since Flame doesn't rebuild overlay widgets on its
/// own each frame.
class ChronoGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  // Game constants
  static const double worldScrollSpeed = 150.0;

  /// Y position of the ground surface. Computed from the actual game
  /// canvas size (not hardcoded) so it always matches where
  /// GroundComponent visually draws the ground (game.size.y - 60) —
  /// this project has no fixed-resolution viewport, so real device
  /// screens vary and a fixed constant only lined up by coincidence.
  double get groundY => size.y - 60;

  // Game state
  late PlayerComponent player;
  late GroundComponent ground;
  late EnemySpawner spawner;
  late GroundSpawner groundSpawner;

  // Maintained by GroundSection's onMount/onRemove (see gap_component.dart)
  // so PlayerComponent can check ground collision without scanning/filtering
  // game.children every frame — that scan runs 60x/sec across every enemy,
  // coin, and wall on screen too, which adds up.
  final List<GroundSection> groundSections = [];

  String currentEra = 'spanish';
  int currentLevel = 1;
  int lives = 3;
  int score = 0;
  int playerCoins = 0;
  bool questionShowing = false;
  bool bossPhase = false;
  bool shieldActive = false;
  Question? currentQuestion;
  EnemyComponent? currentEnemy;
  BossComponent? boss;
  List<QuestionSnapshot> answers = [];
  List<Question> bossQuestions = [];
  int wrongAttemptsOnCurrentQuestion = 0;

  // Powerups
  PowerUps playerPowerUps = PowerUps();

  // Services
  final AudioService audioService = AudioService();
  final ApiService apiService = ApiService();

  // Callbacks for navigation
  Function(int score, int correct, int total, List<QuestionSnapshot> answers)?
      onLevelComplete;
  Function()? onLevelFailed;

  // Elapsed time tracking
  final Stopwatch _stopwatch = Stopwatch();

  // Time tracking for animation
  double _gameTime = 0;
  @override
  double currentTime() => _gameTime;

  // Character selection
  String selectedCharacterId = 'rizal';

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // IMPORTANT: Flame's Images cache defaults to looking under
    // 'assets/images/'. Our pubspec.yaml declares images directly under
    // 'assets/characters/', 'assets/bosses/', 'assets/enemies/', etc.
    // Without this line, every game.loadSprite(...) call in the whole
    // game (player, enemies, boss) throws a "file not found" exception,
    // which is why nothing was rendering.
    images.prefix = 'assets/';

    // Real parallax background using the actual era artwork.
    await _addParallaxBackground();

    // Ground
    ground = GroundComponent();
    add(ground);

    // Ground spawner for gap system
    groundSpawner = GroundSpawner(game: this);
    groundSpawner.spawnInitialGround();

    // Player
    player = PlayerComponent(characterId: selectedCharacterId);
    add(player);

    // Questions are intentionally bundled with the app — no backend round-trip.
    final questions = QuestionBank.getQuestions(currentEra, currentLevel);

    if (currentLevel == 10) {
      // Split into warm-up (regular enemies) and boss-phase (asked while fighting).
      final warmup = questions.take(GameConstants.bossWarmupQuestions).toList();
      bossQuestions = questions.skip(GameConstants.bossWarmupQuestions).toList();
      spawner = EnemySpawner(game: this, questions: warmup);
    } else {
      spawner = EnemySpawner(game: this, questions: questions);
    }

    // Start timer
    _stopwatch.start();

    // Play BGM
    audioService.playBgm(currentEra);
  }

  Future<void> _addParallaxBackground() async {
    final bgKey = _backgroundAssetKeyForEra(currentEra);
    try {
      final parallax = await loadParallaxComponent(
        [
          ParallaxImageData('backgrounds/${bgKey}_far.png'),
          ParallaxImageData('backgrounds/${bgKey}_near.png'),
        ],
        baseVelocity: Vector2(20, 0),
        velocityMultiplierDelta: Vector2(2.2, 1.0),
        fill: LayerFill.height,
        repeat: ImageRepeat.repeatX,
        // Explicit size/position — don't rely on ParallaxComponent
        // auto-sizing to the canvas. It rendered as a small tile in the
        // corner instead of covering the screen without this.
        size: size,
        position: Vector2.zero(),
        priority: -10,
      );
      add(parallax);
    } catch (e) {
      // Fallback so the game is still playable if a background asset is
      // somehow missing, instead of leaving the whole load future unresolved.
      debugPrint('Failed to load parallax background for $currentEra: $e');
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFFD4C4A8),
        priority: -10,
      ));
    }
  }

  /// Background PNGs are named without the hyphen used in era ids
  /// (e.g. 'precolonial_far.png' for the 'pre-colonial' era).
  String _backgroundAssetKeyForEra(String era) {
    if (era == 'pre-colonial') return 'precolonial';
    return era;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;

    if (!questionShowing && !bossPhase) {
      spawner.update(dt);
      groundSpawner.update(dt);
      checkLevelEnd();
    }
  }

  // ─── QUESTION HANDLING ────────────────────────────────────────────────────

  void showQuestion(Question q, EnemyComponent enemy) {
    currentQuestion = q;
    currentEnemy = enemy;
    questionShowing = true;
    wrongAttemptsOnCurrentQuestion = 0;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void showBossQuestion(Question q, BossComponent bossRef) {
    currentQuestion = q;
    currentEnemy = null;
    questionShowing = true;
    wrongAttemptsOnCurrentQuestion = 0;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void handleAnswer(String answer) {
    overlays.remove('QuestionOverlay');
    final isCorrect = answer == currentQuestion!.correctAnswer;

    answers.add(QuestionSnapshot(
      questionId: currentQuestion!.id,
      studentAnswer: answer,
      correctAnswer: currentQuestion!.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: currentQuestion!.elapsedSeconds,
    ));

    if (isCorrect) {
      score += 10;
      // Speed bonus
      if (currentQuestion!.elapsedSeconds < 10) {
        score += 5;
      }

      if (bossPhase && boss != null) {
        boss!.takeDamage();
      } else {
        currentEnemy?.defeat();
      }
      questionShowing = false;
      resumeEngine();
      notifyListeners(); // score changed, and possibly boss health
    } else {
      // Shield absorbs wrong answer
      if (shieldActive) {
        shieldActive = false;
        questionShowing = false;
        if (bossPhase && boss != null) {
          // No damage to boss, but no life lost either
        } else {
          currentEnemy?.defeat();
        }
        resumeEngine();
        return;
      }

      lives--;
      player.triggerHurt();
      wrongAttemptsOnCurrentQuestion++;
      notifyListeners(); // lives changed

      if (lives <= 0) {
        questionShowing = false;
        showLevelFailed();
      } else if (wrongAttemptsOnCurrentQuestion >= 2) {
        // 2 wrong on same enemy: enemy passes, already lost hearts
        questionShowing = false;
        currentEnemy?.defeat();
        resumeEngine();
      } else {
        // Show question one more time
        Future.delayed(const Duration(milliseconds: 800), () {
          overlays.add('QuestionOverlay');
        });
      }
    }
  }

  // ─── GAME EVENTS ──────────────────────────────────────────────────────────

  void onPlayerJump() {
    if (!questionShowing) {
      player.jump();
    }
  }

  void playerFellInGap() {
    lives--;
    player.triggerHurt();
    notifyListeners(); // lives changed
    if (lives <= 0) {
      showLevelFailed();
    } else {
      player.respawn();
    }
  }

  /// Player failed to jump over a wall obstacle in time. Same damage as
  /// falling in a gap, but no respawn — the player didn't fall anywhere,
  /// they just took a hit, and the wall keeps scrolling past.
  void playerHitObstacle() {
    lives--;
    player.triggerHurt();
    notifyListeners(); // lives changed
    if (lives <= 0) {
      showLevelFailed();
    }
  }

  void collectCoin() {
    playerCoins++;
    score += 5;
    audioService.playCoin();
    notifyListeners(); // coins/score changed
  }

  // ─── LEVEL STATE ──────────────────────────────────────────────────────────

  void checkLevelEnd() {
    if (spawner.allEnemiesSpawned &&
        children.whereType<EnemyComponent>().isEmpty) {
      if (currentLevel == 10 && !bossPhase) {
        startBossFight();
      } else if (currentLevel < 10) {
        levelComplete();
      }
    }
  }

  void startBossFight() {
    bossPhase = true;
    boss = BossComponent(eraId: currentEra);
    add(boss!);
    overlays.add('BossHealthOverlay');
  }

  void levelComplete() {
    _stopwatch.stop();
    pauseEngine();
    audioService.playLevelComplete();

    final correct = answers.where((a) => a.isCorrect).length;
    final total = answers.length;
    final percentage = total > 0 ? (correct / total * 100).round() : 0;

    // Check perfect level bonus
    if (correct == total && total > 0) {
      score += 50;
    }

    // Submit result
    _submitResult(percentage);

    // Notify game screen
    onLevelComplete?.call(score, correct, total, answers);
  }

  void showLevelFailed() {
    _stopwatch.stop();
    pauseEngine();
    audioService.playLevelFailed();
    onLevelFailed?.call();
  }

  Future<void> _submitResult(int percentage) async {
    try {
      await apiService.submitResult(QuizResult(
        era: currentEra,
        level: currentLevel,
        type: currentLevel == 10 ? 'post_test' : 'pre_test',
        correctAnswersCount:
            answers.where((a) => a.isCorrect).length,
        totalQuestions: answers.length,
        percentage: percentage,
        timeTakenTotal: _stopwatch.elapsed.inSeconds,
        questionSnapshots: answers,
      ));
    } catch (_) {
      // Silently fail — result can be retransmitted later
    }
  }
}
```
