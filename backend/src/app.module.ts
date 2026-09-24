import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { HabitModule } from './habit/habit.module';
import { EntriesModule } from './entries/entries.module';
import { EmailModule } from './email/email.module';
import { ProfileModule } from './profile/profile.module';
import { RoutineModule } from './routine/routine.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    HabitModule,
    EntriesModule,
    EmailModule,
    ProfileModule,
    RoutineModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
