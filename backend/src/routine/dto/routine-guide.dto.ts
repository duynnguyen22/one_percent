import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsInt, IsString, Length, Max, Min } from 'class-validator';

export class RoutineGuideDto {
  @ApiProperty({ example: 'Cat-Cow spinal rolls' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(1, 100)
  title: string;

  @ApiProperty({ example: 60, minimum: 5, maximum: 3600 })
  @IsInt()
  @Min(5)
  @Max(3600)
  durationSeconds: number;
}
