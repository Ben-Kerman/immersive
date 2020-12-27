# Card Creation

## Subtitle Selection

The card creation process can be started at any time by pressing `a`, which
brings up a menu for selecting subtitles to include on the card. Once the sub
selection menu is active, The selected subtitles are show at the bottom right
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

If no times are set the start will be that start of the first subtitle, the
end will be the end of the last subtitle, and the screenshot will be the frame
that's visible when the export happens.

`k` resets the selection and times. `p` plays the audio that would be exported
with the current selection/times. `d` ends subtitle selection mode and starts
the target word selection. `f` exports the selection immediately without any
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
[Forvo] using `a` (see below).

When you are ready to export the card you can do so using `f`, or `F` if you
want to open the export menu first.


## Forvo Audio

If you hit `a` after selecting a target word, Immersive will load a list of
pronunciations of that word from [Forvo](https://forvo.com/). You will then be
able to choose one using `↑`/`↓`. To play the audio of a pronunciation press
`SPACE`. If it isn't loaded yet it might take a few seconds before it starts
playing. If you want to load all audio files automatically set
`forvo_preload_audio` to `yes` in the [script config](doc/script-config.md).
Once you have selected a pronunciation that you are happy with, confirm it
using `⏎`.


## Export Menu

The export menu allows exporting a card using Anki's 'Add' GUI (`g`) and
adding the export to an existing note.

`A` exports by adding to the most recently added note. `a` does the same, but
allows selecting a note to add to from a list of candidates first. These are
found using the following query: `"deck:<target deck>" "note:<target note
type>" is:new`, so all new cards of the target note type from the target deck.
You can select a note with `↑`/`↓` and `⏎`. If you want to change how notes
are displayed, you can use the target config entry `note_template`:

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
