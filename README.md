# Hackathon Docker Sandboxes : « Mission : poste de travail agentique de confiance »

| Fichier | Pour qui |
|---|---|
| `LIVRET-PARTICIPANT.md` | les participants : énoncés, documentation, astuces |
| `../guide-animateur-pas-a-pas.md` | l'animateur : énoncés, **solutions**, validation (non distribué) |
| `PARTICIPANT-BOOKLET.md` | version anglaise du livret participant |
| `../facilitator-guide-step-by-step.md` | version anglaise du guide animateur (non distribué) |

Arborescence :

```text
app/        l'application Loan Desk (Node.js, sans dépendance), avec un bug volontaire
backlog/    tickets Markdown (simule Jira) pour l'agent autonome du niveau 7
kits/       kits sbx : node (mixin), hack-tools (mixin), vscode-remote (mixin), vscode-ssh (workload)
env/        couches sbxenv : vscode, mcp, secrets, et la recette devsbx
sbxenv.yaml environnement socle (niveau 3)
skills/     la skill loan-desk-conventions (niveau 5)
ide/        configurations Zed et ACP Patchbay (niveau 4 bis)
mcp/        enregistrement des serveurs MCP (niveau 5)
scripts/    check.sh (flags), install-node.sh (Node.js dans un sandbox) et worker-loop.sh (niveau 7)
```
