# Dictionaries

Immersive currently supports two dictionary formats:
[Yomichan](https://foosoft.net/projects/yomichan/) and
[Migaku](https://ankiweb.net/shared/info/1655992655). Both need to be
configured slightly differently.

The first time it is accessed, the dictionary is imported, which can take some
time. After that it is loaded into memory until the active mpv instance is
closed. New instances of Immersive can load a cached version of the dictionary
from disk which will take less time. By default, dictionaries are only loaded
once they are used, however setting the [script config](/doc/script-config.md)
option `preload_dictionaries` to `yes`/`true` will load all dictionaries every
time mpv is started. This will cause Immersive (but not mpv) to be
unresponsive for several seconds on startup.

Every dictionary has its own config section. Each one also has an exporter,
which is responsible for turning its data into a format that is usable by
Anki. Options that configure the exporter must be prefixed with `export:` in
the config file, e.g. `export:template`. Exporters make heavy use of
[templates](/doc/templates.md).

## Common Options

- `type`: The type of the dictionary. Allowed values are `yomichan` and `migaku`.
- `location`: The location of the dictionary files. This needs to be an absolute
  path, so one starting with `/` on Unix or `C:\`/`D:\`/etc. on Windows.
- `preload`: If set to `yes`/`true`, always preload this dictionary,
  regardless of the script setting `preload_dictionaries`. If set to
  `no`/`false`, never preload this dictionary. If unset (default), use the
  script setting.
- `exporter`: The exporter used for generating the `{{definitions}}` template
  field on the Anki card. Currently only `default` is available for either
  dictionary type, which is also used if `exporter` is not set.
- `quick_def_template`: template used for rendering the definitions shown in mpv
- `export:<exporter option>`: config entries used by the exporter.
- `transformations`: Transformations to apply to the selected text when
  invoking lookup with Ctrl+⏎.  
  See [here](/doc/lookup-transformations.md) for more details.


## Yomichan

Yomichan dictionaries need to be unzipped into a directory first, which is
then used as the value of `location`. For example, if you downloaded
`jmdict_english.zip` from the Yomichan website and extracted it to a folder in
your home directory, the location entry should look something like this:
`location=/home/<user name>/jmdict_english` (Unix) or `location=C:\Users\<user
name>\jmdict_english` (Windows), with `jmdict_english` being the folder that
contains the file `index.json` and the term/tag banks of the dictionary.

The dictionary config entry `insert_cjk_breaks` inserts a soft line break
after each of the following fullwidth characters before rendering the
definition that is shown inside mpv: `。、，！？；：`. This can be useful for
monolingual Japanese dictionaries that have definitions which otherwise
wouldn't fit on the screen.

`quick_def_template` for Yomichan has the following template variables:

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>quick_def_template</code></th>
	</tr>
	<tr>
		<td><code>readings</code></td>
		<td><code>list</code></td>
		<td>all readings of the dictionary entry</td>
	<tr>
		<td><code>variants</code></td>
		<td><code>list</code></td>
		<td>all variants of writing the word</td>
	<tr>
		<td><code>definitions</code></td>
		<td><code>list</code></td>
		<td>all definitions of the entry</td>
	</tr>
</table>

Its default value is:

```
{{readings:::・}}{{variants:【:】:・}}: {{definitions:::; }}
```

### Exporter

The default Yomichan exporter can be configured with the following options:

- `digits`: Replacement digits for the definition number. The value should
  contain exactly ten characters. For example set this to `０１２３４５６７８９` if you
  want to use fullwidth digits. Unset by default, in which case regular ASCII
  numerals (`0123456789`) are used.
- `reading_template`: Template used for displaying each reading and its
  variants. Default:

```
{{reading}}{{variants:【:】:・}}
```

- `definition_template`: Template for each separate definition in an entry.

```
{{tags:<span style="font-size\: 0.8em">:</span><br>:, }}{{num}}. {{keywords:::; }}
```

- `template`: Template for the final exported entry.

```
{{readings[1]}}:{{readings[2:] (:):　}}<br>{{definitions:::<br>}}
```

- `use_single_template`: If set to `yes`/`true`, use `single_template` for
  rendering entries that only have a single definition.
  Enabled by default.
- `single_template`: Default:

```
{{readings[1]}}:{{readings[2:] (:):　}} {{keywords:::; }}
```

All defaults are set so that entries of the Yomichan version of JMdict are
exported in a format somewhat similar to Jisho.org.

---

The Yomichan exporter works as follows:

1. Group all variants of the word by reading. These will be rendered using
   `reading_template`.

2. Go through the definitions of the dictionary entry one by one. If the tags
   for the definition are different from those of the previous one, insert them
   into the template data. Render the definition using `definition_template`,
   with the tags (if present), the keywords and the number. If it is set, the
   digits of the number are taken from `digits`.

3. Render `template` using the readings and definitions from steps 1. and 2.
   Alternatively, if `use_single_template` is `true`, render `single_template`
   using the readings and the keywords from the only definition. The result of
   either of these is what will be exported to Anki.

Template overview:

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>reading_template</code></th>
	</tr>
	<tr>
		<td><code>reading</code></td>
		<td><code>single</code></td>
		<td>the reading itself; usually hiragana but sometimes katakana</td>
	</tr>
	<tr>
		<td><code>variants</code></td>
		<td><code>list</code></td>
		<td>all variants of writing the word with this reading</td>
	</tr>
	<tr>
		<th colspan="3"><code>definition_template</code></th>
	</tr>
	<tr>
		<td><code>tags</code></td>
		<td><code>list</code></td>
		<td>all tags for the dictionary entry</td>
	<tr>
		<td><code>num</code></td>
		<td><code>single</code></td>
		<td>the number of the definition, with the digits taken from <code>digits</code></td>
	<tr>
		<td><code>keywords</code></td>
		<td><code>list</code></td>
		<td>the keywords for the definition</td>
	<tr>
		<th colspan="3"><code>template</code></th>
	</tr>
	<tr>
		<td><code>readings</code></td>
		<td><code>list</code></td>
		<td>all readings as generated from <code>reading_template</code></td>
	</tr>
	<tr>
		<td><code>definitions</code></td>
		<td><code>list</code></td>
		<td>all readings as generated from <code>definition_template</code></td>
	</tr>
	<tr>
		<th colspan="3"><code>single_template</code></th>
	</tr>
	<tr>
		<td><code>readings</code></td>
		<td><code>list</code></td>
		<td>same as for <code>template</code></td>
	</tr>
	<tr>
		<td><code>keywords</code></td>
		<td><code>list</code></td>
		<td>keywords of the single definition</td>
	</tr>
</table>


## Migaku

For Migaku dictionaries `location` is simply the path of the dictionary's JSON
file, so something like this: `location=/home/<user
name>/Migaku_Dictionary.json` (Unix) or `location=C:\Users\<user
name>\Migaku_Dictionary.json` (Windows).

`quick_def_template` for Migaku has the following template variables:

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>quick_def_template</code></th>
	</tr>
	<tr>
		<td><code>terms</code></td>
		<td><code>list</code></td>
		<td>all terms associated with the definition</td>
	<tr>
		<td><code>altterms</code></td>
		<td><code>list</code></td>
		<td>alternative versions of the terms above</td>
	<tr>
		<td><code>definitions</code></td>
		<td><code>list</code></td>
		<td>all definitions of the entry</td>
	</tr>
</table>

Its default value is:

```
{{definitions}}
```

### Exporter

The Migaku format is much simpler than Yomichan's, and so is its exporter. It
uses the template provided in the config option `export:template` directly on
the dictionary data.

<table>
	<tr>
		<th>Variable</th>
		<th>Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<th colspan="3"><code>template</code></th>
	</tr>
	<tr>
		<td><code>terms</code></td>
		<td><code>list</code></td>
		<td>terms associated with the definition</td>
	</tr>
	<tr>
		<td><code>altterms</code></td>
		<td><code>list</code></td>
		<td>alternative versions of the terms above</td>
	</tr>
	<tr>
		<td><code>definition</code></td>
		<td><code>single</code></td>
		<td>the definition itself; it should already be in an Anki-friendly format</td>
	</tr>
	<tr>
		<td><code>pronunciations</code></td>
		<td><code>list</code></td>
		<td>pronunciations associated with the definition</td>
	</tr>
	<tr>
		<td><code>positions</code></td>
		<td><code>list</code></td>
		<td>parts of speech associated with the definition</td>
	</tr>
	<tr>
		<td><code>examples</code></td>
		<td><code>list</code></td>
		<td>example sentences</td>
	</tr>
</table>

All list entries aside from `terms` (and possibly `altterms`) will most likely
only contain a single item.

The default value of `export:template` is:

```
{{terms[1]}}{{terms[2:] (:):, }}:<br>
{{altterms::<br>:, }}{{pronunciations::<br>:, }}{{positions::<br>:, }}
{{definition}}
{{examples:::, }}
```
