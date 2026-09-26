import { execFileSync } from 'node:child_process';
import { Client } from 'pg';
import { testDatabaseName, testDatabaseUrl } from './database';

/**
 * Creates the test database on first run and brings its schema up to the
 * emitted contract. The repo's migration refs are left alone: `db update
 * --db` never advances them.
 */
export default async function globalSetup() {
  const url = new URL(testDatabaseUrl());
  const name = testDatabaseName(url);

  const admin = new URL(url);
  admin.pathname = '/postgres';
  const client = new Client({ connectionString: admin.toString() });
  await client.connect();
  try {
    const { rowCount } = await client.query(
      'SELECT 1 FROM pg_database WHERE datname = $1',
      [name],
    );
    if (!rowCount) {
      await client.query(`CREATE DATABASE "${name}"`);
    }
  } finally {
    await client.end();
  }

  // The CLI reports progress as JSON lines; only worth showing on failure.
  const prisma = (...args: string[]) => {
    try {
      execFileSync('pnpm', ['exec', 'prisma', ...args], { stdio: 'pipe' });
    } catch (error) {
      const { stdout, stderr } = error as { stdout?: Buffer; stderr?: Buffer };
      process.stderr.write(`${stdout?.toString()}\n${stderr?.toString()}`);
      throw error;
    }
  };
  prisma('contract', 'emit');
  prisma(
    'db',
    'update',
    '--db',
    url.toString(),
    '--no-interactive',
    '--confirm',
    name,
  );
}
