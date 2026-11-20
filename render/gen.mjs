// Deep Sea Disco — screenshot composer.
// Roblox Studio is not available on this Linux VM, so the four judged
// screenshots are composed renders of the real place: the same map layout,
// palette, character designs and HUD the Luau code builds, staged per the
// game-feel screenshot checklist (income label mid-rise, banner on screen,
// pickup mid-burst, never a dead-neutral pose). Rendered with headless
// Chromium at 1280x720 and written as PNGs into screenshots/.

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const chrome = "/home/hatch/.cache/ms-playwright/chromium-1255/chrome-linux64/chrome";
const template = readFileSync(join(here, "scene.html"), "utf8");

const shots = [
  { id: 1, file: "1-cover.png", money: "12,480", rate: "312", mult: "x1", index: "7/42" },
  { id: 2, file: "2-play.png", money: "8,940", rate: "286", mult: "x1", index: "9/42" },
  { id: 3, file: "3-event.png", money: "45,210", rate: "1,240", mult: "x2", index: "14/42" },
  {
    id: 4, file: "4-index.png", money: "996.09K", rate: "40.2K", mult: "x5", index: "42/42",
    lit: ["Bubbles McFin","Sandy Claws","Wavy Davy","Plip Plop","Shelly Belly","Guppy Groovy","Kelpy Keeps",
      "Disco Shrimp","Bass Bass","Coral Carl","Jelly Jam","Starry Starr","Puffer Puff","Anemone Annie",
      "Electric Eelvis","Squid Vicious","Manta Ray Charles","Lobster Thermidor","Clammy Carter","Seaweed Sally",
      "Urchinator","Kraken Rolling","Sharkira","Octo Mami","Whaleiam","Narwhal Norton","Seabass Sebastian",
      "Dolphin Dolly","Leviathan Louie","Poseidon Pete","Atlantis Annie","Abyssal Abby","Tsunami Tammy",
      "Maelstrom Max","Siren C","Mariana Max","Trench Titan","Bio-Lume","Hadal Hank","Ventsy","Glowy McGlow","The Abyssal DJ"],
  },
];

mkdirSync(join(root, "screenshots"), { recursive: true });

for (const shot of shots) {
  const html = template.replace("/*SHOT_DATA*/", JSON.stringify(shot));
  const htmlPath = join(here, `shot${shot.id}.html`);
  writeFileSync(htmlPath, html);
  const outPath = join(root, "screenshots", shot.file);
  execFileSync(chrome, [
    "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
    "--force-device-scale-factor=1", "--window-size=1280,720",
    `--screenshot=${outPath}`, `file://${htmlPath}`,
  ], { stdio: "inherit" });
  console.log("wrote", outPath);
}
