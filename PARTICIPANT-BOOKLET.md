# Participant booklet: Docker Sandboxes hackathon

> **Mission: a trusted agentic workstation**
>
> Nationwide wants its developers to work with **autonomous AI agents** (Copilot CLI, OpenCode...), **without** opening the network to them, **without** exposing secrets, and **without** losing control of the tools (MCP, skills) or the models they use.
>
> Your mission: build and prove, in one day, a **trusted agentic development environment** with Docker Sandboxes (`sbx`).
>
> At 3 pm, you will show everyone an agent that **fixes and evolves a real application** in an environment that is **locked down, reproducible and auditable**. You will also show **that it cannot** do what it must not do.

---

## Contents

1. [The day's schedule](#1-the-days-schedule)
2. [Rules of the game and points](#2-rules-of-the-game-and-points)
3. [Level 0: to do before the day](#3-level-0-to-do-before-the-day)
4. [Understand sbx in 5 minutes](#4-understand-sbx-in-5-minutes)
5. [The exercise repository](#5-the-exercise-repository)
6. [Morning levels (1 to 4 bis)](#6-morning-levels)
7. [Advanced levels (5 to 7)](#7-advanced-levels)
8. [The afternoon team project](#8-the-afternoon-team-project)
9. [Tips](#9-tips)
10. [sbx cheat sheet](#10-sbx-cheat-sheet)
11. [Troubleshooting](#11-troubleshooting)
12. [Glossary](#12-glossary)

---

## 1. The day's schedule

| Time | Session |
|---|---|
| 9:30 | Kick-off: why a sandbox, reading the mission, forming pairs |
| 9:50 | Level 0 check, and catching up on installations |
| 10:00 | **Levels 1 to 4**, in pairs, with points |
| 12:15 | Team check-in: choosing the afternoon workstreams |
| 12:30 | Lunch |
| 13:15 | **Team project**: workstreams A to D (levels 5 to 7) |
| 14:15 | Integration check-in |
| 14:40 | Freeze, demo rehearsal |
| **15:00** | **Demo in front of everyone** |
| 15:30 | Booth prizes, retrospective |

---

## 2. Rules of the game and points

- You work **in pairs**. One pair = one line on the leaderboard.
- Each level has a **flag**: a proof of success. Most flags are checked with `./scripts/check.sh <level>`, which must print `FLAG OK` (otherwise `Not yet...`). Show it to a facilitator to score the points.
- Stuck on a level? **Move on to the next one**: the levels are independent (unless stated otherwise).
- **You hardly write any code**: you **drive agents** and you **configure sandboxes**.

| Level | Topic | Duration | Points |
|---|---|---|---|
| 0 | Installation (before the day) | at home | 50 |
| 1 | First caged agent | 30 min | 100 (+25) |
| 2 | Network and secrets | 40 min | 150 (+50) |
| 3 | `sbxenv.yaml` and kits | 45 min | 200 (+150) |
| 4 | SSH and VS Code | 20 min | 100 |
| 4 bis | Sandboxed agent in the editor (ACP) | 20 min | +75 |
| 5 | MCP and skills | 45 min | 200 |
| 6 | Local model (depending on hardware) | 40 min | 200 |
| 7 | Autonomous agent | 60 min | 300 (+125) |

**Booth prizes**:

- "**Tightest cage**": the shortest network list that still lets the agent work (level 2).
- "**First boss defeated**": the first pair to finish level 7.
- "**Best kit**": the most useful kit, published and signed (level 3).

---

## 3. Level 0: to do before the day

> **50 points**, and above all: you don't waste the morning installing things.

### What you need

- **Workstation**: macOS on Apple Silicon (recommended), or Windows 10 22H2 / 11 x64 with Hyper-V or the Windows Hypervisor Platform enabled. ⚠️ **VDI** or virtualized workstations do not work.
- **RAM**: 16 GB minimum, 32 GB for level 6. **Disk**: 30 GB free.
- **Accounts**: a Docker account in the Nationwide org (SSO), a GitHub account with a **Copilot seat**.
- **Context7 API key** (level 5): create a free account on [context7.com](https://context7.com) and generate a **personal** API key before the day. Keep it to yourself: it will be stored in the sbx vault on your workstation, never in the repository.
- **Software**: `git`, `gh` (GitHub CLI), VS Code with the Remote-SSH extension, an `ssh` client.

### The steps

```bash
# 1. sbx is installed, and you are logged in
sbx version
sbx login
sbx diagnose

# 2. A starting network policy
sbx policy init balanced

# 3. The experimental features used in levels 4 and 6
sbx settings set platform.allowExperimentalFeatures true
sbx settings set feature.ssh true
sbx settings set feature.model true
sbx daemon stop && sbx daemon start --detach

# 4. GitHub, then the Copilot secrets (sbx keeps the COMMAND, not the token)
gh auth login --web --hostname github.com --git-protocol https
sbx secret set copilot --command 'gh auth token'
sbx secret set github  --command 'gh auth token'

# 5. A first sandbox, to download the images in advance
sbx run shell .          # then "exit"
```

**What do the step 3 settings do?**

| Setting | What it enables | Used in |
|---|---|---|
| `platform.allowExperimentalFeatures` | The main switch for sbx experimental features. Without it, the next two settings are ignored | levels 4 and 6 |
| `feature.ssh` | The SSH server built into sbx: each sandbox can be reached with `ssh <name>.sbx`, and so with VS Code Remote-SSH. It is only read when the daemon starts, hence the `sbx daemon stop && sbx daemon start --detach` | level 4 |
| `feature.model` | The `sbx run --model` option: a **local model** served on your workstation by llmman, to which sbx redirects the agent's calls | level 6 |

**Flag**: in the repository folder, `./scripts/check.sh 0` prints `FLAG OK`. Post the output in the hackathon channel.

> If your GitHub org enforces **SSO**, authorize it for `gh` when the browser asks. Otherwise, Copilot answers with a 401 or 403 error.

---

## 4. Understand sbx in 5 minutes

**The problem.** An AI agent no longer just suggests code: it **runs** commands, installs packages and calls APIs. On your workstation, it has **your** rights, **your** network and **your** secrets. On a flat network, that means the whole IT system.

**The sbx answer.** Each agent runs in **its own microVM**:

```text
 Your workstation (host)                                microVM (the sandbox)
 ┌───────────────────────────────┐                     ┌──────────────────────────┐
 │ your files, your secrets      │   shared folder     │ the agent (Copilot...)   │
 │                               │ ◀─────────────────▶ │ its own Linux            │
 │ sbx proxy:                    │                     │ its own Docker           │
 │  - network policy             │ ◀── all network ────│ DECOYS instead           │
 │  - injection of real secrets  │                     │ of secrets               │
 │ MCP gateway, llmman           │                     │                          │
 └───────────────────────────────┘                     └──────────────────────────┘
```

**The three locks**:

1. **Network**: everything goes through the proxy, which applies an allow list and **logs** every decision. A deny always wins.
2. **Secrets**: the VM only sees a **decoy**. The proxy replaces it with the real value, and **only** towards the expected domains.
3. **Tools**: MCP servers and skills are loaded **explicitly**, by you.

**Reproducible**: an `sbxenv.yaml` file and **kits** give the whole team the same environment.

---

## 5. The exercise repository

```text
app/        Loan Desk: a small loan API (Node.js, no dependencies), with a deliberate bug
backlog/    six Markdown tickets that simulate Jira (level 7)
kits/       sbx kits: node, hack-tools, vscode-remote, vscode-ssh
env/        sbxenv layers to stack: vscode, mcp, secrets, devsbx
sbxenv.yaml the base environment (level 3)
skills/     the loan-desk-conventions skill (level 5)
ide/        Zed and ACP Patchbay configurations (level 4 bis)
mcp/        registration of the MCP servers (level 5)
scripts/    check.sh (your flags), install-node.sh (Node.js in a sandbox) and worker-loop.sh (level 7)
```

**Loan Desk** calculates monthly loan payments, lists applications and returns their status. All data is fictitious. Tests: `cd app && npm test`.

> All commands in this booklet are run **from the root of the repository**, unless stated otherwise. 💻 = on your workstation, 📦 = in the sandbox, 🤖 = to ask the agent.

---

## 6. Morning levels

### Level 1: my first caged agent · 100 pts · 30 min

**Goal**: run Copilot CLI in a sandbox on the repository, and have it **fix the bug** that makes two tests fail.

**You will learn**: the agent runs in an isolated microVM. Only the working folder is shared. So the agent can work in "YOLO" mode (without asking for permission) with no risk to your workstation.

**To do**:

1. 💻 Create a sandbox named `lab1`, install Node.js in it, then run Copilot in it:
   ```bash
   sbx create --name lab1 copilot .
   sbx exec -i lab1 sh -s < scripts/install-node.sh   # the Copilot image has no Node.js
   sbx run lab1
   ```
2. 🤖 Ask it to run the tests in `app/`, find out why two tests fail, and fix the code **without touching the tests**.
3. 💻 Quit Copilot, then "visit the cage" with `sbx exec -it lab1 bash`. What can you see? What is the value of `$COPILOT_GITHUB_TOKEN`?

**Flag**: `./scripts/check.sh 1 lab1` prints `FLAG OK`.

**Bonus (+25)**: do the exercise again with `--clone` (don't forget to install Node.js in this new sandbox). The files on your workstation no longer change, and you get the agent's work with `git fetch sandbox-<name>`. This is the **human review before merging**.

<details>
<summary>Hint</summary>

Look at how `app/src/loan.js` rounds the monthly payment, and compare it with the `roundCents` function just above.

</details>

<details>
<summary>OpenCode variant, if Copilot causes problems</summary>

`sbx create --name lab1o opencode .`, `sbx exec -i lab1o sh -s < scripts/install-node.sh`, then `sbx run lab1o`, `/models` in OpenCode and a "GitHub Copilot" model. OpenCode uses your Copilot license with only the `github` secret.

</details>

> 💡 Once the tests are green, **commit** the fix (`git commit`). Level 7 starts from the last commit.

---

### Level 2: zero trust network, zero secrets in the VM · 150 pts · 40 min

**Goal**: start from a **closed** network, open only what is strictly needed, and prove that the agent **cannot exfiltrate** a secret.

**You will learn**:

- network policies (`allow`, `deny`, and the deny that wins);
- the decision log (`sbx policy log`);
- secrets injected by the proxy: the VM only sees a decoy.

**To do**:

1. 💻 Close the network: `sbx policy reset`, then choose **deny-all** when the command asks for the policy to apply (or manually: `sbx policy reset` then `sbx policy init deny-all`).
2. 💻 Restart the agent (`sbx run lab1`). Does it still work? Why? Look at `sbx policy ls --wide` and its origin column.
3. 🤖 Ask the agent to call `https://example.com` and the npm registry. 💻 What does `sbx policy log lab1` say?
4. 💻 Register a **canary secret**, whose "real" value is `nw-canary-0000-real`:

   ```bash
   printf '%s' 'nw-canary-0000-real' | sbx secret set-custom --host api.loandesk.example --env LOANDESK_API_KEY --value-stdin
   ```

   What this command does, piece by piece:

   | Piece | Role |
   |---|---|
   | `printf '%s' 'nw-canary-0000-real'` | Writes the value **without a final newline** (unlike `echo`). Otherwise, the `\n` would be part of the secret. |
   | `\|` … `--value-stdin` | The value comes through standard input, not as an argument: it shows up neither in `ps` nor as an argument of `sbx`. |
   | `sbx secret set-custom` | Registers a "custom" secret (not one of the known services such as `github`). It is stored **on the host**, never in the VM. |
   | `--env LOANDESK_API_KEY` | Creates this environment variable in the sandboxes, but with a **decoy** instead of the real value. |
   | `--host api.loandesk.example` | The only domain for which the proxy replaces the decoy with the real value, in outgoing requests. |

   Result: the agent can only see and copy the decoy. The real value only exists in the proxy, and only towards `api.loandesk.example`. Sent anywhere else, the decoy is worthless.

   ⚠️ The secret is injected **when** a sandbox **is created**. A sandbox that already existed does not see it (see the hint below).

5. **Red team** 🤖: ask the agent to display `LOANDESK_API_KEY`, then to send it to `pastebin.com`. What does it see? What happens?
6. 💻 `sbx policy check network --sandbox lab1 pastebin.com:443`: the decision, **before** even trying.

**Flag**: `./scripts/check.sh 2 lab1` prints `FLAG OK` (the decoy is displayed, pastebin.com is denied).

**Bonus (+50)**: the team's shortest `allow` list that still lets Copilot work.

<details>
<summary>Hint</summary>

If `printenv LOANDESK_API_KEY` returns nothing in the sandbox, the sandbox was created **before** the secret. Delete it (`sbx rm lab1`) and create it again.

</details>

> 💡 After this level, go back to a comfortable policy: `sbx policy reset`, then choose **balanced** (or manually: `sbx policy reset` then `sbx policy init balanced`).

---

### Level 3: declarative, reproducible environment · 200 pts · 45 min

**Goal**: replace manual commands with a versioned **`sbxenv.yaml`**, and understand how a **mixin kit** adds a tool to the sandbox.

**You will learn**:

- `sbx env plan`, `sbx env create` and `sbx env run`;
- how **kits** are composed: a *workload* kit (the agent) and *mixin* kits (tools, network rules, hooks);
- that **a kit carries its own network policy**.

**To do**:

1. Read `sbxenv.yaml`, then `kits/hack-tools/hack-tools.yaml` and `kits/hack-tools/hack-tools.dockerfile`. What does each file do?
2. 💻 `sbx kit validate ./kits/hack-tools`, then `sbx kit inspect ./kits/hack-tools --resolved`.
3. 💻 `sbx env plan`: read what is going to be created.
4. 💻 `sbx env create --force`, then `sbx env run`.
5. 💻 `sbx env exec -- yq --version`. Then `sbx policy ls --source kit`: which rule did the kit add?

**Flag**: `./scripts/check.sh 3` prints `FLAG OK`.

**Bonus**:

- **(+50)** Choose the `yq` version with an **argument** in `sbxenv.yaml` (`args:` under the kit entry), without touching the kit.
- **(+50)** Add a **toolchain** (for example Rust, based on the [devsbx](https://k33g.org/p/20261017-devsbx) article), then `sbx env exec -- cargo --version`.
- **(+50)** Publish the kit to a registry and **sign** it: `sbx kit push ... --sign`, then `sbx kit verify`.

<details>
<summary>Hint: how does the companion Dockerfile work?</summary>

A first stage (`FROM debian...`) downloads the `yq` binary. The final stage (`FROM scratch`) copies only the result: the mixin is just **a layer of files** placed on top of the sandbox. The `.yaml` and the `.dockerfile` are named after the kit folder.

</details>

---

### Level 4: SSH and VS Code access · 100 pts · 20 min

**Goal**: open the sandbox in **VS Code Remote-SSH**, like a devcontainer, but with the isolation, the proxy and the network policy of sbx. The code is built and runs **inside** the sandbox, and Copilot is available in the VS Code terminal.

**To do**:

1. 💻 `sbx setup ssh` (once): it adds a `*.sbx` block to your `~/.ssh/config`.
2. 💻 `code --install-extension ms-vscode-remote.remote-ssh` (once).
3. 💻 Recreate the environment by **stacking** the VS Code layer:

   ```bash
   sbx env rm --force
   sbx env create --force sbxenv.yaml env/sbxenv.vscode.yaml
   ```

4. 💻 `ssh loandesk.sbx 'uname -a'`
5. 💻 `code --new-window --remote ssh-remote+loandesk.sbx "$PWD"`
6. 📦 In the VS Code terminal: run the tests in `app/`, then `copilot`.

**Flag**: `./scripts/check.sh 4 loandesk` prints `FLAG OK`, plus a screenshot of VS Code connected to `loandesk.sbx`.

<details>
<summary>Hint: what does the vscode-remote kit bring?</summary>

On the first connection, VS Code downloads its server **from the sandbox**, then installs extensions. The kit opens exactly these domains, and nothing else. Read `kits/vscode-remote/vscode-remote.yaml`.

</details>

> 📖 To go further: the article ["Reproducing the devcontainer DX, but securely with SBX"](https://k33g.org/p/20261017-devsbx). Its exact recipe is in `env/sbxenv.devsbx.yaml`.

---

### Level 4 bis: the sandboxed agent in my editor (ACP) · +75 pts · 20 min

**Goal**: chat with Copilot, then with OpenCode, **from your editor** (Zed, or VS Code with the **ACP Patchbay** extension), while the agent runs **in its sandbox**.

**You will learn**: with the **Agent Client Protocol** (ACP), the editor starts the agent as a subprocess and talks to it in JSON. `sbx exec -i <sandbox> <agent>` acts as the "cable": the editor stays on your workstation, the agent stays in the cage.

**To do**:

1. 💻 Create two sandboxes: `sbx create copilot --name nw-copilot .` and `sbx create opencode --name nw-opencode --kit-arg model=github-copilot/claude-sonnet-5.5 .` (without a model, OpenCode starts on a model that needs its own authentication, and the editor shows "Authentication required"). If you want the agents to run the tests, install Node.js in each of them (`sbx exec -i <name> sh -s < scripts/install-node.sh`).
2. Declare the agents in the editor, using `ide/zed-settings.json` or `ide/patchbay-commands.txt`. The command is simply `sbx`, with no path.
3. 🤖 Ask for a small file change. Approve it, then reject it, **from the editor**. (Copilot asks for permission; OpenCode writes without asking.)

**Flag**: `./scripts/check.sh 4bis` prints `FLAG OK` (both sandboxes exist and each agent answers over ACP through `sbx exec -i`), plus a screenshot of the editor with an answer from each agent.

> ⚠️ With `sbx exec`, use **`-i` and never `-t`**: a terminal would corrupt the JSON stream. And don't take the agent from the editor's built-in registry: it would run on your workstation, **outside** the sandbox.

---

## 7. Advanced levels

### Level 5: controlled tools, MCP and skills · 200 pts · 45 min

**Goal**: give the agent **reliable context** with two remote MCP servers, show the **before/after**, and prove that no key enters the VM. Then load a conventions **skill**, read-only.

| Server | URL | Authentication |
|---|---|---|
| Wikipedia | `https://wikipedia-mcp.vercel.app/mcp` | none: declared in `env/sbxenv.mcp.yaml` |
| Context7 (up-to-date library docs) | `https://mcp.context7.com/mcp` | personal API key, kept **on the host** |

**You will learn**:

- the **MCP gateway**: the **host** calls the servers, and the agent only sees the gateway address;
- **MCP secrets** (`mcp:<server>:<name>`), which always stay on the host;
- read-only **skills**: the agent cannot add skills to itself.

**To do**:

1. **Before** 🤖: without MCP, ask two questions:
   - "What is banker's rounding (*round half to even*), and should our monthly payment calculation use it? Cite your sources."
   - "Show me the current API of `node:test` in the latest version of Node.js, with the source."
   
   The agent will probably try to go on the web and get **403** errors: the sbx proxy is blocking. 💻 Look at `sbx policy log loandesk`. **Do not approve** these domains (`sbx policy approval ls`): otherwise the "after" no longer proves anything.
2. 💻 Register Context7 and its key on the host: follow `mcp/README.md`.
3. 💻 Recreate the environment by stacking the MCP layer: `sbx env create --force sbxenv.yaml env/sbxenv.vscode.yaml env/sbxenv.mcp.yaml`. Then `sbx mcp ls`.
4. 🤖 In Copilot, `/mcp`, then ask the two questions again, adding "Use the MCP tools (Wikipedia, Context7) rather than the web". What changes? (Without this instruction, Copilot often goes back to its web tool.)
5. **Red team** 💻: `sbx env exec -- sh -c 'env | grep -i context7'`. Then try to call `https://mcp.context7.com/mcp` directly from the sandbox: `sbx env exec -- sh -c 'curl -sS -m 10 -w "\nhttp=%{http_code}\n" https://mcp.context7.com/mcp'`. Who answers, Context7 or the sbx proxy? What does `sbx policy approval ls` show? (Do not approve.)
6. **Skill** 💻: the `skills/loan-desk-conventions/SKILL.md` skill describes the Loan Desk team's conventions (amounts rounded with `roundCents()`, no npm dependency, HTTP error format, one test per change, comments in English). Its last rule is a marker: every answer must end with `— Loan Desk conventions applied`. Read it, then copy `skills/loan-desk-conventions` into `~/.agents/skills/`, then `sbx skills import --dry-run` and `sbx skills import`. Stop the sandbox (`sbx stop loandesk`), because skills are linked at startup, then `sbx env run`. 🤖 Ask it to complete the ticket `backlog/LD-105.md`. How can you tell that the skill was applied? Can the agent change its skills?

**Flag**: `./scripts/check.sh 5 loandesk` prints `FLAG OK`, plus the two "after" answers with their source.

**To discuss**: using an MCP server safely also means **choosing whom you trust**. The Wikipedia server is hosted by a third party, with no authentication, and it receives the agent's questions. At Nationwide, which servers would you allow?

<details>
<summary>Hint</summary>

`sbx env rm --force` before recreating. The **single** quotes around `'CONTEXT7_API_KEY: ${api-key}'` are essential: `${api-key}` is an sbx placeholder, not a shell variable.

</details>

---

### Level 6: local model, the AI stays on the workstation · 200 pts · 40 min

> **Optional** level, which depends on your hardware. Without suitable hardware, team up with another workstation.

**Goal**: run OpenCode with a **local model** on your workstation, without any cloud API, complete a backlog task, and **discuss the remaining risks**.

**You will learn**: **llmman**, the model server **shipped with sbx**, runs on the host. `sbx run --model ...` makes it download and serve the model, then rewrites the agent's routing to it. The model runs **outside** the sandbox, but the sandbox **controls where the agent's traffic goes**.

**To do**:

1. 💻 Check the plumbing with a very small model (the `node` kit brings Node.js and survives model changes, which recreate the container):

   ```bash
   sbx run --name lab6 --kit ./kits/node --model qwen3.5:0.8b \
     --deny-network '**.githubcopilot.com' --deny-network api.openai.com \
     --deny-network api.anthropic.com --deny-network openrouter.ai \
     opencode .
   ```

   The `--deny-network` options block the cloud AI APIs for **this** sandbox. Why is it needed? OpenCode receives your `github` secret and also enables its Copilot provider, even if the default model is the local model. Note the **two** stars in `'**.githubcopilot.com'`: with only one, the rule covers only one level of subdomain, and OpenCode calls `api.business.githubcopilot.com`.
2. 💻 Switch to the model chosen by the facilitators: `sbx run --model <reference> lab6`.
3. 🤖 Complete the ticket `backlog/LD-102.md`, then run the tests.
4. 💻 `sbx policy log lab6`: no **allowed** call to a cloud AI API. **Blocked** attempts to `*.githubcopilot.com` are normal: they prove that nothing gets out.

| Your workstation | Recommended model |
|---|---|
| Apple Silicon Mac, 32 GB or more | the model chosen by the facilitators |
| 16 GB | Gemma 4 E4B or Qwen 3.5 4B |
| No GPU | `qwen3.5:0.8b`: it proves the plumbing, not the quality |

**Flag**: `./scripts/check.sh 6 lab6` prints `FLAG OK`, plus the LD-102 task completed.

**Debate (10 min)**: what is still at risk? The model on the host, the model cache, where the GGUF file comes from, local ports...

---

### Level 7 "Final boss": the agent that works while you sleep · 300 pts · 60 min

**Goal**: start an **autonomous** agent that works through the backlog. For each ticket, it completes it, runs the tests, commits and moves on to the next one. You review its work **before** merging it.

**You will learn**: how to make an agent work alone, on a dedicated branch, with `sbx exec`. Why the sandbox makes this autonomous mode **acceptable**: closed network, secrets outside the VM, human review before merging.

**To do**:

1. 💻 Check that everything is committed (`git status`): the loop refuses to start on a folder that is not clean.
2. 💻 Create a `worker` sandbox and install Node.js in it: `sbx create --name worker copilot .`, then `sbx exec -i worker sh -s < scripts/install-node.sh`
3. Read `scripts/worker-loop.sh`: what does it do with each ticket? What happens if the tests stay red?
4. 💻 In a second terminal: `sbx exec worker env MAX_TICKETS=3 bash scripts/worker-loop.sh`
5. 💻 Meanwhile, **do not change** the repository: the agent works in it, on the `worker/backlog` branch. Watch its commits arrive with `git log --oneline -5`.
6. 💻 At the end, the loop brings you back to `main`. Review the work **as a human** before merging: `git log main..worker/backlog` and `git diff main worker/backlog`.

**Flag**: `./scripts/check.sh 7 worker` prints `FLAG OK` (at least 3 tickets committed, tests green).

**Bonus (+25)**: do the exercise again with `--clone` (before merging). Delete the local branch (`git branch -D worker/backlog`), recreate the worker with `sbx create --clone --name worker copilot .`, reinstall Node.js and restart the loop. This time, your files do not change at all: you get the work with `git fetch sandbox-worker`.

**Bonus (+100)**: replace `backlog/` with a **real test Jira** through an Atlassian MCP server.

---

## 8. The afternoon team project

**Shared goal**: deliver at 3 pm a **"Nationwide Trusted Agent Workstation"** environment and a 5 to 7 minute demo.

**The golden rule**: each workstream delivers **its own** `sbxenv` **file**. The integrator stacks them, like `docker compose -f a.yaml -f b.yaml`. There are no Git conflicts, and the architecture can be shown on screen.

```bash
sbx env create sbxenv.yaml env/sbxenv.vscode.yaml env/sbxenv.mcp.yaml
```

| Workstream | What you deliver | Levels |
|---|---|---|
| **A. Locked-down base** | `sbxenv.yaml`, minimal network list, canary secret | 2, 3 |
| **B. Controlled tools** | `env/sbxenv.mcp.yaml`, conventions skill | 5 |
| **C. Sovereignty** | local model variant, analysis of the remaining risks | 6 |
| **D. Autonomy** | worker sandbox, processed tickets, human review | 7 |
| **Integrator** | assembling the layers, VS Code layer, demo script | 4 |

**The 3 pm demo (7 min)**:

1. The problem: "our agents are powerful, our network is flat".
2. `sbx env plan`: the whole environment fits in a few readable files.
3. The agent at work: the worker has processed N tickets, we show a commit.
4. It cannot cheat: the canary exfiltration is blocked, with `sbx policy log` on screen.
5. Controlled tools: the MCP before/after.
6. The sovereign option: the same environment, a local model, zero cloud calls.

**Suggested criteria for the jury**: value for Nationwide, **demonstrated** security (we prove it, we don't just claim it), reproducibility (can a colleague run everything again tomorrow with a single file?) and demo quality.

---

## 9. Tips

- **Read the log before looking elsewhere**: `sbx policy log <sandbox>` explains 9 blocks out of 10.
- **Name your sandboxes** (`--name lab1`): it is simpler than the default names, and essential for `ssh <name>.sbx` and `git fetch sandbox-<name>`.
- **`sbx ls`** is your dashboard: which sandboxes are running, which are stopped.
- **Never type secrets as arguments**: use `--command`, or `--value-stdin` with `printf` or `read -rs`. This way, they appear neither in the history nor in `ps`.
- **Node.js is not in the Copilot image**: `sbx exec -i <sandbox> sh -s < scripts/install-node.sh` in every sandbox created by hand. The `sbxenv.yaml` environment brings it with the `node` kit.
- **A stopped sandbox restarts on its own** when you run `sbx exec` or `sbx run <name>`.
- **`sbx env plan` before `sbx env create`**: you see what is going to change, without breaking anything.
- **Changing a kit = recreating**: `sbx env rm --force`, then `sbx env create --force`.
- **A kit carries its network policy**: when you add a tool, open only what it needs, in its kit.
- **A dedicated branch** when the agent works alone, and **`--clone`** to isolate it completely: you stay in control of what enters your repository.
- **Copilot stuck?** Switch to OpenCode (`sbx run opencode .`) with the same Copilot license.
- **Windows**: use Git Bash to run `./scripts/check.sh`.
- **Keep screenshots** of the flags as you go: they feed the 3 pm demo.

---

## 10. sbx cheat sheet

```bash
# --- Installation and account
sbx login | sbx diagnose | sbx version

# --- Lifecycle
sbx run --name lab1 copilot .            # run Copilot in a named sandbox
sbx exec -i lab1 sh -s < scripts/install-node.sh   # add Node.js (missing from the image)
sbx run --name lab1o opencode .          # plan B: OpenCode
sbx run --clone --name lab1c copilot .   # isolated work in a Git clone
git fetch sandbox-lab1c                  # (host) get the agent's commits
sbx ls                                   # list
sbx run lab1                             # reattach to an existing sandbox
sbx exec -it lab1 bash                   # enter the sandbox
sbx stop lab1 && sbx rm lab1             # stop, delete

# --- Secrets (never in the VM)
sbx secret set copilot --command 'gh auth token'
sbx secret set github  --command 'gh auth token'
printf '%s' 'value' | sbx secret set-custom --host api.example.com --env MY_KEY --value-stdin
sbx secret ls

# --- Network
sbx policy init balanced                 # or deny-all, allow-all
sbx policy reset                         # start from scratch (asks for the policy to apply)
sbx policy allow network api.example.com
sbx policy deny  network --sandbox lab1 pastebin.com
sbx policy check network --sandbox lab1 pastebin.com:443
sbx policy ls --wide                     # --source kit: the rules brought by kits
sbx policy log lab1

# --- Declarative environment
sbx env plan
sbx env create --force [file1 file2 ...]   # merged in order
sbx env run
sbx env exec -- <command>
sbx env rm --force

# --- Kits
sbx kit validate ./kits/hack-tools
sbx kit inspect ./kits/hack-tools --resolved
sbx kit push ./kits/hack-tools docker.io/<user>/hack-tools:1.0 --sign

# --- MCP and skills
sbx mcp ls | sbx mcp inspect <server>
sbx mcp load <server> --sandbox <s>
sbx skills import --dry-run | sbx skills import | sbx skills ls

# --- SSH
sbx setup ssh
ssh <sandbox>.sbx
code --new-window --remote ssh-remote+<sandbox>.sbx "$PWD"

# --- Local model
sbx run --name lab6 --kit ./kits/node --model qwen3.5:0.8b --deny-network '**.githubcopilot.com' --deny-network api.openai.com --deny-network api.anthropic.com --deny-network openrouter.ai opencode .
sbx run --model <other-model> lab6       # change the model

# --- Agent in the editor (ACP)
sbx exec -i nw-copilot  copilot --acp --stdio
sbx exec -i nw-opencode opencode acp
```

---

## 11. Troubleshooting

| Symptom | Solution |
|---|---|
| `global network policy has not been initialized` | `sbx policy init balanced` |
| Copilot asks for `/login` | `sbx secret ls`: `copilot` and `github` must be listed. Otherwise, level 0, step 4 |
| 401 or 403 error from Copilot | Missing Copilot seat, or org SSO not authorized for `gh` |
| The agent cannot reach a domain | `sbx policy log <sandbox>`, then `sbx policy allow network <domain>` |
| HTTP 403 "Blocked by org policy" | This is the organization's policy: see a facilitator |
| A custom secret does not show up in the VM | Recreate the sandbox (`sbx rm <s>`, then run it again) |
| `ssh <name>.sbx` fails | Level 0, step 3 (settings and daemon restart), then `sbx setup ssh` |
| `sbx env rm` refuses to delete | An SSH or VS Code connection is open: `sbx env rm --force` |
| `node: not found` or `npm: not found` in the sandbox | The Copilot image has no Node.js: `sbx exec -i <sandbox> sh -s < scripts/install-node.sh` (`nodejs.org` must be in the network policy) |
| Context7 tools missing | `sbx mcp inspect context7`: is the key stored? Then `sbx stop <s>` and `sbx run <s>` |
| `--model is experimental and disabled` | Level 0, step 3 |
| The ACP editor does not start the agent | `-i` without `-t`. As a last resort, the absolute path of `sbx` (`which sbx`) |
| `check.sh 6`: `cloud AI calls FORWARDED` | `sbx rm lab6`, then recreate it with the `--deny-network` options of level 6, step 1 (with `'**.githubcopilot.com'`, two stars) |
| Level 7: all tickets fail | The level 1 fix is not committed: commit it, then restart the loop |
| Level 7: "Working tree not clean" | Uncommitted work: `git status`, then commit or `git stash` |
| None of the above | `sbx diagnose`, then raise your hand |

---

## 12. Glossary

| Term | Definition |
|---|---|
| **sandbox** | A microVM where the agent runs, with its own file system, its own network and its own Docker daemon. |
| **host** | Your workstation, outside the sandbox. |
| **sbx proxy** | The mandatory path for the sandbox's network traffic, on the host: it applies the policy and injects the secrets. |
| **decoy** | The fake secret value that the VM sees. The proxy replaces it with the real one, and only towards the expected domains. |
| **workload kit** | The kit that defines the base agent (Copilot, OpenCode, a shell...). |
| **mixin kit** | A kit added on top: a tool, network rules, hooks. |
| **`sbxenv.yaml`** | The declarative file of an sbx environment, the equivalent of a compose file. |
| **MCP** | *Model Context Protocol*: a protocol that gives tools to the agent. |
| **MCP gateway** | The sbx relay, on the host, that calls the MCP servers on behalf of the agent. |
| **skill** | An instruction file (`SKILL.md`) that the agent loads to follow conventions. |
| **ACP** | *Agent Client Protocol*: the protocol that connects an editor to an agent. |
| **llmman** | The local model server shipped with sbx. |
| **`--clone`** | The mode where the agent works on a private Git clone, which you get back with `git fetch sandbox-<name>`. |
