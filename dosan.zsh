# Dosan plugin and alias loader.
# Source this file from ~/.zshrc; work is deferred until the first prompt so
# startup stays light. Files are sourced in the interactive shell because a
# background shell cannot export aliases, functions, or options back to zsh.

: ${DOSAN_HOME:=${${(%):-%N}:A:h}}
: ${DOSAN_PLUGIN_DIR:="$DOSAN_HOME/src/plugins"}
: ${DOSAN_ALIAS_DIR:="$DOSAN_HOME/src/aliases"}

autoload -Uz add-zsh-hook

typeset -ga DOSAN_PLUGINS=()
typeset -ga DOSAN_ALIASES=()
typeset -gi _DOSAN_LOAD_INDEX=1

# Print installed plugin directory names, one per line.
dosan_plugins() {
  local dir
  for dir in "$DOSAN_PLUGIN_DIR"/*(N/); do
    print -r -- "${dir:t}"
  done
}

# Print available alias files, one per line.
dosan_aliases() {
  local file
  for file in "$DOSAN_ALIAS_DIR"/*.zsh(N); do
    print -r -- "${file:t:r}"
  done
}

# Source a named plugin by its standard plugin entrypoint filename.
dosan_load_plugin() {
  emulate -L zsh
  local name="$1" file
  [[ -n "$name" ]] || { print -u2 'usage: dosan_load_plugin <name>'; return 2; }
  [[ -d "$DOSAN_PLUGIN_DIR/$name" ]] || { print -u2 "dosan: plugin not found: $name"; return 1; }
  for file in "$DOSAN_PLUGIN_DIR/$name/$name.plugin.zsh" \
              "$DOSAN_PLUGIN_DIR/$name/$name.zsh" \
              "$DOSAN_PLUGIN_DIR/$name/plugin.zsh"; do
    if [[ -f "$file" ]]; then
      source "$file"
      return $?
    fi
  done
  print -u2 "dosan: no plugin entrypoint found for $name"
  return 1
}

# Source a named alias file from src/aliases (name may omit .zsh).
dosan_load_alias() {
  emulate -L zsh
  local name="$1"
  [[ -n "$name" ]] || { print -u2 'usage: dosan_load_alias <name>'; return 2; }
  name=${name%.zsh}
  [[ -f "$DOSAN_ALIAS_DIR/$name.zsh" ]] || { print -u2 "dosan: alias file not found: $name"; return 1; }
  source "$DOSAN_ALIAS_DIR/$name.zsh"
}

_dosan_load_next() {
  local item
  if (( _DOSAN_LOAD_INDEX <= ${#DOSAN_PLUGINS} )); then
    item=${DOSAN_PLUGINS[_DOSAN_LOAD_INDEX++]}
    dosan_load_plugin "$item" || true
  elif (( _DOSAN_LOAD_INDEX <= ${#DOSAN_PLUGINS} + ${#DOSAN_ALIASES} )); then
    item=${DOSAN_ALIASES[$((_DOSAN_LOAD_INDEX - ${#DOSAN_PLUGINS}))]}
    ((_DOSAN_LOAD_INDEX++))
    dosan_load_alias "$item" || true
  else
    add-zsh-hook -d precmd _dosan_load_next
  fi
}

# Capture installed files now and source one per prompt in the current shell.
dosan_init() {
  local item
  DOSAN_PLUGINS=(${(f)"$(dosan_plugins)"})
  DOSAN_ALIASES=(${(f)"$(dosan_aliases)"})
  _DOSAN_LOAD_INDEX=1
  (( ${#DOSAN_PLUGINS} + ${#DOSAN_ALIASES} )) && add-zsh-hook precmd _dosan_load_next
}

dosan_init
