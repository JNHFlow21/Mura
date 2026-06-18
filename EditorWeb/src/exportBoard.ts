export async function exportBoardPNG(): Promise<Blob> {
  const canvas = document.createElement('canvas');
  canvas.width = 1920; canvas.height = 1080;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('missing 2d context');
  ctx.fillStyle = '#fff8df'; ctx.fillRect(0, 0, canvas.width, canvas.height);
  return await new Promise((resolve, reject) => canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('png export failed')), 'image/png'));
}
