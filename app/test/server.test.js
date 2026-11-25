import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from '../src/server.js';

const server = createServer().listen(0);
const base = () => `http://127.0.0.1:${server.address().port}`;
after(() => server.close());

test('GET /health', async () => {
  const res = await fetch(`${base()}/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'ok' });
});

test('GET /loans/L-003 returns the monthly payment', async () => {
  const res = await fetch(`${base()}/loans/L-003`);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).monthlyPayment, 856.07);
});

test('GET /loans/unknown returns 404', async () => {
  const res = await fetch(`${base()}/loans/L-999`);
  assert.equal(res.status, 404);
});
