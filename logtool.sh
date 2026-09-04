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
  services <log_dir>           Print counts by service
  failed-logins <log_dir>      Print failed login counts by user
  report <log_dir> <file>      Generate a plain-text report
  top-users <log_dir> [N]      Print the top N users (default: 3)
HELP
        exit 0
        ;;
    summary|services|failed-logins)
        if [ "$#" -ne 2 ]; then
            error "Use: $0 $command <log_dir>"
        fi
        ;;
    report)
        if [ "$#" -ne 3 ]; then
            error "Use: $0 report <log_dir> <output_file>"
        fi
        output_file=$3
        if [ -z "$output_file" ] || [ -L "$output_file" ]; then
            error "Output must be a regular file"
        fi
        if [ -e "$output_file" ] && [ ! -f "$output_file" ]; then
            error "Output must be a regular file"
        fi
        ;;
    top-users)
        if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
            error "Use: $0 top-users <log_dir> [N]"
        fi
        limit=3
        if [ "$#" -eq 3 ]; then
            limit=$3
        fi
        if [[ ! "$limit" =~ ^[1-9][0-9]*$ ]]; then
            error "N must be a positive whole number"
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
    if [ "$command" = report ] && [ "$file" -ef "$output_file" ]; then
        error "Cannot overwrite an input log"
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

# the spec wants name order when counts match
count_names() {
    sort | uniq -c | sort -k1,1nr -k2,2 | awk '{print $2, $1}'
}

services() {
    grep -oE 'service=[^[:space:]]+' "$data" | cut -d= -f2 | count_names
}

failed_logins() {
    grep -w 'event=FAILED_LOGIN' "$data" |
    grep -oE 'user=[^[:space:]]+' | cut -d= -f2 | grep -v '^-$' | count_names
}

top_users() {
    grep -oE 'user=[^[:space:]]+' "$data" |
    cut -d= -f2 | grep -v '^-$' | count_names | head -n "$limit"
}

report() {
    echo '=== LOG REPORT ==='
    echo '[OVERVIEW]'
    printf 'Files scanned: %d\nLines processed: %d\n' "$files" "$lines"
    echo '[COUNTS BY LEVEL]'
    printf 'ERROR %d\nWARN %d\nINFO %d\n' "$errors" "$warnings" "$infos"
    echo '[COUNTS BY SERVICE]'
    services
    echo '[FAILED LOGIN USERS]'
    failed_logins
}

case "$command" in
    summary) summary ;;
    services) services ;;
    failed-logins) failed_logins ;;
    top-users) top_users ;;
    report) report > "$output_file" || error "Cannot write report" ;;
esac
