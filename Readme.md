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

- [**colours.rb**](https://github.com/samsonjs/config/blob/main/bin/colours.rb) - Convert between color formats (hex, RGB, UIColor)
- [**convert-all-songs**](https://github.com/samsonjs/config/blob/main/bin/convert-all-songs) - Batch convert audio files to different formats
- [**convert-song**](https://github.com/samsonjs/config/blob/main/bin/convert-song) - Convert single audio file to different format
- [**diff-so-fancy**](https://github.com/samsonjs/config/blob/main/bin/diff-so-fancy) - Enhanced git diff output with better formatting ([source](https://github.com/so-fancy/diff-so-fancy))
- [**enable-sudo-touch-id**](https://github.com/samsonjs/config/blob/main/bin/enable-sudo-touch-id) - Enable Touch ID authentication for sudo commands
- [**finder-show-hidden-files**](https://github.com/samsonjs/config/blob/main/bin/finder-show-hidden-files) - Toggle visibility of hidden files in Finder
- [**generate-xcode-imageset**](https://github.com/samsonjs/config/blob/main/bin/generate-xcode-imageset) - Generate Xcode imageset from @2x and @3x images
- [**git-conflicts**](https://github.com/samsonjs/config/blob/main/bin/git-conflicts) - List files in merge conflict state
- [**git-diff-merge-conflict-resolution**](https://github.com/samsonjs/config/blob/main/bin/git-diff-merge-conflict-resolution) - Show diff for merge conflict resolution
- [**git-edit-conflicted-files**](https://github.com/samsonjs/config/blob/main/bin/git-edit-conflicted-files) - Open all conflicted files in editor
- [**git-large-files**](https://github.com/samsonjs/config/blob/main/bin/git-large-files) - Find largest objects in git repository pack files
- [**git-open-in-github**](https://github.com/samsonjs/config/blob/main/bin/git-open-in-github) - Open current repo/branch in GitHub web interface
- [**git-remove-merged-branches**](https://github.com/samsonjs/config/blob/main/bin/git-remove-merged-branches) - Delete merged branches from remote repository
- [**git-uncommit**](https://github.com/samsonjs/config/blob/main/bin/git-uncommit) - Undo the last commit (soft reset)
- [**git-update**](https://github.com/samsonjs/config/blob/main/bin/git-update) - Update and rebase current branch from remote with stash management
- [**jsonugly**](https://github.com/samsonjs/config/blob/main/bin/jsonugly) - Minify JSON by removing whitespace
- [**make-bookmarklet**](https://github.com/samsonjs/config/blob/main/bin/make-bookmarklet) - Convert JavaScript code to bookmarklet format
- [**progress**](https://github.com/samsonjs/config/blob/main/bin/progress) - Add progress indicators to piped data streams
- [**retina-scale**](https://github.com/samsonjs/config/blob/main/bin/retina-scale) - Scale images for 1x, 2x, and 3x display densities
- [**roll**](https://github.com/samsonjs/config/blob/main/bin/roll) - Random choice selector from command line arguments
- [**save-keyboard-shortcuts.sh**](https://github.com/samsonjs/config/blob/main/bin/save-keyboard-shortcuts.sh) - Export macOS keyboard shortcuts to file
- [**scale-app-icons**](https://github.com/samsonjs/config/blob/main/bin/scale-app-icons) - Generate iOS and macOS app icons at all required sizes
- [**screen-shell**](https://github.com/samsonjs/config/blob/main/bin/screen-shell) - Screen session management utility
- [**sd-before-copy**](https://github.com/samsonjs/config/blob/main/bin/sd-before-copy) - Pre-backup script for SuperDuper! to run Vortex backup system
- [**serve**](https://github.com/samsonjs/config/blob/main/bin/serve) - Start simple HTTP server (default port 8080)
- [**sri-integrity**](https://github.com/samsonjs/config/blob/main/bin/sri-integrity) - Generate Sub-Resource Integrity hashes for external resources
- [**youtube-snarf-audio**](https://github.com/samsonjs/config/blob/main/bin/youtube-snarf-audio) - Extract audio from YouTube videos

