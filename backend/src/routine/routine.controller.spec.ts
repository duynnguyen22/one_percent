import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { RoutineController } from './routine.controller';
import { RoutineService } from './routine.service';

describe('RoutineController', () => {
  const service = {
    findAll: jest.fn().mockResolvedValue('all'),
    findOne: jest.fn().mockResolvedValue('one'),
    create: jest.fn().mockResolvedValue('created'),
    update: jest.fn().mockResolvedValue('updated'),
    remove: jest.fn().mockResolvedValue('removed'),
  };
  const controller = new RoutineController(
    service as unknown as RoutineService,
  );

  it('serves /routines behind the JWT guard', () => {
    expect(Reflect.getMetadata(PATH_METADATA, RoutineController)).toBe(
      'routines',
    );
    expect(Reflect.getMetadata(GUARDS_METADATA, RoutineController)).toEqual([
      JwtAuthGuard,
    ]);
  });

  it('passes the current user to every service call', async () => {
    const body = { name: 'x', steps: [] };
    expect(await controller.findAll('u1', { date: '2026-09-25' })).toBe('all');
    expect(await controller.findOne('r1', 'u1', {})).toBe('one');
    expect(await controller.create('u1', body)).toBe('created');
    expect(await controller.update('r1', 'u1', { name: 'y' })).toBe('updated');
    expect(await controller.remove('r1', 'u1')).toBe('removed');

    expect(service.findAll).toHaveBeenCalledWith('u1', { date: '2026-09-25' });
    expect(service.findOne).toHaveBeenCalledWith('u1', 'r1', {});
    expect(service.create).toHaveBeenCalledWith('u1', body);
    expect(service.update).toHaveBeenCalledWith('u1', 'r1', { name: 'y' });
    expect(service.remove).toHaveBeenCalledWith('u1', 'r1');
  });
});
