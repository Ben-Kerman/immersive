# Script Config

Some general config options are located in `immersive.conf`:

```
# if set to 'yes', load dictionaries when mpv starts
preload_dictionaries=no

# show the dictionary loading overlay when loading dicts at startup
startup_dict_overlay=yes

# maximum number of target words per card
# set to 0 to disable limit
max_targets=1

# always show minutes when displaying times,
# even if playback has not reached 01:00 yet
always_show_minutes=yes

# black out the screen during and after target selection
target_select_blackout=yes

# black out the screen when looking up words
# from the active subtitle
active_sub_blackout=yes

# language code to use when searching Forvo audio
forvo_language=ja

# Automatically load Forvo audio instead of
# waiting until attempting to play it.
forvo_preload_audio=no

# download mp3 files from Forvo instead of Ogg/Vorbis
forvo_prefer_mp3=no

# prefix for Forvo filenames in the Anki media directory
# Files will be named '<prefix>-<word>.<extension>''
forvo_prefix=word_audio

# reencode Forvo audio files since they are unnecessarily large
forvo_reencode=yes

# Forvo audio encoding options
# These behave like the corresponding options in target configs.
forvo_extension=mka
forvo_format=matroska
forvo_codec=libopus
forvo_bitrate=64ki

# AnkiConnect host and port
ankiconnect_host=localhost
ankiconnect_port=8765

# Windows clipboard mode
# "exact" takes longer (200ms-1s), but preserves the text exactly,
# i.e. it also copies line breaks.
# "quick" is much faster (<50ms), but might not copy the text
# with 100% accuracy (more like 99%).
# The method used by "quick" is also a dirty hack.
windows_clip_mode=exact

# make subtitle autoselect toggle global instead
# of being tied to each subtitle select menu
global_autoselect=yes

# enable subtitle autoselect by default
enable_autoselect=yes

# same as above but for the menu help toggle
global_help=yes
enable_help=no

# enable screenshots by default
take_screenshots=yes

# Hide the menu info at the bottom left if the help overlay is active.
# Useful if the two collide due to large font sizes.
hide_infos_if_help_active=no
```
