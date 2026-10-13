import { afterEach, beforeEach, expect, test } from 'bun:test';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Garita } from '../opencode/garita.js';

let project;
let hooks;

const config = {
    git: { pushMessage: 'bloqueado desde opencode' },
    content: [{ files: ['*.yml'], pattern: 'TAG:-', message: 'sin defaults' }],
};

beforeEach(async () => {
    project = mkdtempSync(join(tmpdir(), 'garita-opencode-'));
    mkdirSync(join(project, '.claude'));
    writeFileSync(join(project, '.claude', 'garita.json'), JSON.stringify(config));
    hooks = await Garita({ directory: project });
});

afterEach(() => {
    rmSync(project, { recursive: true, force: true });
});

const before = (tool, args) => hooks['tool.execute.before']({ tool }, { args });

test('blocks push with the configured message', async () => {
    await expect(before('bash', { command: 'git -C x push' })).rejects.toThrow('bloqueado desde opencode');
});

test('lets other commands through', async () => {
    await expect(before('bash', { command: 'git status' })).resolves.toBeUndefined();
});

test('does not block commits: opencode asks through its own permissions', async () => {
    await expect(before('bash', { command: 'git commit -m "feat: x"' })).resolves.toBeUndefined();
});

test('blocks attributions', async () => {
    await expect(before('bash', { command: 'git commit -m "x Co-Authored-By: y"' })).rejects.toThrow();
});

test('applies content rules to write', async () => {
    await expect(before('write', { filePath: join(project, 'a.yml'), content: 'image: ${TAG:-x}' })).rejects.toThrow('sin defaults');
});

test('applies content rules to edit', async () => {
    await expect(before('edit', { filePath: join(project, 'a.yml'), oldString: 'a', newString: '${TAG:-x}' })).rejects.toThrow('sin defaults');
});

test('ignores other tools', async () => {
    await expect(before('read', { filePath: join(project, 'a.yml') })).resolves.toBeUndefined();
});

test('mirrors CLAUDE.md after a write', async () => {
    writeFileSync(join(project, 'CLAUDE.md'), 'hola\n');
    await hooks['tool.execute.after']({ tool: 'write', args: { filePath: join(project, 'CLAUDE.md') } }, {});
    expect(readFileSync(join(project, 'AGENTS.md'), 'utf8')).toBe('hola\n');
});

test('does nothing without config', async () => {
    rmSync(join(project, '.claude'), { recursive: true });
    await expect(before('bash', { command: 'git push' })).resolves.toBeUndefined();
    writeFileSync(join(project, 'CLAUDE.md'), 'hola\n');
    await hooks['tool.execute.after']({ tool: 'write', args: { filePath: join(project, 'CLAUDE.md') } }, {});
    expect(existsSync(join(project, 'AGENTS.md'))).toBe(false);
});
