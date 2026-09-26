import { PrismaService } from './prisma.service';
import { fromDb } from './utils/temporal';
import { createUser } from '../test/factories';
import { resetDatabase } from '../test/database';

describe('PrismaService', () => {
  const prisma = new PrismaService();

  beforeEach(resetDatabase);
  afterAll(() => prisma.onModuleDestroy());

  // Timestamp columns carry no zone, and the rows Prisma 7 wrote are UTC. A
  // database-side `now()` must agree, whatever the server's TimeZone is.
  it('stores database-default timestamps in UTC', async () => {
    const before = Date.now();
    const user = fromDb(await createUser(prisma));

    expect(Math.abs(user.createdAt.getTime() - before)).toBeLessThan(5_000);
  });
});
