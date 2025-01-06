#!/usr/bin/env bash

# Function to extract Chrome bookmarks for a specific user
extract_bookmarks() {
  local USERNAME="$1"
  local DATE
  DATE=$(date +%Y%m%d)
  
  # Ensure the bookmarks file exists
  BOOKMARKS_FILE="/home/$USERNAME/.config/google-chrome/Default/Bookmarks"
  if [ ! -f "$BOOKMARKS_FILE" ]; then
    echo "Bookmarks file not found for user $USERNAME at $BOOKMARKS_FILE"
    return 1
  fi

  # Extract bookmark data and output to a file
  sudo jq -r '.roots.other.children[] | "\(.name)\n\t \(.url)\n"' "$BOOKMARKS_FILE" | tee ./chrome_data/BookmarkURL_"$DATE".txt
}

# Main script
main() {
  # Check if a username argument is provided
  if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
  fi

  USERNAME="$1"

  # Call the function to extract bookmarks
  extract_bookmarks "$USERNAME"
}

# Run the main function
main "$@"
