#!/bin/sh
#
# save-keyboard-shortcuts.sh - Export macOS keyboard shortcuts to restore script
#
# Reads all NSUserKeyEquivalents from macOS preferences and generates a script
# to restore them. Useful for backing up custom keyboard shortcuts.
#
# Usage: save-keyboard-shortcuts.sh
#
# Output: Creates ~/bin/restore-keyboard-shortcuts.sh

DESTFILE=~/bin/restore-keyboard-shortcuts.sh
echo '#!/bin/bash' > $DESTFILE

defaults find NSUserKeyEquivalents | sed -e "s/Found [0-9]* keys in domain '\\([^']*\\)':/defaults write \\1 NSUserKeyEquivalents '/" -e "s/    NSUserKeyEquivalents =     {//"  -e "s/};//" -e "s/}/}'/" >> $DESTFILE
echo killall cfprefsd >> $DESTFILE
chmod a+x $DESTFILE

echo "Keyboard shortcuts saved to $DESTFILE"
