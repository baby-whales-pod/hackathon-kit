import { test } from 'node:test';
import assert from 'node:assert/strict';
import { monthlyPayment, roundCents } from '../src/loan.js';

test('roundCents rounds to the nearest cent', () => {
  assert.equal(roundCents(1.005), 1.01);
  assert.equal(roundCents(2.344), 2.34);
});

test('monthly payment: 10 000 at 5% over 12 months', () => {
  assert.equal(monthlyPayment(10000, 5, 12), 856.07);
});

test('monthly payment: 200 000 at 3.5% over 300 months', () => {
  assert.equal(monthlyPayment(200000, 3.5, 300), 1001.25);
});

test('monthly payment: 12 500 at 6.5% over 60 months', () => {
  assert.equal(monthlyPayment(12500, 6.5, 60), 244.58);
});
