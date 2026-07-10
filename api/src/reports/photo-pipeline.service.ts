import { randomUUID } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { BadRequestException, Injectable } from '@nestjs/common';
import sharp from 'sharp';

const MAX_DIMENSION = 1280;
const WEBP_QUALITY = 70;

export const UPLOADS_DIR = join(process.cwd(), 'uploads');

@Injectable()
export class PhotoPipelineService {
  /**
   * Decodes, re-encodes to WebP and writes the file. sharp() decoding
   * doubles as "is this really an image" validation — corrupt/non-image
   * buffers throw here. Never call withMetadata(): EXIF (incl. GPS) must
   * always be stripped.
   */
  async process(buffer: Buffer): Promise<string> {
    const filename = `${randomUUID()}.webp`;
    await mkdir(UPLOADS_DIR, { recursive: true });
    try {
      await sharp(buffer, { failOn: 'error', limitInputPixels: 50_000_000 })
        .rotate()
        .resize({
          width: MAX_DIMENSION,
          height: MAX_DIMENSION,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: WEBP_QUALITY })
        .toFile(join(UPLOADS_DIR, filename));
    } catch {
      throw new BadRequestException('Geçersiz fotoğraf dosyası');
    }
    return filename;
  }
}
