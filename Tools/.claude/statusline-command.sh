#!/usr/bin/env bash

input=$(cat)

CYAN='\033[36m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

ICON_FOLDER=$'\xef\x81\xbb'
ICON_GITHUB=$'\xee\x9c\x89'
ICON_GITLAB=$'\xef\x8a\x96'
ICON_BITBUCKET=$'\xef\x85\xb1'
ICON_NODE=$'\xee\x9c\x98'
ICON_BUN=$'\xee\x9d\xaf'
ICON_PNPM=$'\xee\xa1\xa5'
ICON_YARN=$'\xee\x9a\xa7'
ICON_NPM=$'\xee\x9c\x9e'
ICON_PYTHON=$'\xee\x9c\xbc'
ICON_GO=$'\xee\x9c\xa4'
ICON_RUST=$'\xee\x9e\xa8'
ICON_JAVA=$'\xee\x9c\xb8'
ICON_DOCKER=$'\xee\x99\x90'
ICON_PHP=$'\xee\x9c\xbd'

BAR_WIDTH=20

eval "$(echo "$input" | jq -r '
  "model=" + (.model.display_name // "Unknown" | @sh),
  "used_context=" + ((.context_window.used_percentage // "") | tostring),
  "cost=" + ((.cost.total_cost_usd // 0) | tostring),
  "duration_ms=" + ((.cost.total_duration_ms // 0) | tostring),
  "lines_add=" + ((.cost.total_lines_added // 0) | tostring),
  "lines_del=" + ((.cost.total_lines_removed // 0) | tostring),
  "cwd=" + ((.workspace.current_dir // .cwd // "") | @sh),
  "effort=" + ((.effort.level // "unknown") | @sh),
  "thinking_enabled=" + ((.thinking.enabled // false) | tostring),
  "rate_5h=" + ((.rate_limits.five_hour.used_percentage // "") | tostring),
  "rate_5h_reset=" + ((.rate_limits.five_hour.resets_at // "") | tostring | @sh),
  "rate_7d=" + ((.rate_limits.seven_day.used_percentage // "") | tostring),
  "rate_7d_reset=" + ((.rate_limits.seven_day.resets_at // "") | tostring | @sh)
')"

[[ "$thinking_enabled" == "true" ]] && think="\xf0\x9f\x92\xad" || think="\xf0\x9f\xa7\xa0"

remote_icon="" branch="" repo="" staged=0 modified=0 stash=0 pull=0 push=0
env_parts=()

if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
  staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  stash=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')
  read -r pull push < <(git -C "$cwd" --no-optional-locks rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
  pull=${pull:-0}; push=${push:-0}
  git_tag=$(git -C "$cwd" --no-optional-locks describe --tags --abbrev=0 2>/dev/null)

  remote_url=$(git -C "$cwd" --no-optional-locks remote get-url origin 2>/dev/null)
  if   [[ "$remote_url" == *github* ]];    then remote_icon="${ICON_GITHUB}"
  elif [[ "$remote_url" == *gitlab* ]];    then remote_icon="${ICON_GITLAB}"
  elif [[ "$remote_url" == *bitbucket* ]]; then remote_icon="${ICON_BITBUCKET}"
  fi

  if [ -f "$cwd/package.json" ]; then
    node_ver=""
    if   [ -f "$cwd/.nvmrc" ];        then node_ver=$(<"$cwd/.nvmrc")
    elif [ -f "$cwd/.node-version" ];  then node_ver=$(<"$cwd/.node-version")
    fi
    node_ver="${node_ver//[$'\n\r\t ']}"

    if   [ -f "$cwd/bun.lockb" ] || [ -f "$cwd/bun.lock" ]; then pm_part="$(rgb 251 191 36)${ICON_BUN}${RESET}"
    elif [ -f "$cwd/pnpm-lock.yaml" ];   then pm_part="${YELLOW}${ICON_PNPM}${RESET}"
    elif [ -f "$cwd/yarn.lock" ];         then pm_part="${BLUE}${ICON_YARN}${RESET}"
    elif [ -f "$cwd/package-lock.json" ]; then pm_part="${RED}${ICON_NPM}${RESET}"
    else pm_part=""
    fi
    env_parts+=("${GREEN}${ICON_NODE}${node_ver:+ $node_ver}${RESET}${pm_part:+ $pm_part}")
  fi

  if [ -f "$cwd/requirements.txt" ] || [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/setup.py" ] || [ -f "$cwd/Pipfile" ]; then
    py_ver=""
    [ -f "$cwd/.python-version" ] && py_ver=$(<"$cwd/.python-version") && py_ver="${py_ver//[$'\n\r\t ']}"
    venv=""
    [ -d "$cwd/.venv" ] && venv=".venv"
    [ -z "$venv" ] && [ -d "$cwd/venv" ] && venv="venv"
    env_parts+=("${YELLOW}${ICON_PYTHON}${py_ver:+ $py_ver}${venv:+ ($venv)}${RESET}")
  fi

  if [ -f "$cwd/go.mod" ]; then
    go_ver=$(grep -m1 '^go ' "$cwd/go.mod" 2>/dev/null)
    go_ver="${go_ver#go }"
    env_parts+=("${CYAN}${ICON_GO}${go_ver:+ $go_ver}${RESET}")
  fi

  if [ -f "$cwd/Cargo.toml" ]; then
    rust_edition=$(grep -m1 '^edition' "$cwd/Cargo.toml" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
    env_parts+=("$(rgb 222 165 90)${ICON_RUST}${rust_edition:+ ($rust_edition)}${RESET}")
  fi

  if [ -f "$cwd/pom.xml" ] || [ -f "$cwd/build.gradle" ] || [ -f "$cwd/build.gradle.kts" ]; then
    env_parts+=("${RED}${ICON_JAVA}${RESET}")
  fi

  if [ -f "$cwd/composer.json" ]; then
    env_parts+=("${MAGENTA}${ICON_PHP}${RESET}")
  fi

  if [ -f "$cwd/Dockerfile" ] || [ -f "$cwd/docker-compose.yml" ] || [ -f "$cwd/docker-compose.yaml" ] || [ -d "$cwd/.docker" ]; then
    env_parts+=("${BLUE}${ICON_DOCKER}${RESET}")
  fi

  if command -v ss &>/dev/null; then
    listening=$(ss -tln 2>/dev/null)
    dev_ports=()
    for port in 3000 3001 4000 4200 4321 5173 8000 8080 8888; do
      [[ "$listening" == *":${port} "* ]] && dev_ports+=("$port")
    done
    if (( ${#dev_ports[@]} > 0 )); then
      port_str=$(printf ':%s ' "${dev_ports[@]}")
      env_parts+=("${GREEN}\xf0\x9f\x94\x8c ${port_str% }${RESET}")
    fi
  fi
fi

parse_epoch() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "$1"
  else
    date -d "$1" +%s 2>/dev/null || return 1
  fi
}

time_until() {
  local epoch diff d h m
  epoch=$(parse_epoch "$1") || return
  diff=$(( epoch - $(date +%s) ))
  (( diff < 0 )) && diff=0
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if (( d > 0 )); then
    printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

reset_clock() {
  local epoch fmt='%H:%M'
  epoch=$(parse_epoch "$1") || return
  [[ "$(date +%Y%m%d)" != "$(date -d "@$epoch" +%Y%m%d 2>/dev/null)" ]] && fmt='%d/%m %H:%M'
  date -d "@$epoch" "+$fmt" 2>/dev/null
}

create_usage_bar() {
  local percentage=$1 resets_at=$2

  if [ -z "$percentage" ]; then
    printf %b "\xf0\x9f\x9f\xa2 \033[38;2;60;60;60m\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91\xe2\x96\x91${RESET} --%"
    return
  fi

  local used_int bar="" i pos r g b adj filled
  used_int=$(printf '%.0f' "$percentage")
  filled=$(( (used_int * BAR_WIDTH + 50) / 100 ))

  for (( i=0; i<BAR_WIDTH; i++ )); do
    pos=$(( i * 100 / (BAR_WIDTH - 1) ))
    if (( pos <= 50 )); then
      r=$(( 220 * pos / 50 )) g=200 b=$(( 80 - 80 * pos / 50 ))
    else
      adj=$(( pos - 50 ))
      r=220 g=$(( 200 - 160 * adj / 50 )) b=$(( 20 * adj / 50 ))
    fi
    (( i < filled )) && bar+="$(rgb $r $g $b)\xe2\x96\x88" || bar+="\033[38;2;60;60;60m\xe2\x96\x91"
  done

  local emoji color
  if (( used_int >= 90 )); then   emoji="\xf0\x9f\x9a\xa8" color="$RED"
  elif (( used_int >= 70 )); then emoji="\xf0\x9f\x94\xa5" color="$YELLOW"
  elif (( used_int >= 20 )); then emoji="\xe2\x9a\xa1"     color="$GREEN"
  else                            emoji="\xf0\x9f\x9f\xa2" color="$GREEN"
  fi

  local reset_str=""
  if [ -n "$resets_at" ]; then
    local t clock
    t=$(time_until "$resets_at")
    clock=$(reset_clock "$resets_at")
    [ -n "$t" ] && reset_str=" ${DIM}\xe2\x8f\xb3${t}${clock:+ ($clock)}${RESET}"
  fi

  printf %b "${emoji} ${bar}${RESET} ${color}${used_int}%${RESET}${reset_str}"
}

duration_sec=$(( duration_ms / 1000 ))
elapsed=""
(( duration_sec >= 86400 )) && elapsed+="$(( duration_sec / 86400 ))d"
(( (duration_sec % 86400) >= 3600 )) && elapsed+="$(( (duration_sec % 86400) / 3600 ))h"
(( (duration_sec % 3600) >= 60 )) && elapsed+="$(( (duration_sec % 3600) / 60 ))m"
elapsed+="$(( duration_sec % 60 ))s"

git_parts=()
(( staged   > 0 )) && git_parts+=("${GREEN}+${staged}${RESET}")
(( modified > 0 )) && git_parts+=("${YELLOW}~${modified}${RESET}")
(( stash    > 0 )) && git_parts+=("${BLUE}*${stash}${RESET}")
(( push     > 0 )) && git_parts+=("${GREEN}\xe2\xac\x86${push}${RESET}")
(( pull     > 0 )) && git_parts+=("${CYAN}\xe2\xac\x87${pull}${RESET}")

line1=""
[ -n "$repo" ]    && line1="${BOLD}${YELLOW}${ICON_FOLDER} ${repo}${remote_icon:+ $remote_icon}${RESET}"
[ -n "$git_tag" ] && line1+=" ${DIM}${git_tag}${RESET}"
[ -n "$branch" ]  && line1+="${line1:+ }${BOLD}${CYAN}\xf0\x9f\x8c\xbf (${branch})${RESET}"
(( ${#git_parts[@]} > 0 )) && line1+=" ${BOLD}[ ${git_parts[*]} ${BOLD}]"
line1+=" ${DIM}|${RESET} ${GREEN}+${lines_add}${RESET} ${RED}-${lines_del}${RESET}"

line2=" ${MAGENTA}\xf0\x9f\xa4\x96 ${model}${RESET} ${BOLD}[\xf0\x9f\x92\xaa ${effort} ${think}${BOLD}]"
line2+=" ${DIM}|${RESET} Ctx: $(create_usage_bar "$used_context")"
line2+=" ${DIM}|${RESET} ${YELLOW}\xf0\x9f\x92\xb0 $(printf '$%.2f' "$cost")${RESET} (\xe2\x8f\xb1\xef\xb8\x8f ${elapsed})"

line3="5h: $(create_usage_bar "$rate_5h" "$rate_5h_reset") ${DIM}|${RESET} 7d: $(create_usage_bar "$rate_7d" "$rate_7d_reset")"

printf '%b\n%b\n%b' "$line1" "$line2" "$line3"

if (( ${#env_parts[@]} > 0 )); then
  line4=""
  for part in "${env_parts[@]}"; do
    line4+="${line4:+ ${DIM}|${RESET} }${part}"
  done
  printf '\n%b' "$line4"
fi
