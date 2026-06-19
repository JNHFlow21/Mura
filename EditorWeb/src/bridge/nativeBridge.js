export function encodeMessage(message) {
  return JSON.stringify({ payload: {}, ...message });
}

export function decodePNGDataURL(dataURL) {
  const prefix = 'data:image/png;base64,';
  if (!dataURL.startsWith(prefix)) throw new Error('expected PNG data URL');
  return dataURL.slice(prefix.length);
}
