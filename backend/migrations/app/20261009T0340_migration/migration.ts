#!/usr/bin/env -S node
import type { Contract as Start } from '../../snapshots/07d328a12b399baa17e881b986e0a4bb390abe409e196457c0982927e0b66483/contract';
import startContract from '../../snapshots/07d328a12b399baa17e881b986e0a4bb390abe409e196457c0982927e0b66483/contract.json' with { type: 'json' };
import type { Contract as End } from '../../snapshots/c67279a33ba771c58d05e1c28e3ae9a4b6a90a25d71e012fd6e5bc12c4d7f142/contract';
import endContract from '../../snapshots/c67279a33ba771c58d05e1c28e3ae9a4b6a90a25d71e012fd6e5bc12c4d7f142/contract.json' with { type: 'json' };
import { Migration, MigrationCLI, col, primaryKey } from '@prisma/orm-postgres/migration';

export default class M extends Migration<Start, End> {
  override readonly startContractJson = startContract;
  override readonly endContractJson = endContract;

  override get operations() {
    return [
      this.createTable({
        schema: 'public',
        table: 'routine_step_guides',
        columns: [
          col('durationSeconds', 'int4', { notNull: true, codecRef: { codecId: 'pg/int4@1' } }),
          col('habitId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('id', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('order', 'int4', { notNull: true, codecRef: { codecId: 'pg/int4@1' } }),
          col('routineId', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
          col('title', 'text', { notNull: true, codecRef: { codecId: 'pg/text@1' } }),
        ],
        constraints: [primaryKey(['id'])],
      }),
      this.createIndex({
        schema: 'public',
        table: 'routine_step_guides',
        index: 'routine_step_guides_step_order_idx',
        columns: ['routineId', 'habitId', 'order'],
      }),
      this.addForeignKey({
        schema: 'public',
        table: 'routine_step_guides',
        foreignKey: {
          name: 'routine_step_guides_step_fkey',
          columns: ['routineId', 'habitId'],
          references: {
            schema: 'public',
            table: 'routine_habits',
            columns: ['routineId', 'habitId'],
          },
          onDelete: 'cascade',
          onUpdate: 'cascade',
        },
      }),
    ];
  }
}

MigrationCLI.run(import.meta.url, M);
