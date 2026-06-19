import { copyFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
const files = [
  ['../Sources/MemoryWallEditorBridge/Resources/Editor/index.html', '../App/DesktopMemoryWallApp/Resources/Editor/index.html'],
  ['../Sources/MemoryWallEditorBridge/Resources/Fonts/LXGWWenKai-Regular.ttf', '../App/DesktopMemoryWallApp/Resources/Fonts/LXGWWenKai-Regular.ttf']
];
for (const [source, target] of files) {
  const src = resolve(source);
  const dst = resolve(target);
  mkdirSync(dirname(dst), { recursive: true });
  copyFileSync(src, dst);
  console.log(`copied ${src} -> ${dst}`);
}
