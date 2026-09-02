#!/bin/bash
export LC_ALL=C

error() {
    echo "Error: $1" >&2
    exit 1
}

command=$1
case "$command" in
    --help)
        if [ "$#" -ne 1 ]; then
            error "Use: $0 --help"
        fi
        cat <<'HELP'
Commands:
  --help                      Show this help message
  summary <log_dir>            Print summary counts
HELP
        exit 0
        ;;
    summary)
        if [ "$#" -ne 2 ]; then
            error "Use: $0 $command <log_dir>"
        fi
        ;;
    *) error "Missing or unknown command. Use --help." ;;
esac

if [ ! -d "$2" ]; then
    error "Directory does not exist: $2"
fi
log_dir=$(cd -- "$2" && pwd) || error "Cannot access directory"

temp_dir=$(mktemp -d) || error "Cannot create temporary directory"
trap 'rm -r "$temp_dir"' EXIT
find "$log_dir/." -type f -name '*.log' > "$temp_dir/files" || error "Cannot search directory"

while IFS= read -r file; do
    if [ ! -r "$file" ]; then
        error "Cannot read: $file"
    fi
    # msg can have usernames in it too
    sed 's/[[:space:]]msg=.*//' "$file" || error "Cannot read: $file"
    echo
done < "$temp_dir/files" > "$temp_dir/raw"

data="$temp_dir/data"
grep -v '^[[:space:]]*#' "$temp_dir/raw" |
grep -v '^[[:space:]]*$' |
grep -E 'service=[^[:space:]]+' |
grep -E 'event=[^[:space:]]+' |
grep -E 'level=(ERROR|WARN|INFO)([[:space:]]|$)' > "$data"

files=$(wc -l < "$temp_dir/files")
lines=$(wc -l < "$data")
errors=$(grep -cw 'level=ERROR' "$data")
warnings=$(grep -cw 'level=WARN' "$data")
infos=$(grep -cw 'level=INFO' "$data")

summary() {
    printf 'FILES_SCANNED=%d\nLINES_PROCESSED=%d\n' "$files" "$lines"
    printf 'ERROR=%d\nWARN=%d\nINFO=%d\n' "$errors" "$warnings" "$infos"
}

case "$command" in
    summary) summary ;;
esac
