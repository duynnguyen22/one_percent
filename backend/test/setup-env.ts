import { testDatabaseUrl } from './database';

// Runs before each test file, so every PrismaService the tests construct
// talks to the test database, never the dev one. TEST_DATABASE_URL is pinned
// so later testDatabaseUrl() calls don't derive from the overwritten value.
const url = testDatabaseUrl();
process.env.TEST_DATABASE_URL = url;
process.env.DATABASE_URL = url;
