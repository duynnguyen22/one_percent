import type { Scalars } from '@prisma/orm-postgres/family-contract/types';
import type { Models } from 'generated/prisma8/contract';
import type { FromDb } from 'src/utils/temporal';

/** A habit row, with its timestamps as `Date`s. */
export type Habit = FromDb<Scalars<Models.public_Habit>>;

/**
 * A habit row as `GET /habits?date=` returns it.
 *
 * `getHabits` answers with one shape or the other depending on whether a date
 * was asked for, so naming the decorated one lets callers narrow the union
 * instead of casting.
 */
export type DecoratedHabit = Habit & {
  doneToday: boolean;
  currentStreak: number;
};
