import assert from 'node:assert/strict';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Exercise native resource selection and reference loading after real relocation.
const { loadSkills, loadSkillsFromDir } = await import(pathToFileURL(resolve(process.argv[2])).href);
const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const temp = mkdtempSync(join(tmpdir(), 'review-package-'));

function readReferences(file, root, visited = new Set()) {
  file = realpathSync(file);
  const within = relative(realpathSync(root), file);
  assert(!isAbsolute(within) && within !== '..' && !within.startsWith(`..${sep}`), `Reference escapes plugin: ${file}`);
  if (visited.has(file)) return;
  visited.add(file);
  const content = readFileSync(file, 'utf8');
  for (const [, target] of content.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
    if (/^[a-z]+:|^#/i.test(target)) continue;
    readReferences(resolve(dirname(file), target.split('#')[0]), root, visited);
  }
}

try {
  const copy = join(temp, 'relocated package with spaces');
  mkdirSync(copy);
  cpSync(join(repo, 'package.json'), join(copy, 'package.json'));
  for (const plugin of ['codex-tools', 'pi-tools', 'wslopen-tools']) {
    const source = join(repo, 'plugins', plugin);
    if (existsSync(source)) cpSync(source, join(copy, 'plugins', plugin), { recursive: true });
  }
  const upstream = join(temp, 'upstream', 'brainstorming');
  mkdirSync(upstream, { recursive: true });
  writeFileSync(join(upstream, 'SKILL.md'), '---\nname: brainstorming\ndescription: Upstream brainstorming fixture\n---\nUse upstream guidance.\n');
  const manifest = JSON.parse(readFileSync(join(copy, 'package.json'), 'utf8'));
  const selected = loadSkills({ cwd: temp, agentDir: join(temp, 'empty-agent'), includeDefaults: false,
    skillPaths: [...manifest.pi.skills.map(path => resolve(copy, path)), upstream] });
  assert.equal(realpathSync(selected.skills.find(skill => skill.name === 'brainstorming').filePath),
    realpathSync(join(upstream, 'SKILL.md')), 'Package shadows upstream brainstorming');
  assert.deepEqual(selected.diagnostics, [], 'Native resource diagnostics');

  const plugin = join(copy, 'plugins', 'codex-tools');
  const linked = join(temp, 'linked skills');
  symlinkSync(join(plugin, 'skills'), linked, 'dir');
  for (const dir of [join(plugin, 'skills'), linked]) {
    const loaded = loadSkillsFromDir({ dir, source: 'package-check' });
    assert.deepEqual(loaded.diagnostics, []);
    for (const skill of loaded.skills) readReferences(skill.filePath, plugin);
  }
  const broken = join(plugin, 'skills', 'broken.md');
  writeFileSync(join(copy, 'outside.md'), 'Not shipped with the plugin.');
  writeFileSync(broken, '[external dependency](../../../outside.md)');
  assert.throws(() => readReferences(broken, plugin), /Reference escapes plugin/);
  console.log('Native selection, copied/symlinked references, and broken-package rejection passed.');
} finally {
  rmSync(temp, { recursive: true, force: true });
}
