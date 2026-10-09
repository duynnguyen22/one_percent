import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { RoutineGuideDto } from './routine-guide.dto';

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

  /**
   * Ordered sub-moves; array position is the order. Omitted on update keeps
   * the step's current guides, `[]` clears them.
   */
  @ApiPropertyOptional({ type: [RoutineGuideDto] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => RoutineGuideDto)
  guides?: RoutineGuideDto[];
}
