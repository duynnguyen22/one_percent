/// <reference types="temporal-polyfill/types/global" />
import 'temporal-polyfill/global';

/**
 * Prisma 8 reads and writes `Timestamp` columns as `Temporal.PlainDateTime`
 * and `Date` columns as `Temporal.PlainDate`. The rest of the app, and the
 * API, work in JS `Date`s, so values are converted here on the way in and
 * out. Timestamps hold UTC wall-clock time, as Prisma 7 wrote them.
 */

export const toDbTimestamp = (date: Date): Temporal.PlainDateTime =>
  Temporal.Instant.fromEpochMilliseconds(date.getTime())
    .toZonedDateTimeISO('UTC')
    .toPlainDateTime();

/** For day keys, which `standardizeDate` puts at UTC midnight. */
export const toDbDate = (date: Date): Temporal.PlainDate =>
  Temporal.PlainDate.from(date.toISOString().slice(0, 10));

export type FromDb<T> = T extends Temporal.PlainDateTime | Temporal.PlainDate
  ? Date
  : T extends readonly (infer U)[]
    ? FromDb<U>[]
    : T extends object
      ? { [K in keyof T]: FromDb<T[K]> }
      : T;

/** Converts every Temporal value in a query result, however deeply nested. */
export function fromDb<T>(value: T): FromDb<T> {
  return convert(value) as FromDb<T>;
}

function convert(value: unknown): unknown {
  if (value instanceof Temporal.PlainDateTime) {
    return new Date(value.toZonedDateTime('UTC').epochMilliseconds);
  }
  if (value instanceof Temporal.PlainDate) {
    return new Date(Date.UTC(value.year, value.month - 1, value.day));
  }
  if (Array.isArray(value)) {
    return value.map(convert);
  }
  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, field]) => [key, convert(field)]),
    );
  }
  return value;
}
