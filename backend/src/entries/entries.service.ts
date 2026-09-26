import { Injectable, NotFoundException } from '@nestjs/common';
import { type Orm, PrismaService } from 'src/prisma.service';
import { CreateEntryDto } from './dto/create-entry';
import { standardizeDate, today } from 'src/utils/dayjs';
import { fromDb, toDbDate } from 'src/utils/temporal';

@Injectable()
export class EntriesService {
  constructor(private prisma: PrismaService) {}

  async checkOff(userId: string, habitId: string, dto: CreateEntryDto) {
    const date = toDbDate(dto.date ? standardizeDate(dto.date) : today());

    const habit = await this.prisma.orm.Habit.where({ id: habitId, userId })
      .where((h) => h.archivedAt.isNull())
      .first();

    if (!habit) {
      throw new NotFoundException();
    }

    // Checking off a day twice returns the existing entry. (habitId, date) is
    // a unique index, not a constraint, so the ORM's types only offer the
    // primary key as a conflict target; Postgres accepts the index.
    type ConflictOn = Parameters<Orm['HabitEntry']['upsert']>[0]['conflictOn'];
    const entry = await this.prisma.orm.HabitEntry.upsert({
      create: { habitId, date },
      update: {},
      conflictOn: { habitId, date } as unknown as ConflictOn,
    });
    return fromDb(entry);
  }

  async getEntries(userId: string, habitId: string, from: string, to: string) {
    await this.findOwnedHabit(userId, habitId);

    const entries = await this.prisma.orm.HabitEntry.where({ habitId })
      .where((e) => e.date.gte(toDbDate(standardizeDate(from))))
      .where((e) => e.date.lte(toDbDate(standardizeDate(to))))
      .orderBy((e) => e.date.asc())
      .select('date')
      .all();

    return {
      entries: fromDb(entries).map((entry) => entry.date),
    };
  }

  async deleteEntry(userId: string, habitId: string, date: string) {
    await this.findOwnedHabit(userId, habitId);

    const entry = await this.prisma.orm.HabitEntry.where({
      habitId,
      date: toDbDate(standardizeDate(date)),
    }).delete();

    if (!entry) {
      throw new NotFoundException('Habit entry not found!');
    }

    return { code: 200, message: 'Deleted successfully' };
  }

  private async findOwnedHabit(userId: string, habitId: string) {
    const habit = await this.prisma.orm.Habit.first({ id: habitId, userId });

    if (!habit) {
      throw new NotFoundException('Habit not found!');
    }
    return habit;
  }
}
