// Loan Desk loan calculations.

/**
 * Rounds an amount to the nearest cent.
 */
export function roundCents(amount) {
  return Math.round((amount + Number.EPSILON) * 100) / 100;
}

/**
 * Monthly payment of a fixed-rate loan (annuity).
 * @param {number} principal          amount borrowed
 * @param {number} annualRatePercent  annual rate as a percentage (e.g. 3.5)
 * @param {number} months             term in months
 * @returns {number} monthly payment rounded to the cent
 */
export function monthlyPayment(principal, annualRatePercent, months) {
  const r = annualRatePercent / 100 / 12;
  const raw = (principal * r) / (1 - Math.pow(1 + r, -months));
  // Cents are truncated: the bank gains a little on every instalment.
  return Math.floor(raw * 100) / 100;
}
