import { fromDb, toDbDate, toDbTimestamp } from './temporal';

describe('toDbTimestamp', () => {
  it('stores the UTC wall-clock time of the instant', () => {
    const stored = toDbTimestamp(new Date('2026-09-25T23:30:00.123Z'));

    expect(stored).toBeInstanceOf(Temporal.PlainDateTime);
    expect(stored.toString()).toBe('2026-09-25T23:30:00.123');
  });
});

describe('toDbDate', () => {
  it('keeps the UTC calendar day of a standardized day key', () => {
    const stored = toDbDate(new Date('2026-09-25T00:00:00.000Z'));

    expect(stored).toBeInstanceOf(Temporal.PlainDate);
    expect(stored.toString()).toBe('2026-09-25');
  });
});

describe('fromDb', () => {
  it('reads timestamps back as the instant they were written from', () => {
    const at = new Date('2026-09-25T23:30:00.123Z');

    expect(fromDb(toDbTimestamp(at))).toEqual(at);
  });

  it('reads dates back as UTC midnight, the shape standardizeDate produces', () => {
    expect(fromDb(Temporal.PlainDate.from('2026-09-25'))).toEqual(
      new Date('2026-09-25T00:00:00.000Z'),
    );
  });

  it('converts every date in nested rows and leaves the rest alone', () => {
    const row = {
      id: 'r1',
      archivedAt: null,
      createdAt: Temporal.PlainDateTime.from('2026-09-25T08:00:00'),
      entries: [{ date: Temporal.PlainDate.from('2026-09-24'), count: 2 }],
    };

    expect(fromDb(row)).toEqual({
      id: 'r1',
      archivedAt: null,
      createdAt: new Date('2026-09-25T08:00:00.000Z'),
      entries: [{ date: new Date('2026-09-24T00:00:00.000Z'), count: 2 }],
    });
  });

  it('passes null through, for a lookup that found nothing', () => {
    expect(fromDb(null)).toBeNull();
  });
});
