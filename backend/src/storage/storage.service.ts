import { Injectable } from '@nestjs/common';
import { mkdir, unlink, writeFile } from 'fs/promises';
import { dirname, join, resolve } from 'path';

/** URL prefix the uploads directory is served under — see `main.ts`. */
export const UPLOADS_URL_PREFIX = '/uploads';

/** Where uploaded files live on disk. Overridable so tests write to a temp dir. */
export const uploadsDir = () =>
  resolve(process.env.UPLOADS_DIR ?? join(process.cwd(), 'uploads'));

/**
 * Stores user-uploaded files on the local disk and hands back the public path
 * they are served from.
 *
 * The rest of the app only sees `save` / `remove` and a path string, so moving
 * to S3, R2 or Cloudinary means reimplementing this class and nothing else.
 */
@Injectable()
export class StorageService {
  /**
   * Writes [data] under [key] (e.g. `avatars/abc.jpg`) and returns the path
   * clients fetch it from, e.g. `/uploads/avatars/abc.jpg`.
   */
  async save(key: string, data: Buffer): Promise<string> {
    const target = this.toDiskPath(key);
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, data);
    return `${UPLOADS_URL_PREFIX}/${key}`;
  }

  /**
   * Deletes a file previously returned by [save]. Anything else — an external
   * URL, a path outside the uploads dir, a file already gone — is ignored.
   */
  async remove(publicPath: string | null | undefined): Promise<void> {
    if (!publicPath?.startsWith(`${UPLOADS_URL_PREFIX}/`)) return;
    const key = publicPath.slice(UPLOADS_URL_PREFIX.length + 1);
    await unlink(this.toDiskPath(key)).catch(() => undefined);
  }

  private toDiskPath(key: string) {
    const root = uploadsDir();
    const target = resolve(root, key);
    if (!target.startsWith(root + '/')) {
      throw new Error(`Refusing to touch a path outside uploads: ${key}`);
    }
    return target;
  }
}
