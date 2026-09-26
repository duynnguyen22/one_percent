import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { EmailService } from 'src/email/email.service';
import { hashingPassword } from 'src/utils';
import { fromDb, toDbTimestamp } from 'src/utils/temporal';
import { createUser, useDatabaseService } from '../../test/factories';

const ACCESS_SECRET = 'access-secret';
const RESET_SECRET = 'reset-secret';

const GENERIC_MESSAGE =
  'If that email is registered, a reset code is on its way.';
const INVALID_CODE_MESSAGE = 'Invalid or expired code';

describe('AuthService password reset', () => {
  let sent: { to: string; code: string }[];
  const ctx = useDatabaseService(AuthService, [
    {
      provide: JwtService,
      useValue: new JwtService({ secret: ACCESS_SECRET }),
    },
    {
      provide: ConfigService,
      useValue: {
        get: (key: string) =>
          ({
            JWT_SECRET: ACCESS_SECRET,
            JWT_RESET_SECRET: RESET_SECRET,
          })[key],
      },
    },
    {
      provide: EmailService,
      useValue: {
        sendPasswordResetCode: (to: string, code: string) => {
          sent.push({ to, code });
          return Promise.resolve();
        },
      },
    },
  ]);
  let user: { id: string; email: string };

  /** The code most recently delivered by email — what the real user would type. */
  const lastCode = () => sent[sent.length - 1].code;
  const codes = async () =>
    fromDb(
      await ctx.prisma.orm.PasswordResetCode.where({ userId: user.id })
        .orderBy((c) => c.createdAt.asc())
        .all(),
    );
  const newestRow = async () => (await codes()).at(-1)!;
  const storedHash = async () =>
    (await ctx.prisma.orm.User.first({ id: user.id }))!.passwordHash;
  /** Overwrites columns of a stored code, e.g. to expire or consume it. */
  const setCode = (id: string, fields: Record<string, Date>) =>
    ctx.prisma.orm.PasswordResetCode.where({ id }).update(
      Object.fromEntries(
        Object.entries(fields).map(([key, at]) => [key, toDbTimestamp(at)]),
      ),
    );
  /** Moves a row's `createdAt` back so the resend cooldown reads as elapsed. */
  const backdate = async (ms: number) => {
    const row = await newestRow();
    await setCode(row.id, {
      createdAt: new Date(row.createdAt.getTime() - ms),
    });
  };

  beforeEach(async () => {
    sent = [];
    user = await createUser(ctx.prisma, {
      email: 'alex@example.com',
      passwordHash: await hashingPassword('old-password'),
    });
  });

  describe('forgotPassword', () => {
    it('answers identically for a registered and an unregistered address', async () => {
      const registered = await ctx.service.forgotPassword(user.email);
      const unregistered =
        await ctx.service.forgotPassword('nobody@example.com');

      expect(registered).toEqual({ message: GENERIC_MESSAGE });
      expect(unregistered).toEqual(registered);
    });

    it('sends only for the registered address', async () => {
      await ctx.service.forgotPassword('nobody@example.com');
      expect(sent).toHaveLength(0);

      await ctx.service.forgotPassword(user.email);
      expect(sent).toEqual([
        { to: user.email, code: expect.stringMatching(/^\d{6}$/) as string },
      ]);
    });

    it('stores the code hashed, never in the clear', async () => {
      await ctx.service.forgotPassword(user.email);

      expect((await newestRow()).codeHash).not.toContain(lastCode());
    });

    it('expires the stored code 15 minutes out', async () => {
      const before = Date.now();
      await ctx.service.forgotPassword(user.email);

      const ttl = (await newestRow()).expiresAt.getTime() - before;
      expect(ttl).toBeGreaterThan(14 * 60 * 1000);
      expect(ttl).toBeLessThanOrEqual(15 * 60 * 1000 + 1000);
    });

    it('consumes prior unconsumed rows when a new code is requested', async () => {
      await ctx.service.forgotPassword(user.email);
      await backdate(61_000);

      await ctx.service.forgotPassword(user.email);

      const [first, second] = await codes();
      expect(first.consumedAt).toBeInstanceOf(Date);
      expect(second.consumedAt).toBeNull();
      expect(await codes()).toHaveLength(2);
    });

    it('suppresses a resend inside 60 seconds of the previous request', async () => {
      await ctx.service.forgotPassword(user.email);

      const second = await ctx.service.forgotPassword(user.email);

      expect(second).toEqual({ message: GENERIC_MESSAGE });
      expect(sent).toHaveLength(1);
      expect(await codes()).toHaveLength(1);
    });

    it('allows a resend once the cooldown has elapsed', async () => {
      await ctx.service.forgotPassword(user.email);
      await backdate(61_000);

      await ctx.service.forgotPassword(user.email);

      expect(sent).toHaveLength(2);
      expect(await codes()).toHaveLength(2);
    });
  });

  describe('verifyResetCode', () => {
    it('returns a reset token for the correct code', async () => {
      await ctx.service.forgotPassword(user.email);

      const { resetToken } = await ctx.service.verifyResetCode(
        user.email,
        lastCode(),
      );

      expect(typeof resetToken).toBe('string');
      expect((await newestRow()).verifiedAt).toBeInstanceOf(Date);
    });

    it('issues a token JwtStrategy’s access secret will not accept', async () => {
      await ctx.service.forgotPassword(user.email);
      const { resetToken } = await ctx.service.verifyResetCode(
        user.email,
        lastCode(),
      );

      const asAccessToken = new JwtService({ secret: ACCESS_SECRET });
      expect(() => {
        asAccessToken.verify(resetToken);
      }).toThrow();

      const asResetToken = new JwtService({ secret: RESET_SECRET });
      const { id: prcId } = await newestRow();
      expect(asResetToken.verify(resetToken)).toEqual(
        expect.objectContaining({
          userId: user.id,
          prcId,
          typ: 'pwd_reset',
        }),
      );
    });

    it('rejects a wrong code and counts the attempt', async () => {
      await ctx.service.forgotPassword(user.email);

      await expect(
        ctx.service.verifyResetCode(user.email, '000000'),
      ).rejects.toThrow(INVALID_CODE_MESSAGE);
      expect((await newestRow()).attempts).toBe(1);
    });

    it('stops accepting the code once 5 attempts are spent', async () => {
      await ctx.service.forgotPassword(user.email);
      for (let i = 0; i < 5; i++) {
        await expect(
          ctx.service.verifyResetCode(user.email, '000000'),
        ).rejects.toThrow(INVALID_CODE_MESSAGE);
      }

      // The correct code no longer works either.
      await expect(
        ctx.service.verifyResetCode(user.email, lastCode()),
      ).rejects.toThrow(INVALID_CODE_MESSAGE);
      expect((await newestRow()).attempts).toBe(5);
    });

    it('rejects a code past its expiry', async () => {
      await ctx.service.forgotPassword(user.email);
      await setCode((await newestRow()).id, {
        expiresAt: new Date(Date.now() - 1000),
      });

      await expect(
        ctx.service.verifyResetCode(user.email, lastCode()),
      ).rejects.toThrow(INVALID_CODE_MESSAGE);
    });

    it('rejects a code whose row was already consumed', async () => {
      await ctx.service.forgotPassword(user.email);
      const code = lastCode();
      await setCode((await newestRow()).id, { consumedAt: new Date() });

      await expect(
        ctx.service.verifyResetCode(user.email, code),
      ).rejects.toThrow(INVALID_CODE_MESSAGE);
    });

    it('rejects an unknown address with the same message as a wrong code', async () => {
      await expect(
        ctx.service.verifyResetCode('nobody@example.com', '123456'),
      ).rejects.toThrow(INVALID_CODE_MESSAGE);
    });

    it('re-verifies a still-valid code so back-navigation is not a dead end', async () => {
      await ctx.service.forgotPassword(user.email);
      const first = await ctx.service.verifyResetCode(user.email, lastCode());

      const second = await ctx.service.verifyResetCode(user.email, lastCode());

      expect(second.resetToken).toEqual(expect.any(String));
      expect(first.resetToken).toEqual(expect.any(String));
    });
  });

  describe('resetPassword', () => {
    const verifiedToken = async (email: string) => {
      const { resetToken } = await ctx.service.verifyResetCode(
        email,
        sentCode(sent),
      );
      return resetToken;
    };

    it('replaces the password and consumes the row', async () => {
      await ctx.service.forgotPassword(user.email);
      const resetToken = await verifiedToken(user.email);
      const previousHash = await storedHash();

      await ctx.service.resetPassword(resetToken, 'brand-new-password');

      expect(await storedHash()).not.toBe(previousHash);
      expect((await newestRow()).consumedAt).toBeInstanceOf(Date);
    });

    it('lets the user log in with the new password afterwards', async () => {
      await ctx.service.forgotPassword(user.email);
      const resetToken = await verifiedToken(user.email);

      await ctx.service.resetPassword(resetToken, 'brand-new-password');

      await expect(
        ctx.service.login(user.email, 'brand-new-password'),
      ).resolves.toEqual(
        expect.objectContaining({ accessToken: expect.any(String) as string }),
      );
    });

    it('refuses to reuse the same reset token twice', async () => {
      await ctx.service.forgotPassword(user.email);
      const resetToken = await verifiedToken(user.email);
      await ctx.service.resetPassword(resetToken, 'brand-new-password');

      await expect(
        ctx.service.resetPassword(resetToken, 'another-password'),
      ).rejects.toThrow();
    });

    it('refuses a token whose row was never verified', async () => {
      await ctx.service.forgotPassword(user.email);
      const forged = new JwtService({ secret: RESET_SECRET }).sign({
        userId: user.id,
        prcId: (await newestRow()).id,
        typ: 'pwd_reset',
      });

      await expect(
        ctx.service.resetPassword(forged, 'brand-new-password'),
      ).rejects.toThrow();
    });

    it('refuses a token signed with the access secret', async () => {
      await ctx.service.forgotPassword(user.email);
      const accessToken = new JwtService({ secret: ACCESS_SECRET }).sign({
        userId: user.id,
        prcId: (await newestRow()).id,
        typ: 'pwd_reset',
      });

      await expect(
        ctx.service.resetPassword(accessToken, 'brand-new-password'),
      ).rejects.toThrow();
    });

    it('refuses a valid reset-secret token that is not a reset token', async () => {
      await ctx.service.forgotPassword(user.email);
      await ctx.service.verifyResetCode(user.email, sentCode(sent));
      const wrongType = new JwtService({ secret: RESET_SECRET }).sign({
        userId: user.id,
        prcId: (await newestRow()).id,
        typ: 'access',
      });

      await expect(
        ctx.service.resetPassword(wrongType, 'brand-new-password'),
      ).rejects.toThrow();
    });
  });
});

function sentCode(sent: { to: string; code: string }[]): string {
  return sent[sent.length - 1].code;
}
