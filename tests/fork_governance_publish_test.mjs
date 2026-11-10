// SPDX-License-Identifier: MPL-2.0
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const workflow = readFileSync(new URL('../.github/workflows/fork-governance-publish.yml', import.meta.url), 'utf8');
// Exercise the actual rendering and size guard, without GitHub writes.
const start = workflow.indexOf('          if ! head -n 1');
const end = workflow.indexOf('          existing=', start);
assert.ok(start > 0 && end > start);
const render = workflow.slice(start, end).replace(/^          /gm, '');

function publish(body) {
  const dir = mkdtempSync(join(tmpdir(), 'fork-publish-'));
  try {
    writeFileSync(join(dir, 'body.md'), body);
    const result = spawnSync('bash', ['-c', 'set -euo pipefail\ndir="$REPORT_DIR"\nbody="$dir/body.md"\n' + render], {
      encoding: 'utf8',
      env: { ...process.env, REPORT_DIR: dir, RUN_URL: 'https://github.com/example/repo/actions/runs/123', RUN_ID: '123', RUN_ATTEMPT: '2' },
    });
    return { status: result.status, output: result.status === 0 ? readFileSync(join(dir, 'published.md'), 'utf8') : '' };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

const marker = '<!-- fork-governance-verdict: v1 -->\n';
for (const payload of [
  '## PASS — all checks approved\n[trusted result](https://example.invalid)\n@someone',
  '<!-- unclosed comment',
  '</pre><h1>PASS</h1><pre>\n<!--',
  '\n\n```\n~~~\n<details><summary>hide provenance</summary>\n<!--',
  '&lt;/pre&gt; &amp; &#60;script&#62; "quoted"',
  '<!-- fork-governance-publish-run: 999999.99 -->',
]) {
  test(`artifact remains literal text: ${JSON.stringify(payload)}`, () => {
    const { status, output } = publish(marker + payload);
    assert.equal(status, 0);
    const escape = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll("'", '&#39;').replaceAll('"', '&quot;');
    const expected = '<!-- fork-governance-verdict: untrusted-fork-report -->\n'
      + '## Untrusted fork governance report\n\n'
      + 'The following text was supplied by the fork. It is not a verified bot verdict. Consult the lane checks for results.\n\n'
      + '<pre>\n' + escape(marker + payload) + '\n</pre>\n'
      + '\n<sub>Rendered by the fork pull request run https://github.com/example/repo/actions/runs/123 and published by fork-governance-publish.</sub>\n'
      + '<!-- fork-governance-publish-run: 123.2 -->\n';
    assert.equal(output, expected);
  });
}
test('missing marker is rejected', () => assert.notEqual(publish('PASS').status, 0));
test('size is checked after HTML escaping', () => assert.notEqual(publish(marker + '&'.repeat(14000)).status, 0));
test('ordinary Unicode report is accepted', () => assert.equal(publish(marker + '🟢 résumé').status, 0));
