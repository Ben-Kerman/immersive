# Immersive

Immersive is an mpv script for improving language immersion, with a special
focus on sentence mining. It can automatically generate Anki cards with
dictionary definitions of the target word, sentence audio clips, screenshots
from the video, and pronunciation audio taken from [Forvo](https://forvo.com/).
The script is highly configurable and supports many possible workflows.

This is a short video walking through the full process of creating a card with
Immersive: https://youtu.be/FrTcu4ZO92w. It's possible to skip parts of the
process if you don't need them.

Another demo that isn't artificially slowed down for the sake of being easier
to follow: https://youtu.be/g1aPNkdGTUc


## Requirements

Immersive supports all major desktop operating systems:

<table>
	<tr>
		<th>Linux</th>
		<th>Windows</th>
		<th>macOS</th>
		<th>required for & comments</th>
	</tr>
	<tr>
		<td colspan="3">mpv (0.33.0 or later)</td>
		<td></td>
	</tr>
	<tr>
		<td colspan="3">
			Anki with <a href="https://ankiweb.net/shared/info/2055492159">AnkiConnect</a>
		</td>
		<td>card export</td>
	</tr>
	<tr>
		<td colspan="3">curl</td>
		<td>
			web requests (Forvo, AnkiConnect). Already present by default on most systems.
			Part of Windows 10 since April 2018
		</td>
	</tr>
	<tr>
		<td>socat</td>
		<td>-</td>
		<td>netcat (<code>nc</code>)</td>
		<td>
			background playback (sentence and Forvo audio preview).
			<code>nc</code> is included with macOS 10.13 and later.
		</td>
	</tr>
	<tr>
		<td>xclip</td>
		<td>PowerShell</td>
		<td>-</td>
		<td>clipboard access, PowerShell is installed by default</td>
	</tr>
</table>


## Feature Overview

### Fully Integrated Card Creation

The basic process for creating cards is as follows:

1. Bring up the subtitle selection menu (`a`)
2. Select the subtitles that should be on the card using `a` or the autoselect
   (toggle with `A`). If there are no subtitles or if they are badly timed, set
   the start/end time for the audio export manually using `Q` and `E`. If you
   wish to take a screenshot at a specific time instead of the current frame,
   set it using `s`.
3. Enter target word selection mode using `d`. Select the target word with
   (`Ctrl`+)`⇧`+`←`/`→` and confirm it using (`⇧`+)`⏎`. It's possible
   to search for an external word from the clipboard using `v` if there are no
   text subtitles or if a word can't be found.
4. Choose a definition from the dictionary entries with `↑`/`↓` and `⏎`. Switch
   between dictionaries with `←`/`→` if you have more than one configured.
5. Optionally add Forvo audio by pressing `a` after adding a target word.
6. Export to Anki using `f`.

The card creation process is highly customizable. For further information read
[this](/doc/card-export.md).

### Dictionary Lookup in mpv

You can look up words in your configured dictionaries at any time. Open the word
selection menu by pressing `k` and search for the selection using (`⇧`+)`⏎`.

### Automatic Deinflection

Immersive supports automatic deinflection (deconjugation) based on the same
tables that the Migaku Dictionary addon for Anki uses in addition to a
simpler Japanese-specific deinflector.
Read [this page](/doc/lookup-transformations.md) for details.

### Subtitle Copying

Immersive can copy subtitles to the clipboard. Use `c` to manually copy the
active line at any time, or toggle automatic copying with `C`. You can
partially copy lines from the active line menu (`k`).


## Installation & Setup

For a guide to getting started as quickly as possible see [below](#quick-start-guide).

Immersive can be installed by placing the contents of this repository in a
folder within your mpv scripts directory (`~/.config/mpv/scripts/` on Linux,
`%APPDATA%\mpv\scripts` on Windows). This folder should be named `immersive`.
Using any other name will mean that you will have to change the names of all
config files to match it as well.

All necessary files can be downloaded as a ZIP file from the latest
[release](https://github.com/Ben-Kerman/immersive/releases). When installing
Immersive from a release archive, it only needs to be extracted into the mpv
config directory for the full release, or `scripts` directory for the script-only
release. The `immersive` directory is already contained in the archive.

If you want the most up-to-date version possible, use the "Code" button at the
top of the repo's start page. Simply extract the contents of the file into
your mpv scripts folder and remove the branch name (most likely `-master`)
from the name of the extracted directory.

---

The script is configured in several different files. These need to be placed
in a directory called `script-opts` that is located next to your `mpv.conf`
and `scripts` folder. For a description of the general config syntax, see [this
document](/doc/config.md). Except for `immersive-dictionaries.conf` all config
files can be reloaded from the global menu (`Ctrl`+`a`) at runtime.

In order to use the main feature of generating Anki cards with included
definitions, these config files need to be present:
- [`immersive-targets.conf`](/doc/targets.md): how to export to Anki
- [`immersive-dictionaries.conf`](/doc/dictionaries.md): which dictionaries to use

The following config files are optional:
- [`immersive.conf`](/doc/script-config.md): general configuration of the script
- [`immersive-keys.conf`](/doc/keys.md): reassign key bindings
- [`immersive-series.conf`](/doc/series.md): custom series IDs and titles
- [`immersive-style.conf`](/doc/style.md): appearance of the interface

Documentation that is not about specific config files:
- [Config Syntax](/doc/config.md)
- [Interface](/doc/interface.md)
- [Templates](/doc/templates.md)
- [Card Export](/doc/card-export.md)

### Updating

To update Immersive, delete the script's folder in your `scripts` directory
and replace it with the one from the latest release's script-only ZIP file.
Also check if there were any changes to config entries that you have used in
the [change log](/CHANGELOG.md).

### Quick Start Guide

1. Make sure your mpv install is version 0.33.0 or later.
2. Download the latest full release of Immersive from
   [here](https://github.com/Ben-Kerman/immersive/releases).
3. Unzip its contents into your mpv config directory. Make sure that you are
   not overwriting any existing config files.
4. Open `immersive-targets.conf` in `script-opts` with a text editor of your
   choice (like Notepad++, Sublime Text or vim), and change the values of
   `profile`, `deck`, `note_type`, and the `field:` values so that they match
   your Anki setup.
5. Open `immersive-dictionaries.conf` and set up your dictionaries as
   explained [here](/doc/dictionaries.md). If you are learning Japanese and are
   using the Yomichan version of JMdict, you will most likely only have to change
   `location` so it is set to the path of a directory containing the unzipped
   contents of `jmdict_english.zip` from the Yomichan website.

Your mpv config directory should contain the following files at this point:

```
scripts/
    immersive/
        dict/
        interface/
        systems/
        utility/
        LICENSE
        main.lua
script-opts/
    immersive-dictionaries.conf
    immersive-series.conf
    immersive-style.conf
    immersive-targets.conf
    immersive.conf
```

You can now start mpv and open the main menu of Immersive using `Ctrl`+`a` or
begin creating a card with `a`.


## Troubleshooting

If Immersive crashes at any point (when this happens, the interface suddenly
disappears and all keybindings stop working), open the console using `ˋ`/`~`,
take a screenshot of it and report the issue to me. If you started mpv from
the command line the output there is preferred.


## Suggestions & Reporting Issues

If you have any suggestions for improving Immersive or encounter a problem
while using it please contact me, even if that problem is not understanding
parts of the documentation or how to do something with the script. Outside of
GitHub you can reach me on the [Refold](https://refold.la/) community's
discord servers.
