# Targets

Targets determine how Immersive exports notes to Anki. Each target is defined
in its own config section. The global entries are used as default values for
all targets.

The section header is used as the target name that is visible in the global
menu. (`Ctrl+a`)

In addition to the entries listed below, each target can include entries with
keys like `field:<field name>`, where `<field name>` is the name of a field of
the target's note type. These determine what the contents of the fields of the
exported notes will be. Their values are interpreted as
[templates](doc/templating.md).

---

Example target config with all possible entries and their default values as
comments:

```
[target name]
# Anki profile the target will use
# Can be taken from the window title of the main Anki window or from the profile
# menu (Ctrl+Shift+P in Anki)
#profile=<must be set manually>

# Anki deck the target will use
# Subdecks use the same syntax as in Anki itself
# e.g. Root::SubdeckA::SubdeckB
#deck=<must be set manually>

# note type the target will use
#note_type=<must be set manually>

# how export data will be added to existing notes
# allowed values: 'append', 'prepend', 'overwrite'
# overwrite replaces fields (but cf. template variable {{prev_content}})
#add_mode=append

# template used for formatting notes within mpv when selecting which existing
# note to export to
#note_template={{type}}: {{id}}

# Anki media dir override, normally derived from system default
#media_directory=<unset>

# space-separated list of tags that will be added to exported notes
#tags=immersive

# --------------------

# substitutions to apply to the {{sentences}} field
# for more information, see doc/note-export.md
#sentence_substitutions=[[
<（.-%）
<(.-%)
]]

# same as sentence_substitutions but for {{definitions}}
#definition_substitutions=

# --------------------

# file extension to use for audio clips
# unrelated to the format used, but should match it (especially on Windows)
#audio/extension=mka

# audio container format
# e.g. 'matroska' (MKV/MKA), 'ogg', 'mp3'
#audio/format=matroska

# audio codec
# e.g. 'libopus' (NOT opus), 'aac', 'vorbis', 'libmp3lame' (MP3)
#audio/codec=libopus

# audio bitrate
# Uses the same syntax as mpv/ffmpeg bitrates.
# Sensible values are 32ki-64ki for libopus and 128ki for AAC and MP3.
#audio/bitrate=48ki

# how many seconds of padding to include before the start of audio clips
#audio/pad_start=0.1

# same as above, but after the end of the clip
#audio/pad_end=0.1

# --------------------

# image file extension
#image/extension=jpg

# image codec
# supported values are 'mjpeg' (JPG), 'libwebp' (WebP), and 'png'
# Technically, any codec that works with ffmpeg's image2 format can be used.
#image/codec=mjpeg

# maximum image width/height
# If one option is set to a negative value aspect ratio will be preserved.
# If both are negative the video's resolution will be used.
#image/max_width=-1
#image/max_height=-1

# quality of JPG (mjpeg) images
# valid range: 1-69
# lower is better (but files will be larger)
# Values above 5-10 result in noticeable artifacting.
#image/jpeg/qscale=5

# whether to use lossless compression for WebP
#image/webp/lossless=no

# libwebp quality factor
# valid range: 0-100
# higher is better
#image/webp/quality=90

# libwebp compression level
# valid range: 0-6
# Higher values result in better compression but take longer to encode.
#image/webp/compression=4

# PNG compression level
# valid range: 0-9
# higher is better
#image/png/compression=9
```