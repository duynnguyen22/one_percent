import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional } from 'class-validator';

export class GetRoutinesQueryDto {
  @ApiPropertyOptional({ example: '2026-09-25' })
  @IsOptional()
  @IsDateString()
  date?: string;
}
