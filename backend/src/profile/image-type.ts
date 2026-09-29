/** Image formats accepted as avatars, keyed by the extension they are saved with. */
const SIGNATURES = {
  jpg: (b: Buffer) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
  png: (b: Buffer) =>
    b
      .subarray(0, 8)
      .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  webp: (b: Buffer) =>
    b.toString('ascii', 0, 4) === 'RIFF' &&
    b.toString('ascii', 8, 12) === 'WEBP',
} as const;

export type ImageExtension = keyof typeof SIGNATURES;

/**
 * Identifies an image by its leading bytes rather than the client-supplied
 * mimetype, which is trivially spoofed. Returns null for anything else.
 */
export function detectImageType(buffer: Buffer): ImageExtension | null {
  if (buffer.length < 12) return null;
  const match = (Object.keys(SIGNATURES) as ImageExtension[]).find((ext) =>
    SIGNATURES[ext](buffer),
  );
  return match ?? null;
}
