import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateRoutineDto } from './create-routine.dto';
import { UpdateRoutineDto } from './update-routine.dto';

const HABIT_A = 'aaaaaaaa-0000-4000-8000-000000000001';

/** Property paths that failed, as the global ValidationPipe would see them. */
const failures = async (
  cls: new () => object,
  body: Record<string, unknown>,
): Promise<string[]> => {
  const errors = await validate(plainToInstance(cls, body), {
    whitelist: true,
  });
  const paths: string[] = [];
  const walk = (list: typeof errors, prefix: string) =>
    list.forEach((e) => {
      const path = prefix ? `${prefix}.${e.property}` : e.property;
      if (e.constraints) paths.push(path);
      walk(e.children ?? [], path);
    });
  walk(errors, '');
  return paths;
};

const valid = {
  name: 'Morning Ritual',
  steps: [{ habitId: HABIT_A, durationMinutes: 2 }],
};

describe('CreateRoutineDto', () => {
  it('accepts a full body', async () => {
    expect(
      await failures(CreateRoutineDto, {
        ...valid,
        description: 'Start slow.',
        color: '#4d6054',
        cadence: 'Morning',
      }),
    ).toEqual([]);
  });

  it('accepts a step without a duration', async () => {
    expect(
      await failures(CreateRoutineDto, {
        name: 'x',
        steps: [{ habitId: HABIT_A }],
      }),
    ).toEqual([]);
  });

  it.each([
    ['empty name', { name: '' }, 'name'],
    ['whitespace name', { name: '   ' }, 'name'],
    ['long name', { name: 'a'.repeat(101) }, 'name'],
    ['bad color', { color: 'green' }, 'color'],
    ['long cadence', { cadence: 'a'.repeat(31) }, 'cadence'],
    ['long description', { description: 'a'.repeat(501) }, 'description'],
    ['no steps', { steps: [] }, 'steps'],
    [
      'too many steps',
      { steps: Array.from({ length: 21 }, () => ({ habitId: HABIT_A })) },
      'steps',
    ],
    ['non-uuid habit', { steps: [{ habitId: 'nope' }] }, 'steps.0.habitId'],
    [
      'zero minutes',
      { steps: [{ habitId: HABIT_A, durationMinutes: 0 }] },
      'steps.0.durationMinutes',
    ],
    [
      'too many minutes',
      { steps: [{ habitId: HABIT_A, durationMinutes: 181 }] },
      'steps.0.durationMinutes',
    ],
    [
      'fractional minutes',
      { steps: [{ habitId: HABIT_A, durationMinutes: 1.5 }] },
      'steps.0.durationMinutes',
    ],
  ])('rejects %s', async (_label, patch, path) => {
    expect(await failures(CreateRoutineDto, { ...valid, ...patch })).toEqual([
      path,
    ]);
  });

  it('requires name and steps', async () => {
    expect((await failures(CreateRoutineDto, {})).sort()).toEqual([
      'name',
      'steps',
    ]);
  });

  it('trims name and cadence', () => {
    const dto = plainToInstance(CreateRoutineDto, {
      ...valid,
      name: '  Morning  ',
      cadence: ' Evening ',
    });
    expect(dto.name).toBe('Morning');
    expect(dto.cadence).toBe('Evening');
  });
});

describe('UpdateRoutineDto', () => {
  it('accepts an empty body', async () => {
    expect(await failures(UpdateRoutineDto, {})).toEqual([]);
  });

  it('still validates steps when present', async () => {
    expect(await failures(UpdateRoutineDto, { steps: [] })).toEqual(['steps']);
  });
});
