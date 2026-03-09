#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_SECRETS:-}" == "1" ]]; then
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel)"
cd "$repo_root"

mapfile -d '' staged_files < <(git diff --cached --name-only --diff-filter=ACMRTUXB -z)

if [[ "${#staged_files[@]}" -eq 0 ]]; then
  exit 0
fi

blocked_path_pattern='(^|/)(\.env(\..*)?|config\.env|id_(rsa|ed25519)(\.pub)?|.*\.(pem|key|p12|pfx|crt|cer|secrets))$|(^|/)(data|logs|runtime)(/|$)'
content_pattern='(-----BEGIN [A-Z ]*PRIVATE KEY-----|ssh-ed25519 AAAA|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|[0-9]{8,10}:[A-Za-z0-9_-]{30,})'
safe_placeholder_pattern='(YOUR_|your-|example|sample|placeholder|xxxxx|xxxx|bot1234567890:ABC|test-|fake-|dummy-)'

fail=0

for path in "${staged_files[@]}"; do
  if [[ "$path" =~ $blocked_path_pattern ]]; then
    echo "Blocked sensitive path: $path" >&2
    fail=1
  fi
done

for path in "${staged_files[@]}"; do
  if ! git cat-file -e ":$path" 2>/dev/null; then
    continue
  fi

  matches="$(git show ":$path" | LC_ALL=C grep -nE "$content_pattern" || true)"
  if [[ -z "$matches" ]]; then
    continue
  fi

  filtered="$(printf '%s\n' "$matches" | LC_ALL=C grep -viE "$safe_placeholder_pattern" || true)"
  if [[ -n "$filtered" ]]; then
    echo "Potential secret in staged file: $path" >&2
    printf '%s\n' "$filtered" >&2
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  cat >&2 <<'EOF'
Commit blocked by secret check.
If this is truly intentional, review the diff carefully and re-run with:
  ALLOW_SECRETS=1 git commit ...
EOF
  exit 1
fi

exit 0
