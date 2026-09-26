# Routine Features & API Architecture — Design

Date: 2026-09-25
Status: approved for planning (revised 2026-09-25 after review)

## Purpose

The Flutter mobile application contains a 7-screen flow generated in Google Stitch (Project ID: `12234759688445532359`, *One Percent Habit Tracker*) covering Routine browsing, detail preview, creation, editing, step-by-step execution, and completion celebration.

The live PostgreSQL schema already has `routines` and `routine_habits` tables, and `backend/src/routine/` contains a Nest CLI scaffold (`RoutineModule`, `RoutineController` at `@Controller('routine')`, `RoutineService`, empty DTOs) that is registered in `app.module.ts` but only returns placeholder strings. The Stitch screens also introduce data the schema lacks: per-step duration in minutes and a routine cadence tag.

This document specifies the API, the Prisma contract changes, endpoint contracts, authorization rules, and the execution data flow needed to power the mobile routine feature end-to-end. Implementation **replaces the scaffold in place** in `src/routine/`; no second module is created.

---

## Product Scope

A routine is an **ordered way to walk through existing habits** — typically small ones (drink water, take pill, stretch). It is a grouping and playback aid, not a trackable unit of its own.

- **Streaks live on habits only.** Playing a routine logs each step's habit entry, which updates that habit's streak on Today. Routines have no streak, no run history and no "times played" statistics.
- **Consequence:** no `routine_runs` table (considered in `docs/superpowers/plans/2026-09-24-routines-api.md` and rejected). If routine-level stats are wanted later, a runs table can be added then; plays before that point will not be recoverable.

### Non-goals (v1)
- Routine streaks, run history, or recording actual time spent per step.
- Per-step guidance text, category tag, energy tag and portion goal shown in some Stitch mockups (Screens 1, 5, 6). `Habits` has only `name` and `color`; the mobile screens omit these elements for v1.
- The same habit appearing more than once in a routine (the primary key is `(routineId, habitId)`).

---

## Stitch Screen Mapping & UX Requirements

| # | Screen Name & ID | UI Data & Interactions | Backend Operations |
|---|---|---|---|
| **1** | **Routine Detail Preview**<br>`37104ba5aca94716b3fdb55355df2b81` | • Routine name, description, color, cadence badge (e.g. *Morning Cadence*).<br>• Summary: step count and total duration (e.g. `4 steps · ~22 min total`).<br>• Ordered steps: step number, habit name, duration badge.<br>• "Start Routine" CTA (disabled when the routine has no active steps). | `GET /routines/:id` |
| **2** | **Routines Home**<br>`4efa2478aaf241b6b0ce465e2a1cc99b` | • Routine cards with cadence tag, step count, total duration, habit pills.<br>• Quick "Start" button per card.<br>• "+ Create Routine" button. | `GET /routines` |
| **3** | **Create Routine**<br>`04149fd7c3f54e26a2ce66cfae468647` | • Name, color picker, description.<br>• "Select Habits from Today" bottom sheet (user's active habits).<br>• Ordered step list with drag handles and remove buttons.<br>• "Create Routine" submission. | `GET /habits` *(existing)*<br>`POST /routines` |
| **4** | **Edit Routine**<br>`fa04d39476994b879ba44b87df557d1d` | • Edit name, description, color, cadence.<br>• Reorder, add and remove steps; duration dropdown per step (`2 min`, `5 min`, `10 min`).<br>• Total duration recomputed on the client.<br>• "Save Changes" and "Delete Routine" (confirmation states habits on Today are kept). | `PATCH /routines/:id`<br>`DELETE /routines/:id` |
| **5 & 6** | **Routine Execution** (Step 1 & Step 2)<br>`3c3e8b254cf84f48bf9d146472f04843`<br>`ccd38dc4317d43768539f0d34c1bd475` | • Countdown timer for the active step's `durationMinutes`.<br>• Habit name.<br>• Pause / Resume / Skip.<br>• **"Done & Next"** logs the active habit on Today.<br>• Toast: *"Step 1 logged to Today (+2 min) · +1%"*. | `POST /habits/:id/entries`<br>*(existing `EntriesService.checkOff`)* |
| **7** | **Calm Routine Completed**<br>`3ef548383cfc42fdaa0dc035266f6d70` | • Celebratory emblem with `+1.0%` momentum indicator.<br>• Summary of the steps done in this session, with durations — held in app memory from the play session, not fetched.<br>• Status line reflects what happened: *"All 4 habits marked completed on Today"*, or *"3 of 4 habits logged · 1 skipped"* when steps were skipped. "Streak" here means the habits' own streaks. | None required. Optionally `GET /habits?date=YYYY-MM-DD` to refresh Today. |

---

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| **Step Duration Storage** | Add `durationMinutes Int @default(5)` to `routine_habits` | Drives the execution timer and the `~22 min total` summary. Stored on the join row so the same habit can have different durations in different routines. This is a *planned* duration; actual time spent is not recorded. |
| **Routine Cadence** | Add `cadence String?` to `routines` | Display-only badge (`Morning`, `Afternoon`, `Evening`, `Weekend`). A plain string keeps it flexible; the DTO trims it and caps length to avoid near-duplicate values. |
| **Execution Architecture** | Client-driven, server-stateless, via `POST /habits/:id/entries` | Each "Done & Next" logs that habit's entry for the day, which updates its streak and Today. No run or session is stored (see Product Scope). The existing endpoint upserts, so app retries are safe. |
| **Cascade Behavior** | Non-destructive deletion | Deleting a routine removes only its `routine_habits` rows (DB cascade). `habits` and `habit_entries` are untouched. |
| **Step Order** | Array position is the order | Requests send steps as an ordered array without an `order` field. The service writes `order = index + 1`. One source of truth, and the client's drag-and-drop list maps directly to it. |
| **Step Replacement** | Transactional replace on update | `PATCH` with `steps` deletes and re-creates the routine's `routine_habits` inside one interactive `prisma.$transaction`, together with the metadata update. |
| **Module Location** | Replace the scaffold in `src/routine/` | Avoids two modules and two URL prefixes. The controller path changes from `routine` to `routines` to match the plural `habits` route. |

---

## Data Model (Prisma Contract)

The database is migrated from `backend/prisma8/contract.prisma` (Prisma 8). Two additive columns, no backfill needed:

```prisma
model Routines {
  ...
  cadence       String?                     // NEW
  ...
}

model RoutineHabits {
  ...
  durationMinutes Int      @default(5)      // NEW
  ...
}
```

### Schema workflow
Queries go through `PrismaService`, which extends the Prisma 7 client generated into `generated/prisma` from `backend/prisma/schema.prisma`. The two schemas describe the same tables and must change together:

1. Edit `prisma8/contract.prisma`, then `pnpm prisma contract emit` and `pnpm prisma db update --dry-run`. For this feature the DDL must be exactly: add `routines.cadence`, add `routine_habits.durationMinutes`, and drop the unused `_prisma_migrations` table.
2. Apply with `pnpm prisma db update`.
3. Mirror the change in `prisma/schema.prisma` (`Routine.cadence`, `RoutineHabit.durationMinutes`, relations `Routine.steps`, `Habit.routineSteps`), then `pnpm prisma:generate` (Prisma 7 CLI via `prisma7.config.ts`).

### Field notes
- **`Routine.cadence`** — optional display tag.
- **`RoutineHabit.order`** — 1-based position, written by the service from the array index.
- **`RoutineHabit.durationMinutes`** — planned minutes for the step, 1–180.
- **`Routine.userId`** — scopes every operation; deleting the user cascades their routines.

---

## Step Visibility Rules

A step is **active** when its habit is not archived (`archivedAt IS NULL`).

| Situation | Behavior |
|---|---|
| Habit archived after being added | Step is hidden: excluded from `steps`, `stepCount`, `totalDurationMinutes` and `completedToday`. The join row is kept, so un-archiving the habit brings the step back. |
| Habit deleted | The join row is removed by DB cascade. |
| Routine has no active steps | Still returned by `GET`, with `stepCount: 0`, `totalDurationMinutes: 0`, `completedToday: false`. The app shows an empty state and disables Start. |
| `PATCH` with `steps` on a routine that has hidden archived steps | The replace removes them, since the client never saw them. |

---

## API Endpoints Specification

All endpoints live in `RoutineController` (`@Controller('routines')`), use `@UseGuards(JwtAuthGuard)`, `@ApiBearerAuth()`, and `@CurrentUser('id') userId: string`, matching `HabitController`.

### Routine response shape

Used by `GET /routines` (as an array), `GET /routines/:id`, `POST` and `PATCH`:

```json
{
  "id": "e0b82f1b-4f91-4d32-9b2e-0a56885df4b1",
  "name": "Morning Ritual",
  "description": "Start your morning with intention and quiet focus.",
  "color": "#4d6054",
  "cadence": "Morning",
  "stepCount": 4,
  "totalDurationMinutes": 22,
  "completedToday": false,
  "steps": [
    { "habitId": "c1f7a3d2-6e21-4f11-9a3b-9e451b6a22c1", "name": "Drink Water",       "color": "#4d6054", "order": 1, "durationMinutes": 2,  "doneToday": true },
    { "habitId": "d2f8b4e3-7f32-4e22-8b4c-0f562c7b33d2", "name": "Gentle Stretch",    "color": "#4c5f69", "order": 2, "durationMinutes": 5,  "doneToday": false },
    { "habitId": "e3a9c5f4-8a43-4f33-9c5d-1a673d8c44e3", "name": "Mindful Stillness", "color": "#7c5454", "order": 3, "durationMinutes": 10, "doneToday": false },
    { "habitId": "f4b0d6a5-9b54-4a44-ad6e-2b784e9d55f4", "name": "Journal",           "color": "#66796c", "order": 4, "durationMinutes": 5,  "doneToday": false }
  ],
  "createdAt": "2026-09-25T08:00:00.000Z",
  "updatedAt": "2026-09-25T08:00:00.000Z"
}
```

- `steps` contains active steps only, sorted by `order`.
- `stepCount` and `totalDurationMinutes` are computed from active steps.
- `doneToday` / `completedToday` are present only when a `date` query is given (same convention as `GET /habits?date=`). `doneToday` is `true` if the habit has an entry on that date; `completedToday` is `true` if there is at least one active step and every active step is `doneToday`. A habit checked off outside the routine also counts — acceptable because routines are not tracked on their own.
- The `date` query is parsed with the existing `standardizeDate` / `formatDate` helpers (`src/utils/dayjs.ts`) and compared by day key, as `HabitService.getHabits` does.
- Entries for all steps of all returned routines are fetched in **one** query: `habitEntry.findMany({ where: { habitId: { in: allHabitIds }, date } })`. No per-routine or per-step queries.

---

### 1. `GET /routines`
Lists the user's routines, newest first.

- **Query**: `date` (optional, `YYYY-MM-DD`).
- **Response `200 OK`**: array of the routine response shape.

---

### 2. `GET /routines/:id`
- **Parameters**: `id` (`ParseUUIDPipe`)
- **Query**: `date` (optional, `YYYY-MM-DD`)
- **Response `200 OK`**: routine response shape.
- **Errors**: `404 Not Found` if the routine doesn't exist or belongs to another user.

---

### 3. `POST /routines`
- **Request Body**:
```json
{
  "name": "Morning Ritual",
  "description": "Start your morning with intention and quiet focus.",
  "color": "#4d6054",
  "cadence": "Morning",
  "steps": [
    { "habitId": "c1f7a3d2-6e21-4f11-9a3b-9e451b6a22c1", "durationMinutes": 2 },
    { "habitId": "d2f8b4e3-7f32-4e22-8b4c-0f562c7b33d2", "durationMinutes": 5 },
    { "habitId": "e3a9c5f4-8a43-4f33-9c5d-1a673d8c44e3", "durationMinutes": 10 },
    { "habitId": "f4b0d6a5-9b54-4a44-ad6e-2b784e9d55f4", "durationMinutes": 5 }
  ]
}
```
- **Validation (DTO)**:
  - `name`: string, trimmed, 1–100 characters, required.
  - `description`: string, optional, max 500 characters.
  - `color`: optional, `@IsHexColor()` (same as `CreateHabitDto`).
  - `cadence`: string, optional, trimmed, 1–30 characters.
  - `steps`: array, 1–20 items, required. Each item `{ habitId: UUID, durationMinutes?: int 1–180 }` (defaults to 5).
- **Validation (service)**:
  - No duplicate `habitId` in `steps` → `400 Bad Request` ("Each habit can appear only once in a routine").
  - Every `habitId` belongs to the user and is not archived → otherwise `400 Bad Request` (see Security).
- **Behavior**: creates the routine and its `routine_habits` rows (`order = index + 1`) in one transaction.
- **Response `201 Created`**: routine response shape (without `date` fields).

---

### 4. `PATCH /routines/:id`
- **Parameters**: `id` (`ParseUUIDPipe`)
- **Request Body**: any subset of the `POST` fields. If `steps` is present it follows the same rules (1–20 items, no duplicates, owned and active) and **replaces** the full sequence.
```json
{
  "name": "Morning Ritual (Updated)",
  "steps": [
    { "habitId": "c1f7a3d2-6e21-4f11-9a3b-9e451b6a22c1", "durationMinutes": 3 },
    { "habitId": "d2f8b4e3-7f32-4e22-8b4c-0f562c7b33d2", "durationMinutes": 7 }
  ]
}
```
- **Behavior** (one interactive `$transaction`):
  1. Load the routine with `where: { id, userId }` → `404` if missing.
  2. If `steps` is present: validate the habits, `deleteMany` the routine's `routine_habits`, `createMany` the new rows with `order = index + 1`.
  3. Update the supplied metadata fields (`updatedAt` is set by `@updatedAt`). Only supplied fields are written (same approach as `HabitService.updateHabits`).
- **Response `200 OK`**: routine response shape.

---

### 5. `DELETE /routines/:id`
- **Parameters**: `id` (`ParseUUIDPipe`)
- **Behavior**: `findFirst({ where: { id, userId } })` → `404` if missing; then delete. The DB cascade removes `routine_habits`; `habits` and `habit_entries` are untouched.
- **Response `200 OK`**: same response format as `DELETE /habits/:id`.

---

### 6. Habit Check-Off During Routine Execution
*(Reuses the existing `POST /habits/:id/entries` from `EntriesModule` — no new endpoint.)*

- On **Done & Next** for a step:
  - Request: `POST /habits/c1f7a3d2-6e21-4f11-9a3b-9e451b6a22c1/entries`
  - Body: `{ "date": "2026-09-25" }`
  - The service upserts on `(habitId, date)`, so retries and steps already done earlier today are safe.
- **Skip** sends nothing. The app tracks done vs. skipped steps in memory for the Completed screen.
- Whether check-offs queue while offline depends on the mobile app's existing request handling; this spec adds nothing server-side for it.

---

## Security & Multi-Tenancy

1. **User scoping**: every routine query filters on `userId`. Another user's routine returns `404`, not `403`, so the API does not reveal whether it exists.
2. **Habit ownership check** on `POST` and on `PATCH` with `steps`:
   ```ts
   const habitIds = dto.steps.map((s) => s.habitId);
   if (new Set(habitIds).size !== habitIds.length) {
     throw new BadRequestException('Each habit can appear only once in a routine');
   }
   const owned = await tx.habit.count({
     where: { id: { in: habitIds }, userId, archivedAt: null },
   });
   if (owned !== habitIds.length) {
     throw new BadRequestException('One or more habits are invalid or do not belong to you');
   }
   ```
   The duplicate check runs first so the count comparison can't be thrown off by repeated IDs.

---

## File Structure & Changes

All routine code lives in the existing `backend/src/routine/` folder.

### Replace (scaffold → real implementation)
- `src/routine/routine.controller.ts` — `@Controller('routines')`, guards, Swagger annotations, `ParseUUIDPipe`.
- `src/routine/routine.service.ts` — CRUD, ownership and habit validation, step visibility, totals, transactions.
- `src/routine/routine.module.ts` — add `PrismaService` to providers.
- `src/routine/dto/create-routine.dto.ts` — validated create body.

### Keep
- `src/routine/dto/update-routine.dto.ts` — already `PartialType(CreateRoutineDto)`.

### Create
- `src/routine/dto/routine-step.dto.ts` — `{ habitId, durationMinutes? }`.
- `src/routine/dto/get-routines-query.dto.ts` — optional `date`.
- `src/routine/routine.service.spec.ts` — unit tests: CRUD, step order from array index, duplicate habits, foreign and archived habits, archived-step visibility, empty routine, `completedToday`, cross-user `404`.

### Modify
- `backend/prisma8/contract.prisma` — `routines.cadence`, `routine_habits.durationMinutes`.
- `backend/prisma/schema.prisma` + `backend/prisma7.config.ts` — Prisma 7 client schema (removed in commit 37963bc, restored with the routine models) and the `prisma:generate` script.
- `backend/src/app.module.ts` — no change; `RoutineModule` is already registered.
