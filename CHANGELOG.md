# 1.4 - TBD

Features:
- Add field template variable `selections`.
- Replace field template variable `word` with `words`.
  **Config change required** for any fields that contained `{{word}}`.

# 1.3 - 2021-10-12

Features:
- Experimental macOS support
- Audio/image encoding from youtube-dl streams  
  This should add support for any site/service youtube-dl supports
- Dictionary switching while selecting a definition
- Transformed lookup of selected text  
  Currently supports Migaku format-based deinflection, Japanese deinflection, and kana conversion
- Key bindings for deleting text during target word selection
- Runtime-reloadable config files (except dictionary config)
- Validation and error messages/warnings for most config files
- Optional support for multiple dictionary groups
- Dynamic tags using the same template variables as note fields

Improvements:
- Significantly improved export speed by running encoding in the background
- Disable menu and screen blackout while exporting notes
- Apply sentence substitutions when selecting text instead of before exporting
- Text selection rework
- Automatically set primary X11 selection based on selected text
- Only search for notes to add to after starting the export process

Fixes:
- Show an error message if the background player is unreachable instead of crashing
- Use the current mpv executable for encoding and audio preview instead of assuming mpv is in PATH
- Fix precedence of conflicting series IDs
- Add conditional replacements for `table.pack` and `table.unpack` (missing in Lua 5.1)
- Disable mpv config for encoder processes

# 1.2 - 2021-02-08

Features:
- Audio preview during target selection
- Key binding for deleting target words
- Key binding for adding word audio from selection

Fixes:
- Several bugs related to dictionary import and lookup
- Base background player socket name on mpv's PID
- Tags are now actually added to cards
- Prevent clashes with mpvacious' filename scheme
- Add sub delay for single line export
- Warn if subtitle times are nil due to invalid sub data
- Fix Forvo audio preloading
- Fix crash when manually selecting times with no active subs
- Set image export dimension placeholder properly
- Use active track for audio preview
- Fix infinite loop in Yomichan exporter that happened for certain words

# 1.1 - 2021-01-01

Minor improvements:
- New key binding for single-line export using the export menu.
- Automatic subtitle copying can now be enabled by default.

Fixes for crashes and other bugs:
- Start/end time overrides now take sub delay into account.
- The script no longer crashes if AnkiConnect can't be reached.
- Improved handling of invalid template data.
- The active sub lookup blackout now works properly
- Empty sentence/definition substitutions are ignored.

# 1.0 - 2020-12-29

First release of Immersive

Key features:
- Anki note/card generation including dictionary definitions
- Versatile note field generation based on a template syntax
- Automatic or manual selection of subtitles to be added to a note
- Dictionary lookup from within mpv
- Support for multiple dictionaries
- Forvo audio support with the ability to choose a pronunciation
- Support for multiple Anki target decks/note types, with the ability to switch at runtime
- A high degree of configurability, including fully rebindable key bindings
