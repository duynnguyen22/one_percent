import 'dotenv/config';
import { Client } from 'pg';

const APP_TABLES = [
  'users',
  'habits',
  'habit_entries',
  'password_reset_codes',
  'routines',
  'routine_habits',
];

/**
 * The database service tests run against: `TEST_DATABASE_URL`, or the dev
 * database's name with `_test` appended. Anything not named `*_test` is
 * refused, since the tests truncate every table.
 */
export function testDatabaseUrl(): string {
  const url = new URL(
    process.env.TEST_DATABASE_URL ?? process.env.DATABASE_URL ?? '',
  );
  if (!process.env.TEST_DATABASE_URL) {
    url.pathname = `${url.pathname}_test`;
  }
  if (!testDatabaseName(url).endsWith('_test')) {
    throw new Error(`Refusing to run tests against ${testDatabaseName(url)}`);
  }
  return url.toString();
}

export const testDatabaseName = (url: URL) => url.pathname.slice(1);

/** Empties every app table. Call in `beforeEach` of a database-backed suite. */
export async function resetDatabase(): Promise<void> {
  const client = new Client({ connectionString: testDatabaseUrl() });
  await client.connect();
  try {
    await client.query(`TRUNCATE ${APP_TABLES.join(', ')} CASCADE`);
  } finally {
    await client.end();
  }
}
