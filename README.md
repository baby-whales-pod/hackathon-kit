# Docker Sandboxes hackathon: "Mission: a trusted agentic workstation"

| File | For whom |
|---|---|
| `PARTICIPANT-BOOKLET.md` | participants: briefs, documentation, tips |
| `facilitator-guide-step-by-step.md` | facilitators: briefs, **solutions**, validation (do not give it to participants) |

Folder layout:

```text
app/        the Loan Desk application (Node.js, no dependencies), with a deliberate bug
backlog/    Markdown tickets (simulates Jira) for the autonomous agent of level 7
kits/       sbx kits: node (mixin), hack-tools (mixin), vscode-remote (mixin), vscode-ssh (workload)
env/        sbxenv layers: vscode, mcp, secrets, and the devsbx recipe
sbxenv.yaml base environment (level 3)
skills/     the loan-desk-conventions skill (level 5)
ide/        Zed and ACP Patchbay configurations (level 4 bis)
mcp/        registration of the MCP servers (level 5)
scripts/    check.sh (flags), install-node.sh (Node.js in a sandbox) and worker-loop.sh (level 7)
```
