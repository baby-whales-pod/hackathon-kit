#!/usr/bin/env bash
# Checks the "flag" of a level. Run it ON THE HOST, from the repository root.
#   ./scripts/check.sh <level> [sandbox]
#   ./scripts/check.sh 4bis [copilot-sandbox] [opencode-sandbox]
# Compatible with bash 3.2 (macOS) and Git Bash (Windows).
set -u

LEVEL="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANARY_REAL_VALUE="${CANARY_REAL_VALUE:-nw-canary-0000-real}"
# Cloud AI APIs that must never be reached at level 6 (local model).
CLOUD_AI='githubcopilot\.com|api\.openai\.com|api\.anthropic\.com|openrouter\.ai|generativelanguage\.googleapis\.com|api\.mistral\.ai|api\.groq\.com|api\.x\.ai'

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
ko()   { printf '  \033[31m✘\033[0m %s\n' "$1"; FAILED=1; }
info() { printf '  · %s\n' "$1"; }
FAILED=0

run_tests_in() { # $1 = sandbox
  sbx exec "$1" sh -c "cd '$ROOT/app' && node --test test/*.test.js" >/tmp/sbx-check-tests.log 2>&1
}

# Sends an ACP "initialize" request through `sbx exec -i`, exactly like the
# editor does, and waits for the agent's answer (no `timeout` on macOS).
acp_handshake() { # $1 = sandbox, then the agent command
  sb="$1"; shift
  log="/tmp/sbx-check-acp-$sb.log"
  req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}'
  { printf '%s\n' "$req"; sleep 60; } | sbx exec -i "$sb" "$@" >"$log" 2>&1 &
  pid=$!
  i=0
  while [ $i -lt 60 ]; do
    grep -q '"protocolVersion"' "$log" 2>/dev/null && break
    kill -0 "$pid" 2>/dev/null || break
    sleep 1; i=$((i + 1))
  done
  kill "$pid" 2>/dev/null
  if grep -q '"protocolVersion"' "$log" 2>/dev/null; then ok "$1 answers over ACP in $sb"
  else ko "$1 does not answer over ACP in $sb (see $log; use -i, never -t)"; fi
}

case "$LEVEL" in
  0)
    echo "Level 0: workstation ready"
    sbx version >/dev/null 2>&1 && ok "sbx is installed ($(sbx version 2>/dev/null | head -1))" || ko "sbx not found"
    sbx diagnose >/tmp/sbx-check-diag.log 2>&1 && ok "sbx diagnose reports no error" || ko "sbx diagnose reports a problem (see /tmp/sbx-check-diag.log)"
    sbx secret ls 2>/dev/null | grep -q -E '(^|[[:space:]])(copilot|github)([[:space:]]|$)' && ok "copilot or github secret registered" || ko "no copilot/github secret (see the secrets appendix)"
    ;;
  1)
    SB="${2:-lab1}"
    echo "Level 1: the Loan Desk tests pass in sandbox $SB"
    if nv=$(sbx exec "$SB" node --version 2>/dev/null); then ok "Node.js found in $SB: $nv"
    else ko "Node.js missing from $SB: sbx exec -i $SB sh -s < scripts/install-node.sh"; fi
    if run_tests_in "$SB"; then ok "tests green"; else ko "tests red (see /tmp/sbx-check-tests.log)"; fi
    ;;
  2)
    SB="${2:-lab1}"
    echo "Level 2: closed network and canary secret (sandbox $SB)"
    # Effective view for this sandbox: "allow N hosts from <policies>" (global + kit rules).
    n=$(sbx policy ls "$SB" 2>/dev/null | grep -o 'allow [0-9]* hosts' | awk '{s+=$2} END {print s+0}')
    info "hosts allowed for $SB (sbx policy ls $SB): $n (the shorter, the better)"
    v=$(sbx exec "$SB" printenv LOANDESK_API_KEY 2>/dev/null | tr -d '\r')
    if [ -z "$v" ]; then ko "LOANDESK_API_KEY missing from the sandbox (sbx secret set-custom ...)"
    elif [ "$v" = "$CANARY_REAL_VALUE" ]; then ko "the REAL canary value is visible in the VM!"
    else ok "the VM only sees a placeholder: $v"; fi
    out=$(sbx policy check network --sandbox "$SB" pastebin.com:443 2>&1 || true)
    echo "$out" | grep -q -i -E 'deny|denied|block' && ok "pastebin.com is denied" || ko "pastebin.com is not denied: $out"
    sbx policy log "$SB" 2>/dev/null | grep -q -i pastebin && ok "the attempt to reach pastebin.com is logged" || info "no trace of pastebin.com in sbx policy log (do the red team exercise)"
    ;;
  3)
    echo "Level 3: declarative environment (sbx env, from $ROOT)"
    (cd "$ROOT" && sbx env exec -- yq --version) >/tmp/sbx-check-yq.log 2>&1 && ok "yq answers: $(tr -d '\r' </tmp/sbx-check-yq.log | tail -1)" || ko "yq not found in the environment's sandbox"
    (cd "$ROOT" && sbx env exec -- node --version) >/tmp/sbx-check-node.log 2>&1 && ok "Node.js answers: $(tr -d '\r' </tmp/sbx-check-node.log | tail -1)" || ko "Node.js not found in the environment's sandbox (kit ./kits/node)"
    ;;
  4)
    SB="${2:-loandesk}"
    echo "Level 4: SSH access to $SB.sbx"
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 "$SB.sbx" true 2>/tmp/sbx-check-ssh.log && ok "ssh $SB.sbx works" || ko "ssh $SB.sbx fails (see /tmp/sbx-check-ssh.log)"
    ;;
  4bis)
    SB_COPILOT="${2:-nw-copilot}"
    SB_OPENCODE="${3:-nw-opencode}"
    echo "Level 4 bis: sandboxed agents over ACP ($SB_COPILOT, $SB_OPENCODE)"
    for sb in "$SB_COPILOT" "$SB_OPENCODE"; do
      sbx ls 2>/dev/null | grep -q -E "(^|[[:space:]])$sb([[:space:]]|$)" && ok "sandbox $sb exists" || ko "sandbox $sb not found (sbx create ... --name $sb .)"
    done
    acp_handshake "$SB_COPILOT"  copilot --acp --stdio
    acp_handshake "$SB_OPENCODE" opencode acp
    info "Also show an editor screenshot: an answer from each agent and the permission request"
    ;;
  5)
    SB="${2:-loandesk}"
    echo "Level 5: controlled MCP servers (sandbox $SB)"
    l=$(sbx mcp ls 2>/dev/null)
    echo "$l" | grep -q -i wikipedia && ok "wikipedia registered" || ko "wikipedia missing from sbx mcp ls"
    echo "$l" | grep -q -i context7  && ok "context7 registered"  || ko "context7 missing from sbx mcp ls"
    leak=$(sbx exec "$SB" sh -c 'env | grep -i context7' 2>/dev/null || true)
    [ -z "$leak" ] && ok "no trace of the Context7 key in the VM" || ko "leak in the VM: $leak"
    ;;
  6)
    SB="${2:-lab6}"
    echo "Level 6: local model (sandbox $SB)"
    sbx ls 2>/dev/null | grep -q -E "(^|[[:space:]])$SB([[:space:]]|$)" && ok "sandbox $SB exists" || ko "sandbox $SB not found"
    # The JSON log separates what the proxy forwarded ("allowed") from what it
    # stopped ("blocked"). Flatten it so this works for pretty or compact JSON.
    log=$(sbx policy log "$SB" --json 2>/dev/null | tr -d '\n\r\t ')
    if [ -z "$log" ]; then
      ko "cannot read sbx policy log $SB --json"
    else
      allowed=${log#*\"allowed\":}; allowed=${allowed%%\"blocked\":*}
      blocked=${log#*\"blocked\":}
      # The log is keyed by sandbox NAME and survives "sbx rm": a recreated lab6
      # inherits the entries of the previous lab6. Ignore entries whose last_seen
      # is older than the current container (seconds precision, same local
      # timezone for both timestamps). Note: "sbx run --model" recreates the
      # container and resets created_at, hence the policy check below.
      created=$(sbx inspect "$SB" --json 2>/dev/null | tr -d '\n\r\t ' | grep -o '"created_at":"[^"]*"' | cut -d'"' -f4)
      created=${created:0:19}
      recent() {
        printf '%s' "$1" | grep -o '{[^}]*}' | while IFS= read -r e; do
          seen=$(printf '%s' "$e" | grep -o '"last_seen":"[^"]*"' | cut -d'"' -f4)
          if [ -n "$created" ] && [ -n "$seen" ] && [[ "${seen:0:19}" < "$created" ]]; then continue; fi
          printf '%s\n' "$e"
        done
      }
      hosts() { recent "$1" | grep -o '"host":"[^"]*"' | cut -d'"' -f4 | grep -i -E "$CLOUD_AI" | sort -u | tr '\n' ' '; }
      a=$(hosts "$allowed"); b=$(hosts "$blocked")
      old=$(printf '%s' "$allowed" | grep -o '"host":"[^"]*"' | cut -d'"' -f4 | grep -i -E "$CLOUD_AI" | sort -u | tr '\n' ' ')
      [ -n "$old" ] && [ -z "$a" ] && info "ignored log entries older than the current $SB container (created or recreated by --model at $created): $old"
      [ -n "$b" ] && info "cloud AI calls attempted but BLOCKED by the proxy: $b"
      [ -z "$a" ] && ok "no cloud AI call went out (nothing forwarded to a cloud AI API)" || ko "cloud AI calls FORWARDED by the proxy: $a(recreate $SB with --deny-network, see the level 6 instructions)"
    fi
    # The proof must hold for the future too: the cloud AI APIs must be denied now.
    open_hosts=""
    for h in api.business.githubcopilot.com api.openai.com api.anthropic.com openrouter.ai; do
      sbx policy check network --sandbox "$SB" "$h:443" 2>&1 | grep -q 'Denied:' || open_hosts="$open_hosts$h "
    done
    [ -z "$open_hosts" ] && ok "cloud AI APIs denied for $SB (sbx policy check)" || ko "not denied for $SB: $open_hosts(recreate $SB with the level 6 --deny-network rules)"
    ;;
  7)
    SB="${2:-worker}"
    echo "Level 7: the autonomous agent processed tickets"
    if git -C "$ROOT" rev-parse -q --verify refs/heads/worker/backlog >/dev/null; then
      REF="worker/backlog"                                   # direct mode
    elif git -C "$ROOT" fetch "sandbox-$SB" >/dev/null 2>&1; then
      REF="remotes/sandbox-$SB/worker/backlog"               # --clone bonus
    else
      REF=""
      ko "branch worker/backlog not found (neither locally nor on the sandbox-$SB remote)"
    fi
    if [ -n "$REF" ]; then
      n=$(git -C "$ROOT" log --oneline "$REF" 2>/dev/null | grep -c -E 'LD-[0-9]+' || true)
      [ "${n:-0}" -ge 3 ] && ok "$n ticket commits on $REF" || ko "only ${n:-0} ticket commit(s) on $REF (3 needed)"
    fi
    ;;
  *)
    echo "usage: $0 <0-7|4bis> [sandbox] (4bis: [copilot-sandbox] [opencode-sandbox])"; exit 2 ;;
esac

[ "$FAILED" = 0 ] && printf '\n\033[32mFLAG OK\033[0m\n' || { printf '\n\033[31mNot yet...\033[0m\n'; exit 1; }
