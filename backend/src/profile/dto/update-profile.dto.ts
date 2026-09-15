import { IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  avatarUrl?: string;

  @IsOptional()
  userName?: string;

  @IsOptional()
  userPhone?: string;
}
