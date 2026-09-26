import { ConflictException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { EmailService } from 'src/email/email.service';
import { hashingPassword } from 'src/utils';
import { createUser, useDatabaseService } from '../../test/factories';

describe('AuthService', () => {
  const jwt = {
    sign: jest.fn().mockReturnValue('token'),
    signAsync: jest.fn().mockResolvedValue('token'),
  };
  const ctx = useDatabaseService(AuthService, [
    { provide: JwtService, useValue: jwt },
    { provide: ConfigService, useValue: { get: jest.fn() } },
    { provide: EmailService, useValue: { sendPasswordResetCode: jest.fn() } },
  ]);

  beforeEach(() => jest.clearAllMocks());

  describe('register', () => {
    it('stores the user and signs the userId claim JwtStrategy reads', async () => {
      const response = await ctx.service.register(
        'alex@example.com',
        'pw123456',
      );

      const stored = await ctx.prisma.orm.User.first({
        email: 'alex@example.com',
      });
      expect(stored).not.toBeNull();
      expect(jwt.signAsync).toHaveBeenCalledWith({ userId: stored!.id });
      expect(response.user).toMatchObject({
        id: stored!.id,
        email: 'alex@example.com',
      });
      expect(response.user.createdAt).toBeInstanceOf(Date);
    });

    it('never leaks the password hash', async () => {
      const response = await ctx.service.register(
        'alex@example.com',
        'pw123456',
      );

      expect(response.user).not.toHaveProperty('passwordHash');
    });

    it('refuses an email that is already registered', async () => {
      await createUser(ctx.prisma, { email: 'alex@example.com' });

      await expect(
        ctx.service.register('alex@example.com', 'pw123456'),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    it('returns the user without the hash and an access token', async () => {
      const user = await createUser(ctx.prisma, {
        passwordHash: await hashingPassword('pw123456'),
      });

      const response = await ctx.service.login(user.email, 'pw123456');

      expect(response.accessToken).toBe('token');
      expect(response.user).toMatchObject({ id: user.id });
      expect(response.user).not.toHaveProperty('passwordHash');
    });

    it('404s for an unknown email', async () => {
      await expect(
        ctx.service.login('nobody@example.com', 'pw123456'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getProfile', () => {
    it('returns the user without the hash', async () => {
      const user = await createUser(ctx.prisma);

      const profile = await ctx.service.getProfile(user.id);

      expect(profile).toMatchObject({ id: user.id, email: user.email });
      expect(profile).not.toHaveProperty('passwordHash');
      expect(profile.createdAt).toBeInstanceOf(Date);
    });

    it('404s for an unknown id', async () => {
      await expect(
        ctx.service.getProfile('aaaaaaaa-0000-4000-8000-000000000001'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('validateUser', () => {
    it('returns the user without the hash, or null', async () => {
      const user = await createUser(ctx.prisma);

      const found = (await ctx.service.validateUser(user.id)) as object;

      expect(found).toMatchObject({ id: user.id });
      expect(found).not.toHaveProperty('passwordHash');
      await expect(
        ctx.service.validateUser('aaaaaaaa-0000-4000-8000-000000000001'),
      ).resolves.toBeNull();
    });
  });
});
