#!/bin/bash
# run from the project folder

temp_dir=$(mktemp -d) || exit 1
trap 'rm -r "$temp_dir"' EXIT

check() {
    if [ "$2" != "$3" ]; then
        echo "FAIL: $1"
        printf 'Expected:\n%s\nGot:\n%s\n' "$2" "$3"
        exit 1
    fi
    echo "PASS: $1"
}

./logtool.sh --help > /dev/null
check "Help" "0" "$?"

check "Summary" 'FILES_SCANNED=3
LINES_PROCESSED=54
ERROR=19
WARN=11
INFO=24' "$(./logtool.sh summary logs)"

check "Services" 'sshd 14
nginx 10
backup 9
cron 9
kernel 7
authd 5' "$(./logtool.sh services logs)"

check "Failed logins" 'alice 3
dave 2
bob 1
erin 1' "$(./logtool.sh failed-logins logs)"

echo "All 4 checks passed."
