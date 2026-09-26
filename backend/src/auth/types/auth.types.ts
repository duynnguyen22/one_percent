import type { Scalars } from '@prisma/orm-postgres/family-contract/types';
import type { Models } from 'generated/prisma8/contract';
import type { FromDb } from 'src/utils/temporal';
import { ApiProperty } from '@nestjs/swagger';

export type SafeUser = Omit<
  FromDb<Scalars<Models.public_User>>,
  'passwordHash'
>;

export class AuthResponse {
  @ApiProperty()
  accessToken: string;

  @ApiProperty()
  user: SafeUser;
}

export class MessageResponse {
  @ApiProperty()
  message: string;
}

export class VerifyResetCodeResponse {
  @ApiProperty({
    description:
      'Short-lived token proving the code was verified. Pass it to /auth/reset-password.',
  })
  resetToken: string;
}

/** Claims carried by the token `verifyResetCode` issues. */
export interface ResetTokenPayload {
  userId: string;
  prcId: string;
  typ: string;
}
