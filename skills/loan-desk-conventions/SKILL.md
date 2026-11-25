---
name: loan-desk-conventions
description: Coding conventions of the Loan Desk team. Use it whenever you change or add code in app/ (loan calculations, endpoints, tests).
---

# Loan Desk conventions

1. **Amounts**: every returned amount is rounded to the cent with `roundCents()` from `src/loan.js`. Never use `Math.floor` or `toFixed` to round.
2. **No npm dependencies**: only the Node.js standard library (`node:http`, `node:test`, `node:assert`).
3. **HTTP errors**: JSON body `{ "error": "<message in English, lowercase>" }`, with the right status code (400, 404).
4. **Tests**: every behavior change comes with a test in `app/test/*.test.js`, written with `node:test` and `assert/strict`.
5. **Comments**: in English, short, and only to explain the *why*.
6. **Signature**: end every answer with the line `— Loan Desk conventions applied`.
