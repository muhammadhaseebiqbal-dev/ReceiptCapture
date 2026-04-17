import fs from 'fs/promises';
import path from 'path';
import { randomUUID } from 'crypto';

const uploadRoot = path.resolve('uploads');

async function ensureDirectory(dirPath) {
  await fs.mkdir(dirPath, { recursive: true });
}

function extensionFromMimeType(mimeType = '') {
  if (mimeType === 'image/jpeg') return '.jpg';
  if (mimeType === 'image/png') return '.png';
  if (mimeType === 'image/webp') return '.webp';
  if (mimeType === 'image/heic') return '.heic';
  return '';
}

export async function saveBufferAsReceiptImage(buffer, mimeType, originalName = '') {
  const receiptDir = path.join(uploadRoot, 'receipts');
  await ensureDirectory(receiptDir);

  const extFromName = path.extname(originalName || '');
  const fileName = `${randomUUID()}${extFromName || extensionFromMimeType(mimeType) || '.bin'}`;
  const filePath = path.join(receiptDir, fileName);
  await fs.writeFile(filePath, buffer);

  return {
    filePath,
    publicPath: `/uploads/receipts/${fileName}`,
  };
}

export async function saveBase64AsReceiptImage(base64Data, mimeType, originalName = '') {
  const normalized = String(base64Data || '').replace(/^data:[^;]+;base64,/, '');
  const buffer = Buffer.from(normalized, 'base64');
  return saveBufferAsReceiptImage(buffer, mimeType, originalName);
}