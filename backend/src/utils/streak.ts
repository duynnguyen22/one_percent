import { Dayjs } from 'dayjs';
import { DATE_FORMAT, formatDate } from './dayjs';

export const computeCurrentStreak = (dates: Date[], targetDate: Dayjs) => {
  const completedDays = new Set(dates.map((date) => formatDate(date)));

  // An unchecked target day doesn't break the streak yet — the day is still
  // in progress — so count back from the day before.
  let current = completedDays.has(targetDate.format(DATE_FORMAT))
    ? targetDate
    : targetDate.subtract(1, 'day');

  let streak = 0;
  while (completedDays.has(current.format(DATE_FORMAT))) {
    streak++;
    current = current.subtract(1, 'day');
  }

  return streak;
};
