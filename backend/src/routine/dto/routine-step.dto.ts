import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';

export class RoutineStepDto {
  @ApiProperty({ example: 'c1f7a3d2-6e21-4f11-9a3b-9e451b6a22c1' })
  @IsUUID()
  habitId: string;

  @ApiPropertyOptional({ example: 5, minimum: 1, maximum: 180, default: 5 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(180)
  durationMinutes?: number;
}
