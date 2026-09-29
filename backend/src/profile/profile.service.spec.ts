import { BadRequestException, NotFoundException } from '@nestjs/common';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { ProfileService } from './profile.service';
import { StorageService } from 'src/storage/storage.service';
import { createUser, useDatabaseService } from '../../test/factories';

describe('ProfileService.update', () => {
  const ctx = useDatabaseService(ProfileService, [StorageService]);

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

describe('ProfileService.updateAvatar', () => {
  const ctx = useDatabaseService(ProfileService, [StorageService]);
  let dir: string;

  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    Buffer.alloc(16),
  ]);
  const asUpload = (buffer: Buffer) => ({ buffer }) as Express.Multer.File;
  const onDisk = (publicPath: string) =>
    join(dir, publicPath.replace(/^\/uploads\//, ''));

  beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'bloom-uploads-'));
    process.env.UPLOADS_DIR = dir;
  });
  afterEach(() => {
    rmSync(dir, { recursive: true, force: true });
    delete process.env.UPLOADS_DIR;
  });

  it('stores the image and points avatarUrl at its public path', async () => {
    const user = await createUser(ctx.prisma);

    const result = await ctx.service.updateAvatar(user.id, asUpload(png));

    const avatarUrl = result.user.avatarUrl!;
    expect(avatarUrl).toMatch(
      new RegExp(`^/uploads/avatars/${user.id}-[0-9a-f-]+\\.png$`),
    );
    expect(readFileSync(onDisk(avatarUrl))).toEqual(png);
    const stored = await ctx.prisma.orm.User.first({ id: user.id });
    expect(stored?.avatarUrl).toBe(avatarUrl);
  });

  it('deletes the avatar it replaces', async () => {
    const user = await createUser(ctx.prisma);
    const first = await ctx.service.updateAvatar(user.id, asUpload(png));

    const second = await ctx.service.updateAvatar(user.id, asUpload(png));

    expect(second.user.avatarUrl).not.toBe(first.user.avatarUrl);
    expect(existsSync(onDisk(first.user.avatarUrl!))).toBe(false);
    expect(existsSync(onDisk(second.user.avatarUrl!))).toBe(true);
  });

  it('rejects files that are not images, whatever their mimetype', async () => {
    const user = await createUser(ctx.prisma);
    const fake = {
      buffer: Buffer.from('<script>alert(1)</script>'),
      mimetype: 'image/png',
    } as Express.Multer.File;

    await expect(ctx.service.updateAvatar(user.id, fake)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('400s when no file was sent', async () => {
    const user = await createUser(ctx.prisma);

    await expect(ctx.service.updateAvatar(user.id, undefined)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('404s for an unknown user without writing anything', async () => {
    await expect(
      ctx.service.updateAvatar(
        'aaaaaaaa-0000-4000-8000-000000000001',
        asUpload(png),
      ),
    ).rejects.toThrow(NotFoundException);
    expect(existsSync(join(dir, 'avatars'))).toBe(false);
  });
});
