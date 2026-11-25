#!/usr/bin/env bash
# Autonomous agent loop (level 7). Run it INSIDE the "worker" sandbox:
#   sbx exec worker bash scripts/worker-loop.sh
# Direct mode (default): the loop works in YOUR folder, on the worker/backlog branch.
# --clone mode (bonus): it works in a private clone, which you fetch with
# git fetch sandbox-worker.
#
# For each "Status: TODO" ticket in backlog/:
#   1. the agent receives the ticket and implements it;
#   2. the tests run;
#   3. green: the ticket is marked DONE and committed; red: the work is discarded
#      and the loop moves on to the next ticket.
set -u
cd "$(git rev-parse --show-toplevel)"
command -v node >/dev/null 2>&1 || {
  echo "!!! Node.js is missing from the sandbox. From the host: sbx exec -i <sandbox> sh -s < scripts/install-node.sh" >&2
  exit 1
}

MAX_TICKETS="${MAX_TICKETS:-6}"
BRANCH="${BRANCH:-worker/backlog}"
# Non-interactive agent command. The prompt is passed as the last argument.
#   Copilot  : copilot -p <prompt> --yolo     (default)
#   OpenCode : AGENT=opencode -> opencode run <prompt>
AGENT="${AGENT:-copilot}"

agent_do() {
  case "$AGENT" in
    copilot)  copilot -p "$1" --yolo ;;
    opencode) opencode run "$1" ;;
    *) echo "Unknown AGENT: $AGENT" >&2; return 2 ;;
  esac
}

# Commit identity of the agent, set through environment variables: in direct mode,
# a "git config" would write into the .git/config of your workstation.
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-sbx worker}" GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-worker@sandbox.invalid}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
# In direct mode, git reset --hard and git clean would touch your files: refuse to
# start if the folder contains uncommitted work.
if [ -n "$(git status --porcelain)" ]; then
  echo "!!! Working tree not clean: commit (or stash) your work before starting the loop." >&2
  git status --short >&2
  exit 1
fi
START_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git checkout -B "$BRANCH" >/dev/null 2>&1

done_count=0
for ticket in backlog/LD-*.md; do
  [ "$done_count" -ge "$MAX_TICKETS" ] && break
  grep -q '^Status: TODO' "$ticket" || continue
  id="$(basename "$ticket" .md)"
  title="$(head -1 "$ticket" | sed 's/^# *//')"
  echo "=== $(date +%H:%M:%S) $id: $title"

  prompt="You are working on the Loan Desk repository (app/ folder, Node.js with no dependencies).
Implement the following ticket. Meet the acceptance criteria, add tests,
then check with: cd app && node --test test/*.test.js
Do not modify any file in backlog/. Do not commit: the loop takes care of it.

$(cat "$ticket")"

  agent_do "$prompt" || echo "!!! the agent returned an error on $id"

  if (cd app && node --test test/*.test.js) >"/tmp/$id-tests.log" 2>&1; then
    sed -i 's/^Status: TODO/Status: DONE/' "$ticket"
    git add -A
    git commit -q -m "$title" && echo "+++ $id committed"
    done_count=$((done_count + 1))
  else
    echo "--- $id: tests red, work discarded (see /tmp/$id-tests.log)"
    git reset -q --hard
    git clean -q -fd
  fi
done
echo "=== Done: $done_count ticket(s) processed on branch $BRANCH"
git checkout -q "$START_BRANCH" && echo "=== Back on branch $START_BRANCH (review $BRANCH before merging)"
