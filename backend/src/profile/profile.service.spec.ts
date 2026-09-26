import { NotFoundException } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { createUser, useDatabaseService } from '../../test/factories';

describe('ProfileService.update', () => {
  const ctx = useDatabaseService(ProfileService);

  it('updates the supplied fields and never returns the password hash', async () => {
    const user = await createUser(ctx.prisma, { userName: 'Alex' });

    const result = await ctx.service.update(user.id, { userName: 'Sam' });

    expect(result.message).toBe('Profile updated successfully');
    expect(result.user).not.toHaveProperty('passwordHash');
    expect(result.user).toMatchObject({ id: user.id, userName: 'Sam' });
    expect(result.user.createdAt).toBeInstanceOf(Date);
    const stored = await ctx.prisma.orm.User.first({ id: user.id });
    expect(stored?.userName).toBe('Sam');
  });

  it('leaves fields that were not supplied untouched', async () => {
    const user = await createUser(ctx.prisma, { userName: 'Alex' });

    await ctx.service.update(user.id, { userPhone: '0123' });

    const stored = await ctx.prisma.orm.User.first({ id: user.id });
    expect(stored).toMatchObject({ userName: 'Alex', userPhone: '0123' });
  });

  it('404s for an unknown user', async () => {
    await expect(
      ctx.service.update('aaaaaaaa-0000-4000-8000-000000000001', {
        userName: 'x',
      }),
    ).rejects.toThrow(NotFoundException);
  });
});
