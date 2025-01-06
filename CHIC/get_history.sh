#!/usr/bin/env bash

# Function to extract Chrome history for a specific user
extract_chrome_history() {
  local USERNAME="$1"
  local DATE
  DATE=$(date +%Y%m%d)

  # Path to the user's Chrome history file
  HISTORY_FILE="/home/$USERNAME/.config/google-chrome/Default/History"

  # Ensure the history file exists
  if [ ! -f "$HISTORY_FILE" ]; then
    echo "History file not found for user $USERNAME at $HISTORY_FILE"
    return 1
  fi

  # Copy the History file to the current directory and change ownership
  sudo cp "$HISTORY_FILE" ./chrome_data/History.db && sudo chown "$USER":"$USER" ./chrome_data/History.db

  # Query the SQLite database for the 100 most recent URLs and titles
  # Change DESC LIMIT 100; as needed.
  sudo sqlite3 -json ./chrome_data/History.db "SELECT url, title FROM urls ORDER BY last_visit_time DESC LIMIT 100;" \
    | jq -r '.[] | "\(.title)\n\t\(.url)\n"' \
    | tee ./chrome_data/History_"$DATE".txt
}

# Main script
main() {
  # Check if a username argument is provided
  if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
  fi

  USERNAME="$1"

  # Call the function to extract Chrome history
  extract_chrome_history "$USERNAME"
}

# Run the main function
main "$@"
