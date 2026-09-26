import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from 'generated/prisma/client';
import { PrismaService } from 'src/prisma.service';
import { standardizeDate } from 'src/utils/dayjs';
import { GetRoutinesQueryDto } from './dto/get-routines-query.dto';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { RoutineStepDto } from './dto/routine-step.dto';

const DEFAULT_STEP_MINUTES = 5;

const ROUTINE_INCLUDE = {
  steps: { include: { habit: true }, orderBy: { order: 'asc' } },
} satisfies Prisma.RoutineInclude;

type RoutineWithSteps = Prisma.RoutineGetPayload<{
  include: typeof ROUTINE_INCLUDE;
}>;

/** Array position is the step order (1-based). */
const toStepRows = (steps: RoutineStepDto[]) =>
  steps.map((s, index) => ({
    habitId: s.habitId,
    order: index + 1,
    durationMinutes: s.durationMinutes ?? DEFAULT_STEP_MINUTES,
  }));

@Injectable()
export class RoutineService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string, query: GetRoutinesQueryDto) {
    const routines = await this.prisma.routine.findMany({
      where: { userId },
      include: ROUTINE_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
    return this.toViews(routines, query.date);
  }

  async findOne(userId: string, id: string, query: GetRoutinesQueryDto) {
    const routine = await this.findOwned(userId, id);
    const [view] = await this.toViews([routine], query.date);
    return view;
  }

  async create(userId: string, dto: CreateRoutineDto) {
    const { steps, ...fields } = dto;

    const routine = await this.prisma.$transaction(async (tx) => {
      await this.assertUsableHabits(tx, userId, steps);
      return tx.routine.create({
        data: { ...fields, userId, steps: { create: toStepRows(steps) } },
        include: ROUTINE_INCLUDE,
      });
    });

    const [view] = await this.toViews([routine]);
    return view;
  }

  /** With `steps`, the whole sequence is replaced. */
  async update(userId: string, id: string, dto: UpdateRoutineDto) {
    const { steps, ...fields } = dto;

    const routine = await this.prisma.$transaction(async (tx) => {
      await this.findOwned(userId, id, tx);

      if (steps) {
        await this.assertUsableHabits(tx, userId, steps);
        await tx.routineHabit.deleteMany({ where: { routineId: id } });
        await tx.routineHabit.createMany({
          data: toStepRows(steps).map((row) => ({ routineId: id, ...row })),
        });
      }

      return tx.routine.update({
        where: { id },
        data: fields,
        include: ROUTINE_INCLUDE,
      });
    });

    const [view] = await this.toViews([routine]);
    return view;
  }

  /** Cascades routine_habits only. Habits and their entries are untouched. */
  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.routine.delete({ where: { id, userId } });
    return {
      code: 200,
      message: `Deleted successfully the routine with id: ${id}`,
    };
  }

  /** Every habit must be unique in the list, owned by the user and active. */
  private async assertUsableHabits(
    tx: Prisma.TransactionClient,
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

    const owned = await tx.habit.count({
      where: { id: { in: habitIds }, userId, archivedAt: null },
    });
    if (owned !== habitIds.length) {
      throw new BadRequestException(
        'One or more habits are invalid or do not belong to you',
      );
    }
  }

  private async findOwned(
    userId: string,
    id: string,
    client: Prisma.TransactionClient = this.prisma,
  ) {
    const routine = await client.routine.findFirst({
      where: { id, userId },
      include: ROUTINE_INCLUDE,
    });
    if (!routine) {
      throw new NotFoundException('Routine not found!');
    }
    return routine;
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
        ? await this.prisma.habitEntry.findMany({
            where: { habitId: { in: habitIds }, date: standardizeDate(date) },
            select: { habitId: true },
          })
        : [];
      done = new Set(found.map((e) => e.habitId));
    }

    return active.map(({ routine, steps }) => {
      const stepViews = steps.map((s) => ({
        habitId: s.habitId,
        name: s.habit.name,
        color: s.habit.color,
        order: s.order,
        durationMinutes: s.durationMinutes,
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
