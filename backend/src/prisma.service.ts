// Prisma 8 reads and writes date columns as Temporal values, which Node 22
// does not ship. Loaded here so it is in place before the first query.
import 'temporal-polyfill/global';
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import postgres, { type PostgresClient } from '@prisma/orm-postgres/runtime';
import { Pool } from 'pg';
import type { Contract } from 'generated/prisma8/contract';
import contractJson from 'generated/prisma8/contract.json';

type Client = PostgresClient<Contract>;

/** The models of the `public` schema, e.g. `orm.User`. */
export type Orm = Client['orm']['public'];

@Injectable()
export class PrismaService implements OnModuleDestroy {
  // Timestamp columns carry no zone and hold UTC, so database-side `now()`
  // defaults must run in UTC whatever the server's TimeZone setting is.
  private readonly pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    options: '-c TimeZone=UTC',
  });

  private readonly client: Client = postgres<Contract>({
    contractJson,
    pg: this.pool,
  });

  get orm(): Orm {
    return this.client.orm.public;
  }

  /** The SQL builder, for statements the ORM can't express. */
  get sql(): Client['sql']['public'] {
    return this.client.sql.public;
  }

  /** Runs a SQL-builder write that returns no rows. */
  execute(plan: Parameters<ReturnType<Client['runtime']>['execute']>[0]) {
    return this.client.runtime().execute(plan);
  }

  /** Commits when `fn` resolves, rolls back when it throws. */
  transaction<R>(fn: (orm: Orm) => Promise<R>): Promise<R> {
    return this.client.transaction((tx) => fn(tx.orm.public));
  }

  // The client leaves a pool it was handed open, so it is ended here too.
  async onModuleDestroy() {
    await this.client.close();
    await this.pool.end();
  }
}
