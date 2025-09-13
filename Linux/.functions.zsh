function vcode() {
  local target="${1:-.}"
  local folder_name=$(basename "$target")

  if [ "$folder_name" = "N-D-B" ]; then
    code --profile "N-D-B" "$target"
  elif [ -f "$target/package.json" ]; then
    code --profile "TypeScript" "$target"
  elif [ -f "$target/pom.xml" ]; then
    code --profile "Java" "$target"
  elif [ -f "$target/Cargo.toml" ]; then
    code --profile "Rust" "$target"
  elif [ -n "$(find "$target" -maxdepth 1 -name '*.cpp' -o -name '*.c')" ]; then
    code --profile "C/C++" "$target"
  else
    code --profile "Padrão" "$target"
  fi
}
