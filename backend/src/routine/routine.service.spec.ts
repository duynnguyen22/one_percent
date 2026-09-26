import { BadRequestException, NotFoundException } from '@nestjs/common';
import { RoutineService } from './routine.service';
import { toDbTimestamp } from 'src/utils/temporal';
import {
  createEntry,
  createHabit,
  createUser,
  useDatabaseService,
} from '../../test/factories';

describe('RoutineService', () => {
  const ctx = useDatabaseService(RoutineService);
  let userId: string;
  let water: string;
  let stretch: string;
  let journal: string;

  beforeEach(async () => {
    userId = (await createUser(ctx.prisma)).id;
    water = (await createHabit(ctx.prisma, userId, { name: 'Drink Water' })).id;
    stretch = (
      await createHabit(ctx.prisma, userId, { name: 'Gentle Stretch' })
    ).id;
    journal = (await createHabit(ctx.prisma, userId, { name: 'Journal' })).id;
  });

  const morning = (steps: { habitId: string; durationMinutes?: number }[]) =>
    ctx.service.create(userId, {
      name: 'Morning Ritual',
      description: 'Start slow.',
      color: '#4d6054',
      cadence: 'Morning',
      steps,
    });

  const archive = (habitId: string) =>
    ctx.prisma.orm.Habit.where({ id: habitId }).update({
      archivedAt: toDbTimestamp(new Date()),
    });

  const storedSteps = async (routineId: string) =>
    (
      await ctx.prisma.orm.RoutineHabit.where({ routineId })
        .orderBy((s) => s.order.asc())
        .all()
    ).map((s) => [s.habitId, s.order, s.durationMinutes]);

  describe('findOne', () => {
    it('returns the routine with ordered steps and totals', async () => {
      const { data: created } = await morning([
        { habitId: water, durationMinutes: 2 },
        { habitId: stretch },
      ]);

      const res = await ctx.service.findOne(userId, created.id, {});

      expect(res.statusCode).toBe(200);
      expect(res.message).toBe('Routine retrieved successfully');
      expect(res.data).toEqual({
        id: created.id,
        name: 'Morning Ritual',
        description: 'Start slow.',
        color: '#4d6054',
        cadence: 'Morning',
        stepCount: 2,
        totalDurationMinutes: 7,
        steps: [
          {
            habitId: water,
            name: 'Drink Water',
            color: '#4d6054',
            order: 1,
            durationMinutes: 2,
          },
          {
            habitId: stretch,
            name: 'Gentle Stretch',
            color: '#4d6054',
            order: 2,
            durationMinutes: 5,
          },
        ],
        createdAt: expect.any(Date) as Date,
        updatedAt: expect.any(Date) as Date,
      });
    });

    it('only finds routines owned by the caller', async () => {
      const { data: created } = await morning([{ habitId: water }]);
      const other = (await createUser(ctx.prisma)).id;

      await expect(ctx.service.findOne(other, created.id, {})).rejects.toThrow(
        NotFoundException,
      );
    });

    it('hides steps whose habit is archived', async () => {
      const { data: created } = await morning([
        { habitId: water, durationMinutes: 2 },
        { habitId: journal, durationMinutes: 10 },
      ]);
      await archive(journal);

      const { data: view } = await ctx.service.findOne(userId, created.id, {});

      expect(view.steps.map((s) => s.habitId)).toEqual([water]);
      expect(view.stepCount).toBe(1);
      expect(view.totalDurationMinutes).toBe(2);
    });

    it('marks steps done on the given date', async () => {
      const { data: created } = await morning([
        { habitId: water },
        { habitId: stretch },
      ]);
      await createEntry(ctx.prisma, water, '2026-09-25');
      await createEntry(ctx.prisma, stretch, '2026-09-24');

      const { data: view } = await ctx.service.findOne(userId, created.id, {
        date: '2026-09-25',
      });

      expect(view.steps.map((s) => s.doneToday)).toEqual([true, false]);
      expect(view.completedToday).toBe(false);
    });

    it('is completed when every active step is done', async () => {
      const { data: created } = await morning([
        { habitId: water },
        { habitId: journal },
      ]);
      await archive(journal);
      await createEntry(ctx.prisma, water, '2026-09-25');

      const { data: view } = await ctx.service.findOne(userId, created.id, {
        date: '2026-09-25',
      });

      expect(view.completedToday).toBe(true);
    });

    it('is never completed with no active steps', async () => {
      const { data: created } = await morning([{ habitId: journal }]);
      await archive(journal);

      const { data: view } = await ctx.service.findOne(userId, created.id, {
        date: '2026-09-25',
      });

      expect(view).toMatchObject({
        stepCount: 0,
        totalDurationMinutes: 0,
        completedToday: false,
        steps: [],
      });
    });
  });

  describe('findAll', () => {
    it('returns an empty list', async () => {
      await expect(
        ctx.service.findAll(userId, { date: '2026-09-25' }),
      ).resolves.toEqual({
        statusCode: 200,
        message: 'Routines retrieved successfully',
        data: [],
      });
    });

    it("lists only the caller's routines, newest first", async () => {
      const { data: first } = await morning([{ habitId: water }]);
      const { data: second } = await morning([{ habitId: stretch }]);
      const other = (await createUser(ctx.prisma)).id;
      const theirs = (await createHabit(ctx.prisma, other)).id;
      await ctx.service.create(other, {
        name: 'Theirs',
        steps: [{ habitId: theirs }],
      });

      const { data: views } = await ctx.service.findAll(userId, {});

      expect(views.map((v) => v.id)).toEqual([second.id, first.id]);
    });

    it('marks each routine completed on the given date', async () => {
      const { data: r1 } = await morning([{ habitId: water }]);
      const { data: r2 } = await morning([{ habitId: journal }]);
      await createEntry(ctx.prisma, journal, '2026-09-25');

      const { data: views } = await ctx.service.findAll(userId, {
        date: '2026-09-25',
      });

      expect(views.map((v) => [v.id, v.completedToday])).toEqual([
        [r2.id, true],
        [r1.id, false],
      ]);
    });
  });

  describe('create', () => {
    it('stores steps in array order with default durations', async () => {
      const res = await morning([
        { habitId: stretch, durationMinutes: 5 },
        { habitId: water },
      ]);

      expect(res.statusCode).toBe(201);
      expect(res.message).toBe('Routine created successfully');
      expect(res.data.totalDurationMinutes).toBe(10);
      expect(await storedSteps(res.data.id)).toEqual([
        [stretch, 1, 5],
        [water, 2, 5],
      ]);
    });

    it('rejects the same habit twice', async () => {
      await expect(
        morning([{ habitId: water }, { habitId: water }]),
      ).rejects.toThrow('Each habit can appear only once in a routine');
      expect(await ctx.prisma.orm.Routine.first()).toBeNull();
    });

    it("rejects habits that are archived or someone else's", async () => {
      await archive(journal);
      const other = (await createUser(ctx.prisma)).id;
      const theirs = (await createHabit(ctx.prisma, other)).id;

      await expect(
        morning([{ habitId: water }, { habitId: journal }]),
      ).rejects.toThrow(BadRequestException);
      await expect(
        morning([{ habitId: water }, { habitId: theirs }]),
      ).rejects.toThrow(BadRequestException);
      expect(await ctx.prisma.orm.Routine.first()).toBeNull();
    });
  });

  describe('update', () => {
    it('404s for a routine the caller does not own', async () => {
      const { data: created } = await morning([{ habitId: water }]);
      const other = (await createUser(ctx.prisma)).id;

      await expect(
        ctx.service.update(other, created.id, { name: 'x' }),
      ).rejects.toThrow(NotFoundException);
      const stored = await ctx.prisma.orm.Routine.first({ id: created.id });
      expect(stored?.name).toBe('Morning Ritual');
    });

    it('updates only the supplied fields and keeps the steps', async () => {
      const { data: created } = await morning([
        { habitId: water, durationMinutes: 2 },
      ]);

      const res = await ctx.service.update(userId, created.id, {
        name: 'Renamed',
      });

      expect(res.statusCode).toBe(200);
      expect(res.message).toBe('Routine updated successfully');
      expect(res.data).toMatchObject({
        name: 'Renamed',
        description: 'Start slow.',
        cadence: 'Morning',
      });
      expect(await storedSteps(created.id)).toEqual([[water, 1, 2]]);
    });

    it('moves updatedAt forward', async () => {
      const { data: created } = await morning([{ habitId: water }]);
      const earlier = new Date('2026-01-01T00:00:00.000Z');
      await ctx.prisma.orm.Routine.where({ id: created.id }).update({
        updatedAt: toDbTimestamp(earlier),
      });

      const { data: updated } = await ctx.service.update(userId, created.id, {
        name: 'Renamed',
      });

      expect(updated.updatedAt.getTime()).toBeGreaterThan(earlier.getTime());
      expect(updated.createdAt).toEqual(created.createdAt);
    });

    it('replaces the whole sequence when steps are supplied', async () => {
      const { data: created } = await morning([
        { habitId: water, durationMinutes: 2 },
      ]);

      const { data: view } = await ctx.service.update(userId, created.id, {
        steps: [{ habitId: journal, durationMinutes: 10 }, { habitId: water }],
      });

      expect(view.steps.map((s) => s.habitId)).toEqual([journal, water]);
      expect(await storedSteps(created.id)).toEqual([
        [journal, 1, 10],
        [water, 2, 5],
      ]);
    });

    it('rejects invalid steps before changing anything', async () => {
      const { data: created } = await morning([
        { habitId: water, durationMinutes: 2 },
      ]);

      await expect(
        ctx.service.update(userId, created.id, {
          name: 'Renamed',
          steps: [{ habitId: stretch }, { habitId: stretch }],
        }),
      ).rejects.toThrow(BadRequestException);
      expect(await storedSteps(created.id)).toEqual([[water, 1, 2]]);
      const stored = await ctx.prisma.orm.Routine.first({ id: created.id });
      expect(stored?.name).toBe('Morning Ritual');
    });
  });

  describe('remove', () => {
    it('deletes an owned routine and its steps, but not the habits', async () => {
      const { data: created } = await morning([{ habitId: water }]);

      await expect(ctx.service.remove(userId, created.id)).resolves.toEqual({
        statusCode: 200,
        message: `Deleted successfully the routine with id: ${created.id}`,
        data: null,
      });
      expect(await ctx.prisma.orm.Routine.first({ id: created.id })).toBeNull();
      expect(await storedSteps(created.id)).toEqual([]);
      expect(await ctx.prisma.orm.Habit.first({ id: water })).not.toBeNull();
    });

    it('404s for a routine the caller does not own', async () => {
      const { data: created } = await morning([{ habitId: water }]);
      const other = (await createUser(ctx.prisma)).id;

      await expect(ctx.service.remove(other, created.id)).rejects.toThrow(
        NotFoundException,
      );
      expect(
        await ctx.prisma.orm.Routine.first({ id: created.id }),
      ).not.toBeNull();
    });
  });
});
