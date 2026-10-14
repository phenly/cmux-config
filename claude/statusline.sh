#!/usr/bin/env bash
# Claude Code status line (up to three lines)
# Reads session JSON on stdin, prints a colored status.
# Line 3 (session name + id) uses .session_name / .session_id (verified 2026-10-14);
# session_name is absent for unnamed sessions with no AI title, so it is omitted then.

input=$(cat)

# --- Colors (truecolor ANSI) ---
CORAL=$'\033[38;2;159;92;70m'     # deep coral-brown — icons
LAV=$'\033[38;2;183;160;255m'     # lavender — top-line values
GRAY=$'\033[38;2;128;128;128m'    # gray — directory & repo text
GREEN=$'\033[38;2;68;180;95m'
YELLOW=$'\033[38;2;254;185;38m'
RED=$'\033[38;2;125;3;3m'
RESET=$'\033[0m'

# --- ASCII icons (single-quoted so $ etc. stay literal) ---
I_MODEL='{*_*}'
I_EFFORT='<~|~>'
I_CTX='/#/'
I_DAY='/5h/'
I_WEEK='/7d/'
I_COST='/$/'
I_DIR='/.../'
I_REPO='</>'
I_NAME='[nm]'
I_SID='[id]'

# --- Color helpers (arg: integer percent) ---
ctx_color()  { local p=$1; if   ((p<25)); then printf '%s' "$GREEN"; elif ((p<50)); then printf '%s' "$YELLOW"; else printf '%s' "$RED"; fi; }
sess_color() { local p=$1; if   ((p<50)); then printf '%s' "$GREEN"; elif ((p<85)); then printf '%s' "$YELLOW"; else printf '%s' "$RED"; fi; }

# --- Extract fields ---
model=$(jq -r '.model.display_name // "?"'          <<< "$input")
effort=$(jq -r '.effort.level // "n/a"'             <<< "$input")
used=$(jq -r '.context_window.used_percentage // 0' <<< "$input")
cost=$(jq -r '.cost.total_cost_usd // 0'            <<< "$input")
dir=$(jq -r '.workspace.current_dir // .cwd // ""'  <<< "$input")
r5=$(jq -r '.rate_limits.five_hour.used_percentage // empty'  <<< "$input")
r7=$(jq -r '.rate_limits.seven_day.used_percentage // empty'  <<< "$input")
rhost=$(jq -r '.workspace.repo.host  // empty'      <<< "$input")
rowner=$(jq -r '.workspace.repo.owner // empty'     <<< "$input")
sname=$(jq -r '.session_name // empty'  <<< "$input")
sid=$(jq -r '.session_id // empty'      <<< "$input")
rname=$(jq -r '.workspace.repo.name  // empty'      <<< "$input")

# --- Formatting ---
effort=$(printf '%s' "$effort" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')  # high -> High
printf -v pct "%.0f" "$used"
printf -v costfmt "%.2f" "$cost"
cc=$(ctx_color "$pct")

# home-relative dir + git branch/dirty marker
disp="${dir/#$HOME/~}"
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && branch="${branch}*"
  [ -n "$branch" ] && disp="$disp ($branch)"
fi

# ===== Line 1: model · thinking · context · day · week =====
l1="${CORAL}${I_MODEL} ${LAV}${model}${RESET}"
l1="$l1  ${CORAL}${I_EFFORT} ${LAV}${effort}${RESET}"
l1="$l1  ${CORAL}${I_CTX} ${cc}${pct}%${RESET}"
if [ -n "$r5" ]; then
  printf -v d5 "%.0f" "$r5"; dc=$(sess_color "$d5")
  l1="$l1  ${CORAL}${I_DAY} ${dc}${d5}%${RESET}"
fi
if [ -n "$r7" ]; then
  printf -v d7 "%.0f" "$r7"; wc=$(sess_color "$d7")
  l1="$l1  ${CORAL}${I_WEEK} ${wc}${d7}%${RESET}"
fi
l1="$l1  ${CORAL}${I_COST} ${GRAY}\$${costfmt}${RESET}"

# ===== Line 2: directory + repo host/owner/name =====
l2="${CORAL}${I_DIR} ${GRAY}${disp}${RESET}"
if [ -n "$rhost$rowner$rname" ]; then
  repo=$(printf '%s/%s/%s' "$rhost" "$rowner" "$rname" | sed 's://*:/:g; s:^/::; s:/$::')
  l2="$l2  ${CORAL}${I_REPO} ${GRAY}${repo}${RESET}"
fi

# ===== Line 3: session name + id (each omitted when absent) =====
l3=""
[ -n "$sname" ] && l3="${CORAL}${I_NAME} ${LAV}${sname}${RESET}"
[ -n "$sid" ] && l3="${l3:+$l3  }${CORAL}${I_SID} ${GRAY}${sid}${RESET}"

printf '%s\n%s' "$l1" "$l2"
[ -n "$l3" ] && printf '\n%s' "$l3"
exit 0
