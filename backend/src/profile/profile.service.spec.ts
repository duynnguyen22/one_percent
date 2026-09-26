import { Test } from '@nestjs/testing';
import { ProfileService } from './profile.service';
import { PrismaService } from 'src/prisma.service';

describe('ProfileService.update', () => {
  const user = {
    id: 'aaaaaaaa-0000-4000-8000-000000000001',
    email: 'a@x.io',
    passwordHash: '$2b$10$abcdefghijklmnopqrstuv',
    userName: 'Alex',
  };

  let service: ProfileService;
  let prisma: { user: { findUnique: jest.Mock; update: jest.Mock } };

  beforeEach(async () => {
    prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue(user),
        update: jest.fn(({ data }: { data: object }) =>
          Promise.resolve({ ...user, ...data }),
        ),
      },
    };
    const moduleRef = await Test.createTestingModule({
      providers: [ProfileService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = moduleRef.get(ProfileService);
  });

  it('never returns the password hash', async () => {
    const result = await service.update(user.id, { userName: 'Sam' });

    expect(result.user).not.toHaveProperty('passwordHash');
    expect(result.user).toMatchObject({ userName: 'Sam' });
  });

  it('404s for an unknown user', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(service.update('nobody', { userName: 'x' })).rejects.toThrow(
      'No user found for id: nobody',
    );
  });
});
