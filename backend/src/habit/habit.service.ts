import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateHabitDto } from './dto/create-habit.dto';
import { PrismaService } from 'src/prisma.service';
import { GetHabitsDto } from './dto/get-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
import dayjs from 'dayjs';
import { computeCurrentStreak } from 'src/utils/streak';
import { DATE_FORMAT, formatDate } from 'src/utils/dayjs';
import { fromDb, toDbTimestamp } from 'src/utils/temporal';
import { omit } from 'lodash';
@Injectable()
export class HabitService {
  constructor(private prisma: PrismaService) {}
  async addHabit(userId: string, dto: CreateHabitDto) {
    return fromDb(await this.prisma.orm.Habit.create({ ...dto, userId }));
  }

  async getHabits(userId: string, query?: GetHabitsDto) {
    const active = this.prisma.orm.Habit.where({ userId }).where((h) =>
      h.archivedAt.isNull(),
    );

    // `@Query()` always binds an object, so the guard is on the field.
    if (!query?.date) {
      return fromDb(await active.all());
    }

    const habits = fromDb(
      await active
        .include('entries', (entries) =>
          entries.orderBy((entry) => entry.date.desc()),
        )
        .all(),
    );

    const target = dayjs(query.date);
    const targetKey = target.format(DATE_FORMAT);

    return habits.map((habit) => ({
      ...omit(habit, 'entries'),
      // Compare day keys, not instants: entries are stored at UTC midnight and
      // `target` is a local day, so `isSame(…, 'day')` shifts west of UTC.
      doneToday: habit.entries.some(
        (entry) => formatDate(entry.date) === targetKey,
      ),
      currentStreak: computeCurrentStreak(
        habit.entries.map((entry) => entry.date),
        target,
      ),
    }));
  }

  async updateHabits(id: string, userId: string, habitDto: UpdateHabitDto) {
    const { archived, ...fields } = habitDto;

    // Only the supplied fields are written, so a plain rename can't
    // un-archive the habit.
    const data = {
      ...fields,
      ...(archived !== undefined && {
        archivedAt: archived ? toDbTimestamp(new Date()) : null,
      }),
    };

    // Scoped to the owner, so someone else's habit reads as missing.
    const owned = this.prisma.orm.Habit.where({ id, userId });
    const habit = Object.keys(data).length
      ? await owned.update(data)
      : await owned.first();

    if (!habit) {
      throw new NotFoundException('Habit not found!');
    }

    return fromDb(habit);
  }

  async deleteHabit(id: string, userId: string) {
    if (!id) throw new BadRequestException();

    const deletedHabit = await this.prisma.orm.Habit.where({
      id,
      userId,
    }).delete();

    if (!deletedHabit) {
      throw new NotFoundException('Habit not found!');
    }

    return {
      code: 200,
      message: `Deleted successfully the habit with id: ${id}`,
    };
  }
}
