/* eslint-disable @typescript-eslint/no-unsafe-call */
import 'dotenv/config';
import { definePrismaConfig } from 'prisma/config';
import { defineConfig as definePostgresConfig } from '@prisma/orm-postgres/config';

declare const process: {
  env: {
    DATABASE_URL?: string;
  };
};

export default definePrismaConfig({
  orm: definePostgresConfig({
    contract: 'prisma8/contract.prisma',
    output: 'generated/prisma8',
    db: {
      connection: process.env.DATABASE_URL,
    },
  }),
});
