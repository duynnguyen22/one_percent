import dayjs from 'dayjs';
import { computeCurrentStreak } from './streak';

const day = (key: string) => new Date(`${key}T00:00:00.000Z`);
const target = dayjs('2026-09-28');

describe('computeCurrentStreak', () => {
  it('is 0 with no entries', () => {
    expect(computeCurrentStreak([], target)).toBe(0);
  });

  it('counts consecutive days ending on the target day', () => {
    const dates = [day('2026-09-28'), day('2026-09-27'), day('2026-09-26')];
    expect(computeCurrentStreak(dates, target)).toBe(3);
  });

  it('keeps yesterday’s streak while the target day is not checked yet', () => {
    const dates = [day('2026-09-27'), day('2026-09-26')];
    expect(computeCurrentStreak(dates, target)).toBe(2);
  });

  it('is 0 once a full day was missed', () => {
    const dates = [day('2026-09-26'), day('2026-09-25')];
    expect(computeCurrentStreak(dates, target)).toBe(0);
  });

  it('stops at the first gap', () => {
    const dates = [day('2026-09-28'), day('2026-09-27'), day('2026-09-25')];
    expect(computeCurrentStreak(dates, target)).toBe(2);
  });
});
