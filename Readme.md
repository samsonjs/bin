# bin

My personal collection of command-line utilities. Mostly git workflow stuff, but there's a bunch of other random tools that have accumulated over the years.

## What's in here

These are shell scripts, Ruby utilities, and various other command-line tools that live in my PATH. I've been collecting them for ages - some date back to 2006 - and they handle the mundane tasks I got tired of doing manually.

The usual suspects:
- Git workflow shortcuts (because who remembers those flag combinations?)
- Image processing for app icons and retina displays
- JSON manipulation and data analysis tools
- System automation for macOS
- Media conversion utilities

Most follow the Unix philosophy of doing one thing well, though some have grown a bit over time. The ones I still use regularly work reliably, but there are definitely some in here that haven't been touched in years and may or may not still function properly.

## The collection

- [**add-eac3-audio**](https://git.samhuri.net/sjs/bin/src/branch/main/add-eac3-audio) - Add a DD+ 5.1 TV mix to movies that only have DTS audio
- [**colours.rb**](https://git.samhuri.net/sjs/bin/src/branch/main/colours.rb) - Convert between color formats (hex, RGB, UIColor)
- [**convert-all-songs**](https://git.samhuri.net/sjs/bin/src/branch/main/convert-all-songs) - Batch convert audio files to different formats
- [**convert-song**](https://git.samhuri.net/sjs/bin/src/branch/main/convert-song) - Convert single audio file to different format
- [**dfn**](https://git.samhuri.net/sjs/bin/src/branch/main/dfn) - df without the noise - just the volumes you see on the desktop
- [**enable-sudo-touch-id**](https://git.samhuri.net/sjs/bin/src/branch/main/enable-sudo-touch-id) - Enable Touch ID authentication for sudo commands
- [**finder-show-hidden-files**](https://git.samhuri.net/sjs/bin/src/branch/main/finder-show-hidden-files) - Toggle visibility of hidden files in Finder
- [**generate-xcode-imageset**](https://git.samhuri.net/sjs/bin/src/branch/main/generate-xcode-imageset) - Generate Xcode imageset from @2x and @3x images
- [**git-conflicts**](https://git.samhuri.net/sjs/bin/src/branch/main/git-conflicts) - List files in merge conflict state
- [**git-diff-merge-conflict-resolution**](https://git.samhuri.net/sjs/bin/src/branch/main/git-diff-merge-conflict-resolution) - Show diff for merge conflict resolution
- [**git-edit-conflicted-files**](https://git.samhuri.net/sjs/bin/src/branch/main/git-edit-conflicted-files) - Open all conflicted files in editor
- [**git-large-files**](https://git.samhuri.net/sjs/bin/src/branch/main/git-large-files) - Find largest objects in git repository pack files
- [**git-remove-merged-branches**](https://git.samhuri.net/sjs/bin/src/branch/main/git-remove-merged-branches) - Delete merged branches from remote repository
- [**git-uncommit**](https://git.samhuri.net/sjs/bin/src/branch/main/git-uncommit) - Undo the last commit (soft reset)
- [**git-update**](https://git.samhuri.net/sjs/bin/src/branch/main/git-update) - Update and rebase current branch from remote with stash management
- [**jj-rebase-check**](https://git.samhuri.net/sjs/bin/src/branch/main/jj-rebase-check) - Show which jj bookmarks will conflict when rebased onto trunk
- [**jsonugly**](https://git.samhuri.net/sjs/bin/src/branch/main/jsonugly) - Minify JSON by removing whitespace
- [**make-bookmarklet**](https://git.samhuri.net/sjs/bin/src/branch/main/make-bookmarklet) - Convert JavaScript code to bookmarklet format
- [**mem-report**](https://git.samhuri.net/sjs/bin/src/branch/main/mem-report) - Memory use by grouped program, matching Activity Monitor's footprint
- [**photos-size-csv**](https://git.samhuri.net/sjs/bin/src/branch/main/photos-size-csv) - CSV of Photos library asset counts and sizes by year and media type
- [**progress**](https://git.samhuri.net/sjs/bin/src/branch/main/progress) - Add progress indicators to piped data streams
- [**retina-scale**](https://git.samhuri.net/sjs/bin/src/branch/main/retina-scale) - Scale images for 1x, 2x, and 3x display densities
- [**roll**](https://git.samhuri.net/sjs/bin/src/branch/main/roll) - Random choice selector from command line arguments
- [**save-keyboard-shortcuts.sh**](https://git.samhuri.net/sjs/bin/src/branch/main/save-keyboard-shortcuts.sh) - Export macOS keyboard shortcuts to file
- [**scale-app-icons**](https://git.samhuri.net/sjs/bin/src/branch/main/scale-app-icons) - Generate iOS and macOS app icons at all required sizes
- [**screen-shell**](https://git.samhuri.net/sjs/bin/src/branch/main/screen-shell) - Screen session management utility
- [**screenshare-display**](https://git.samhuri.net/sjs/bin/src/branch/main/src/screenshare-display.swift) - Fix the Screen Sharing virtual display sticking at 1080p
- [**serve**](https://git.samhuri.net/sjs/bin/src/branch/main/serve) - Start simple HTTP server (default port 8080)
- [**sri-integrity**](https://git.samhuri.net/sjs/bin/src/branch/main/sri-integrity) - Generate Sub-Resource Integrity hashes for external resources
- [**youtube-snarf-audio**](https://git.samhuri.net/sjs/bin/src/branch/main/youtube-snarf-audio) - Extract audio from YouTube videos

