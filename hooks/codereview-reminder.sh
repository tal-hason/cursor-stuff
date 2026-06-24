#!/usr/bin/env bash
# ~/.cursor/hooks/codereview-reminder.sh
# stop hook: remind agent to run /codereview if ANY files were modified.
set -euo pipefail

input=$(cat)
modified_files=$(echo "$input" | jq -r '.modified_files // [] | .[]' 2>/dev/null)

if [[ -z "$modified_files" ]]; then
  echo '{}'
  exit 0
fi

file_count=$(echo "$modified_files" | wc -l)

cat << EOF
{
  "followup_message": "You modified ${file_count} file(s) during this session. Before wrapping up, run /codereview to review your changes (attach the plan + diff context package)."
}
EOF
