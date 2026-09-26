import { NotFoundException } from '@nestjs/common';
import { EntriesService } from './entries.service';
import { today } from 'src/utils/dayjs';
import {
  createEntry,
  createHabit,
  createUser,
  useDatabaseService,
} from '../../test/factories';

const day = (key: string) => new Date(`${key}T00:00:00.000Z`);

describe('EntriesService', () => {
  const ctx = useDatabaseService(EntriesService);
  let userId: string;
  let habitId: string;

  beforeEach(async () => {
    userId = (await createUser(ctx.prisma)).id;
    habitId = (await createHabit(ctx.prisma, userId)).id;
  });

  const storedDays = async () =>
    (await ctx.prisma.orm.HabitEntry.where({ habitId }).all()).map((e) =>
      e.date.toString(),
    );

  describe('checkOff', () => {
    it('records the given day as a UTC day key', async () => {
      const entry = await ctx.service.checkOff(userId, habitId, {
        date: '2026-03-10',
      });

      expect(entry).toMatchObject({ habitId, date: day('2026-03-10') });
      expect(await storedDays()).toEqual(['2026-03-10']);
    });

    it('defaults to today', async () => {
      const entry = await ctx.service.checkOff(userId, habitId, {});

      expect(entry.date).toEqual(today());
    });

    it('is idempotent for the same day', async () => {
      const first = await ctx.service.checkOff(userId, habitId, {
        date: '2026-03-10',
      });
      const again = await ctx.service.checkOff(userId, habitId, {
        date: '2026-03-10',
      });

      expect(again.id).toBe(first.id);
      expect(await storedDays()).toEqual(['2026-03-10']);
    });

    it('refuses an archived habit', async () => {
      const archived = await createHabit(ctx.prisma, userId, {
        archivedAt: new Date(),
      });

      await expect(
        ctx.service.checkOff(userId, archived.id, { date: '2026-03-10' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('refuses a habit the caller does not own', async () => {
      const other = (await createUser(ctx.prisma)).id;

      await expect(
        ctx.service.checkOff(other, habitId, { date: '2026-03-10' }),
      ).rejects.toThrow(NotFoundException);
      expect(await storedDays()).toEqual([]);
    });
  });

  describe('getEntries', () => {
    it('lists the days in the range, oldest first', async () => {
      for (const key of [
        '2026-03-12',
        '2026-03-09',
        '2026-03-10',
        '2026-03-01',
      ]) {
        await createEntry(ctx.prisma, habitId, key);
      }

      await expect(
        ctx.service.getEntries(userId, habitId, '2026-03-09', '2026-03-12'),
      ).resolves.toEqual({
        entries: [day('2026-03-09'), day('2026-03-10'), day('2026-03-12')],
      });
    });

    it('refuses a habit the caller does not own', async () => {
      const other = (await createUser(ctx.prisma)).id;

      await expect(
        ctx.service.getEntries(other, habitId, '2026-03-01', '2026-03-31'),
      ).rejects.toThrow('Habit not found!');
    });
  });

  describe('deleteEntry', () => {
    it('deletes the entry for that day only', async () => {
      await createEntry(ctx.prisma, habitId, '2026-03-10');
      await createEntry(ctx.prisma, habitId, '2026-03-11');

      await expect(
        ctx.service.deleteEntry(userId, habitId, '2026-03-10'),
      ).resolves.toEqual({ code: 200, message: 'Deleted successfully' });
      expect(await storedDays()).toEqual(['2026-03-11']);
    });

    it('refuses a habit the caller does not own', async () => {
      await createEntry(ctx.prisma, habitId, '2026-03-10');
      const other = (await createUser(ctx.prisma)).id;

      await expect(
        ctx.service.deleteEntry(other, habitId, '2026-03-10'),
      ).rejects.toThrow('Habit not found!');
      expect(await storedDays()).toEqual(['2026-03-10']);
    });

    it('404s when the day was never checked off', async () => {
      await expect(
        ctx.service.deleteEntry(userId, habitId, '2026-03-10'),
      ).rejects.toThrow('Habit entry not found!');
    });
  });
});
