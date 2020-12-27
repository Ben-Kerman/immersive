# Immersive

Immersive is an mpv script for improving language immersion, with a special
focus on sentence mining. It can be used to create Anki cards including a
dictionary definition of the target word, an audio clip of the sentence, a
screenshot of a frame from the source video, and pronunciation audio from
Forvo. The script is highly configurable and supports many possible workflows.

## Requirements

The currently supported platforms are Linux and Windows. If you would like to
assist in adding macOS support please contact me.

<table>
	<tr>
		<th>Linux</th>
		<th>Windows</th>
		<th>required for & comments</th>
	</tr>
	<tr>
		<td colspan="2">mpv (0.33.0 or later)</td>
		<td></td>
	</tr>
	<tr>
		<td colspan="2">
			Anki with <a href="https://ankiweb.net/shared/info/2055492159">AnkiConnect</a>
		</td>
		<td>card export</td>
	</tr>
	<tr>
		<td colspan="2">curl</td>
		<td>web requests (Forvo, AnkiConnect), installed on Windows 10 by default since April 2018</td>
	</tr>
	<tr>
		<td>socat</td>
		<td>-</td>
		<td>background playback (export preview and Forvo)</td>
	</tr>
	<tr>
		<td>xclip</td>
		<td>PowerShell</td>
		<td>clipboard access, PowerShell is installed by default</td>
	</tr>
</table>

## Installation & Setup

Immersive can be installed by placing the contents of this repository in a
folder within your mpv scripts directory (`~/.config/mpv/scripts/` on Linux,
`%APPDATA%\mpv\scripts` on Windows). This folder should be named `immersive`.
Using any other name will mean that you will have to change the names of all
config files to match it as well. All necessary files can be downloaded as a
ZIP file from GitHub using the "Code" button at the top of the repo's start
page. Simply extract the contents of the file into your mpv scripts folder and
remove the branch name (most likely `-master`) from the name of the extracted
directory.

The script is configured in several different files. For a description of the
general syntax, see [this document](doc/config.md). In order to use the main
feature of generating Anki cards with included definitions, these config files
need to be present: [`targets.conf`](doc/targets.md) (how to export to Anki),
[`dictionaries.conf`](doc/dictionaries.md) (which dictionaries to use). The
following config files are optional: [`keys.conf`](doc/keys.md) (for
reassigning menu key bindings), [`series.conf`](doc/series.md) (for using
custom series IDs and titles), [`style.conf`](doc/style.md) (for changing the
appearance of the interface).

## Feature Overview

### Automatic Card Creation

The process for creating cards is as follows:

1. Bring up the subtitle selection menu (`a`)
2. Select the subtitles that should be on the card using `a` or the autoselect
(toggle with `A`). If there are no subtitles or if they are badly timed, set
the start/end time for the audio export manually using `Q` and `E`. If you
wish to take a screenshot at a specific time, set it using `s`, otherwise the
current frame will be used.
3. Enter target word selection mode using `d`. Select the target word with
(`Ctrl`+)`⇧`+`←`/`→` and confirm it using (`⇧`+)`⏎`. It's possible to search
for an external word from the clipboard using `v` if there are no text
subtitles or if a word can't be found.
4. Optionally add Forvo audio by pressing `a` after adding a target word.
5. Export to Anki using `f`.

The card creation process is highly customizable. For further information see
[here](doc/card-export.md).

### Looking up Words in mpv

You can look up words in your configured dictionaries. Bring up the word
selection menu by pressing `k` and search for the selection using (`⇧`+)`⏎`.

### Copying Subtitles

Immersive can copy subtitles to clipboard. Use `c` to manually copy the active
line at any time, or toggle automatic copying with `C`. You can copy a line
partially in the menu for selecting text from the active line.

## Troubleshooting

If Immersive crashes at any point (when this happens, the interface suddenly
disappears and all keybindings stop working), open the console using `ˋ`/`~`
and take a screenshot of it and report the issue to me. If you started mpv
from the command line the output there is preferable.
