import { Module } from '@nestjs/common';
import { RoutineService } from './routine.service';
import { RoutineController } from './routine.controller';
import { PrismaService } from 'src/prisma.service';

@Module({
  controllers: [RoutineController],
  providers: [RoutineService, PrismaService],
})
export class RoutineModule {}
