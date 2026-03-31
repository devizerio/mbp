#!/usr/bin/env node
// bin/mbp-prompts.mjs — Interactive prompts for mbp using @clack/prompts
// Called by bin/mbp for rich terminal UI. Falls back to bash prompts if Node unavailable.
//
// Communication: results are written to a file specified by --output <path>.
// The @clack UI renders to stdout/stderr normally (visible to the user).

import * as p from '@clack/prompts';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MBP_REPO = join(__dirname, '..');
const VERSION = readFileSync(join(MBP_REPO, 'VERSION'), 'utf8').trim();

// Parse --output flag from argv
const args = process.argv.slice(2);
let outputFile = null;
const outputIdx = args.indexOf('--output');
if (outputIdx !== -1 && args[outputIdx + 1]) {
  outputFile = args[outputIdx + 1];
  args.splice(outputIdx, 2);
}

function writeResult(data) {
  if (outputFile) {
    writeFileSync(outputFile, data, 'utf8');
  }
}

// Devizer brand color (blue-700 approximation in terminal)
const brand = (text) => `\x1b[38;5;26m${text}\x1b[0m`;
const bold = (text) => `\x1b[1m${text}\x1b[0m`;

// Module definitions — must match bin/mbp
const MODULES = [
  { name: 'xcode',          desc: 'Xcode Command Line Tools', required: true },
  { name: 'homebrew',       desc: 'Homebrew package manager', required: true },
  { name: 'shell',          desc: 'Oh My Zsh + default shell' },
  { name: 'mise',           desc: 'Runtime version manager (node, ruby, python)' },
  { name: 'dotfiles',       desc: 'Symlink dotfiles (.zshrc, .gitconfig, etc.)' },
  { name: 'git',            desc: 'Git config + SSH signing' },
  { name: 'ssh',            desc: 'SSH key permissions + config' },
  { name: 'secrets',        desc: '1Password CLI' },
  { name: 'docker',         desc: 'Docker Desktop' },
  { name: 'ai-tools',       desc: 'Claude Code + gstack' },
  { name: 'macos-defaults', desc: 'Dock, Finder, keyboard, widget defaults' },
  { name: 'apps',           desc: 'GUI applications (casks)' },
  { name: 'dev-dirs',       desc: 'Create ~/.mbp infrastructure dirs' },
];

// === Commands ===

async function modulePicker() {
  p.intro(brand(bold(`mbp v${VERSION}`) + ' — Module Selection'));

  const selected = await p.multiselect({
    message: 'Which modules should we set up?',
    options: MODULES.map((m) => ({
      value: m.name,
      label: m.name,
      hint: m.required ? `${m.desc} (required)` : m.desc,
      disabled: m.required,
    })),
    initialValues: MODULES.map((m) => m.name),
    required: true,
  });

  if (p.isCancel(selected)) {
    p.cancel('Setup cancelled.');
    process.exit(1);
  }

  // Always include required modules
  const result = [...new Set([
    ...MODULES.filter((m) => m.required).map((m) => m.name),
    ...selected,
  ])];

  writeResult(result.join('\n') + '\n');
  p.outro('Module selection saved.');
}

async function confirmUpdate() {
  const shouldRerun = await p.confirm({
    message: 'Re-run setup with the updated version?',
  });

  if (p.isCancel(shouldRerun)) {
    p.cancel('Update cancelled.');
    writeResult('no\n');
    process.exit(0);
  }

  writeResult(shouldRerun ? 'yes\n' : 'no\n');
}

async function selectSingleModule() {
  p.intro(brand(bold(`mbp v${VERSION}`) + ' — Run a single module'));

  const module = await p.select({
    message: 'Which module do you want to run?',
    options: MODULES.map((m) => ({
      value: m.name,
      label: m.name,
      hint: m.desc,
    })),
  });

  if (p.isCancel(module)) {
    p.cancel('Cancelled.');
    process.exit(1);
  }

  writeResult(module + '\n');
}

async function tourStep(stepTitle, stepN, totalSteps, contentPath) {
  const n = parseInt(stepN, 10);
  const total = parseInt(totalSteps, 10);

  let content = '(content not found)';
  if (existsSync(contentPath)) {
    // Skip H1 header (first line), show rest
    const lines = readFileSync(contentPath, 'utf8').split('\n');
    content = lines.slice(1).join('\n').trim();
  }

  p.note(content, `[${n}/${total}] ${stepTitle}`);

  if (n < total) {
    const cont = await p.confirm({ message: 'Continue to next?' });
    if (p.isCancel(cont) || !cont) {
      p.cancel('Tour ended early.');
      process.exit(0);
    }
  } else {
    await p.confirm({ message: 'Finish the tour?' });
  }
}

async function tourWelcome(totalSteps) {
  p.intro(brand(bold('Welcome to your Devizer MBP!')));
  p.log.info(`Let's walk through what was set up (${totalSteps} tools).`);

  const start = await p.confirm({ message: 'Ready to start the tour?' });
  if (p.isCancel(start) || !start) {
    p.cancel('Tour cancelled.');
    process.exit(0);
  }
}

async function tourComplete() {
  p.note(
    [
      `${brand('mbp status')}           — see your current setup`,
      `${brand('mbp audit')}            — check for config drift`,
      `${brand('mbp update')}           — keep mbp current`,
      `${brand('claude')}               — start Claude Code in any project`,
      '',
      `Secrets and personal aliases: ~/.zshrc.local`,
    ].join('\n'),
    'Quick Reference'
  );
  p.outro(brand(bold('Tour complete!')));
}

// === Main dispatcher ===
const command = args[0];

switch (command) {
  case 'module-picker':
    await modulePicker();
    break;
  case 'confirm-update':
    await confirmUpdate();
    break;
  case 'select-module':
    await selectSingleModule();
    break;
  case 'tour-welcome':
    await tourWelcome(args[1]);
    break;
  case 'tour-step':
    await tourStep(args[1], args[2], args[3], args[4]);
    break;
  case 'tour-complete':
    await tourComplete();
    break;
  default:
    console.error(`Unknown prompt command: ${command}`);
    process.exit(1);
}
