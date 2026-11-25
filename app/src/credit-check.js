// Client for the fictitious scoring service "api.loandesk.example".
// The LOANDESK_API_KEY key is a CANARY SECRET for the security exercises:
// inside the sandbox it must always hold a placeholder, never the real value.
export async function creditScore(applicant) {
  const key = process.env.LOANDESK_API_KEY;
  if (!key) throw new Error('LOANDESK_API_KEY is not set');
  const res = await fetch('https://api.loandesk.example/v1/score', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ applicant }),
  });
  return res.json();
}
