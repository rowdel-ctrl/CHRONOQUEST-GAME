# ChronoQuest — Full Project Context

**Paste this at the start of any new conversation to restore full context.**

---

## What ChronoQuest is

A capstone project at Marinduque State University. ChronoQuest is a gamified learning system for teaching Philippine History (Araling Panlipunan) to Grade 4–6 elementary students in public schools in Boac, Marinduque.

Two interfaces share one backend:
- **React.js Web Dashboard** — for teachers and school administrators (ICT Coordinators)
- **Flutter Mobile Game** — for students only (auto-runner platformer with manual jump)

**Authors:** Rodel Anoche, Yuan Wilson Fuerte, Andrea Pearl Manqueria, Jhonn Carlo Rey
**Partner schools:** Boac Central Elementary School, Mogpog Elementary School, Sta. Cruz Elementary School

---

## Research background

DepEd proficiency data showed Marinduque public elementary students averaged 40–50% in Araling Panlipunan — well below the 75% benchmark. ChronoQuest addresses this through gamified learning with a built-in pre-test/post-test measurement system.

**27.8% of students have no personal smartphone.** Solution: primary use is scheduled ICT lab sessions where the school provides 5–10 devices. Home use is optional.

---

## DepEd MELC curriculum mapping (verified from MELC document)

This is the official curriculum alignment for ChronoQuest. Each grade level sees ONLY the eras mapped to their grade.

| Grade | Quarter | Era in ChronoQuest | Historical Content |
|-------|---------|-------------------|-------------------|
| Grade 4 | Q1–Q4 | Pre-colonial (Sinaunang Panahon) | Geography of the Philippines, early Filipino life, barangay system, trade with Asia, Baybayin, Battle of Mactan |
| Grade 5 | Q1 | Pre-colonial (Sinaunang Panahon) | Origins of the Filipino people, Austronesian theory, early settlements, socio-cultural life |
| Grade 5 | Q2–Q3 | Spanish Colonial (Panahon ng Kastila) | Spanish colonization, encomienda, Christianization, resistance movements, Katipunan |
| Grade 5 | Q4 | Rise of Nationalism | Propaganda movement, Rizal's works, birth of Philippine nationalism |
| Grade 6 | Q1 | Philippine Revolution & American Period | Katipunan, Himagsikan, Philippine-American War, Commonwealth |
| Grade 6 | Q2 | American Period (Panahon ng Amerikano) | American governance, public education, Thomasites, transition to independence |
| Grade 6 | Q3 | World War II (Ikalawang Digmaang Pandaigdig) | Japanese occupation, Bataan Death March, liberation, guerrilla resistance |
| Grade 6 | Q4 | Modern Era (Makabagong Panahon) | Post-independence, Marcos era, EDSA Revolution, contemporary issues |

**Era-to-grade mapping in code:**
```javascript
const ERA_GRADE_MAP = {
  'pre-colonial': ['grade4', 'grade5'],  // Grade 4 full year + Grade 5 Q1
  'spanish':      ['grade5'],            // Grade 5 Q2-Q3
  'american':     ['grade5', 'grade6'],  // Grade 5 Q4 + Grade 6 Q1-Q2
  'ww2':          ['grade6'],            // Grade 6 Q3
  'modern':       ['grade6'],            // Grade 6 Q4
};

// In Flutter:
final visibleEras = eras.where((era) =>
  ERA_GRADE_MAP[era.id]!.contains(student.gradeLevel)
).toList();
```

Grade 4 students → see Pre-colonial only
Grade 5 students → see Pre-colonial, Spanish, and start of American
Grade 6 students → see American, WW2, and Modern

---

## Tech stack

**Backend:** Node.js 20+, Express 4+, Mongoose 8+, MongoDB Atlas, JWT, bcryptjs (10 rounds), express-validator, express-rate-limit, helmet, morgan, nanoid, dotenv, dayjs

**Dashboard:** Vite, React 18, React Router v6, Axios + JWT interceptor, Context + useReducer, Tailwind CSS v3, Recharts, TanStack Table, React Hook Form + Zod, Lucide React (16px strokeWidth=1.5), React Hot Toast, Day.js, PapaParse

**Flutter game:** Flutter 3.x, Dart, Flame 1.17.0 (game engine), dio, flutter_secure_storage, go_router, flutter_riverpod, hive, audioplayers, lottie

---

## User roles (final — 3 roles only, no super_admin)

| Role | Who | Access |
|------|-----|--------|
| `admin` | ICT Coordinator (1 per school) | Manages teachers, students, analytics for their school |
| `teacher` | Araling Panlipunan teachers | Manages own sections, views own class results |
| `student` | Elementary students (Grades 4–6) | Flutter game only — no dashboard access |

Each school has its own independent system (separate deployment). No cross-school super admin.

**Teacher model role enum:**
```javascript
role: { type: String, enum: ['teacher', 'admin'], default: 'teacher' }
```

---

## Questions are hardcoded — no admin question UI

Questions are DepEd MELC-aligned, written by developers, and seeded into MongoDB at deployment. Nobody in the schools creates or edits questions. The Question Bank page is removed from the dashboard entirely.

**Justification for paper:**
> "Questions are pre-validated by the development team against DepEd MELC competencies for each grade level and seeded at deployment. This ensures curriculum accuracy and removes the burden of content creation from teachers, whose primary role is instruction, not content authoring."

---

## MongoDB collections

**teachers** — name, email, password (bcrypt), role (teacher|admin), schoolName, gradeLevelsTaught, sections (embedded: name, classCode CQ-XXXX, gradeLevel, schoolYear, isArchived), isActive, isDeleted, lastLogin

**students** — name, classCode, schoolName, gradeLevel, score, levelReached, isActive, isDeleted, lastActive, powerUps { fiftyFifty, timeFreeze, extraLife }
- No email, no password — students join by entering classCode + full name only
- Account auto-created on first join

**questions** — era, subTopic, gradeLevel, level (1–10), difficulty, questionType, questionText, options [{label, text}], correctAnswer, explanation, status (active|archived), errorRate, timesAnswered

**quizresults** — studentId, studentName, classCode, era, level (1–10), type (cold_pre_test|pre_test|post_test), testDate, correctAnswersCount, totalQuestions, score, percentage, timeTakenTotal, questionSnapshots

**feedback** — title, description, type (general_feedback|bug_report), submittedBy, submitterEmail, priority, status (open|in_progress|resolved|closed), responseMessage, respondedAt

**activitylogs** — userId, userModel, userRole, action, resource, resourceId, ipAddress, status, createdAt

**systemsettings** — key, value, type, description, category, updatedBy

---

## QuizResult type field (critical for learning gain)

```javascript
type: {
  type: String,
  enum: ['cold_pre_test', 'pre_test', 'post_test'],
  default: 'pre_test',
}
```

- `cold_pre_test` — Baseline/pre-test. Plain questions before reading anything. No timer, no powerups. Score hidden until era complete screen.
- `pre_test` — Formative assessment. Levels 1–9 map exploration gameplay. Measures progressive learning AFTER reading the background.
- `post_test` — Summative assessment. Level 10 final boss battle. True post-test measuring final retention.

Dashboard shows: coldPreAvg → Levels 1–9 avg → postAvg = full learning curve per student per era.

---

## Student join flow (no pre-registration)

Students join by entering:
1. Class code (e.g. `CQ-G5A1`) — teacher writes on board
2. Their full name

Backend finds existing account or creates one automatically.

```javascript
// POST /api/v1/student/login
// Body: { classCode, name }
// First time: creates account with gradeLevel from section
// Returning: finds account, updates lastActive
// Returns: { token, user, isNewStudent }
```

JWT expiry: 30 days (students stay logged in).

---

## API endpoints

```
POST   /api/v1/auth/login
POST   /api/v1/auth/register
GET    /api/v1/auth/me

GET    /api/v1/teacher/sections
POST   /api/v1/teacher/sections
PUT    /api/v1/teacher/sections/:id
PATCH  /api/v1/teacher/sections/:id/archive
PATCH  /api/v1/teacher/sections/:id/unarchive
GET    /api/v1/teacher/sections/:id/students
DELETE /api/v1/teacher/sections/:id/students/:sid
GET    /api/v1/teacher/results
GET    /api/v1/teacher/results/:studentId
GET    /api/v1/teacher/analytics/overview
GET    /api/v1/teacher/activity-feed

GET    /api/v1/questions/by-era/:era    (Flutter — ?level=N&gradeLevel=grade5&limit=10)

GET    /api/v1/analytics/era-performance
GET    /api/v1/analytics/score-distribution
GET    /api/v1/analytics/progress-over-time
GET    /api/v1/analytics/at-risk-students
GET    /api/v1/analytics/engagement-over-time
GET    /api/v1/analytics/era-performance-all
GET    /api/v1/analytics/top-students
GET    /api/v1/analytics/at-risk-students-all

GET    /api/v1/admin/users
POST   /api/v1/admin/users/teacher
PUT    /api/v1/admin/users/:id
PATCH  /api/v1/admin/users/:id/activate
PATCH  /api/v1/admin/users/:id/archive
POST   /api/v1/admin/users/:id/reset-password
GET    /api/v1/admin/system/stats
GET    /api/v1/admin/activity-feed

POST   /api/v1/feedback
GET    /api/v1/feedback/my
GET    /api/v1/feedback
PATCH  /api/v1/feedback/:id/respond

GET    /api/v1/logs
GET    /api/v1/logs/export

GET    /api/v1/settings
PUT    /api/v1/settings

POST   /api/v1/student/login
GET    /api/v1/student/profile
PUT    /api/v1/student/profile
GET    /api/v1/student/results
POST   /api/v1/student/results
PATCH  /api/v1/student/power-ups
GET    /api/v1/student/leaderboard
GET    /api/v1/student/era-progress
```

---

## Dashboard design system

```css
--color-primary:        #8B4513
--color-primary-light:  #C4773B
--color-primary-dark:   #5C2D0A
--color-accent:         #D4AF37
--color-bg:             #FAF7F2
--color-surface:        #FFFFFF
--color-surface-alt:    #F3EDE3
--color-border:         #E8D9C4
--color-text-primary:   #2C1810
--color-text-secondary: #7A5C42
--color-text-muted:     #B09880
--color-success:        #3A7D44
--color-warning:        #D97706
--color-danger:         #C0392B
--color-info:           #2E6DA4
--font-display:         'Playfair Display', Georgia, serif
--font-body:            'Source Sans 3', Helvetica, sans-serif
--font-mono:            'JetBrains Mono', monospace
--sidebar-width:        256px
--card-radius:          0.75rem
```

No emojis in dashboard. Lucide React icons only (16px, strokeWidth=1.5). Warm academic aesthetic.

---

## Key design decisions (final)

**No super_admin.** Each school has its own `admin` (ICT Coordinator). Role enum: `['teacher', 'admin']`.

**Questions are hardcoded.** No question bank UI in dashboard. Questions seeded by developers. Questions tagged by era, level (1–10), and gradeLevel.

**Students join via classCode + name.** No email, no password, no pre-registration. Account auto-created on first join. Class code written on board by teacher.

**Eras locked by grade level.** Grade 4 sees pre-colonial only. Grade 5 sees pre-colonial, spanish, american (partial). Grade 6 sees american, ww2, modern.

**Three assessment stages.**
- `cold_pre_test` — baseline (true pre-test, before reading anything)
- `pre_test` — formative assessment (Levels 1–9, after reading, during gameplay)
- `post_test` — summative assessment (Level 10 boss, final retention)
Learning gain reported to panel = post_test minus cold_pre_test. Levels 1–9 data shows progressive improvement graph.

**Cold pre-test is plain UI.** No game elements. No timer. No powerups. Score hidden until era complete screen.

**Send Feedback in TopBar.** Not in teacher sidebar. Modal from TopBar button.

**Feedback types:** general_feedback and bug_report only.

**SectionManager shows class code prominently.** Large mono font, dashed gold border, "Share with students" text.

**UserManagement student tab** shows self-joined students. No "Add Student" button.

---

## Dashboard features (complete)

**Teacher dashboard:**
- Learning gain metric card (coldPreAvg → postAvg)
- Score trend with DepEd 75% benchmark line
- Era performance bar chart with benchmark
- Score distribution pie chart
- Section breakdown panel
- At-risk students panel (inactive 7+ days OR avg < 60%)
- Activity feed with readable labels

**Class Results:**
- Filterable paginated table
- Student drawer: learning gain, score history, topic accuracy, answer breakdown

**Admin dashboard:**
- System metrics, 30-day engagement, era performance
- School performance leaderboard, top students
- At-risk panel, activity feed

**Feedback Management:**
- Ticket table, respond drawer, status update

---

## Panel feedback — 12 items and solutions

| # | Panel concern | Solution | Status |
|---|--------------|----------|--------|
| 1 | Pre-test | Cold pre-test (plain screen, before reading) → Levels 1–9 → Level 10 post-test | ✅ Done |
| 2 | Lesson coverage & quarter | MELC-aligned per grade (see table above). Grade 4 = Pre-colonial, Grade 5 = Spanish/American, Grade 6 = WW2/Modern | ✅ Done |
| 3 | Reward system | Points (10 per correct), powerups, badges, leaderboard. Grade conversion: teacher sets rate in dashboard (e.g. 100 pts = 1 recitation point) | ⚠️ Grade conversion needs paper documentation |
| 4 | Sustainability | Admin role per school (ICT Coordinator). Developers provide 12-month support post-deployment. Visit ICT coordinator one-on-one to confirm capability | ⚠️ Needs ICT coordinator interview in paper |
| 5 | Low participation | Game mechanics, leaderboard, grade conversion as motivators. Teacher controls game sessions | ✅ Done |
| 6 | Poor retention | 9 exploration levels with increasing difficulty before post-test. Repeated exposure to same content | ✅ Done |
| 7 | Device access (27.8%) | Primary = ICT lab with school devices, rotating schedule. Home use optional | ✅ Done |
| 8 | Proficiency measurement | coldPreAvg → Levels avg → postAvg. DepEd 75% benchmark on all charts | ✅ Done |
| 9 | Lesson plan integration | App used last 10–15 min of AP class. Sample lesson plan template needed in appendix | ⚠️ Needs sample lesson plan in paper |
| 10 | Content management | Questions hardcoded/seeded by developers. No admin UI needed. Justification in paper | ✅ Done |
| 11 | Performance monitoring | Teacher dashboard: learning gain, at-risk panel, class results. Student: era complete screen shows own scores | ✅ Done |
| 12 | Game design | Historical characters per era. Enemies contextualized to historical period. Auto-runner platformer with manual jump | ✅ Done |

**3 remaining paper tasks:**
1. Document grade conversion system (points → recitation points)
2. Add ICT coordinator one-on-one interview results
3. Add sample lesson plan template showing where app fits in 60-minute AP class

---

## Flutter game — final design

**Type:** Auto-runner platformer with manual jump (tap screen to jump)
**Engine:** Flutter + Flame 1.17.0
**Lives:** 3 hearts per level. Lost from wrong answers AND falling into gaps. Fall into gap = lose 1 heart. 0 hearts = Level Failed, restart from Question 1.

### Complete game flow

```
Login Screen (class code + full name, no password)
  ↓
Character Selection (5 characters, Mechanics + Leaderboard cards on left)
  ↓
Era Selection (books on shelf — only eras for student's grade level visible)
  ↓
Tap available era
  ↓
COLD PRE-TEST (plain screen, no game elements, no timer, 10 questions)
  Score saved silently → { type: 'cold_pre_test' }
  ↓
BACKGROUND HISTORY SCREEN (scroll-gated, Filipino text 150–200 words)
  ↓
LEVEL SELECT (10 milestones, Level 1 unlocked, Level 10 locked)
  ↓
GAMEPLAY (Flame canvas)
  Character runs right automatically
  Tap screen = jump over walls and gaps
  Fall into gap → lose 1 heart (gaps are a real threat)
  Enemy approaches → game pauses → question card
  Correct: enemy defeated, resume
  Wrong: lose heart, question once more
  Level complete → { type: 'pre_test', level: N }
  ↓
Levels 1–9 done → Level 10 unlocks
  ↓
Level 10: Boss fight (5-question battle)
  → { type: 'post_test', level: 10 }
  ↓
ERA COMPLETE SCREEN
  Cold pre-test: 42% (revealed here for first time)
  Levels 1–9 avg: 63%
  Level 10 score: 81%
  Learning gain: +39%
```

### 5 eras, enemies, and characters

| Era | Grade | Character | Enemy 1 | Enemy 2 | Boss |
|-----|-------|-----------|---------|---------|------|
| Sinaunang Panahon | 4, 5 | Lapu-Lapu | Tribal warrior | Dark spirit | Bakunawa |
| Panahon ng Kastila | 5 | Jose Rizal | Spanish soldier | Tax collector | Governor-General |
| Panahon ng Amerikano | 5, 6 | Apolinario Mabini | American soldier | Propaganda | American General |
| Ikalawang Digmaang Pandaigdig | 6 | Josefa Llanes Escoda | Japanese soldier | Military tank | Japanese Commander |
| Makabagong Panahon | 6 | Corazon Aquino | Corruption figure | Misinformation cloud | Corruption Boss |

### Powerups
- **50/50** — removes 2 wrong answer options
- **Time Freeze** — freezes all enemies 10 seconds
- **Shield** — absorbs one wrong answer without losing heart

NOT available during cold pre-test or Level 10 boss.

---

## Learning gain calculation (dashboard)

```javascript
const coldPreResults = await QuizResult.find({ classCode: { $in: classCodes }, type: 'cold_pre_test' });
const postResults    = await QuizResult.find({ classCode: { $in: classCodes }, type: 'post_test' });

const coldPreAvg = coldPreResults.length
  ? Math.round(coldPreResults.reduce((s, r) => s + r.percentage, 0) / coldPreResults.length)
  : null;

const postAvg = postResults.length
  ? Math.round(postResults.reduce((s, r) => s + r.percentage, 0) / postResults.length)
  : null;

return { coldPreAvg, postAvg, learningGain: coldPreAvg != null && postAvg != null ? postAvg - coldPreAvg : null };
```

---

## Seed credentials

```bash
node src/utils/seed.js          # safe run
node src/utils/seed.js --fresh  # wipe and reseed
```

```
Admin:    admin@chronoquest.dev    / admin123
Teachers: teacher1@chronoquest.dev / teacher123
Students: enter classCode + name in app
```

---

## Bugs fixed

| Bug | Fix |
|-----|-----|
| E11000 duplicate key | sparse: true on classCode in sectionSchema |
| No unarchive endpoint | Added PATCH /api/v1/teacher/sections/:id/unarchive |
| Admin dashboard crash | Added getOverview and getSchoolPerformance aliases in admin.api.js |
| School leaderboard Unknown | schoolPerformance returns field `school` not `schoolName` |
| Activity feed raw strings | Added ACTION_LABELS map |
| Section breakdown 1 section | buildSectionSummary uses classCode as key |
| Feedback drawer not opening | Replaced usePolling with useEffect in FeedbackManagement |
| QuestionBank import error | Delete both import AND route from AppRouter.jsx |

---

## What still needs building

### Backend (before Flutter build)
- [ ] Add `level` field to QuizResult model (1–10)
- [ ] Add `type` field to QuizResult model (cold_pre_test|pre_test|post_test)
- [ ] Add `level` field to Question model (1–10)
- [ ] Add `gradeLevel` filter to /questions/by-era/:era
- [ ] Update student results to increment Student.score and lastActive
- [ ] Grade conversion setting in SystemSettings

### Flutter game
- Not yet built. Use `ChronoQuest_Platformer_Game.md` for the AI prompt.

### Paper
- [ ] MELC mapping table (use table above — verified from MELC document)
- [ ] Sample lesson plan template
- [ ] ICT coordinator capability assessment (visit schools)
- [ ] Grade conversion documentation
- [ ] Updated Section 3.4 (device plan, timeline, success metrics)

---

## How to run

```bash
# Backend
cd chronoquest-backend && npm install && npm run dev   # :5000

# Dashboard
cd chronoquest-dashboard && npm install && npm run dev # :5173

# Flutter
cd chronoquest-flutter
flutter pub get
flutter pub run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
```

---

## Key panel answers

**"How do you measure learning gain?"**
Cold pre-test before reading → 9 levels of gameplay → Level 10 post-test boss. Three data points per student per era. Dashboard shows full learning curve. Learning gain = post-test minus cold pre-test.

**"What specific lessons are covered?"**
Grade 4: Pre-colonial Philippines (Q1–Q4 MELC). Grade 5: Pre-colonial, Spanish colonial, early American period. Grade 6: American period, WW2, modern era. All questions are MELC-aligned per grade level.

**"Who creates the questions?"**
Developers write and seed ~200 questions aligned to DepEd MELC at deployment. Nobody in the schools creates or edits questions.

**"What about the 27.8% without devices?"**
Primary use is scheduled ICT lab sessions with school-provided devices, rotating schedule. Home use is optional.

**"How do students log in?"**
No accounts to create. Teacher writes class code on board. Student enters code + full name in app. Account created automatically.

**"How does the game teach history?"**
Students read background history first (scroll-gated). Then play levels on a historical map. Answering questions correctly defeats enemies. Level 10 boss = post-test.

**"Is this aligned to the DepEd curriculum?"**
Yes. Questions are mapped to specific MELC competencies per grade level. Grade 4 students see only pre-colonial content, Grade 5 see colonial period, Grade 6 see WW2 and modern. The game cannot be played out of sequence.
