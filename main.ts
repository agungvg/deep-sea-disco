// Deep Sea Disco — the entry program for make.fun's roblox-brainrot-01.
// It hands the game in: the Rojo place (game.rbxl), the Luau sources, the
// screenshots and PLAY.json are copied to /output, and /output/dossier.json
// is written with the vendored make.fun library. Node 22, standard library
// only; nothing is installed before it runs.
//
// Local check, exactly as the grader runs it:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoRoot = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Skip every file or directory whose name starts with a dot. The grader
 *  refuses an entry whose output holds one (.gitkeep, .DS_Store, .git). */
function keepVisible(sourcePath: string): boolean {
  return !basename(sourcePath).startsWith('.');
}

function deliver(): void {
  mkdirSync(outputDir, { recursive: true });

  // The place and its link go in first, then the sources and the pictures.
  copyFileSync(join(repoRoot, 'game.rbxl'), join(outputDir, 'game.rbxl'));
  copyFileSync(join(repoRoot, 'PLAY.json'), join(outputDir, 'PLAY.json'));
  cpSync(join(repoRoot, 'src'), join(outputDir, 'src'), { recursive: true, filter: keepVisible });

  const shots = join(repoRoot, 'screenshots');
  mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
  if (existsSync(shots)) {
    cpSync(shots, join(outputDir, 'screenshots'), { recursive: true, filter: keepVisible });
  }

  // The dossier is what the gate compares byte for byte, so the caps here
  // are the scorer's own: at most 4 screenshots of at most 256 KiB each,
  // a place of at most 500,000 instances, scripts of at most 8 MiB total.
  const dossier = buildDossier(outputDir, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  });
  writeFileSync(join(outputDir, 'dossier.json'), dossier);
}

deliver();
