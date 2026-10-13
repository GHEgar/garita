import { spawnSync } from 'node:child_process';
import { realpathSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(realpathSync(fileURLToPath(import.meta.url))));

const WRITES = new Set(['write', 'edit', 'multiedit', 'patch']);

function toolInput(tool, args = {}) {
    if (tool === 'bash') {
        return { command: args.command ?? '' };
    }
    return {
        file_path: args.filePath ?? args.path ?? '',
        content: args.content ?? '',
        new_string: args.newString ?? '',
        edits: (args.edits ?? []).map((edit) => ({ new_string: edit.newString ?? '' })),
    };
}

function run(hook, directory, input) {
    const result = spawnSync(join(root, 'hooks', hook), {
        input: JSON.stringify({ tool_input: input }),
        env: { ...process.env, CLAUDE_PROJECT_DIR: directory },
        encoding: 'utf8',
    });
    if (result.error) {
        const mentionsPush = (input.command ?? '').includes('push');
        return mentionsPush ? { decision: 'deny', reason: `garita: ${hook} failed, blocking a command that mentions push` } : null;
    }
    if (result.status === 2) {
        return { decision: 'deny', reason: result.stderr.trim() };
    }
    if (!result.stdout.trim()) {
        return null;
    }
    try {
        const output = JSON.parse(result.stdout).hookSpecificOutput;
        return { decision: output.permissionDecision, reason: output.permissionDecisionReason };
    } catch {
        return null;
    }
}

function hookFor(tool) {
    if (tool === 'bash') {
        return 'guard-git.sh';
    }
    return WRITES.has(tool) ? 'guard-content.sh' : null;
}

export const Garita = async ({ directory }) => ({
    'tool.execute.before': async (input, output) => {
        const hook = hookFor(input.tool);
        if (!hook) {
            return;
        }
        const verdict = run(hook, directory, toolInput(input.tool, output.args));
        if (verdict?.decision === 'deny') {
            throw new Error(verdict.reason);
        }
    },
    'tool.execute.after': async (input) => {
        if (WRITES.has(input.tool)) {
            run('mirror.sh', directory, toolInput(input.tool, input.args));
        }
    },
});
