# FIT2109 Log Toolkit - Variant B

## What this does

Log files are long and boring to read by hand if you wanted to know how many
errors happened, or who keeps failing to log in, you'd
usually scroll through hundreds of lines and start counting. This script counts for you, you point it at a folder and it reads every `.log` file inside (including the  subfolders) and prints the totals.

## How to run it

Use WSL if on windows, otherwise run this command for help

```bash
chmod +x logtool.sh
./logtool.sh --help
```

If a folder has spaces in the name put quotes around it

## Example commands

```bash
./logtool.sh summary logs              # counts overall
./logtool.sh services logs             # which services are logged most
./logtool.sh failed-logins logs        # who couldn't log in
./logtool.sh top-users logs            # the 3 most active users
./logtool.sh report logs report.txt    # save everything to a txt
```


## Expected output

Running this command `summary logs` on the demo log files will display

```text
FILES_SCANNED=3
LINES_PROCESSED=54
ERROR=19
WARN=11
INFO=24
```

The other commands print one name and one count per line


**Top users**
```text
alice 9
carol 8
erin 7
```

 
**Failed logins**
```text
alice 3
dave 2
bob 1
erin 1
```


## How it works

1. Checks the command and argument you gave it makes sense 
2. Find the `.log` files and we copy their content into a temporary file
3. Discard all the information we don't need
4. Count with `grep` and `wc` for totals, and `sort` with `uniq` for the grouped counts
5. Print it or write the report, then delete the temporary file