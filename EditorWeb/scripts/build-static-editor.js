import { copyFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
const src = resolve('../Sources/MemoryWallEditorBridge/Resources/Editor/index.html');
const dst = resolve('../App/DesktopMemoryWallApp/Resources/Editor/index.html');
mkdirSync(dirname(dst), { recursive: true });
copyFileSync(src, dst);
console.log(`copied ${src} -> ${dst}`);
