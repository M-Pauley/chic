#!/usr/bin/env bash

# Define the directory where the processed files are stored (adjust if needed)
CHROME_DATA_DIR="./chrome_data"

# Define the directory to store the combined blocklist
BLOCKLIST_FILE="./blocklist.txt"

# Easylist and other blocklist URLs (you can add more as needed)
LIST_URLS=(
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/abuse.txt"
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/malware.txt"
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/phishing.txt"
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/porn.txt"
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/ransomware.txt"
    "https://raw.githubusercontent.com/blocklistproject/Lists/main/scam.txt"
)

download_and_merge_blocklists() {
    # Check if the combined blocklist already exists
    if [ -f "$BLOCKLIST_FILE" ]; then
        # Prompt the user whether they want to overwrite the existing blocklist
        read -r -p "The combined blocklist already exists. Do you want to regenerate it? (y/n): " choice
        case "$choice" in
            [Yy]*)
                echo "Regenerating the blocklist..."
                : > "$BLOCKLIST_FILE"  # Clear the existing blocklist file
                ;;
            [Nn]*)
                echo "Using the existing blocklist: $BLOCKLIST_FILE"
                return 0  # Skip the generation if the user chooses not to regenerate
                ;;
            *)
                echo "Invalid option. Exiting..."
                exit 1
                ;;
        esac
    fi

    # Start downloading and merging the blocklist files
    echo "Downloading blocklist files..."

    # Download and append each blocklist file to the combined blocklist
    # Added a filter to remove IP addresses and HTTP/HTTPS and www.
    for url in "${LIST_URLS[@]}"; do
        echo "Downloading from $url..."
        wget -q -O - "$url" | sed -E 's/^0\.0\.0\.0\s*//; s/^https?\:\/\///; s/^www\.//;' >> "$BLOCKLIST_FILE"
    done

    # Remove duplicate entries and sort the blocklist
    sort -u "$BLOCKLIST_FILE" -o "$BLOCKLIST_FILE"
    echo "Combined blocklist created at $BLOCKLIST_FILE"
}

# Function to get the most recent file based on the date in the filename
get_most_recent_file() {
    local prefix=$1
    local extension=$2

    # Use 'find' to locate files, sorted by modification time, and pick the most recent one
    local recent_file
    recent_file=$(find "$CHROME_DATA_DIR" -type f -name "${prefix}*${extension}" -print0 | xargs -0 ls -t | head -n 1)

    echo "$recent_file"
}

# Get the most recent Bookmark file and History file
BOOKMARKS_FILE=$(get_most_recent_file "BookmarkURL_" ".txt")
HISTORY_FILE=$(get_most_recent_file "History_" ".txt")

# Check if the files exist
if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    echo "Error: No bookmarks file found!"
    exit 1
fi

if [[ ! -f "$HISTORY_FILE" ]]; then
    echo "Error: No history file found!"
    exit 1
fi

# Copy the most recent Bookmark file to working files
cp "$BOOKMARKS_FILE" "$CHROME_DATA_DIR/working_bookmarks.txt"
echo "Copied the most recent Bookmark file to 'working_bookmarks.txt'. Normalizing..."

# For Bookmarks: extract and normalize URLs, overwrite the working file
if ! grep -oP '(https?://[^\s]+)' "$CHROME_DATA_DIR/working_bookmarks.txt" | sed -E 's/^0\.0\.0\.0\s*//; s/^https?\:\/\///; s/^www\.//; s/\/.*//' | sort -u > "$CHROME_DATA_DIR/working_bookmarks.tmp"; then
    echo "Error: URL extraction or normalization failed for 'working_bookmarks.txt'."
    exit 1
fi

# Move normalized bookmarks back to the original file
mv "$CHROME_DATA_DIR/working_bookmarks.tmp" "$CHROME_DATA_DIR/working_bookmarks.txt"
echo "Normalization complete for 'working_bookmarks.txt'"

# Copy the most recent History file to working files
cp "$HISTORY_FILE" "$CHROME_DATA_DIR/working_history.txt"
echo "Copied the most recent History file to 'working_history.txt'. Normalizing..."

# For History: extract and normalize URLs, overwrite the working file
if ! grep -oP '(https?://[^\s]+)' "$CHROME_DATA_DIR/working_history.txt" | sed -E 's/^0\.0\.0\.0\s*//; s/^https?\:\/\///; s/^www\.//; s/\/.*//' | sort -u > "$CHROME_DATA_DIR/working_history.tmp"; then
    echo "Error: URL extraction or normalization failed for 'working_history.txt'."
    exit 1
fi

# Move normalized history back to the original file
mv "$CHROME_DATA_DIR/working_history.tmp" "$CHROME_DATA_DIR/working_history.txt"
echo "Normalization complete for 'working_history.txt'"

# Define the blocklist file
BLOCKLIST_FILE="blocklist.txt"

# Output files for matches
BOOKMARKS_MATCHES="bookmarks_matches.txt"
HISTORY_MATCHES="history_matches.txt"

# Function to compare a file with the blocklist
compare_file() {
    local input_file=$1
    local output_file=$2

    echo "Checking $input_file for blocklist matches..."

    # Create a temporary file to store the matches
    temp_output=$(mktemp)

    # Loop over each URL in the input file and check if it's in the blocklist
    while read -r url; do
        # Normalize the URL from bookmarks/history
        normalized_url=$(echo "$url" | sed -E 's/^0\.0\.0\.0\s*//; s/^https?\:\/\///; s/^www\.//;')

        # Check against the blocklist
        if grep -Pq "^\Q$normalized_url\E($|\.)" "$BLOCKLIST_FILE"; then
            echo "$url" >> "$temp_output"
        fi
    done < "$input_file"

    # Clean the temp output:
    # Remove blank lines and duplicates
    if ! grep -v '^\s*$' "$temp_output" | sort -u > "$output_file"; then
        echo "Error: Failed to clean up the match file."
        exit 1
    fi

    # Remove the temporary file
    rm "$temp_output"

    echo "Matches saved to $output_file"
}

# Call the function to download and merge blocklists
download_and_merge_blocklists

# Compare Bookmarks against the Blocklist
compare_file "$CHROME_DATA_DIR/working_bookmarks.txt" "$BOOKMARKS_MATCHES"

# Compare History against the Blocklist
compare_file "$CHROME_DATA_DIR/working_history.txt" "$HISTORY_MATCHES"

# Output the results
printf "Matches in Bookmarks:\n---------------------\n"
while IFS= read -r line; do
    printf "\t%s\n" "$line"
done < "$BOOKMARKS_MATCHES"

printf "\n"

printf "Matches in History:\n-------------------\n"
while IFS= read -r line; do
    printf "\t%s\n" "$line"
done < "$HISTORY_MATCHES"
