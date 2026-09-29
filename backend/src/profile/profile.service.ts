import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { PrismaService } from 'src/prisma.service';
import { StorageService } from 'src/storage/storage.service';
import { fromDb } from 'src/utils/temporal';
import { omit } from 'lodash';
import { detectImageType } from './image-type';

@Injectable()
export class ProfileService {
  constructor(
    private prisma: PrismaService,
    private storage: StorageService,
  ) {}
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

  /**
   * Stores [file] as the user's avatar, points `avatarUrl` at it, and deletes
   * the avatar it replaces.
   */
  async updateAvatar(id: string, file: Express.Multer.File | undefined) {
    if (!file) {
      throw new BadRequestException('No image was uploaded');
    }
    const ext = detectImageType(file.buffer);
    if (!ext) {
      throw new BadRequestException('Avatar must be a JPEG, PNG or WebP image');
    }

    const existing = await this.prisma.orm.User.first({ id });
    if (!existing) {
      throw new NotFoundException(`No user found for id: ${id}`);
    }

    // A fresh name per upload, so clients never show a stale cached image.
    const avatarUrl = await this.storage.save(
      `avatars/${id}-${randomUUID()}.${ext}`,
      file.buffer,
    );
    const result = await this.update(id, { avatarUrl });
    await this.storage.remove(existing.avatarUrl);

    return { ...result, message: 'Avatar updated successfully' };
  }
}
