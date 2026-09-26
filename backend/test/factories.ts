import { Test } from '@nestjs/testing';
import type { Type } from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { toDbDate, toDbTimestamp } from 'src/utils/temporal';
import { resetDatabase } from './database';

/**
 * Boots `service` against the test database and empties it before each test.
 * Call at the top of a `describe`; read the instances inside tests.
 */
export function useDatabaseService<T>(
  service: Type<T>,
  providers: object[] = [],
) {
  const ctx = {} as { service: T; prisma: PrismaService };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [service, PrismaService, ...(providers as Type[])],
    }).compile();
    ctx.service = moduleRef.get(service);
    ctx.prisma = moduleRef.get(PrismaService);
  });
  afterAll(() => ctx.prisma.onModuleDestroy());
  beforeEach(resetDatabase);

  return ctx;
}

let seq = 0;

export const createUser = (
  prisma: PrismaService,
  fields: { email?: string; passwordHash?: string; userName?: string } = {},
) =>
  prisma.orm.User.create({
    email: fields.email ?? `user${++seq}@x.io`,
    passwordHash: fields.passwordHash ?? '$2b$10$abcdefghijklmnopqrstuv',
    ...(fields.userName !== undefined && { userName: fields.userName }),
  });

export const createHabit = (
  prisma: PrismaService,
  userId: string,
  fields: { name?: string; color?: string; archivedAt?: Date } = {},
) =>
  prisma.orm.Habit.create({
    userId,
    name: fields.name ?? `Habit ${++seq}`,
    color: fields.color ?? '#4d6054',
    archivedAt: fields.archivedAt ? toDbTimestamp(fields.archivedAt) : null,
  });

export const createEntry = (
  prisma: PrismaService,
  habitId: string,
  day: string,
) =>
  prisma.orm.HabitEntry.create({
    habitId,
    date: toDbDate(new Date(`${day}T00:00:00.000Z`)),
  });
