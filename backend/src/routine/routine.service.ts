import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { ResultType } from '@prisma/orm-postgres/components/runtime';
import { type Orm, PrismaService } from 'src/prisma.service';
import { standardizeDate } from 'src/utils/dayjs';
import {
  type FromDb,
  fromDb,
  toDbDate,
  toDbTimestamp,
} from 'src/utils/temporal';
import { GetRoutinesQueryDto } from './dto/get-routines-query.dto';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { RoutineStepDto } from './dto/routine-step.dto';
import { RoutineGuideDto } from './dto/routine-guide.dto';

const DEFAULT_STEP_MINUTES = 5;

/** Routines with their steps, in order, and each step's habit. */
const withSteps = (routines: Orm['Routine']) =>
  routines.include('steps', (steps) =>
    steps.include('habit').orderBy((step) => step.order.asc()),
  );

type RoutineWithSteps = FromDb<ResultType<ReturnType<typeof withSteps>>>;

const respond = <T>(statusCode: number, message: string, data: T) => ({
  statusCode,
  message,
  data,
});

const stepKey = (routineId: string, habitId: string) =>
  `${routineId}:${habitId}`;

/** Array position is the order, for steps and for guides (1-based). */
const toGuideRows = (routineId: string, steps: RoutineStepDto[]) =>
  steps.flatMap((s) =>
    (s.guides ?? []).map((g, index) => ({
      routineId,
      habitId: s.habitId,
      order: index + 1,
      title: g.title,
      durationSeconds: g.durationSeconds,
    })),
  );

const toStepRows = (routineId: string, steps: RoutineStepDto[]) =>
  steps.map((s, index) => ({
    routineId,
    habitId: s.habitId,
    order: index + 1,
    durationMinutes: s.durationMinutes ?? DEFAULT_STEP_MINUTES,
  }));

@Injectable()
export class RoutineService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string, query: GetRoutinesQueryDto) {
    const routines = await withSteps(this.prisma.orm.Routine)
      .where({ userId })
      .orderBy((routine) => routine.createdAt.desc())
      .all();
    const views = await this.toViews(fromDb(routines), query.date);
    return respond(200, 'Routines retrieved successfully', views);
  }

  async findOne(userId: string, id: string, query: GetRoutinesQueryDto) {
    const routine = await this.findOwned(userId, id);
    const [view] = await this.toViews([routine], query.date);
    return respond(200, 'Routine retrieved successfully', view);
  }

  async create(userId: string, dto: CreateRoutineDto) {
    const { steps, ...fields } = dto;
    const now = toDbTimestamp(new Date());

    const routine = await this.prisma.transaction(async (orm) => {
      await this.assertUsableHabits(orm, userId, steps);
      const { id } = await orm.Routine.create({
        ...fields,
        userId,
        createdAt: now,
        updatedAt: now,
      });
      await this.writeSteps(orm, id, steps);
      return this.findOwned(userId, id, orm);
    });

    const [view] = await this.toViews([routine]);
    return respond(201, 'Routine created successfully', view);
  }

  /** With `steps`, the whole sequence is replaced. */
  async update(userId: string, id: string, dto: UpdateRoutineDto) {
    const { steps, ...fields } = dto;

    const routine = await this.prisma.transaction(async (orm) => {
      await this.findOwned(userId, id, orm);

      if (steps) {
        await this.assertUsableHabits(orm, userId, steps);
        const kept = await this.withExistingGuides(orm, id, steps);
        await orm.RoutineHabit.where({ routineId: id }).deleteAndCount();
        await this.writeSteps(orm, id, kept);
      }

      await orm.Routine.where({ id }).update({
        ...fields,
        updatedAt: toDbTimestamp(new Date()),
      });
      return this.findOwned(userId, id, orm);
    });

    const [view] = await this.toViews([routine]);
    return respond(200, 'Routine updated successfully', view);
  }

  /** Cascades routine_habits only. Habits and their entries are untouched. */
  async remove(userId: string, id: string) {
    const deleted = await this.prisma.orm.Routine.where({
      id,
      userId,
    }).delete();
    if (!deleted) {
      throw new NotFoundException('Routine not found!');
    }
    return respond(
      200,
      `Deleted successfully the routine with id: ${id}`,
      null,
    );
  }

  private async writeSteps(
    orm: Orm,
    routineId: string,
    steps: RoutineStepDto[],
  ) {
    await orm.RoutineHabit.createAndCount(toStepRows(routineId, steps));
    const guides = toGuideRows(routineId, steps);
    if (guides.length) {
      await orm.RoutineStepGuide.createAndCount(guides);
    }
  }

  /**
   * Replacing steps deletes and re-creates them, which cascades to their
   * guides. A step that sends no `guides` keeps the ones it had; an explicit
   * array (even empty) replaces them.
   */
  private async withExistingGuides(
    orm: Orm,
    routineId: string,
    steps: RoutineStepDto[],
  ): Promise<RoutineStepDto[]> {
    if (steps.every((s) => s.guides != null)) return steps;

    const existing = await orm.RoutineStepGuide.where({ routineId })
      .orderBy((g) => g.order.asc())
      .all();
    const byHabit = new Map<string, RoutineGuideDto[]>();
    for (const g of existing) {
      const list = byHabit.get(g.habitId) ?? [];
      list.push({ title: g.title, durationSeconds: g.durationSeconds });
      byHabit.set(g.habitId, list);
    }
    return steps.map((s) => ({
      ...s,
      guides: s.guides ?? byHabit.get(s.habitId) ?? [],
    }));
  }

  /** Every habit must be unique in the list, owned by the user and active. */
  private async assertUsableHabits(
    orm: Orm,
    userId: string,
    steps: RoutineStepDto[],
  ) {
    const habitIds = steps.map((s) => s.habitId);
    // Checked first: repeated ids would otherwise skew the count below.
    if (new Set(habitIds).size !== habitIds.length) {
      throw new BadRequestException(
        'Each habit can appear only once in a routine',
      );
    }

    const { owned } = await orm.Habit.where({ userId })
      .where((h) => h.id.in(habitIds))
      .where((h) => h.archivedAt.isNull())
      .aggregate((a) => ({ owned: a.count() }));
    if (owned !== habitIds.length) {
      throw new BadRequestException(
        'One or more habits are invalid or do not belong to you',
      );
    }
  }

  private async findOwned(
    userId: string,
    id: string,
    orm: Orm = this.prisma.orm,
  ): Promise<RoutineWithSteps> {
    const routine = await withSteps(orm.Routine).where({ id, userId }).first();
    if (!routine) {
      throw new NotFoundException('Routine not found!');
    }
    return fromDb(routine);
  }

  /**
   * One query for every step's guides, keyed by `stepKey`. Not a nested
   * include: the ORM's include of the composite-key `guides` relation returns
   * every guide of the routine for each step.
   */
  private async guidesByStep(routineIds: string[]) {
    const byStep = new Map<
      string,
      { order: number; title: string; durationSeconds: number }[]
    >();
    if (!routineIds.length) return byStep;

    const rows = await this.prisma.orm.RoutineStepGuide.where((g) =>
      g.routineId.in(routineIds),
    )
      .orderBy((g) => g.order.asc())
      .all();
    for (const g of rows) {
      const key = stepKey(g.routineId, g.habitId);
      const list = byStep.get(key) ?? [];
      list.push({
        order: g.order,
        title: g.title,
        durationSeconds: g.durationSeconds,
      });
      byStep.set(key, list);
    }
    return byStep;
  }

  /**
   * Shapes routines for the API. Steps whose habit is archived are hidden but
   * their join rows are kept, so un-archiving the habit brings the step back.
   * With a date, one entries query covers every step of every routine.
   */
  private async toViews(routines: RoutineWithSteps[], date?: string) {
    const active = routines.map((routine) => ({
      routine,
      steps: routine.steps
        .filter((s) => s.habit.archivedAt === null)
        .sort((a, b) => a.order - b.order),
    }));

    let done: Set<string> | undefined;
    const habitIds = active.flatMap(({ steps }) => steps.map((s) => s.habitId));
    if (date !== undefined) {
      const found = habitIds.length
        ? await this.prisma.orm.HabitEntry.where((e) => e.habitId.in(habitIds))
            .where({ date: toDbDate(standardizeDate(date)) })
            .select('habitId')
            .all()
        : [];
      done = new Set(found.map((e) => e.habitId));
    }

    const guides = await this.guidesByStep(routines.map((r) => r.id));

    return active.map(({ routine, steps }) => {
      const stepViews = steps.map((s) => ({
        habitId: s.habitId,
        name: s.habit.name,
        color: s.habit.color,
        order: s.order,
        durationMinutes: s.durationMinutes,
        guides: guides.get(stepKey(routine.id, s.habitId)) ?? [],
        ...(done && { doneToday: done.has(s.habitId) }),
      }));

      return {
        id: routine.id,
        name: routine.name,
        description: routine.description,
        color: routine.color,
        cadence: routine.cadence,
        stepCount: stepViews.length,
        totalDurationMinutes: stepViews.reduce(
          (sum, s) => sum + s.durationMinutes,
          0,
        ),
        ...(done && {
          completedToday:
            stepViews.length > 0 && stepViews.every((s) => s.doneToday),
        }),
        steps: stepViews,
        createdAt: routine.createdAt,
        updatedAt: routine.updatedAt,
      };
    });
  }
}
