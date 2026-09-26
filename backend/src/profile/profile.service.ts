import { Injectable, NotFoundException } from '@nestjs/common';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { PrismaService } from 'src/prisma.service';
import { omit } from 'lodash';

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}
  async update(id: string, updateProfileDto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`No user found for id: ${id}`);
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: { ...user, ...updateProfileDto },
    });

    return {
      message: 'Profile updated successfully',
      user: omit(updatedUser, ['passwordHash']),
    };
  }
}
