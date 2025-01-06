# CHIC
(C)hrome (HI)story (C)omparitor

This script pulls Chrome Bookmarks and History, puts them into a human readable format, then downloads specified text file blocklists and compares the Chrome data to the blocklist for matches.

The script downloads from blocklistproject/Lists repository.

This is intended to be run with priveledged accounts on your own systems. It is also not intended to violate other user's privacy. This is a tool to find rogue websites in your browser history or bookmarks.

TLDR: I am not responsible for your actions.

# Screen_Lock
`screen_lock.sh <lock/unlock> <username>`

Lock or unlock a user account via passwd. If account is being locked, script will also use loginctl to enable the lock screen. This effectivly terminates the user's access without closing any windows or losing any works-in-progress.

This could be setup on a systemd service and triggered with a timer. However, there are concerns if the system is powered off during the time an action would occur.