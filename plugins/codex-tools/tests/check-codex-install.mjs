import assert from 'node:assert/strict';
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, readdirSync, realpathSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// Run the documented snippet; only remote cloning is replaced with local setup.
const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const section = readFileSync(join(repo, 'README.md'), 'utf8').split('### Codex\n')[1];
const snippet = /```bash\n([\s\S]*?)```/.exec(section)?.[1];
assert(snippet, 'Codex installation snippet unavailable');
const temp = mkdtempSync(join(tmpdir(), 'codex-install-'));
try {
  for (const kind of ['absent', 'directory', 'live symlink', 'dangling symlink', 'file']) {
    const root = join(temp, kind);
    const home = join(root, 'home');
    const work = join(root, 'work with spaces');
    const dest = join(home, '.agents/skills/codex-tools');
    const legacy = join(root, 'legacy');
    mkdirSync(dirname(dest), { recursive: true });
    mkdirSync(work, { recursive: true });
    if (kind === 'directory' || kind === 'live symlink') {
      const target = kind === 'directory' ? dest : legacy;
      mkdirSync(target);
      writeFileSync(join(target, 'keep.txt'), 'existing install');
      if (kind === 'live symlink') symlinkSync(legacy, dest, 'dir');
    } else if (kind === 'dangling symlink') {
      symlinkSync(legacy, dest, 'dir');
    } else if (kind === 'file') {
      writeFileSync(dest, 'existing file');
    }
    const result = spawnSync('bash', ['-c', 'git() { [ "$1" = clone ] || return 90; mkdir -p kthorn-skills/plugins/codex-tools; }\n' + snippet],
      { cwd: work, env: { ...process.env, HOME: home }, encoding: 'utf8' });
    assert.equal(result.status, kind === 'absent' ? 0 : 1, `${kind}: ${result.stderr}`);
    if (kind === 'absent') {
      assert(lstatSync(dest).isSymbolicLink());
      assert.equal(realpathSync(dest), join(work, 'kthorn-skills/plugins/codex-tools'));
    } else if (kind === 'directory' || kind === 'live symlink') {
      assert.deepEqual(readdirSync(dest), ['keep.txt'], `${kind}: existing install changed`);
      assert.equal(readFileSync(join(dest, 'keep.txt'), 'utf8'), 'existing install');
      if (kind === 'live symlink') assert.equal(readlinkSync(dest), legacy);
    } else if (kind === 'dangling symlink') {
      assert.equal(readlinkSync(dest), legacy);
      assert(!existsSync(legacy));
    } else {
      assert.equal(readFileSync(dest, 'utf8'), 'existing file');
    }
  }
  console.log('Documented Codex install creates a full-plugin link and rejects existing destinations without nesting or replacement.');
} finally {
  rmSync(temp, { recursive: true, force: true });
}
