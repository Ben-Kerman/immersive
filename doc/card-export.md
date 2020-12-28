# Card Creation

## Subtitle Selection

The card creation process can be started at any time by pressing `a`, which
brings up a menu for selecting subtitles to include on the card. Once the sub
selection menu is active, the selected subtitles are show at the bottom right
of the screen. Information on timing is at the bottom left, and a help menu
listing all available key bindings is at the top left.

Pressing `a` again adds the current subtitle to the selection. By default all
subtitles are automatically added to the selection. This can be toggled with
`A`, or disabled by default in the script config.

`q` and `e` can be used to set the timing of the exported audio clip manually
to the start or end of the currently visible subtitle. `Q` and `E` do the same
but using the current playback time instead. `s` sets the screenshot time to
the current frame. Pressing the timing keys again while a time is set resets
the corresponding time if the keypress would have set it to the same value.
E.g. if the screenshot time is set to `15:00.000` and the current timestamp in
the video is also `15:00.000`, pressing `s` will unset the screenshot time.

If no times are set, the clip will begin at the start of the first subtitle
and end at the end of the last subtitle. The screenshot will be the frame
that's visible when the export happens.

`k` resets the selection and times. `p` plays the audio that would be exported
with the current selection/times. `d` ends the subtitle selection and begins
target word selection. `f` exports the selection immediately without any
target words. `F` does the same but opens the [export menu](#export-menu)
first.


## Single Subtitle Export

By pressing `K`, line selection is skipped and the target word selection is
started immediately with the current subtitle. `Ctrl+k` skips the entirety of
the card creation process and instantly exports a card of the active subtitle
including an audio clip and screenshot.


## Target Word Selection

In this part of the export process you can select one or more target words. By
default you are limited to one in accordance with AJATT/MIA/Refold practices,
but it's possible to increase this limit (or remove it entirely) in the
[script config](doc/script-config.md).

The word can be selected with the usual key combinations for selecting text:
(`Ctrl+`)(`⇧+`)`←`/`→`. `↑` and `↓` switch between subtitles and `DEL` removes
the current one from the selection. Once you have chosen some text you can
look up any dictionary entries that match it exactly using `⏎` and any entries
starting with it using `⇧+⏎`. If the search has any results, a new menu will
open that allows you to choose one of them with `↑`/`↓` and `⏎`.

After selecting a definition, the word will be shown at the bottom right of
the screen. If you want, you can then add pronunciation audio from
Forvo using `a` (see below).

When you are ready to export the card you can do so using `f`, or `F` if you
want to open the export menu first.


## Forvo Audio

If you hit `a` after selecting a target word, Immersive will load a list of
pronunciations of that word from [Forvo](https://forvo.com/). You will then be
able to choose one using `↑`/`↓`. To play the audio of a pronunciation press
`SPACE`. If it isn't loaded yet it might take a few seconds before it starts
playing. If you want to load all audio files automatically set
`forvo_preload_audio` to `yes` in the [script config](script-config.md).
Once you have selected a pronunciation that you are happy with, confirm it
using `⏎`.

If your target language is not Japanese you will have to change `forvo_language`
in the script config. The language code can be found on the Forvo website, for
example on [this page](https://forvo.com/word/%E6%97%A5%E6%9C%AC/) at the right of:

> 日本 pronunciation in Japanese \[**ja**\]


## Export Menu

The export menu allows exporting a card using Anki's 'Add' GUI (`g`) and
adding the export to an existing note.

The candidates for adding are found using the following query: `"deck:<target
deck>" "note:<target note type>" is:new`, so all new cards of the target note
type from the target deck.

`A` exports by adding to the most recently added candidate. `a` allows
selecting a note from the list of candidates first. You can pick a note with
`↑`/`↓` and `⏎`. If you want to change how notes are displayed, you can use
the target config entry `note_template`:

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>note_template</code></th>
	</tr>
	<tr>
		<td><code>type</code></td>
		<td><code>single</code></td>
		<td>The note type</td>
	</tr>
	<tr>
		<td><code>id</code></td>
		<td><code>single</code></td>
		<td>The note ID</td>
	</tr>
	<tr>
		<td><code>tags</code></td>
		<td><code>list</code></td>
		<td>The tags of the note</td>
	</tr>
	<tr>
		<td><code>field_&lt;field name&gt;</code></td>
		<td><code>single</code></td>
		<td>
			One such variable is provided for each field of the note and will
			be rendered as the content of that field
		</td>
	</tr>
</table>


## Exporting

Once you initiate the export, Immersive will first validate your Anki target
config and only proceed if that is successful. After that, the audio clip and
screenshot are encoded, as is the Forvo audio if there is any and it is
configured to be.

Then the following template is applied to each field of the target note type,
as configured by the `field:...` entries of the target config:

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>field:&lt;field name&gt;</code></th>
	</tr>
	<tr>
		<td><code>word</code></td>
		<td><code>single</code></td>
		<td>first target word</td>
	</tr>
	<tr>
		<td><code>sentences</code></td>
		<td><code>list</code></td>
		<td>subtitles selected for export</td>
	</tr>
	<tr>
		<td><code>definitions</code></td>
		<td><code>single</code></td>
		<td>target word definitions as exported by the dictionary</td>
	</tr>
	<tr>
		<td><code>audio</code></td>
		<td><code>single</code></td>
		<td>audio clip as an Anki sound tag</td>
	</tr>
	<tr>
		<td><code>image</code></td>
		<td><code>single</code></td>
		<td>screenshot as an Anki/HTML image tag</td>
	</tr>
	<tr>
		<td><code>word_audio</code></td>
		<td><code>single</code></td>
		<td>pronunciation file as an Anki sound tag</td>
	</tr>
	<tr>
		<td><code>audio_file</code></td>
		<td><code>single</code></td>
		<td>filename of the audio clip</td>
	</tr>
	<tr>
		<td><code>image_file</code></td>
		<td><code>single</code></td>
		<td>filename of the screenshot</td>
	</tr>
	<tr>
		<td><code>word_audio_file</code></td>
		<td><code>single</code></td>
		<td>filename of the pronunciation audio</td>
	</tr>
	<tr>
		<td><code>path</code></td>
		<td><code>single</code></td>
		<td>path to the file mpv is currently playing (excluding the filename)</td>
	</tr>
	<tr>
		<td><code>filename</code></td>
		<td><code>single</code></td>
		<td>filename of the file mpv is currently playing</td>
	</tr>
	<tr>
		<td><code>series_id</code></td>
		<td><code>single</code></td>
		<td>series ID as explained <a href="doc/series.md">here</a></td>
	</tr>
	<tr>
		<td><code>series_title</code></td>
		<td><code>single</code></td>
		<td>series title as explained <a href="doc/series.md">here</a></td>
	</tr>
	<tr>
		<td><code>start</code></td>
		<td><code>single</code></td>
		<td>start time of the audio formatted as [HH:][MM:]SS</td>
	</tr>
	<tr>
		<td><code>end</code></td>
		<td><code>single</code></td>
		<td>end time of the audio formatted as [HH:][MM:]SS</td>
	</tr>
	<tr>
		<td><code>start_ms</code></td>
		<td><code>single</code></td>
		<td>start time of the audio formatted as [HH:][MM:]SS.mmm</td>
	</tr>
	<tr>
		<td><code>end_ms</code></td>
		<td><code>single</code></td>
		<td>end time of the audio formatted as [HH:][MM:]SS.mmm</td>
	</tr>
	<tr>
		<td><code>start_seconds</code></td>
		<td><code>single</code></td>
		<td>start time of the audio in seconds</td>
	</tr>
	<tr>
		<td><code>end_seconds</code></td>
		<td><code>single</code></td>
		<td>end time of the audio in seconds</td>
	</tr>
	<tr>
		<td><code>start_seconds_ms</code></td>
		<td><code>single</code></td>
		<td>start time of the audio in seconds and milliseconds</td>
	</tr>
	<tr>
		<td><code>end_seconds_ms</code></td>
		<td><code>single</code></td>
		<td>end time of the audio in seconds and milliseconds</td>
	</tr>
</table>

The card is exported with the resulting fields, as well as the tags configured
for the target.

### Substitutions

The variables `definitions` and `sentences` can be filtered through
substitutions before being exported. These are defined in the entries
`definition_substitutions` and `sentence_substitutions` of the target config.

Both those entries expect a multiline value, with each line representing a
substitution, e.g. this is what the default value of `sentence_substitutions`
would look like in a config file:

```
sentence_substitutions=[[
<（.-）
<%(.-%)
]]
```

Each line is split at the first `<`. Everything to the left of it becomes the
replacement and everything to the right becomes the pattern. If you want to
use a `<` in the replacement string, you can escape it as `\<`. Other common
escapes like `\n` or `\t` work as well, both in the replacement and pattern.

The pattern is a [Lua pattern](https://www.lua.org/manual/5.1/manual.html#5.4.1),
which means that the following characters need to be escaped by placing a `%`
before them if you want to use them literally: `^$()%.[]*+-?`.

All occurrences of the pattern are replaced by the replacement string, or
deleted if the string is empty (i.e. the `<` is the first character of the
substitution definition). The patterns are applied one after the other in the
order they are defined in.

The default value of `sentence_substitutions` contains the patterns `（.-）` and
`%(.-%)`, both with an empty replacement. They delete character names and
kanji readings from Japanese subtitles. If you want to disable them, simply
put this line in the global section of `immersive-targets.conf`:

```
sentence_substitutions=
```
