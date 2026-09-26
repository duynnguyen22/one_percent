import { Injectable, NotFoundException } from '@nestjs/common';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { PrismaService } from 'src/prisma.service';
import { fromDb } from 'src/utils/temporal';
import { omit } from 'lodash';

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}
  async update(id: string, updateProfileDto: UpdateProfileDto) {
    const updatedUser = await this.prisma.orm.User.where({ id }).update({
      ...updateProfileDto,
    });

    if (!updatedUser) {
      throw new NotFoundException(`No user found for id: ${id}`);
    }

    return {
      message: 'Profile updated successfully',
      user: omit(fromDb(updatedUser), ['passwordHash']),
    };
  }
}
