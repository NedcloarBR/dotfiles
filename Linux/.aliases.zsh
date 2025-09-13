if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --group-directories-first --icon always'
  alias ll='lsd -la --group-directories-first --icon always'
  alias tree='lsd --tree --icon always'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa -la --group-directories-first --icons'
  alias ll='exa -la --group-directories-first --icons'
  alias tree='exa -la --tree --icons'
fi
