---
name: flutter-flame-gamedev
description: Conventions, component patterns, and gotchas for building 2D games with Flutter + Flame (Dart) — components, HUD, parallax, Hive persistence, Riverpod state. Use this whenever writing or editing game code for ChronoQuest, adding a new game component (player/enemy/boss/HUD/pickup), wiring game state to Riverpod, persisting progress with Hive, tuning collision/movement, or debugging Flame-specific issues (game loop, component lifecycle, camera, rendering order). Always consult this before generating new Flame component code, even for small additions — Flame has specific lifecycle and update-loop conventions that generic Flutter widget knowledge does not cover.
---

# Flutter + Flame Game Dev (ChronoQuest)

Conventions for the ChronoQuest capstone: a landscape-locked, auto-runner-style
Flutter/Flame game covering five Philippine historical eras, paired with a
React/Node/MongoDB teacher dashboard. This skill is scoped to the **game**
side only (Dart/Flame) — dashboard work follows normal Flutter/React
conventions and doesn't need this file.

## Project shape

- Engine: **Flame** (not a full game engine with an editor — a Flutter
  package that gives you a game loop, component tree, and rendering on top
  of Flutter's widget/canvas system).
- State management: **Riverpod** providers for game state (score, HP, era
  progress, quiz results) — do not reach for `setState` or global mutable
  singletons inside game logic.
- Persistence: **Hive** with generated `TypeAdapter`s for saved progress,
  unlocked eras, and quiz history. Any new persisted model needs a matching
  adapter — don't hand-roll serialization.
- Orientation: landscape-locked. Never assume portrait dimensions when
  positioning HUD elements or components.
- Content: five historical eras, each with its own tileset/parallax
  background and quiz checkpoints aligned to MATATAG curriculum pacing
  (weekly summative / term-periodical rhythm) — era content and quiz logic
  should stay decoupled from core movement/collision code so a new era can
  be added without touching the player/enemy/boss classes.

## Component conventions

Flame components extend `Component`/`PositionComponent`/`SpriteComponent`
and hook into the lifecycle via `onLoad`, `update(dt)`, and `render(canvas)`
— not Flutter's widget build cycle. Keep these rules in mind:

- **One responsibility per component.** Player, enemy, boss, and HUD are
  separate component classes, not one mega-class with mode flags. When
  asked to add a new entity type, create a new component file rather than
  branching inside an existing one.
- **`update(dt)` must use `dt`, never wall-clock or frame-count.** Any
  movement, cooldown, or timer logic scales by `dt` so speed stays
  consistent across devices/frame rates. This is the single most common
  Flame bug in AI-generated code — always check new components for
  frame-rate-dependent movement before considering them done.
- **HUD components** live in screen space (added via a `CameraComponent`
  viewport or a Flutter overlay widget), not world space. Don't parent HUD
  elements to the same component tree as world entities like player/enemy.
- **Collision** uses Flame's `CollisionCallbacks` mixin with defined hitbox
  shapes — prefer `RectangleHitbox`/`CircleHitbox` sized to the sprite's
  actual silhouette, not the full bounding box, to avoid "phantom hit"
  complaints during playtesting.
- **Parallax** backgrounds use Flame's `ParallaxComponent` with per-layer
  scroll-speed multipliers — new eras should follow the same layer
  structure (far background → mid → near → foreground) already established
  rather than inventing a new layering scheme per era.

## Wiring state (Riverpod)

- Game-affecting state (score, HP, current era, quiz answers) lives in
  Riverpod providers, read/written from components via a reference passed
  in at construction — don't have components reach out to a global
  `ProviderContainer` directly if avoidable.
- Keep the Flame component tree and the Riverpod provider tree in sync
  deliberately: a component's `update()` should read from providers for
  anything the dashboard or quiz UI also needs to see, so there's a single
  source of truth instead of duplicated state in the component and a
  provider.

## Persistence (Hive)

- Every new persisted model gets a `@HiveType`/`@HiveField` annotated class
  and a generated `TypeAdapter` — regenerate adapters
  (`flutter pub run build_runner build`) after adding or changing fields,
  and check the adapter's `typeId` doesn't collide with an existing one.
- Don't persist transient in-run state (current frame position, animation
  state) — only persist what needs to survive an app restart: unlocked
  eras, best scores, quiz history, settings.

## File hygiene

Matches the team's existing standard: keep files under 200–300 lines, and
avoid barrel files in agent-touched code — when a component file starts
sprawling (mixing movement, rendering tweaks, and collision response),
split it rather than letting it grow, and don't route everything through a
single `index.dart` re-export.

## Testing / verifying visual output

Flame code has the same blind-spot problem as any game code: Claude can
write logic that compiles and *should* look right without being able to
see it run. See `references/golden-testing.md` for how to close that loop
with Flutter's built-in golden/widget testing — the Flutter-native
equivalent of the Playwright-screenshot pattern used in web-based
(Phaser/Three.js) vibe-coding workflows. Use it whenever adding or
changing anything visual (new sprite, HUD layout change, parallax layer,
animation) — write or update a golden test alongside the change rather
than asking the user to manually verify every tweak.

## What NOT to bring over from Phaser/Three.js skills

If a Phaser or Three.js skill is also installed in this repo, its APIs
don't apply here — Flame's component/lifecycle model, coordinate system,
and asset-loading conventions are different from both. Don't reference
`Phaser.Scene`, `this.add.sprite(...)`, Three.js `Object3D`/`scene.add()`,
or browser-only APIs (`window`, `document`, Canvas 2D context) when writing
ChronoQuest game code.
