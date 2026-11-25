import http from 'node:http';
import { pathToFileURL } from 'node:url';
import { monthlyPayment } from './loan.js';
import { listLoans, getLoan } from './store.js';

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

export function createServer() {
  return http.createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    const parts = url.pathname.split('/').filter(Boolean);

    if (req.method === 'GET' && url.pathname === '/health') {
      return send(res, 200, { status: 'ok' });
    }
    if (req.method === 'GET' && url.pathname === '/loans') {
      return send(res, 200, listLoans());
    }
    if (req.method === 'GET' && parts[0] === 'loans' && parts.length === 2) {
      const loan = getLoan(parts[1]);
      if (!loan) return send(res, 404, { error: 'loan not found' });
      return send(res, 200, {
        ...loan,
        monthlyPayment: monthlyPayment(loan.principal, loan.annualRatePercent, loan.months),
      });
    }
    // TODO (ticket LD-101): GET /loans/{id}/schedule
    return send(res, 404, { error: 'not found' });
  });
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 3000);
  createServer().listen(port, '0.0.0.0', () => console.log(`Loan Desk listening on :${port}`));
}
