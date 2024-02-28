#!/bin/bash
# set -x

URL="https://data.ny.gov/api/views/5xaw-6ayf/rows.csv?accessType=DOWNLOAD"
tmp_file=$(mktemp /tmp/aws4.dataset.csv.XXXXXX)
S3_BUCKET="aws4-bucket4"
DATA_FILE="dataset.csv"
S3_PATH="s3://$S3_BUCKET/$DATA_FILE"

CMD_LAST_MODIFIED='stat -c %Y'
[ $(uname) == "Darwin" ] && CMD_LAST_MODIFIED='stat -f %m'

function cleanup() {
    exit_code=$1
    shift
    exit_msg="$@"

    rm -f "$tmp_file" 2>/dev/null
    echo "$exit_msg" >&$((exit_code ? 2 : 1))
    exit $exit_code
}

function download() {
    echo "Downloading dataset from NY.gov..."
    wget -q --tries=3 --output-document="$tmp_file" "$URL" ||
        cleanup 2 "Unable to download 'dataset.csv'."
}

function check_timestamps() {
    echo "Checking timestamps..."
    lastmod_new=$($CMD_LAST_MODIFIED "$tmp_file")
    lastmod_old=$(
        (
            echo -n 0
            aws s3api head-object --bucket $S3_BUCKET --key "$DATA_FILE" \
                --query 'Metadata.lastmodified' 2>/dev/null
        ) | sed 's/[^0-9]//g'
    )
    [ "$lastmod_new" -le "$lastmod_old" ] && cleanup 0 "S3 file up-to-date, nothing to do."
    echo "Update ready..."
}

function upload() {
    echo "Uploading to S3..."
    aws s3 cp "$tmp_file" "$S3_PATH" --metadata LastModified=$lastmod_new || cleanup 3 "Failed to upload to '$S3_PATH'."
}

### EXEC ###
download
check_timestamps
upload
cleanup 0 "Done."
