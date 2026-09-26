#!/usr/bin/env -S node
import type { Contract as End } from '../../snapshots/07d328a12b399baa17e881b986e0a4bb390abe409e196457c0982927e0b66483/contract';
import endContract from '../../snapshots/07d328a12b399baa17e881b986e0a4bb390abe409e196457c0982927e0b66483/contract.json' with { type: 'json' };
import { Migration, MigrationCLI, col, fn, lit, primaryKey } from '@prisma/orm-postgres/migration';

export default class M extends Migration<never, End> {
  override readonly endContractJson = endContract;

  override get operations() {
    return [
      this.createSchema({ schema: 'public' }),
      this.createTable({
        schema: 'public',
        table: 'habit_entries',
        columns: [
          col('createdAt', 'timestamp(3)', {
            notNull: true,
            default: fn('now()'),
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('date', 'date', { notNull: true, codecRef: { codecId: 'pg/date-temporal@1' } }),
          col('habitId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['id'], { name: 'habit_entries_pkey' })],
      }),
      this.createTable({
        schema: 'public',
        table: 'habits',
        columns: [
          col('archivedAt', 'timestamp(3)', {
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('color', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('createdAt', 'timestamp(3)', {
            notNull: true,
            default: fn('now()'),
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('name', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('userId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['id'], { name: 'habits_pkey' })],
      }),
      this.createTable({
        schema: 'public',
        table: 'password_reset_codes',
        columns: [
          col('attempts', 'int4', {
            notNull: true,
            default: lit(0),
            codecRef: { codecId: 'pg/int4@1' },
          }),
          col('codeHash', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('consumedAt', 'timestamp(3)', {
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('createdAt', 'timestamp(3)', {
            notNull: true,
            default: fn('now()'),
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('expiresAt', 'timestamp(3)', {
            notNull: true,
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('userId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('verifiedAt', 'timestamp(3)', {
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
        ],
        constraints: [primaryKey(['id'], { name: 'password_reset_codes_pkey' })],
      }),
      this.createTable({
        schema: 'public',
        table: 'routine_habits',
        columns: [
          col('durationMinutes', 'int4', {
            notNull: true,
            default: lit(5),
            codecRef: { codecId: 'pg/int4@1' },
          }),
          col('habitId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('order', 'int4', { notNull: true, codecRef: { codecId: 'pg/int4@1' } }),
          col('routineId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['routineId', 'habitId'], { name: 'routine_habits_pkey' })],
      }),
      this.createTable({
        schema: 'public',
        table: 'routines',
        columns: [
          col('cadence', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('color', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('createdAt', 'timestamp(3)', {
            notNull: true,
            default: fn('now()'),
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('description', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('name', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('updatedAt', 'timestamp(3)', {
            notNull: true,
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('userId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['id'], { name: 'routines_pkey' })],
      }),
      this.createTable({
        schema: 'public',
        table: 'users',
        columns: [
          col('avatarUrl', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('createdAt', 'timestamp(3)', {
            notNull: true,
            default: fn('now()'),
            codecRef: { codecId: 'pg/timestamp-temporal@1', typeParams: { precision: 3 } },
          }),
          col('email', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('passwordHash', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('userName', 'text', { codecRef: { codecId: 'pg/text@1' } }),
          col('userPhone', 'text', { codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['id'], { name: 'users_pkey' })],
      }),
      this.createIndex({
        schema: 'public',
        table: 'habit_entries',
        index: 'habit_entries_habitId_date_key',
        columns: ['habitId', 'date'],
        extras: { unique: true },
      }),
      this.createIndex({
        schema: 'public',
        table: 'password_reset_codes',
        index: 'password_reset_codes_userId_createdAt_idx',
        columns: ['userId', 'createdAt'],
      }),
      this.createIndex({
        schema: 'public',
        table: 'routine_habits',
        index: 'routine_habits_habitId_idx',
        columns: ['habitId'],
      }),
      this.createIndex({
        schema: 'public',
        table: 'routines',
        index: 'routines_userId_idx',
        columns: ['userId'],
      }),
      this.createIndex({
        schema: 'public',
        table: 'users',
        index: 'users_email_key',
        columns: ['email'],
        extras: { unique: true },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'habit_entries',
        foreignKey: {
          name: 'habit_entries_habitId_fkey',
          columns: ['habitId'],
          references: { schema: 'public', table: 'habits', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'habits',
        foreignKey: {
          name: 'habits_userId_fkey',
          columns: ['userId'],
          references: { schema: 'public', table: 'users', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'password_reset_codes',
        foreignKey: {
          name: 'password_reset_codes_userId_fkey',
          columns: ['userId'],
          references: { schema: 'public', table: 'users', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'routine_habits',
        foreignKey: {
          name: 'routine_habits_habitId_fkey',
          columns: ['habitId'],
          references: { schema: 'public', table: 'habits', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'routine_habits',
        foreignKey: {
          name: 'routine_habits_routineId_fkey',
          columns: ['routineId'],
          references: { schema: 'public', table: 'routines', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'routines',
        foreignKey: {
          name: 'routines_userId_fkey',
          columns: ['userId'],
          references: { schema: 'public', table: 'users', columns: ['id'] },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
    ];
  }
}

MigrationCLI.run(import.meta.url, M);
