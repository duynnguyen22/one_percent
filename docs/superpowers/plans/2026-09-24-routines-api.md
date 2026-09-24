# Routines API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `/routine` scaffold with a real `/routines` API that powers the six Flutter routine screens.

**Architecture:** A NestJS `routine` module built like `habit/` and `entries/`: validated DTOs, then a service that checks ownership on every query, then a pure mapper that shapes the response. Streaks are computed when requested and never stored.

**Tech stack:** NestJS 11 · class-validator · Prisma 7.8.0 client (queries) · Prisma 8 rc contract (database schema) · PostgreSQL · Jest

**Spec:** There is no separate spec. The decisions below were agreed with Duy on 2026-09-24. The screens are in `mobile/lib/features/routines/presentation/pages/`.

---

## At a glance

| # | Task | Delivers | Tests |
|---|---|---|---|
| 1 | Schema | New columns + `routine_runs` table in the DB, and a regenerated Prisma client | build + existing suite |
| 2 | DTOs | Request validation for routines, steps and runs | `routine.dto.spec.ts` |
| 3 | Create & read | `create`, `findAll`, `findOne` + response mapper | `routine.mapper.spec.ts`, `routine.service.spec.ts` |
| 4 | Update & delete | Step replacement in one transaction; delete that keeps habits | `routine.service.spec.ts` |
| 5 | Runs & streak | `recordRun`: one run per day, streak from runs | `routine.service.spec.ts` |
| 6 | HTTP + docs | Controller, module wiring, README, curl smoke test | smoke script |

All commands run from `backend/` unless a step says otherwise.

---

## How it works

### Data model

```
routines ──< routine_habits >── habits ──< habit_entries
   │           (order, durationMinutes)
   └──< routine_runs (date, completedSteps)   ← new
```

- A **routine** is a named, colored group of habits with a `cadence` (Morning, Evening, …).
- A **step** is a `routine_habits` row: which habit, where it sits in the order, and how many minutes it takes.
- A **run** records that the routine was played on a day. There is at most one run per routine per day.

A step's title and color come from its habit. The icon, category, subtitle, mindful intention, portion goal, sub-steps and energy level are **not** stored on the server. They are the mobile app's concern.

### Which screen calls what

| Screen | Calls |
|---|---|
| Routines Home | `GET /routines` |
| Routine Detail | `GET /routines/:id` |
| Create Routine | `GET /habits` (existing, for the habit picker), then `POST /routines` |
| Edit Routine | `GET /routines/:id`, then `PATCH /routines/:id` or `DELETE /routines/:id` |
| Execution: **Done & Next** | `POST /habits/:habitId/entries` (existing; this is what checks the habit off on Today) |
| Execution: **Skip** | nothing |
| Completed | `POST /routines/:id/runs` returns `{ completedSteps, totalSteps, currentStreak }` |

### Response shape (`RoutineView`)

Every routine endpoint returns this, except delete and runs:

```json
{
  "id": "uuid", "name": "Morning Ritual", "description": "Start grounded.",
  "color": "#4D6054", "cadence": "Morning",
  "createdAt": "…", "updatedAt": "…",
  "steps": [ { "habitId": "uuid", "name": "Drink Water", "color": "#4D6054", "durationMinutes": 2 } ],
  "stepCount": 1, "totalMinutes": 2
}
```

- `steps` is already in play order.
- Steps whose habit is **archived** are left out of `steps`, `stepCount` and `totalMinutes`. An archived habit can't be checked off, so the player must never offer it. Unarchiving the habit brings the step back.

### Why there are two Prisma files

The app queries the database through the **Prisma 7** client (`generated/prisma`). The last commit moved the schema to a **Prisma 8** contract and deleted the v7 schema, so the v7 client can no longer be regenerated, and it has no Routine model.

| File | Role | Command |
|---|---|---|
| `prisma8/contract.prisma` | Source of truth for the **database** | `pnpm db:emit && pnpm db:update` |
| `prisma/schema.prisma` (restored) | Source for the **query client** | `pnpm prisma:generate` |

> ⚠️ **Change both files together.** A column added to one must be added to the other.
> The v7 CLI can't read `prisma.config.ts`, which is v8-only, so v7 gets its own `prisma7.config.ts`.

---

## Rules for every task

**API**
- Base path `/routines`. Every route has `@UseGuards(JwtAuthGuard)`, `@ApiBearerAuth()` and `@ApiTags('Routine')`.
- Someone else's routine → **404** `Routine not found!`. Never return 403, and never reveal that the routine exists.
- Someone else's habit, or an archived habit, in `steps` → **400**.
- Errors use the existing `HttpExceptionFilter` envelope. Don't add a new format.
- Deleting a routine never touches `habits` or `habit_entries`. The Edit screen promises this.

**Validation limits**

| Field | Rule |
|---|---|
| `name` | trimmed, 1–60 chars |
| `description` | ≤ 280 chars |
| `color` | hex (`@IsHexColor`, same as habits) |
| `cadence` | `Morning` · `Afternoon` · `Evening` · `Weekend` · `Anytime` (default `Anytime`) |
| `steps` | 1–20 items, each `habitId` a UUID and unique within the routine |
| `durationMinutes` | integer 1–120 |

**Dates:** Dates are `YYYY-MM-DD` days stored at UTC midnight. Write them with `standardizeDate` / `today()` and read them with `formatDate` (`src/utils/dayjs.ts`).

**Tooling**
- Use `prisma@7.8.0` for `generate`. Use the repo's `prisma` (8.0.0-rc.15) for `contract emit` and `db update`.
- Run `pnpm lint` before every commit. It applies Prettier with `--fix`, so re-stage any file it rewrites. Errors block the commit. Warnings (`no-unsafe-argument` from `expect.objectContaining`) are fine.
- **Test baseline:** `pnpm test` currently gives 41 passed and 2 failed (`email.service.spec.ts`, `password-reset.service.spec.ts`). Those failures are out of scope. "Tests pass" means **no new failures**.

---

## What is most likely to break

These are the inputs a real user will hit. Each one has a test pinned to it.

| # | Situation | Expected | Pinned by |
|---|---|---|---|
| 1 | Same habit added twice to one routine | 400 from validation, not a 500 from the DB primary key | Task 2 · `rejects a habit used twice` |
| 2 | A habit is archived after it was added to a routine | It disappears from `steps` / `stepCount` / `totalMinutes`; runs are capped at the remaining steps | Task 3 · `leaves archived habits out` · Task 5 · `caps completedSteps at active steps` |
| 3 | Another user's IDs | Their routine → 404 everywhere; their habit in `steps` → 400, with no write | Task 3 · `404s a routine owned by someone else`, `rejects a habit that is not the user's active habit` · Task 4 · `does not write when a step habit is foreign` |
| 4 | Routine finished twice in one day | One run row, the higher `completedSteps` is kept, no double streak | Task 5 · `keeps the best completedSteps for the day` |
| 5 | Whitespace-only name `"   "` | 400, not a blank card | Task 2 · `rejects a blank name` |

---

## Files

```
backend/
├── prisma8/contract.prisma            MODIFY   routines.cadence, routine_habits.durationMinutes, routine_runs
├── prisma/schema.prisma               CREATE   v7 client schema mirroring the contract
├── prisma7.config.ts                  CREATE   config for `prisma@7.8.0 generate` only
├── package.json                       MODIFY   db:emit / db:update / prisma:generate scripts
├── tsconfig.build.json                MODIFY   exclude **/testing/** from the build
└── src/routine/
    ├── routine.constants.ts           CREATE   cadences + limits
    ├── dto/
    │   ├── routine-step.dto.ts        CREATE   { habitId, durationMinutes }
    │   ├── create-routine.dto.ts      REPLACE  scaffold
    │   ├── update-routine.dto.ts      KEEP     PartialType(CreateRoutineDto), unchanged
    │   ├── create-routine-run.dto.ts  CREATE   { date?, completedSteps }
    │   └── routine.dto.spec.ts        CREATE
    ├── types/
    │   ├── routine.types.ts           CREATE   RoutineStepView, RoutineView, RoutineRunResult
    │   └── index.ts                   CREATE
    ├── routine.mapper.ts              CREATE   ROUTINE_INCLUDE, RoutineWithSteps, toRoutineView, toStepRows
    ├── routine.mapper.spec.ts         CREATE
    ├── testing/routine.fixtures.ts    CREATE   shared test rows (excluded from build)
    ├── routine.service.ts             REPLACE  scaffold
    ├── routine.service.spec.ts        CREATE
    ├── routine.controller.ts          REPLACE  scaffold
    └── routine.module.ts              MODIFY   add PrismaService
README.md                              MODIFY   API table, quick start, roadmap
```

---

## Task 1: Schema

**Builds:** the new DB columns and `routine_runs` table, plus a Prisma client that knows about routines.

**Files:** `prisma8/contract.prisma` (modify) · `prisma/schema.prisma` (create) · `prisma7.config.ts` (create) · `package.json` (modify)

**Produces for later tasks**
- Delegates: `prisma.routine`, `prisma.routineHabit`, `prisma.routineRun`
- Relations: `Routine.steps: RoutineHabit[]`, `Routine.runs: RoutineRun[]`, `RoutineHabit.habit: Habit`, `Habit.routineSteps`
- Compound keys: `routineId_habitId` (RoutineHabit) and `routineId_date` (RoutineRun)
- Types `Prisma.RoutineInclude` and `Prisma.RoutineGetPayload`, all from `generated/prisma/client`

- [ ] **Step 1: Edit the v8 contract**

In `prisma8/contract.prisma`, replace the `Routines` model with:

```prisma
model Routines {
  id            String          @id(map: "routines_pkey")
  userId        String
  name          String
  description   String?
  color         String?
  cadence       String          @default("Anytime")
  createdAt     Timestamp(3)    @default(now())
  updatedAt     Timestamp(3)
  routineHabits RoutineHabits[]
  routineRuns   RoutineRuns[]
  user          Users           @relation(fields: [userId], references: [id], onDelete: Cascade, onUpdate: Cascade, map: "routines_userId_fkey")

  @@index([userId], map: "routines_userId_idx")
  @@map("routines")
}
```

In `RoutineHabits`, add this line under `order     Int`:

```prisma
  durationMinutes Int @default(5)
```

At the end of the file, add:

```prisma
model RoutineRuns {
  id             String       @id(map: "routine_runs_pkey")
  routineId      String
  date           Date
  completedSteps Int
  createdAt      Timestamp(3) @default(now())
  routine        Routines     @relation(fields: [routineId], references: [id], onDelete: Cascade, onUpdate: Cascade, map: "routine_runs_routineId_fkey", index: false)

  @@index([routineId, date], map: "routine_runs_routineId_date_key", unique: true)
  @@map("routine_runs")
}
```

- [ ] **Step 2: Preview the database change**

Run: `pnpm prisma contract emit && pnpm prisma db update --dry-run --format markdown`

Expected DDL (the order may differ):

```
DROP TABLE "public"."_prisma_migrations";
CREATE TABLE "public"."routine_runs" ( … );
ALTER TABLE "public"."routine_habits" ADD COLUMN "durationMinutes" int4 DEFAULT 5 NOT NULL;
ALTER TABLE "public"."routines" ADD COLUMN "cadence" text DEFAULT 'Anytime' NOT NULL;
CREATE UNIQUE INDEX "routine_runs_routineId_date_key" …;
ALTER TABLE "public"."routine_runs" ADD CONSTRAINT "routine_runs_routineId_fkey" …;
```

> ⚠️ `DROP TABLE _prisma_migrations` is expected. It is the old Prisma 7 migration history: v8 doesn't use it, and it holds no app data.
> **If the preview contains any other `DROP`, stop and ask Duy.**

- [ ] **Step 3: Apply it**

Run: `pnpm prisma db update`. When prompted, type the database name (`habit_tracker` by default) to confirm the drop.

Check: `pnpm prisma db update --dry-run` should now report no operations.

- [ ] **Step 4: Restore the v7 client schema**

Create `prisma/schema.prisma`:

```prisma
// Prisma 7 client schema. Queries run through the client generated from this
// file; the database itself is migrated from prisma8/contract.prisma. Change
// both together.

generator client {
  provider     = "prisma-client"
  output       = "../generated/prisma"
  moduleFormat = "cjs"
}

datasource db {
  provider = "postgresql"
}

model User {
  id                 String              @id @default(uuid())
  email              String              @unique
  userName           String?
  userPhone          String?
  avatarUrl          String?
  passwordHash       String
  createdAt          DateTime            @default(now())
  habits             Habit[]
  passwordResetCodes PasswordResetCode[]
  routines           Routine[]

  @@map("users")
}

model Habit {
  id           String         @id @default(uuid())
  userId       String
  name         String
  color        String?
  createdAt    DateTime       @default(now())
  archivedAt   DateTime?
  user         User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  entries      HabitEntry[]
  routineSteps RoutineHabit[]

  @@map("habits")
}

model HabitEntry {
  id        String   @id @default(uuid())
  habitId   String
  date      DateTime @db.Date
  createdAt DateTime @default(now())
  habit     Habit    @relation(fields: [habitId], references: [id], onDelete: Cascade)

  @@unique([habitId, date])
  @@map("habit_entries")
}

model PasswordResetCode {
  id         String    @id @default(uuid())
  userId     String
  codeHash   String
  expiresAt  DateTime
  attempts   Int       @default(0)
  verifiedAt DateTime?
  consumedAt DateTime?
  createdAt  DateTime  @default(now())
  user       User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, createdAt])
  @@map("password_reset_codes")
}

model Routine {
  id          String         @id @default(uuid())
  userId      String
  name        String
  description String?
  color       String?
  cadence     String         @default("Anytime")
  createdAt   DateTime       @default(now())
  updatedAt   DateTime       @updatedAt
  user        User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  steps       RoutineHabit[]
  runs        RoutineRun[]

  @@index([userId])
  @@map("routines")
}

model RoutineHabit {
  routineId       String
  habitId         String
  order           Int
  durationMinutes Int     @default(5)
  routine         Routine @relation(fields: [routineId], references: [id], onDelete: Cascade)
  habit           Habit   @relation(fields: [habitId], references: [id], onDelete: Cascade)

  @@id([routineId, habitId])
  @@index([habitId])
  @@map("routine_habits")
}

model RoutineRun {
  id             String   @id @default(uuid())
  routineId      String
  date           DateTime @db.Date
  completedSteps Int
  createdAt      DateTime @default(now())
  routine        Routine  @relation(fields: [routineId], references: [id], onDelete: Cascade)

  @@unique([routineId, date])
  @@map("routine_runs")
}
```

The first four models are the pre-v8 schema (`git show 37963bc^:backend/prisma/schema.prisma`) with the new relation fields added. **Keep their relation names** (`entries`, `habits`, `passwordResetCodes`, `user`), because existing services use them.

- [ ] **Step 5: Add the v7 config and scripts**

Create `prisma7.config.ts`:

```ts
// Config for the Prisma 7 CLI, used only by `pnpm prisma:generate`.
// prisma.config.ts is the Prisma 8 config; the v7 CLI cannot parse it.
export default {
  schema: 'prisma/schema.prisma',
};
```

Add to `"scripts"` in `package.json`:

```json
    "db:emit": "prisma contract emit",
    "db:update": "prisma db update",
    "prisma:generate": "pnpm dlx prisma@7.8.0 generate --config prisma7.config.ts",
```

- [ ] **Step 6: Generate and check nothing regressed**

Run: `pnpm prisma:generate && ls generated/prisma/models`
Expected: `✔ Generated Prisma Client (7.8.0)`. The models list includes `Routine.ts RoutineHabit.ts RoutineRun.ts` next to `Habit.ts HabitEntry.ts PasswordResetCode.ts User.ts`.

Run: `pnpm build && pnpm test`
Expected: the build succeeds and the tests match the baseline (41 passed, 2 failed).

- [ ] **Step 7: Commit**

```bash
git add prisma8/contract.prisma prisma/schema.prisma prisma7.config.ts package.json
git commit -m "feat(routine): add cadence, step duration and routine_runs; restore v7 client schema"
```

---

## Task 2: Constants and DTOs

**Builds:** request validation for create, update and run bodies.

**Files:** `src/routine/routine.constants.ts` (create) · `dto/routine-step.dto.ts` (create) · `dto/create-routine.dto.ts` (replace) · `dto/create-routine-run.dto.ts` (create) · `dto/routine.dto.spec.ts` (test). Leave `dto/update-routine.dto.ts` as it is: it's already `PartialType(CreateRoutineDto)`.

**Produces for later tasks**
- `ROUTINE_CADENCES` and `type RoutineCadence`
- `RoutineStepDto { habitId: string; durationMinutes: number }`
- `CreateRoutineDto { name; description?; color?; cadence?: RoutineCadence; steps: RoutineStepDto[] }`
- `UpdateRoutineDto`: every field of `CreateRoutineDto`, optional
- `CreateRoutineRunDto { date?: string; completedSteps: number }`

- [ ] **Step 1: Write the failing tests**

Create `src/routine/dto/routine.dto.spec.ts`:

```ts
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateRoutineDto } from './create-routine.dto';
import { UpdateRoutineDto } from './update-routine.dto';
import { CreateRoutineRunDto } from './create-routine-run.dto';

const HABIT_A = 'bbbbbbbb-0000-4000-8000-000000000001';
const HABIT_B = 'bbbbbbbb-0000-4000-8000-000000000002';

/// Runs the same transform + validation the global ValidationPipe does and
/// returns the names of the top-level properties that failed.
async function failures<T extends object>(
  cls: new () => T,
  body: Record<string, unknown>,
): Promise<string[]> {
  const errors = await validate(plainToInstance(cls, body), {
    whitelist: true,
  });
  return errors.map((error) => error.property);
}

const validBody = () => ({
  name: 'Morning Ritual',
  description: 'Start the day grounded.',
  color: '#4D6054',
  cadence: 'Morning',
  steps: [
    { habitId: HABIT_A, durationMinutes: 2 },
    { habitId: HABIT_B, durationMinutes: 10 },
  ],
});

describe('CreateRoutineDto', () => {
  it('accepts a complete body', async () => {
    expect(await failures(CreateRoutineDto, validBody())).toEqual([]);
  });

  it('accepts a body without optional fields', async () => {
    const { name, steps } = validBody();
    expect(await failures(CreateRoutineDto, { name, steps })).toEqual([]);
  });

  it('trims the name', () => {
    const dto = plainToInstance(CreateRoutineDto, {
      ...validBody(),
      name: '  Morning Ritual  ',
    });
    expect(dto.name).toBe('Morning Ritual');
  });

  it('rejects a blank name', async () => {
    expect(
      await failures(CreateRoutineDto, { ...validBody(), name: '   ' }),
    ).toEqual(['name']);
  });

  it('rejects a name over 60 characters', async () => {
    expect(
      await failures(CreateRoutineDto, { ...validBody(), name: 'x'.repeat(61) }),
    ).toEqual(['name']);
  });

  it('rejects an unknown cadence', async () => {
    expect(
      await failures(CreateRoutineDto, { ...validBody(), cadence: 'Midnight' }),
    ).toEqual(['cadence']);
  });

  it('rejects a non-hex color', async () => {
    expect(
      await failures(CreateRoutineDto, { ...validBody(), color: 'green' }),
    ).toEqual(['color']);
  });

  it('rejects an empty step list', async () => {
    expect(
      await failures(CreateRoutineDto, { ...validBody(), steps: [] }),
    ).toEqual(['steps']);
  });

  it('rejects more than 20 steps', async () => {
    const steps = Array.from({ length: 21 }, (_, i) => ({
      habitId: `bbbbbbbb-0000-4000-8000-${String(i).padStart(12, '0')}`,
      durationMinutes: 1,
    }));
    expect(await failures(CreateRoutineDto, { ...validBody(), steps })).toEqual(
      ['steps'],
    );
  });

  it('rejects a habit used twice', async () => {
    const steps = [
      { habitId: HABIT_A, durationMinutes: 2 },
      { habitId: HABIT_A, durationMinutes: 5 },
    ];
    expect(await failures(CreateRoutineDto, { ...validBody(), steps })).toEqual(
      ['steps'],
    );
  });

  it.each([0, 121, 2.5, '5'])(
    'rejects durationMinutes %p',
    async (durationMinutes) => {
      const steps = [{ habitId: HABIT_A, durationMinutes }];
      expect(
        await failures(CreateRoutineDto, { ...validBody(), steps }),
      ).toEqual(['steps']);
    },
  );

  it('rejects a habitId that is not a UUID', async () => {
    const steps = [{ habitId: 'sh-1', durationMinutes: 2 }];
    expect(await failures(CreateRoutineDto, { ...validBody(), steps })).toEqual(
      ['steps'],
    );
  });
});

describe('UpdateRoutineDto', () => {
  it('accepts an empty body', async () => {
    expect(await failures(UpdateRoutineDto, {})).toEqual([]);
  });

  it('accepts a rename alone', async () => {
    expect(await failures(UpdateRoutineDto, { name: 'Dawn' })).toEqual([]);
  });

  it('still rejects an empty step list when steps are sent', async () => {
    expect(await failures(UpdateRoutineDto, { steps: [] })).toEqual(['steps']);
  });

  it('still rejects a blank name when a name is sent', async () => {
    expect(await failures(UpdateRoutineDto, { name: ' ' })).toEqual(['name']);
  });
});

describe('CreateRoutineRunDto', () => {
  it('accepts completedSteps without a date', async () => {
    expect(await failures(CreateRoutineRunDto, { completedSteps: 1 })).toEqual(
      [],
    );
  });

  it('accepts a YYYY-MM-DD date', async () => {
    expect(
      await failures(CreateRoutineRunDto, {
        completedSteps: 3,
        date: '2026-09-24',
      }),
    ).toEqual([]);
  });

  it.each([0, -1, 1.5])('rejects completedSteps %p', async (completedSteps) => {
    expect(await failures(CreateRoutineRunDto, { completedSteps })).toEqual([
      'completedSteps',
    ]);
  });

  it('rejects a malformed date', async () => {
    expect(
      await failures(CreateRoutineRunDto, {
        completedSteps: 1,
        date: 'yesterday',
      }),
    ).toEqual(['date']);
  });
});
```

- [ ] **Step 2: Watch it fail**

Run: `pnpm test -- src/routine/dto`
Expected: FAIL (`Cannot find module './create-routine-run.dto'`; the scaffold DTO has no validators).

- [ ] **Step 3: Implement**

Create `src/routine/routine.constants.ts`:

```ts
export const ROUTINE_CADENCES = [
  'Morning',
  'Afternoon',
  'Evening',
  'Weekend',
  'Anytime',
] as const;

export type RoutineCadence = (typeof ROUTINE_CADENCES)[number];

export const ROUTINE_NAME_MAX = 60;
export const ROUTINE_DESCRIPTION_MAX = 280;
export const ROUTINE_STEPS_MAX = 20;
export const STEP_MINUTES_MIN = 1;
export const STEP_MINUTES_MAX = 120;
```

Create `src/routine/dto/routine-step.dto.ts`:

```ts
import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsUUID, Max, Min } from 'class-validator';
import { STEP_MINUTES_MAX, STEP_MINUTES_MIN } from '../routine.constants';

export class RoutineStepDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  habitId: string;

  @ApiProperty({
    minimum: STEP_MINUTES_MIN,
    maximum: STEP_MINUTES_MAX,
    example: 5,
  })
  @IsInt()
  @Min(STEP_MINUTES_MIN)
  @Max(STEP_MINUTES_MAX)
  durationMinutes: number;
}
```

Replace `src/routine/dto/create-routine.dto.ts`:

```ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsHexColor,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import {
  ROUTINE_CADENCES,
  ROUTINE_DESCRIPTION_MAX,
  ROUTINE_NAME_MAX,
  ROUTINE_STEPS_MAX,
  type RoutineCadence,
} from '../routine.constants';
import { RoutineStepDto } from './routine-step.dto';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class CreateRoutineDto {
  @ApiProperty({ example: 'Morning Ritual', maxLength: ROUTINE_NAME_MAX })
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(ROUTINE_NAME_MAX)
  name: string;

  @ApiPropertyOptional({ maxLength: ROUTINE_DESCRIPTION_MAX })
  @Transform(trim)
  @IsOptional()
  @IsString()
  @MaxLength(ROUTINE_DESCRIPTION_MAX)
  description?: string;

  @ApiPropertyOptional({ example: '#4D6054' })
  @IsOptional()
  @IsHexColor()
  color?: string;

  @ApiPropertyOptional({ enum: ROUTINE_CADENCES, default: 'Anytime' })
  @IsOptional()
  @IsIn(ROUTINE_CADENCES)
  cadence?: RoutineCadence;

  /// Play order is array order. A habit may appear once per routine: the
  /// routine_habits primary key is (routineId, habitId).
  @ApiProperty({ type: [RoutineStepDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(ROUTINE_STEPS_MAX)
  @ArrayUnique((step: RoutineStepDto | undefined) => step?.habitId)
  @ValidateNested({ each: true })
  @Type(() => RoutineStepDto)
  steps: RoutineStepDto[];
}
```

Create `src/routine/dto/create-routine-run.dto.ts`:

```ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsInt, IsOptional, Min } from 'class-validator';

export class CreateRoutineRunDto {
  /// The client's local day. Defaults to the server's today, like entries.
  @ApiPropertyOptional({ example: '2026-09-24' })
  @IsOptional()
  @IsDateString()
  date?: string;

  /// Steps finished with "Done & Next". Skipped steps don't count.
  @ApiProperty({ minimum: 1, example: 4 })
  @IsInt()
  @Min(1)
  completedSteps: number;
}
```

- [ ] **Step 4: Watch it pass**

Run: `pnpm test -- src/routine/dto`
Expected: PASS.

> Why `'5'` fails: the global pipe uses `transform: true` without `enableImplicitConversion`, so a JSON string is never turned into a number.

- [ ] **Step 5: Commit**

```bash
git add src/routine/routine.constants.ts src/routine/dto
git commit -m "feat(routine): validated DTOs for routines, steps and runs"
```

---

## Task 3: Mapper, create and read

**Builds:** the response mapper and `create` / `findAll` / `findOne`.

**Files:** `types/routine.types.ts` + `types/index.ts` (create) · `routine.mapper.ts` (create) · `testing/routine.fixtures.ts` (create) · `tsconfig.build.json` (modify) · `routine.service.ts` (replace) · tests: `routine.mapper.spec.ts`, `routine.service.spec.ts`

**Uses:** the Task 1 client (`prisma.routine`, `prisma.habit.count`, Prisma types) and the Task 2 DTOs.

**Produces for later tasks**

| Name | Signature |
|---|---|
| `RoutineStepView` | `{ habitId; name; color: string \| null; durationMinutes }` |
| `RoutineView` | `{ id; name; description: string \| null; color: string \| null; cadence; createdAt; updatedAt; steps; stepCount; totalMinutes }` |
| `RoutineRunResult` | `{ routineId; date: string; completedSteps; totalSteps; currentStreak }` |
| `ROUTINE_INCLUDE`, `RoutineWithSteps` | the Prisma include and its payload type |
| `toRoutineView` | `(routine: RoutineWithSteps) => RoutineView` |
| `toStepRows` | `(steps: RoutineStepDto[]) => { habitId; durationMinutes; order }[]` |
| `RoutineService.create` | `(userId, dto: CreateRoutineDto) => Promise<RoutineView>` |
| `RoutineService.findAll` | `(userId) => Promise<RoutineView[]>` |
| `RoutineService.findOne` | `(userId, id) => Promise<RoutineView>` |
| private `findOwned` | `(userId, id) => Promise<RoutineWithSteps>`; throws `NotFoundException('Routine not found!')` |
| private `assertHabitsUsable` | `(userId, steps) => Promise<void>`; throws `BadRequestException` |

- [ ] **Step 1: Add types and test fixtures** (no behaviour yet; the tests need them)

Create `src/routine/types/routine.types.ts`:

```ts
/** One playable step: a habit plus how long the player gives it. */
export type RoutineStepView = {
  habitId: string;
  name: string;
  color: string | null;
  durationMinutes: number;
};

/** A routine as every /routines endpoint returns it. `steps` is in play order. */
export type RoutineView = {
  id: string;
  name: string;
  description: string | null;
  color: string | null;
  cadence: string;
  createdAt: Date;
  updatedAt: Date;
  steps: RoutineStepView[];
  stepCount: number;
  totalMinutes: number;
};

/** `POST /routines/:id/runs` response, which feeds the Completed screen. */
export type RoutineRunResult = {
  routineId: string;
  date: string;
  completedSteps: number;
  totalSteps: number;
  currentStreak: number;
};
```

Create `src/routine/types/index.ts`:

```ts
export * from './routine.types';
```

Create `src/routine/testing/routine.fixtures.ts`:

```ts
import type { RoutineWithSteps } from '../routine.mapper';

export const USER_ID = 'user-1';
export const ROUTINE_ID = 'aaaaaaaa-0000-4000-8000-000000000001';
export const HABIT_A = 'bbbbbbbb-0000-4000-8000-000000000001';
export const HABIT_B = 'bbbbbbbb-0000-4000-8000-000000000002';
export const HABIT_C = 'bbbbbbbb-0000-4000-8000-000000000003';

export const habitRow = (
  id: string,
  name: string,
  archivedAt: Date | null = null,
) => ({
  id,
  userId: USER_ID,
  name,
  color: '#4D6054',
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  archivedAt,
});

export const stepRow = (
  habit: ReturnType<typeof habitRow>,
  order: number,
  durationMinutes: number,
) => ({ routineId: ROUTINE_ID, habitId: habit.id, order, durationMinutes, habit });

export const routineRow = (
  steps: ReturnType<typeof stepRow>[] = [
    stepRow(habitRow(HABIT_A, 'Drink Water'), 0, 2),
    stepRow(habitRow(HABIT_B, 'Stretch'), 1, 5),
  ],
): RoutineWithSteps => ({
  id: ROUTINE_ID,
  userId: USER_ID,
  name: 'Morning Ritual',
  description: 'Start grounded.',
  color: '#4D6054',
  cadence: 'Morning',
  createdAt: new Date('2026-09-01T00:00:00.000Z'),
  updatedAt: new Date('2026-09-01T00:00:00.000Z'),
  steps,
});
```

In `tsconfig.build.json`, exclude the fixtures from the build:

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts", "**/testing/**"]
}
```

- [ ] **Step 2: Write the failing mapper test**

Create `src/routine/routine.mapper.spec.ts`:

```ts
import { toRoutineView, toStepRows } from './routine.mapper';
import {
  HABIT_A,
  HABIT_B,
  HABIT_C,
  habitRow,
  routineRow,
  stepRow,
} from './testing/routine.fixtures';

describe('toRoutineView', () => {
  it('flattens steps in order and totals their minutes', () => {
    const view = toRoutineView(routineRow());

    expect(view.steps).toEqual([
      { habitId: HABIT_A, name: 'Drink Water', color: '#4D6054', durationMinutes: 2 },
      { habitId: HABIT_B, name: 'Stretch', color: '#4D6054', durationMinutes: 5 },
    ]);
    expect(view.stepCount).toBe(2);
    expect(view.totalMinutes).toBe(7);
  });

  it('never exposes userId', () => {
    expect(toRoutineView(routineRow())).not.toHaveProperty('userId');
  });

  it('leaves archived habits out of steps, count and total', () => {
    const view = toRoutineView(
      routineRow([
        stepRow(habitRow(HABIT_A, 'Drink Water'), 0, 2),
        stepRow(habitRow(HABIT_B, 'Stretch', new Date('2026-09-10')), 1, 5),
        stepRow(habitRow(HABIT_C, 'Journal'), 2, 10),
      ]),
    );

    expect(view.steps.map((step) => step.habitId)).toEqual([HABIT_A, HABIT_C]);
    expect(view.stepCount).toBe(2);
    expect(view.totalMinutes).toBe(12);
  });

  it('handles a routine whose habits are all gone', () => {
    const view = toRoutineView(routineRow([]));

    expect(view.steps).toEqual([]);
    expect(view.stepCount).toBe(0);
    expect(view.totalMinutes).toBe(0);
  });
});

describe('toStepRows', () => {
  it('uses array position as order', () => {
    expect(
      toStepRows([
        { habitId: HABIT_B, durationMinutes: 5 },
        { habitId: HABIT_A, durationMinutes: 2 },
      ]),
    ).toEqual([
      { habitId: HABIT_B, durationMinutes: 5, order: 0 },
      { habitId: HABIT_A, durationMinutes: 2, order: 1 },
    ]);
  });
});
```

- [ ] **Step 3: Watch it fail**

Run: `pnpm test -- src/routine/routine.mapper`
Expected: FAIL with `Cannot find module './routine.mapper'`.

- [ ] **Step 4: Implement the mapper and watch it pass**

Create `src/routine/routine.mapper.ts`:

```ts
import { Prisma } from 'generated/prisma/client';
import { RoutineStepDto } from './dto/routine-step.dto';
import { RoutineView } from './types';

/** Every routine read loads its steps in play order with their habits. */
export const ROUTINE_INCLUDE = {
  steps: { orderBy: { order: 'asc' }, include: { habit: true } },
} as const satisfies Prisma.RoutineInclude;

export type RoutineWithSteps = Prisma.RoutineGetPayload<{
  include: typeof ROUTINE_INCLUDE;
}>;

/**
 * Archived habits are dropped: the entries endpoint refuses to check them off,
 * so the player must not offer them. Unarchiving brings the step back.
 */
export const toRoutineView = (routine: RoutineWithSteps): RoutineView => {
  const steps = routine.steps
    .filter((step) => step.habit.archivedAt === null)
    .map((step) => ({
      habitId: step.habitId,
      name: step.habit.name,
      color: step.habit.color,
      durationMinutes: step.durationMinutes,
    }));

  return {
    id: routine.id,
    name: routine.name,
    description: routine.description,
    color: routine.color,
    cadence: routine.cadence,
    createdAt: routine.createdAt,
    updatedAt: routine.updatedAt,
    steps,
    stepCount: steps.length,
    totalMinutes: steps.reduce((sum, step) => sum + step.durationMinutes, 0),
  };
};

export const toStepRows = (steps: RoutineStepDto[]) =>
  steps.map((step, order) => ({
    habitId: step.habitId,
    durationMinutes: step.durationMinutes,
    order,
  }));
```

Run: `pnpm test -- src/routine/routine.mapper`
Expected: PASS.

- [ ] **Step 5: Write the failing service test**

Create `src/routine/routine.service.spec.ts`. Tasks 4 and 5 append to this file.

```ts
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from 'src/prisma.service';
import { RoutineService } from './routine.service';
import { CreateRoutineDto } from './dto/create-routine.dto';
import {
  HABIT_A,
  HABIT_B,
  ROUTINE_ID,
  USER_ID,
  routineRow,
} from './testing/routine.fixtures';

type PrismaMock = {
  habit: { count: jest.Mock };
  routine: {
    create: jest.Mock;
    findMany: jest.Mock;
    findFirst: jest.Mock;
    update: jest.Mock;
    delete: jest.Mock;
  };
  routineHabit: { deleteMany: jest.Mock };
  routineRun: { findUnique: jest.Mock; upsert: jest.Mock; findMany: jest.Mock };
  $transaction: jest.Mock;
};

const createPrismaMock = (): PrismaMock => {
  const prisma = {
    habit: { count: jest.fn() },
    routine: {
      create: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    routineHabit: { deleteMany: jest.fn() },
    routineRun: { findUnique: jest.fn(), upsert: jest.fn(), findMany: jest.fn() },
    $transaction: jest.fn(),
  };
  // Interactive transactions run the callback against the same mock.
  prisma.$transaction.mockImplementation(
    (callback: (tx: typeof prisma) => unknown) => callback(prisma),
  );
  return prisma;
};

const buildService = async (prisma: PrismaMock) => {
  const moduleRef = await Test.createTestingModule({
    providers: [RoutineService, { provide: PrismaService, useValue: prisma }],
  }).compile();
  return moduleRef.get(RoutineService);
};

const createDto = (): CreateRoutineDto => ({
  name: 'Morning Ritual',
  cadence: 'Morning',
  steps: [
    { habitId: HABIT_A, durationMinutes: 2 },
    { habitId: HABIT_B, durationMinutes: 5 },
  ],
});

describe('RoutineService.create', () => {
  let prisma: PrismaMock;
  let service: RoutineService;

  beforeEach(async () => {
    prisma = createPrismaMock();
    service = await buildService(prisma);
  });

  it('stores steps in array order for the current user', async () => {
    prisma.habit.count.mockResolvedValue(2);
    prisma.routine.create.mockResolvedValue(routineRow());

    const view = await service.create(USER_ID, createDto());

    expect(prisma.habit.count).toHaveBeenCalledWith({
      where: { id: { in: [HABIT_A, HABIT_B] }, userId: USER_ID, archivedAt: null },
    });
    const createArgs = (
      prisma.routine.create.mock.calls as unknown as Array<
        [{ data: Record<string, unknown> }]
      >
    )[0][0];
    expect(createArgs.data).toMatchObject({
      userId: USER_ID,
      name: 'Morning Ritual',
      cadence: 'Morning',
      steps: {
        create: [
          { habitId: HABIT_A, durationMinutes: 2, order: 0 },
          { habitId: HABIT_B, durationMinutes: 5, order: 1 },
        ],
      },
    });
    expect(view.stepCount).toBe(2);
    expect(view.totalMinutes).toBe(7);
  });

  it('rejects a habit that is not the user\'s active habit', async () => {
    // One of the two ids is foreign or archived, so only one matches.
    prisma.habit.count.mockResolvedValue(1);

    await expect(service.create(USER_ID, createDto())).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(prisma.routine.create).not.toHaveBeenCalled();
  });
});

describe('RoutineService reads', () => {
  let prisma: PrismaMock;
  let service: RoutineService;

  beforeEach(async () => {
    prisma = createPrismaMock();
    service = await buildService(prisma);
  });

  it('lists only the user\'s routines, oldest first', async () => {
    prisma.routine.findMany.mockResolvedValue([routineRow()]);

    const views = await service.findAll(USER_ID);

    expect(prisma.routine.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: USER_ID },
        orderBy: { createdAt: 'asc' },
      }),
    );
    expect(views).toHaveLength(1);
    expect(views[0]).not.toHaveProperty('userId');
  });

  it('returns one routine scoped to the user', async () => {
    prisma.routine.findFirst.mockResolvedValue(routineRow());

    const view = await service.findOne(USER_ID, ROUTINE_ID);

    expect(prisma.routine.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: ROUTINE_ID, userId: USER_ID } }),
    );
    expect(view.id).toBe(ROUTINE_ID);
  });

  it('404s a routine owned by someone else', async () => {
    prisma.routine.findFirst.mockResolvedValue(null);

    await expect(
      service.findOne('someone-else', ROUTINE_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
```

- [ ] **Step 6: Watch it fail**

Run: `pnpm test -- src/routine/routine.service`
Expected: FAIL. The scaffold `create` takes one argument and returns a string, so ts-jest reports type errors.

- [ ] **Step 7: Implement the service**

Replace `src/routine/routine.service.ts`:

```ts
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { RoutineStepDto } from './dto/routine-step.dto';
import {
  ROUTINE_INCLUDE,
  RoutineWithSteps,
  toRoutineView,
  toStepRows,
} from './routine.mapper';
import { RoutineView } from './types';

@Injectable()
export class RoutineService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateRoutineDto): Promise<RoutineView> {
    await this.assertHabitsUsable(userId, dto.steps);

    const routine = await this.prisma.routine.create({
      data: {
        userId,
        name: dto.name,
        description: dto.description,
        color: dto.color,
        cadence: dto.cadence,
        steps: { create: toStepRows(dto.steps) },
      },
      include: ROUTINE_INCLUDE,
    });

    return toRoutineView(routine);
  }

  async findAll(userId: string): Promise<RoutineView[]> {
    const routines = await this.prisma.routine.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      include: ROUTINE_INCLUDE,
    });

    return routines.map(toRoutineView);
  }

  async findOne(userId: string, id: string): Promise<RoutineView> {
    return toRoutineView(await this.findOwned(userId, id));
  }

  private async findOwned(
    userId: string,
    id: string,
  ): Promise<RoutineWithSteps> {
    const routine = await this.prisma.routine.findFirst({
      where: { id, userId },
      include: ROUTINE_INCLUDE,
    });

    if (!routine) {
      throw new NotFoundException('Routine not found!');
    }

    return routine;
  }

  /// DTO validation already guarantees the ids are unique, so a count that
  /// falls short means at least one is foreign, archived or missing.
  private async assertHabitsUsable(userId: string, steps: RoutineStepDto[]) {
    const ids = steps.map((step) => step.habitId);
    const usable = await this.prisma.habit.count({
      where: { id: { in: ids }, userId, archivedAt: null },
    });

    if (usable !== ids.length) {
      throw new BadRequestException(
        'Every step must be one of your active habits',
      );
    }
  }
}
```

> **Expected side effect:** `pnpm build` fails from here until Task 6, because the scaffold controller still calls the old signatures. Jest compiles one file at a time, so the tests aren't affected.

- [ ] **Step 8: Watch it pass**

Run: `pnpm test -- src/routine`
Expected: PASS (the dto, mapper and service specs).

- [ ] **Step 9: Commit**

```bash
git add src/routine tsconfig.build.json
git commit -m "feat(routine): create, list and fetch routines with ordered steps"
```

---

## Task 4: Update and delete

**Builds:** `update`, where sending `steps` replaces the whole sequence in one transaction, and `remove`, which deletes only the routine.

**Files:** `routine.service.ts` (modify) · `routine.service.spec.ts` (append)

**Uses:** `findOwned`, `assertHabitsUsable`, `ROUTINE_INCLUDE`, `toRoutineView`, `toStepRows` (Task 3) and `UpdateRoutineDto` (Task 2).

**Produces**
- `RoutineService.update(userId, id, dto: UpdateRoutineDto): Promise<RoutineView>`
- `RoutineService.remove(userId, id): Promise<{ code: 200; message: string }>`

- [ ] **Step 1: Write the failing tests**

Append to `src/routine/routine.service.spec.ts`:

```ts
describe('RoutineService.update', () => {
  let prisma: PrismaMock;
  let service: RoutineService;

  beforeEach(async () => {
    prisma = createPrismaMock();
    prisma.routine.findFirst.mockResolvedValue(routineRow());
    prisma.routine.update.mockResolvedValue(routineRow());
    service = await buildService(prisma);
  });

  it('a rename leaves the steps alone', async () => {
    await service.update(USER_ID, ROUTINE_ID, { name: 'Dawn' });

    expect(prisma.routineHabit.deleteMany).not.toHaveBeenCalled();
    expect(prisma.habit.count).not.toHaveBeenCalled();
    const updateArgs = (
      prisma.routine.update.mock.calls as unknown as Array<
        [{ where: unknown; data: Record<string, unknown> }]
      >
    )[0][0];
    expect(updateArgs.where).toEqual({ id: ROUTINE_ID });
    expect(updateArgs.data).toMatchObject({ name: 'Dawn' });
    expect(updateArgs.data).not.toHaveProperty('steps');
  });

  it('sending steps replaces the whole sequence in one transaction', async () => {
    prisma.habit.count.mockResolvedValue(2);

    await service.update(USER_ID, ROUTINE_ID, {
      steps: [
        { habitId: HABIT_B, durationMinutes: 10 },
        { habitId: HABIT_A, durationMinutes: 1 },
      ],
    });

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.routineHabit.deleteMany).toHaveBeenCalledWith({
      where: { routineId: ROUTINE_ID },
    });
    const updateArgs = (
      prisma.routine.update.mock.calls as unknown as Array<
        [{ data: Record<string, unknown> }]
      >
    )[0][0];
    expect(updateArgs.data.steps).toEqual({
      create: [
        { habitId: HABIT_B, durationMinutes: 10, order: 0 },
        { habitId: HABIT_A, durationMinutes: 1, order: 1 },
      ],
    });
  });

  it('does not write when a step habit is foreign', async () => {
    prisma.habit.count.mockResolvedValue(0);

    await expect(
      service.update(USER_ID, ROUTINE_ID, {
        steps: [{ habitId: HABIT_A, durationMinutes: 5 }],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.routine.update).not.toHaveBeenCalled();
  });

  it('404s someone else\'s routine without writing', async () => {
    prisma.routine.findFirst.mockResolvedValue(null);

    await expect(
      service.update('someone-else', ROUTINE_ID, { name: 'Mine now' }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.routine.update).not.toHaveBeenCalled();
  });
});

describe('RoutineService.remove', () => {
  let prisma: PrismaMock;
  let service: RoutineService;

  beforeEach(async () => {
    prisma = createPrismaMock();
    service = await buildService(prisma);
  });

  it('deletes only the routine row', async () => {
    prisma.routine.findFirst.mockResolvedValue(routineRow());
    prisma.routine.delete.mockResolvedValue(routineRow());

    const result = await service.remove(USER_ID, ROUTINE_ID);

    expect(prisma.routine.delete).toHaveBeenCalledWith({
      where: { id: ROUTINE_ID },
    });
    expect(result).toEqual({
      code: 200,
      message: `Deleted successfully the routine with id: ${ROUTINE_ID}`,
    });
  });

  it('404s someone else\'s routine without deleting', async () => {
    prisma.routine.findFirst.mockResolvedValue(null);

    await expect(
      service.remove('someone-else', ROUTINE_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.routine.delete).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Watch it fail**

Run: `pnpm test -- src/routine/routine.service`
Expected: FAIL with `Property 'update' does not exist on type 'RoutineService'` (and the same for `remove`).

- [ ] **Step 3: Implement**

In `src/routine/routine.service.ts`, add the import:

```ts
import { UpdateRoutineDto } from './dto/update-routine.dto';
```

Add these methods after `findOne`:

```ts
  async update(
    userId: string,
    id: string,
    dto: UpdateRoutineDto,
  ): Promise<RoutineView> {
    await this.findOwned(userId, id);

    const { steps, ...fields } = dto;
    if (steps) {
      await this.assertHabitsUsable(userId, steps);
    }

    // Steps are replaced wholesale: the Edit screen sends the full sequence
    // after reorder/remove/add/duration changes. The transaction means a
    // failed insert leaves the old sequence intact.
    const routine = await this.prisma.$transaction(async (tx) => {
      if (steps) {
        await tx.routineHabit.deleteMany({ where: { routineId: id } });
      }

      return tx.routine.update({
        where: { id },
        data: {
          ...fields,
          ...(steps && { steps: { create: toStepRows(steps) } }),
        },
        include: ROUTINE_INCLUDE,
      });
    });

    return toRoutineView(routine);
  }

  /// Cascades routine_habits and routine_runs only. Habits and their entries
  /// are untouched: the Edit screen promises exactly that.
  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.routine.delete({ where: { id } });

    return {
      code: 200 as const,
      message: `Deleted successfully the routine with id: ${id}`,
    };
  }
```

- [ ] **Step 4: Watch it pass**

Run: `pnpm test -- src/routine`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/routine/routine.service.ts src/routine/routine.service.spec.ts
git commit -m "feat(routine): update with atomic step replacement, and delete"
```

---

## Task 5: Runs and streak

**Builds:** `recordRun`, called once when the player finishes. By then, each step has already been logged to Today through the entries endpoint. This method only records the run so the routine gets its own streak.

**Rules**
- Only one run per routine per day. Running again on the same day keeps the **higher** `completedSteps`.
- `completedSteps` can't exceed the routine's active steps, and a routine with no active steps can't be run. Both return 400.
- The streak counts consecutive run days, ending on the run's date.

**Files:** `routine.service.ts` (modify) · `routine.service.spec.ts` (append)

**Uses:** `findOwned`, `toRoutineView`, `RoutineRunResult` (Task 3), `CreateRoutineRunDto` (Task 2), and the existing helpers `standardizeDate`, `today`, `formatDate` (`src/utils/dayjs.ts`) and `computeCurrentStreak(dates, target)` (`src/utils/streak.ts`).

**Produces:** `RoutineService.recordRun(userId, id, dto: CreateRoutineRunDto): Promise<RoutineRunResult>`

- [ ] **Step 1: Write the failing tests**

Append to `src/routine/routine.service.spec.ts`:

```ts
describe('RoutineService.recordRun', () => {
  let prisma: PrismaMock;
  let service: RoutineService;

  const day = (key: string) => new Date(`${key}T00:00:00.000Z`);

  beforeEach(async () => {
    prisma = createPrismaMock();
    prisma.routine.findFirst.mockResolvedValue(routineRow()); // 2 active steps
    prisma.routineRun.findUnique.mockResolvedValue(null);
    prisma.routineRun.upsert.mockResolvedValue({});
    prisma.routineRun.findMany.mockResolvedValue([{ date: day('2026-09-24') }]);
    service = await buildService(prisma);
  });

  afterEach(() => jest.useRealTimers());

  it('stores one row per routine per day and reports the result', async () => {
    const result = await service.recordRun(USER_ID, ROUTINE_ID, {
      date: '2026-09-24',
      completedSteps: 2,
    });

    const routineId_date = { routineId: ROUTINE_ID, date: day('2026-09-24') };
    expect(prisma.routineRun.upsert).toHaveBeenCalledWith({
      where: { routineId_date },
      create: { ...routineId_date, completedSteps: 2 },
      update: { completedSteps: 2 },
    });
    expect(result).toEqual({
      routineId: ROUTINE_ID,
      date: '2026-09-24',
      completedSteps: 2,
      totalSteps: 2,
      currentStreak: 1,
    });
  });

  it('counts consecutive days ending on the run date', async () => {
    prisma.routineRun.findMany.mockResolvedValue([
      { date: day('2026-09-24') },
      { date: day('2026-09-23') },
      { date: day('2026-09-22') },
      { date: day('2026-09-20') },
    ]);

    const result = await service.recordRun(USER_ID, ROUTINE_ID, {
      date: '2026-09-24',
      completedSteps: 1,
    });

    expect(result.currentStreak).toBe(3);
  });

  it('keeps the best completedSteps for the day', async () => {
    prisma.routineRun.findUnique.mockResolvedValue({ completedSteps: 2 });

    const result = await service.recordRun(USER_ID, ROUTINE_ID, {
      date: '2026-09-24',
      completedSteps: 1,
    });

    expect(result.completedSteps).toBe(2);
    expect(prisma.routineRun.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ update: { completedSteps: 2 } }),
    );
  });

  it('defaults to today', async () => {
    jest.useFakeTimers({ doNotFake: ['nextTick', 'setImmediate'] });
    jest.setSystemTime(new Date(2026, 8, 24, 10, 0, 0)); // local 24 Sep

    const result = await service.recordRun(USER_ID, ROUTINE_ID, {
      completedSteps: 1,
    });

    expect(result.date).toBe('2026-09-24');
  });

  it('caps completedSteps at active steps', async () => {
    await expect(
      service.recordRun(USER_ID, ROUTINE_ID, {
        date: '2026-09-24',
        completedSteps: 3,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.routineRun.upsert).not.toHaveBeenCalled();
  });

  it('rejects a run on a routine with no active steps', async () => {
    prisma.routine.findFirst.mockResolvedValue(routineRow([]));

    await expect(
      service.recordRun(USER_ID, ROUTINE_ID, { completedSteps: 1 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('404s someone else\'s routine', async () => {
    prisma.routine.findFirst.mockResolvedValue(null);

    await expect(
      service.recordRun('someone-else', ROUTINE_ID, { completedSteps: 1 }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
```

- [ ] **Step 2: Watch it fail**

Run: `pnpm test -- src/routine/routine.service`
Expected: FAIL with `Property 'recordRun' does not exist on type 'RoutineService'`.

- [ ] **Step 3: Implement**

In `src/routine/routine.service.ts`, add these imports:

```ts
import dayjs from 'dayjs';
import { formatDate, standardizeDate, today } from 'src/utils/dayjs';
import { computeCurrentStreak } from 'src/utils/streak';
import { CreateRoutineRunDto } from './dto/create-routine-run.dto';
```

Change the types import to:

```ts
import { RoutineRunResult, RoutineView } from './types';
```

Add this method after `remove`:

```ts
  /// Called once when the player finishes. Each step was already logged to
  /// Today through POST /habits/:id/entries; this only records the run so
  /// the routine gets its own streak. Re-running a routine on the same day
  /// keeps the best step count and never adds a second streak day.
  async recordRun(
    userId: string,
    id: string,
    dto: CreateRoutineRunDto,
  ): Promise<RoutineRunResult> {
    const { stepCount } = toRoutineView(await this.findOwned(userId, id));

    if (stepCount === 0) {
      throw new BadRequestException('This routine has no active steps');
    }
    if (dto.completedSteps > stepCount) {
      throw new BadRequestException(
        `completedSteps cannot exceed ${stepCount}`,
      );
    }

    const date = dto.date ? standardizeDate(dto.date) : today();
    const routineId_date = { routineId: id, date };

    const existing = await this.prisma.routineRun.findUnique({
      where: { routineId_date },
    });
    const completedSteps = Math.max(
      existing?.completedSteps ?? 0,
      dto.completedSteps,
    );

    await this.prisma.routineRun.upsert({
      where: { routineId_date },
      create: { ...routineId_date, completedSteps },
      update: { completedSteps },
    });

    const runs = await this.prisma.routineRun.findMany({
      where: { routineId: id },
      select: { date: true },
    });
    const dateKey = formatDate(date);

    return {
      routineId: id,
      date: dateKey,
      completedSteps,
      totalSteps: stepCount,
      currentStreak: computeCurrentStreak(
        runs.map((run) => run.date),
        dayjs(dateKey),
      ),
    };
  }
```

- [ ] **Step 4: Watch it pass**

Run: `pnpm test -- src/routine`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/routine/routine.service.ts src/routine/routine.service.spec.ts
git commit -m "feat(routine): record runs and compute routine streak"
```

---

## Task 6: HTTP layer, docs and smoke test

**Builds:** the `/routines` endpoints, the module wiring, README updates, and a curl script that checks the whole flow against the real database.

**Files:** `routine.controller.ts` (replace) · `routine.module.ts` (modify) · `../README.md` (modify)

**Uses:** all six `RoutineService` methods (Tasks 3–5), `JwtAuthGuard`, `CurrentUser`.

**Produces the HTTP API**

| Method | Path | Body | Success |
|---|---|---|---|
| `POST` | `/routines` | `CreateRoutineDto` | 201 `RoutineView` |
| `GET` | `/routines` | — | 200 `RoutineView[]` |
| `GET` | `/routines/:id` | — | 200 `RoutineView` |
| `PATCH` | `/routines/:id` | `UpdateRoutineDto` | 200 `RoutineView` |
| `DELETE` | `/routines/:id` | — | 200 `{ code, message }` |
| `POST` | `/routines/:id/runs` | `CreateRoutineRunDto` | 201 `RoutineRunResult` |

- [ ] **Step 1: Replace the controller**

Replace `src/routine/routine.controller.ts`:

```ts
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiParam, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { CurrentUser } from 'src/common/decorators';
import { RoutineService } from './routine.service';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { CreateRoutineRunDto } from './dto/create-routine-run.dto';

@Controller('routines')
@ApiTags('Routine')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class RoutineController {
  constructor(private readonly routineService: RoutineService) {}

  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: CreateRoutineDto) {
    return this.routineService.create(userId, dto);
  }

  @Get()
  findAll(@CurrentUser('id') userId: string) {
    return this.routineService.findAll(userId);
  }

  @Get(':id')
  @ApiParam({ name: 'id', description: 'Routine id', required: true })
  findOne(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.routineService.findOne(userId, id);
  }

  @Patch(':id')
  @ApiParam({ name: 'id', description: 'Routine id', required: true })
  update(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateRoutineDto,
  ) {
    return this.routineService.update(userId, id, dto);
  }

  @Delete(':id')
  @ApiParam({ name: 'id', description: 'Routine id', required: true })
  remove(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.routineService.remove(userId, id);
  }

  @Post(':id/runs')
  @ApiParam({ name: 'id', description: 'Routine id', required: true })
  recordRun(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRoutineRunDto,
  ) {
    return this.routineService.recordRun(userId, id, dto);
  }
}
```

- [ ] **Step 2: Provide PrismaService in the module**

Replace `src/routine/routine.module.ts`. It's already imported in `app.module.ts`, so nothing changes there.

```ts
import { Module } from '@nestjs/common';
import { RoutineService } from './routine.service';
import { RoutineController } from './routine.controller';
import { PrismaService } from 'src/prisma.service';

@Module({
  controllers: [RoutineController],
  providers: [RoutineService, PrismaService],
})
export class RoutineModule {}
```

- [ ] **Step 3: Build, lint, test**

Run: `pnpm build && pnpm lint && pnpm test`
Expected: build and lint are clean. The routine specs pass, and only the 2 baseline failures remain.

- [ ] **Step 4: Smoke-test against the real database**

Terminal 1: `pnpm start:dev` (wait for `Nest application successfully started`).

Terminal 2 needs `jq`. Run each block and compare its output with the `→` line under it:

```bash
API=http://localhost:3001
EMAIL="routine-smoke-$(date +%s)@example.com"
TOKEN=$(curl -s -X POST $API/auth/register -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"secret123\"}" | jq -r .accessToken)
AUTH="Authorization: Bearer $TOKEN"
H1=$(curl -s -X POST $API/habits -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Drink Water"}' | jq -r .id)
H2=$(curl -s -X POST $API/habits -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Stretch"}' | jq -r .id)

# 1. create
R=$(curl -s -X POST $API/routines -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"name\":\"Morning Ritual\",\"cadence\":\"Morning\",\"color\":\"#4D6054\",\"steps\":[{\"habitId\":\"$H1\",\"durationMinutes\":2},{\"habitId\":\"$H2\",\"durationMinutes\":5}]}")
echo "$R" | jq -c '{stepCount,totalMinutes,names:[.steps[].name]}'
#   → {"stepCount":2,"totalMinutes":7,"names":["Drink Water","Stretch"]}
RID=$(echo "$R" | jq -r .id)

# 2. list
curl -s $API/routines -H "$AUTH" | jq 'length'
#   → 1

# 3. reorder + change a duration
curl -s -X PATCH $API/routines/$RID -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"steps\":[{\"habitId\":\"$H2\",\"durationMinutes\":10},{\"habitId\":\"$H1\",\"durationMinutes\":2}]}" \
  | jq -c '[.steps[] | [.name, .durationMinutes]]'
#   → [["Stretch",10],["Drink Water",2]]

# 4. duplicate habit is a 400, not a 500
curl -s -o /dev/null -w '%{http_code}\n' -X PATCH $API/routines/$RID -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"steps\":[{\"habitId\":\"$H1\",\"durationMinutes\":2},{\"habitId\":\"$H1\",\"durationMinutes\":2}]}"
#   → 400

# 5. play: log both steps to Today, then record the run
curl -s -o /dev/null -X POST $API/habits/$H2/entries -H "$AUTH" -H 'Content-Type: application/json' -d '{}'
curl -s -o /dev/null -X POST $API/habits/$H1/entries -H "$AUTH" -H 'Content-Type: application/json' -d '{}'
curl -s -X POST $API/routines/$RID/runs -H "$AUTH" -H 'Content-Type: application/json' -d '{"completedSteps":2}' | jq -c
#   → {"routineId":"…","date":"<today>","completedSteps":2,"totalSteps":2,"currentStreak":1}

# 6. delete keeps the habits and today's check-offs
curl -s -X DELETE $API/routines/$RID -H "$AUTH" | jq -r .code
#   → 200
curl -s "$API/habits?date=$(date +%F)" -H "$AUTH" | jq -c '[.[] | .doneToday]'
#   → [true,true]

# 7. unknown routine
curl -s -o /dev/null -w '%{http_code}\n' $API/routines/$RID -H "$AUTH"
#   → 404
```

Then open `http://localhost:3001/api` and check that the **Routine** section lists all six endpoints.

If any output differs, stop and debug with superpowers:systematic-debugging before going on.

- [ ] **Step 5: Update the README**

In `README.md` (repo root):

1. **Features table:** replace the Routines row with
   `| 🧘 | **Routines** | Group habits into a guided, timed routine and play it step by step. Each finished step checks the habit off on Today, and finishing the routine extends its own streak. |`
2. **Quick start › Backend:** replace the `pnpm prisma contract emit` line with
   ```bash
   pnpm db:emit && pnpm db:update    # apply prisma8/contract.prisma to the database
   pnpm prisma:generate              # generate the query client from prisma/schema.prisma
   ```
3. **API intro:** change it to "Everything under `/habits`, `/routines` and `/profile` requires…". Then add this after the "Habits, entries and profile" table:

   ```markdown
   **Routines**

   | Method | Path | Body | Notes |
   |---|---|---|---|
   | `POST` | `/routines` | `{ name, description?, color?, cadence?, steps: [{ habitId, durationMinutes }] }` | steps play in array order · each habit once · must be your active habits |
   | `GET` | `/routines` | — | each routine carries `steps`, `stepCount`, `totalMinutes`; archived habits are left out |
   | `GET` | `/routines/:id` | — | |
   | `PATCH` | `/routines/:id` | any create field | sending `steps` replaces the whole sequence |
   | `DELETE` | `/routines/:id` | — | habits and their entries are kept |
   | `POST` | `/routines/:id/runs` | `{ completedSteps, date? }` | one run per day (best count kept) → `{ completedSteps, totalSteps, currentStreak }` |

   ▶️ **Playing a routine:** call `POST /habits/:habitId/entries` as each step finishes (that's the Today check-off), then `POST /routines/:id/runs` once at the end.
   ```
4. **Roadmap:** change the item to `- [x] 🧘 **Routines backend.** Routines, steps and runs are served by /routines.`
5. **Project tree:** change `src/routine/         routines (scaffold)` to `src/routine/         routines, steps, runs`.

- [ ] **Step 6: Commit**

```bash
git add src/routine ../README.md
git commit -m "feat(routine): expose /routines REST API and document it"
```

---

## Not in this plan

**Mobile integration** gets its own plan, built on the API contract from Task 6. It covers:
- a `routines/data` layer (remote datasource + repository, mirroring `habits/data`);
- replacing `Routine.defaults` with API data, and feeding `SelectHabitsModal` from `GET /habits`;
- calling the entries endpoint on **Done & Next**, and posting the run after the last step;
- dropping the icon, category, sub-step and portion fields, or keeping them client-only.
