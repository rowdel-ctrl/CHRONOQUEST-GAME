# Forgot password for students: what the game needs from the dashboard

From the GAME chat, 2026-10-17. The GAME chat changed nothing in the dashboard; this is only what the game now expects.

## What the student sees

On the game's sign-in screen, "Forgot password?" opens a screen that shows the class code and the username, with a button "I-SEND SA TEACHER". The button sends the request below. The game side is built and tested (uncommitted in the game repo).

The game works before your part exists: any failure tells the student to say the class code and username to the teacher in person.

## 1. Public endpoint (no login)

`POST /api/v1/student/password-reset-request`

Put it in `student.routes.js`, above `router.use(verifyStudentToken)`.

Body: `{ "classCode": "edg5a1", "username": "JuanNinja99" }`. The game sends what the student typed, trimmed. Normalise like login does: class code upper-cased and trimmed, username trimmed and compared ignoring case.

- Answer `200 { success: true, message: "..." }` every time the body is well formed, **whether or not that student exists** (also for a deleted or inactive student, or an archived section). Nobody must be able to learn who is in a class.
- `400` only when `classCode` or `username` is missing, not text, or longer than 64 characters. `429` when limited.
- If the student exists, save **one open request** for that student. Sending again does not add a second one; it refreshes `requestedAt`.
- New model `PasswordResetRequest`: `studentId`, `classCode`, `username`, `name` (copied, so the list needs no join), `requestedAt`, `status` (`open`, `done`, `dismissed`). Old rows delete themselves after 7 days (a TTL index, as `PasswordReset` does).
- Limit by counting in the database (per class code plus username, and per address), like forgot-password does, because the in-memory `authLimiter` does not work on Vercel. Suggestion: at most 1 refresh per minute per student and 20 requests per address per hour.
- **Matching the username:** login builds `new RegExp(`^${cleanUsername}$`, 'i')` from the raw text, so a username like `.*` matches every student, and some patterns can hang the server. Do not copy that here: escape the text first, or use a case-insensitive collation. Fixing login the same way is a separate small job worth doing.

## 2. Teacher side

- `GET /api/v1/teacher/reset-requests`: the open requests for the sections this teacher owns, newest first: `[{ id, studentId, name, username, classCode, requestedAt }]`.
- `POST /api/v1/teacher/reset-requests/:id/dismiss`: marks it dismissed (own sections only, otherwise 404).
- The existing `POST /teacher/sections/:id/students/:sid/reset-password` stays as it is. When it works it also marks that student's open request `done`, so the count goes down.
- Students page (`MyStudents.jsx`): a badge with the count ("2 requests") and a list above the table: name, username, section, "asked 2 minutes ago", and the buttons "Reset password" (opens the existing confirm window, then the one-time password window) and "Dismiss". Refresh by polling every 30 to 60 seconds (there is a polling hook). A rough sketch is in section 9 of the mockup linked from the GAME handoff.

## 3. One-line fix (needed whether or not you build the rest)

`resetStudentPassword` (`teacher.controller.js`) must set `student.mustChangePassword = true` before `save()`. Today only `createStudent` does, so after a teacher reset the student is not asked to choose a new password, and the teacher knows it for good. The game already sends a student with that flag to its change-password screen. Add a case to `studentPasswordReset.test.js`.

## 4. Tests to add

- The same 200 answer for a real and an unknown student. 400 for missing or too long fields. A username made of regex characters matches nobody and does not error.
- Two sends make one open request.
- A teacher sees only requests from their own sections; dismiss and reset both clear a request; another teacher gets 404.
- The 7-day expiry index exists.

## 5. What the game does with the answers (so you can test it)

| Answer | The student sees |
|---|---|
| any 2xx | "Na-send na!" |
| 429 | "Masyadong maraming send. Subukan ulit mamaya." |
| timeout or no internet | "Mabagal o walang internet. Subukan ulit." |
| anything else, including 404 (route not there yet) and 500 | "Hindi ma-send ngayon. Sabihin na lang sa teacher mo ang class code at username mo." |

## When it is deployed

Delete the GAME to DASHBOARD line about this in the requests table on the board, and say if the path or the body differ from the above, because the game uses exactly these names (`ApiService.requestPasswordReset` in `lib/services/api_service.dart`).
