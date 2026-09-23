manifest=$(find . -name Cargo.toml -not -path '*/target/*' -printf '%d %p\n' | sort -n | head -n 1 | cut -d ' ' -f 2-)
cd "$(dirname "${manifest:-.}")" || exit
exec cargo "$@"
