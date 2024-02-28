#!/bin/bash
# set -x

# This script downloads a dataset from NY.gov and uploads it to an AWS S3 bucket.
# It checks the timestamps of the local and remote files and only uploads if the local file is newer.
# Return Codes:
# 0 - Success or no update needed
# 2 - Download failed
# 3 - Upload failed

# NOTE: Return code 1 is ommited to distinguish unexpected errors for further investigation.

# URL of the dataset
URL="https://data.ny.gov/api/views/5xaw-6ayf/rows.csv?accessType=DOWNLOAD"

# Temporary file for the downloaded dataset
tmp_file=$(mktemp /tmp/aws4.dataset.csv.XXXXXX)

# S3 bucket and file details
S3_BUCKET="aws4-bucket4"
DATA_FILE="dataset.csv"
S3_PATH="s3://$S3_BUCKET/$DATA_FILE"

# Command to get the last modified timestamp of a file.
CMD_LAST_MODIFIED='stat -c %Y'
# Fix for macOS as `stat` behaves differently there.
[ $(uname) == "Darwin" ] && CMD_LAST_MODIFIED='stat -f %m'

# Function to clean up temporary files and exit the script
# Takes an exit code and a message as arguments
function cleanup() {
    exit_code=$1
    shift
    exit_msg="$@"

    # Remove the temporary file
    rm -f "$tmp_file" 2>/dev/null

    # Print the exit message to stdout or stderr, depending on the exit code
    echo "$exit_msg" >&$((exit_code ? 2 : 1))

    # Exit the script with the given exit code
    exit $exit_code
}

# Function to download the dataset
function download() {
    echo "Downloading dataset from NY.gov..."
    # NOTE: --quiet used for a cleaner output, in production the output should be written to log
    wget --quiet --tries=3 --output-document="$tmp_file" "$URL" ||
        cleanup 2 "Unable to download 'dataset.csv'."
}

# Function to check the timestamps of the local and remote files
function check_timestamps() {
    echo "Checking timestamps..."
    lastmod_new=$($CMD_LAST_MODIFIED "$tmp_file")
    lastmod_old=$(
        (
            echo -n 0 # Default to 0 if the query fails
            aws s3api head-object --bucket $S3_BUCKET --key "$DATA_FILE" \
                --query 'Metadata.lastmodified' 2>/dev/null
        ) | sed 's/[^0-9]//g'
    )
    [ "$lastmod_new" -le "$lastmod_old" ] &&
        cleanup 0 "S3 file up-to-date, nothing to do."
    echo "Update ready..."
}

# Function to upload the dataset to S3
function upload() {
    echo "Uploading to S3..."
    # S3 uses system LastModified for its own versioning purposes,
    # so we have to save the actual file LastModified time to S3 metadata.
    aws s3 cp "$tmp_file" "$S3_PATH" --metadata lastmodified=$lastmod_new ||
        cleanup 3 "Failed to upload to '$S3_PATH'."
}

# Main execution
download
check_timestamps
upload
cleanup 0 "Done."
