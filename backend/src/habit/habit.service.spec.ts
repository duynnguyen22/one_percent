import { NotFoundException } from '@nestjs/common';
import { HabitService } from './habit.service';
import { DecoratedHabit } from './types';
import {
  createEntry,
  createHabit,
  createUser,
  useDatabaseService,
} from '../../test/factories';

describe('HabitService', () => {
  const ctx = useDatabaseService(HabitService);
  let userId: string;

  beforeEach(async () => {
    userId = (await createUser(ctx.prisma)).id;
  });

  describe('addHabit', () => {
    it('creates a habit owned by the caller', async () => {
      const habit = await ctx.service.addHabit(userId, {
        name: 'Read',
        color: '#4D6054',
      });

      expect(habit).toMatchObject({
        userId,
        name: 'Read',
        color: '#4D6054',
        archivedAt: null,
      });
      expect(habit.createdAt).toBeInstanceOf(Date);
    });
  });

  describe('getHabits', () => {
    it("returns the caller's active habits as bare rows when no date is supplied", async () => {
      const read = await createHabit(ctx.prisma, userId, { name: 'Read' });
      await createHabit(ctx.prisma, userId, { archivedAt: new Date() });
      const other = (await createUser(ctx.prisma)).id;
      await createHabit(ctx.prisma, other);

      const result = await ctx.service.getHabits(userId, undefined);

      expect(result).toEqual([
        {
          id: read.id,
          userId,
          name: 'Read',
          color: '#4d6054',
          archivedAt: null,
          createdAt: expect.any(Date) as Date,
        },
      ]);
    });

    it('treats an empty query object as no date', async () => {
      await createHabit(ctx.prisma, userId);

      const [habit] = await ctx.service.getHabits(userId, {});

      expect(habit).not.toHaveProperty('doneToday');
    });

    it('decorates against the requested date, not today', async () => {
      const habit = await createHabit(ctx.prisma, userId);
      for (const day of ['2026-03-10', '2026-03-09', '2026-03-08']) {
        await createEntry(ctx.prisma, habit.id, day);
      }

      const [decorated] = (await ctx.service.getHabits(userId, {
        date: '2026-03-10',
      })) as DecoratedHabit[];

      expect(decorated.doneToday).toBe(true);
      expect(decorated.currentStreak).toBe(3);
      expect(decorated).not.toHaveProperty('entries');
    });

    it('reports doneToday false for a day with no entry', async () => {
      const habit = await createHabit(ctx.prisma, userId);
      await createEntry(ctx.prisma, habit.id, '2026-03-08');

      const [decorated] = (await ctx.service.getHabits(userId, {
        date: '2026-03-10',
      })) as DecoratedHabit[];

      expect(decorated.doneToday).toBe(false);
      expect(decorated.currentStreak).toBe(0);
    });
  });

  describe('updateHabits', () => {
    const archivedAt = new Date('2026-02-01T00:00:00.000Z');

    it('a rename leaves archivedAt alone', async () => {
      const habit = await createHabit(ctx.prisma, userId, { archivedAt });

      const updated = await ctx.service.updateHabits(habit.id, userId, {
        name: 'Read daily',
      });

      expect(updated).toMatchObject({ name: 'Read daily', archivedAt });
    });

    it('never changes immutable columns', async () => {
      const habit = await createHabit(ctx.prisma, userId);

      const updated = await ctx.service.updateHabits(habit.id, userId, {
        color: '#8A9A5B',
      });

      expect(updated).toMatchObject({ id: habit.id, userId, color: '#8A9A5B' });
      expect(updated.createdAt.getTime()).toBe(
        habit.createdAt.toZonedDateTime('UTC').epochMilliseconds,
      );
    });

    it('archived true stamps archivedAt', async () => {
      const habit = await createHabit(ctx.prisma, userId);

      const updated = await ctx.service.updateHabits(habit.id, userId, {
        archived: true,
      });

      expect(updated.archivedAt).toBeInstanceOf(Date);
      expect(updated).not.toHaveProperty('archived');
    });

    it('archived false clears archivedAt', async () => {
      const habit = await createHabit(ctx.prisma, userId, { archivedAt });

      const updated = await ctx.service.updateHabits(habit.id, userId, {
        archived: false,
      });

      expect(updated.archivedAt).toBeNull();
    });

    it('rejects a habit the caller does not own', async () => {
      const habit = await createHabit(ctx.prisma, userId);
      const other = (await createUser(ctx.prisma)).id;

      await expect(
        ctx.service.updateHabits(habit.id, other, { name: 'Nope' }),
      ).rejects.toThrow('Habit not found!');
      const stored = await ctx.prisma.orm.Habit.first({ id: habit.id });
      expect(stored?.name).toBe(habit.name);
    });
  });

  describe('deleteHabit', () => {
    it('deletes an owned habit', async () => {
      const habit = await createHabit(ctx.prisma, userId);

      await expect(ctx.service.deleteHabit(habit.id, userId)).resolves.toEqual({
        code: 200,
        message: `Deleted successfully the habit with id: ${habit.id}`,
      });
      expect(await ctx.prisma.orm.Habit.first({ id: habit.id })).toBeNull();
    });

    it('404s for a habit the caller does not own', async () => {
      const habit = await createHabit(ctx.prisma, userId);
      const other = (await createUser(ctx.prisma)).id;

      await expect(ctx.service.deleteHabit(habit.id, other)).rejects.toThrow(
        NotFoundException,
      );
      expect(await ctx.prisma.orm.Habit.first({ id: habit.id })).not.toBeNull();
    });
  });
});
