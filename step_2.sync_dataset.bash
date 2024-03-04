#!/bin/bash
# set -x

# This script downloads a dataset from NY.gov and uploads it to an AWS S3 bucket.
# It checks the timestamps of the local and remote files and only uploads if the local file is newer.
# Return Codes:
# 0 - Success or no update needed
# 2 - Download failed
# 3 - Upload failed
# 4 - Cannot write to tmp file
# 5 - Unknown option

# NOTE: Return code 1 is ommited to distinguish unexpected errors for further investigation.
# WARN: Script was developed on MacOS, it should be Linux-compatible, but it has not been tested

# URL of the dataset
URL="https://data.ny.gov/api/views/5xaw-6ayf/rows.csv?accessType=DOWNLOAD"

# Temporary file for the downloaded dataset
raw_file=$(mktemp /tmp/aws4.dataset.raw.XXXXXX)
tmp_file=$(mktemp /tmp/aws4.dataset.csv.XXXXXX)

# S3 bucket and file details
S3_BUCKET="aws4-bucket4"
DATA_FILE="dataset.csv"
S3_PATH="s3://$S3_BUCKET/dataset/$DATA_FILE"

# Command to get the last modified timestamp of a file.
CMD_LAST_MODIFIED='stat -c %Y'
CMD_EPOCH2HUMAN='date -d @'
# Fix for macOS as `stat` behaves differently there.
[ $(uname) == "Darwin" ] && CMD_LAST_MODIFIED='stat -f %m' && CMD_EPOCH2HUMAN='date -r '

# Function to clean up temporary files and exit the script
# Takes an exit code and a message as arguments
function cleanup() {
    exit_code=$1
    shift
    exit_msg="$@"

    # Remove the temporary file
    rm -f "$raw_file" "$tmp_file" 2>/dev/null

    # Print the exit message to stdout or stderr, depending on the exit code
    echo "$exit_msg" >&$((exit_code ? 2 : 1))

    # Reset conditional verbose output
    exec 3>&-
    exec 4>&-

    # Exit the script with the given exit code
    exit $exit_code
}

# Function prints all know options
function usage() {
    echo "Usage: $0 [-f] [-v] [-h]
    -f: force upload
    -v: enable verbose output
    -h: print script usage
    "
    cleanup $1
}

# Function to download the dataset
function download() {
    echo "Downloading dataset from NY.gov..."
    # NOTE: --quiet used for a cleaner output, in production the output could be written to a log
    wget $($verbose || echo "--quiet") --tries=3 --output-document="$raw_file" "$URL" ||
        cleanup 2 "Unable to download 'dataset.csv'."
}

# Function to check the timestamps of the local and remote files
function check_timestamps() {
    echo "Checking timestamps..."
    lastmod_new=$($CMD_LAST_MODIFIED "$raw_file")
    lastmod_old=$(
        (
            echo -n 0 # Default to 0 if the query fails
            aws s3api head-object --bucket $S3_BUCKET --key "dataset/$DATA_FILE" \
                --query 'Metadata.lastmodified' 2>&4
        ) | sed 's/[^0-9]//g;s/^0\(.\)/\1/'
    )
    $verbose && echo -e "Old timestamp: $(${CMD_EPOCH2HUMAN}$lastmod_old)\nNew timestamp: $(${CMD_EPOCH2HUMAN}$lastmod_new)"
    [ "$lastmod_new" -le "$lastmod_old" ] &&
        cleanup 0 "S3 file up-to-date, nothing to do."
    echo "Update available..."
}

# Function to split winning numbers to separate columns
function process_winning_numbers() {
    echo -n "Processing update..."
    # Change format of the Draw date to the standard Athena format 'yyyy-mm-dd'
    # Split numbers to columns by replacing spaces
    # Fix for Multiplier=1
    # Fix for numbers with a leading zero
    tail -n+2 $raw_file | while read line; do
        $verbose && ((i = i + 1)) && ((i % 100)) || echo -n .
        echo "$line" |
            sed 's@^\(..\)/\(..\)/\(....\)@\3-\1-\2@;s/ /,/g;s/,$/,1/;s/,0\([1-9]\)/,\1/g' >>$tmp_file
    done || cleanup 4 "Can not write to '$tmp_file'."
    echo
}

# Function to upload the dataset to S3
function upload() {
    echo "Uploading to S3..."
    # S3 uses system LastModified for its own versioning purposes,
    # so we have to save the actual file LastModified time to S3 metadata.
    aws s3 cp "$tmp_file" "$S3_PATH" --metadata lastmodified=$lastmod_new >&3 ||
        cleanup 3 "Failed to upload to '$S3_PATH'."
}

# Main execution

# Initialize force and verbose flags
force=false
verbose=false

# Loop through all arguments
while getopts ":fvh" arg; do
    case $arg in
    f) force=true ;;
    v) verbose=true ;;
    h) usage 0 ;;
    *)
        echo "Unknown option -$OPTARG"
        usage 5
        ;;
    esac
done
$verbose && exec 3>&1 || exec 3>/dev/null
$verbose && exec 4>&2 || exec 4>/dev/null

# run the script
download
$force || check_timestamps
process_winning_numbers
upload
cleanup 0 "Done."
