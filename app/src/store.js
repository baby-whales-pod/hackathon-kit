// Fictitious in-memory data. No real data.
const loans = [
  { id: 'L-001', applicant: 'Applicant A', principal: 200000, annualRatePercent: 3.5, months: 300, status: 'approved' },
  { id: 'L-002', applicant: 'Applicant B', principal: 12500, annualRatePercent: 6.5, months: 60, status: 'pending' },
  { id: 'L-003', applicant: 'Applicant C', principal: 10000, annualRatePercent: 5, months: 12, status: 'rejected' },
  { id: 'L-004', applicant: 'Applicant D', principal: 30000, annualRatePercent: 2.9, months: 84, status: 'pending' },
  { id: 'L-005', applicant: 'Applicant E', principal: 8000, annualRatePercent: 0, months: 24, status: 'approved' },
];

export function listLoans() {
  return loans;
}

export function getLoan(id) {
  return loans.find((loan) => loan.id === id);
}
