# Styling

The appearance of Immersive's interface can be changed in `immersive-style.conf`.
Global entries in this file represent the base style, which is derived from the
mpv OSD style by default.

Styles are nested. For example, the style for selected text is based on the
style for the text selection interface, so if text_select is set to be bold,
the selection will also be. The section name is a `/`-separated path to the
style being configured by it.

Styling is done through Advanced Substation Alpha (SSA/ASS) tags internally.
The tags corresponding to each entry are listed below.


## Types

Every entry is of a certain type:

- `number`: A number. Decimal places are generally allowed
- `string`: A sequence of multiple characters
- `boolean`: A true/false value. Allowed values are `yes`/`true` and `no`/`false`
- `color`: Six-digit hexadecimal RGB color (RRGGBB), as in HTML/CSS
- `alpha`: Two-digit hexadecimal alpha (opacity). `00` is transparent and `FF` is opaque

"OSD pixels" below refers to pixels at 720p resolution. Even if the video
resolution is different, OSD pixels are always scaled as if the player window
was 720 pixels tall.


## Available Entries

The following entries are available in each section, including the global one:

| key               | type      | SSA     | description
| ----------------- | --------- | ------- | ------------------------------------------------------------------------------------------------------------
| `align`           | `number`  | `an`    | "Numpad" alignment. 7 is top left, 5 is centered, 6 is center-right, etc.
| `bold`            | `boolean` | `b`     | Make text bold
| `italic`          | `boolean` | `i`     | Italicize text
| `underline`       | `boolean` | `u`     | Underline text
| `strikeout`       | `boolean` | `s`     | Strike through text
| `border`          | `number`  | `bord`  | Text border width (OSD pixels)
| `border_x`        | `number`  | `xbord` | Horizontal text border width (OSD pixels)
| `border_y`        | `number`  | `ybord` | Vertical text border width (OSD pixels)
| `shadow`          | `number`  | `shad`  | Shadow distance (OSD pixels)
| `shadow_x`        | `number`  | `xshad` | Horizontal shadow distance (OSD pixels)
| `shadow_y`        | `number`  | `yshad` | Vertical shadow distance (OSD pixels)
| `blur`            | `number`  | `blur`  | Text edge blur strength, 0 to disable
| `font_name`       | `string`  | `fn`    | Name of the font to render text with
| `font_size`       | `number`  | `fs`    | Font size in OSD pixels
| `letter_spacing`  | `number`  | `fsp`   | Letter spacing, 0 is default, positive values increase spacing and negative ones decrease it
| `primary_color`   | `color`   | `1c`    | Color used for text
| `secondary_color` | `color`   | `2c`    | Unused but included for the sake of completeness
| `border_color`    | `color`   | `3c`    | Color used for borders
| `shadow_color`    | `color`   | `4c`    | Color used for shadows
| `all_alpha`       | `alpha`   | `alpha` | Overall transparency
| `primary_alpha`   | `alpha`   | `1a`    | Text transparency
| `secondary_alpha` | `alpha`   | `2a`    | Unused but included for the sake of completeness
| `border_alpha`    | `alpha`   | `3a`    | Border transparency
| `shadow_alpha`    | `alpha`   | `4a`    | Shadow transparency


## Available Sections

These are all available style paths with all entries and their default values
as comments:

```
# Global entries serve as the basis for all other styles.
#align           =5
#bold            =<from mpv property 'osd-bold'>
#italic          =<from mpv property 'osd-italic'>
#underline       =no
#strikeout       =no
#border          =<from mpv property 'osd-border-size'>
#border_x        =<from mpv property 'osd-border-size'>
#border_y        =<from mpv property 'osd-border-size'>
#shadow          =<from mpv property 'osd-shadow-offset'>
#shadow_x        =<from mpv property 'osd-shadow-offset'>
#shadow_y        =<from mpv property 'osd-shadow-offset'>
#blur            =<from mpv property 'osd-blur'>
#font_name       =<from mpv property 'osd-font'>
#font_size       =30
#letter_spacing  =<from mpv property 'osd-spacing'>
#primary_color   =<from mpv property 'osd-color'>
#secondary_color =808080
#border_color    =<from mpv property 'osd-border-color'>
#shadow_color    =<from mpv property 'osd-shadow-color'>
#all_alpha       =FF
#primary_alpha   =<from mpv property 'osd-color'>
#secondary_alpha =00
#border_alpha    =<from mpv property 'osd-border-color'>
#shadow_alpha    =<from mpv property 'osd-shadow-color'>

# --------------------

# message log at the top right
[messages]
#align=9

[messages/fatal]
#bold=yes
#primary_color=5791F9

[messages/error]
#primary_color=7A77F2

[messages/warn]
#primary_color=66CCFF

[messages/info]
# none

[messages/verbose]
#primary_color=99CC99

[messages/debug]
#primary_color=A09F93

[messages/trace]
# none

# --------------------

# menu help ("Press h to show key bindings")
[menu_help]
#align=7

# used for key bindings
[menu_help/key]
#bold=yes

# used for the top line of the menu help
[menu_help/hint]
#italic=yes

# --------------------

# menu info (timings, active target, etc.)
[menu_info]
#align=1

# description of an info item
[menu_info/key]
#bold=yes

# unset/unknown/automatically generated values
[menu_info/unset]
#italic=yes

# --------------------

# line selection
[line_select]
# none

# actively selected line
[line_select/selection]
#bold=yes
#primary_color=FFD0D0

# --------------------

# text selection
# applied on top of line_select
# during target selection
[text_select]
# none

# selected text
[text_select/selection]
#primary_color=FF8080

# --------------------

# Forvo audio selection
# applied on top of line_select
[word_audio_select]
# none

# pronunciations that have not been loaded yet
[word_audio_select/unloaded]
primary_color808080

# pronunciations that are currently loading
[word_audio_select/loading]
primary_color8080FF

# pronunciations that are ready to play
[word_audio_select/loaded]
# none

# --------------------

# overlay of selected subtitles
# during subtitle selection
[selection_overlay]
#align=3

# --------------------

# overlay shown when Immersive is blocked
# e.g. while importing dictionaries
[info_overlay]
#align=1


# overlay for hiding the video during
# and after target selection
[blackout]
#primary_color=<from mpv property 'background'>
#primary_alpha=<from mpv property 'background'>
```
