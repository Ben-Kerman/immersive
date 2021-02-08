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
