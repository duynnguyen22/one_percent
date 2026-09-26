import { Test } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { RoutineService } from './routine.service';
import { PrismaService } from 'src/prisma.service';

const USER_ID = 'user-1';
const ROUTINE_ID = 'eeeeeeee-0000-4000-8000-000000000001';
const WATER = 'aaaaaaaa-0000-4000-8000-000000000001';
const STRETCH = 'aaaaaaaa-0000-4000-8000-000000000002';
const JOURNAL = 'aaaaaaaa-0000-4000-8000-000000000003';

const day = (key: string) => new Date(`${key}T00:00:00.000Z`);
const CREATED = new Date('2026-09-25T08:00:00.000Z');

const habit = (id: string, name: string, archivedAt: Date | null = null) => ({
  id,
  userId: USER_ID,
  name,
  color: '#4d6054',
  createdAt: CREATED,
  archivedAt,
});

const step = (
  h: ReturnType<typeof habit>,
  order: number,
  durationMinutes: number,
) => ({
  routineId: ROUTINE_ID,
  habitId: h.id,
  order,
  durationMinutes,
  habit: h,
});

const routineRow = (steps: ReturnType<typeof step>[], id = ROUTINE_ID) => ({
  id,
  userId: USER_ID,
  name: 'Morning Ritual',
  description: 'Start slow.',
  color: '#4d6054',
  cadence: 'Morning',
  createdAt: CREATED,
  updatedAt: CREATED,
  steps,
});

type Entry = { habitId: string; date: Date };

describe('RoutineService', () => {
  let service: RoutineService;
  let entries: Entry[];
  let prisma: {
    routine: {
      findMany: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
    routineHabit: { deleteMany: jest.Mock; createMany: jest.Mock };
    habit: { count: jest.Mock };
    habitEntry: { findMany: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    entries = [];
    prisma = {
      routine: {
        findMany: jest.fn().mockResolvedValue([]),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      routineHabit: {
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
        createMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      habit: { count: jest.fn() },
      // Behaves like the table: only entries for the asked habits and day.
      habitEntry: {
        findMany: jest.fn(
          ({ where }: { where: { habitId: { in: string[] }; date: Date } }) =>
            Promise.resolve(
              entries.filter(
                (e) =>
                  where.habitId.in.includes(e.habitId) &&
                  e.date.getTime() === where.date.getTime(),
              ),
            ),
        ),
      },
      // Interactive transactions run the callback against the same mock.
      $transaction: jest.fn((cb: (tx: unknown) => unknown) => cb(prisma)),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [RoutineService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = moduleRef.get(RoutineService);
  });

  describe('findOne', () => {
    const water = habit(WATER, 'Drink Water');
    const stretch = habit(STRETCH, 'Gentle Stretch');

    it('returns the routine with ordered steps and totals', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([step(stretch, 2, 5), step(water, 1, 2)]),
      );

      const view = await service.findOne(USER_ID, ROUTINE_ID, {});

      expect(view).toEqual({
        id: ROUTINE_ID,
        name: 'Morning Ritual',
        description: 'Start slow.',
        color: '#4d6054',
        cadence: 'Morning',
        stepCount: 2,
        totalDurationMinutes: 7,
        steps: [
          {
            habitId: WATER,
            name: 'Drink Water',
            color: '#4d6054',
            order: 1,
            durationMinutes: 2,
          },
          {
            habitId: STRETCH,
            name: 'Gentle Stretch',
            color: '#4d6054',
            order: 2,
            durationMinutes: 5,
          },
        ],
        createdAt: CREATED,
        updatedAt: CREATED,
      });
    });

    it('only looks up routines owned by the caller', async () => {
      await expect(
        service.findOne('someone-else', ROUTINE_ID, {}),
      ).rejects.toThrow(NotFoundException);
      expect(prisma.routine.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: ROUTINE_ID, userId: 'someone-else' },
        }),
      );
    });

    it('hides steps whose habit is archived', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([
          step(water, 1, 2),
          step(habit(JOURNAL, 'Journal', CREATED), 2, 10),
        ]),
      );

      const view = await service.findOne(USER_ID, ROUTINE_ID, {});

      expect(view.steps.map((s) => s.habitId)).toEqual([WATER]);
      expect(view.stepCount).toBe(1);
      expect(view.totalDurationMinutes).toBe(2);
    });

    it('marks steps done on the given date', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([step(water, 1, 2), step(stretch, 2, 5)]),
      );
      entries = [
        { habitId: WATER, date: day('2026-09-25') },
        { habitId: STRETCH, date: day('2026-09-24') },
      ];

      const view = await service.findOne(USER_ID, ROUTINE_ID, {
        date: '2026-09-25',
      });

      expect(view.steps.map((s) => s.doneToday)).toEqual([true, false]);
      expect(view.completedToday).toBe(false);
    });

    it('is completed when every active step is done', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([
          step(water, 1, 2),
          step(habit(JOURNAL, 'Journal', CREATED), 2, 10),
        ]),
      );
      entries = [{ habitId: WATER, date: day('2026-09-25') }];

      const view = await service.findOne(USER_ID, ROUTINE_ID, {
        date: '2026-09-25',
      });

      expect(view.completedToday).toBe(true);
    });

    it('is never completed with no active steps', async () => {
      prisma.routine.findFirst.mockResolvedValue(routineRow([]));

      const view = await service.findOne(USER_ID, ROUTINE_ID, {
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
    it('returns an empty list without touching entries', async () => {
      expect(await service.findAll(USER_ID, { date: '2026-09-25' })).toEqual(
        [],
      );
      expect(prisma.habitEntry.findMany).not.toHaveBeenCalled();
    });

    it("lists the caller's routines, newest first", async () => {
      await service.findAll(USER_ID, {});

      expect(prisma.routine.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: USER_ID },
          orderBy: { createdAt: 'desc' },
        }),
      );
    });

    it('reads entries for all routines in one query', async () => {
      prisma.routine.findMany.mockResolvedValue([
        routineRow([step(habit(WATER, 'Drink Water'), 1, 2)], 'r1'),
        routineRow([step(habit(JOURNAL, 'Journal'), 1, 5)], 'r2'),
      ]);
      entries = [{ habitId: JOURNAL, date: day('2026-09-25') }];

      const views = await service.findAll(USER_ID, { date: '2026-09-25' });

      expect(prisma.habitEntry.findMany).toHaveBeenCalledTimes(1);
      expect(views.map((v) => [v.id, v.completedToday])).toEqual([
        ['r1', false],
        ['r2', true],
      ]);
    });
  });

  describe('create', () => {
    const body = {
      name: 'Morning Ritual',
      cadence: 'Morning',
      steps: [{ habitId: STRETCH, durationMinutes: 5 }, { habitId: WATER }],
    };

    it('stores steps in array order with default durations', async () => {
      prisma.habit.count.mockResolvedValue(2);
      prisma.routine.create.mockResolvedValue(
        routineRow([
          step(habit(STRETCH, 'Gentle Stretch'), 1, 5),
          step(habit(WATER, 'Drink Water'), 2, 5),
        ]),
      );

      const view = await service.create(USER_ID, body);

      expect(prisma.routine.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            name: 'Morning Ritual',
            cadence: 'Morning',
            userId: USER_ID,
            steps: {
              create: [
                { habitId: STRETCH, order: 1, durationMinutes: 5 },
                { habitId: WATER, order: 2, durationMinutes: 5 },
              ],
            },
          },
        }),
      );
      expect(view.totalDurationMinutes).toBe(10);
    });

    it('rejects the same habit twice', async () => {
      await expect(
        service.create(USER_ID, {
          name: 'x',
          steps: [{ habitId: WATER }, { habitId: WATER }],
        }),
      ).rejects.toThrow('Each habit can appear only once in a routine');
      expect(prisma.routine.create).not.toHaveBeenCalled();
    });

    it("rejects habits that are archived or someone else's", async () => {
      prisma.habit.count.mockResolvedValue(1);

      await expect(service.create(USER_ID, body)).rejects.toThrow(
        BadRequestException,
      );
      expect(prisma.habit.count).toHaveBeenCalledWith({
        where: {
          id: { in: [STRETCH, WATER] },
          userId: USER_ID,
          archivedAt: null,
        },
      });
      expect(prisma.routine.create).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    const water = habit(WATER, 'Drink Water');

    it('404s for a routine the caller does not own', async () => {
      await expect(
        service.update('someone-else', ROUTINE_ID, { name: 'x' }),
      ).rejects.toThrow(NotFoundException);
      expect(prisma.routine.update).not.toHaveBeenCalled();
    });

    it('updates only the supplied fields and keeps the steps', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([step(water, 1, 2)]),
      );
      prisma.routine.update.mockResolvedValue({
        ...routineRow([step(water, 1, 2)]),
        name: 'Renamed',
      });

      const view = await service.update(USER_ID, ROUTINE_ID, {
        name: 'Renamed',
      });

      expect(prisma.routine.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: ROUTINE_ID },
          data: { name: 'Renamed' },
        }),
      );
      expect(prisma.routineHabit.deleteMany).not.toHaveBeenCalled();
      expect(view.name).toBe('Renamed');
    });

    it('replaces the whole sequence when steps are supplied', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([step(water, 1, 2)]),
      );
      prisma.habit.count.mockResolvedValue(2);
      prisma.routine.update.mockResolvedValue(routineRow([]));

      await service.update(USER_ID, ROUTINE_ID, {
        steps: [{ habitId: JOURNAL, durationMinutes: 10 }, { habitId: WATER }],
      });

      expect(prisma.$transaction).toHaveBeenCalled();
      expect(prisma.routineHabit.deleteMany).toHaveBeenCalledWith({
        where: { routineId: ROUTINE_ID },
      });
      expect(prisma.routineHabit.createMany).toHaveBeenCalledWith({
        data: [
          {
            routineId: ROUTINE_ID,
            habitId: JOURNAL,
            order: 1,
            durationMinutes: 10,
          },
          {
            routineId: ROUTINE_ID,
            habitId: WATER,
            order: 2,
            durationMinutes: 5,
          },
        ],
      });
    });

    it('rejects invalid steps before changing anything', async () => {
      prisma.routine.findFirst.mockResolvedValue(
        routineRow([step(water, 1, 2)]),
      );

      await expect(
        service.update(USER_ID, ROUTINE_ID, {
          steps: [{ habitId: WATER }, { habitId: WATER }],
        }),
      ).rejects.toThrow(BadRequestException);
      expect(prisma.routineHabit.deleteMany).not.toHaveBeenCalled();
      expect(prisma.routine.update).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('deletes an owned routine', async () => {
      prisma.routine.findFirst.mockResolvedValue(routineRow([]));

      await expect(service.remove(USER_ID, ROUTINE_ID)).resolves.toEqual({
        code: 200,
        message: `Deleted successfully the routine with id: ${ROUTINE_ID}`,
      });
      expect(prisma.routine.delete).toHaveBeenCalledWith({
        where: { id: ROUTINE_ID, userId: USER_ID },
      });
    });

    it('404s for a routine the caller does not own', async () => {
      await expect(service.remove('someone-else', ROUTINE_ID)).rejects.toThrow(
        NotFoundException,
      );
      expect(prisma.routine.delete).not.toHaveBeenCalled();
    });
  });
});
