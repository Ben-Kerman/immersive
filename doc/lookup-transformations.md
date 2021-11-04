# Lookup Transformations

By looking up a word with `transform` from the active line menu or
`lookup_transform` during target selection (both bound to Ctrl+⏎ by default),
transformations are applied to the selected text before searching the
dictionary. All possible results are looked up, including the untransformed
selection.

Transformations must be defined for each dictionary by adding an entry named
`transformations` to its section in `immersive-dicts.conf`. The value of the
entry should be a comma-separated list of IDs, depending on the type of
transformation with an additional parameter in parentheses following
immediately after:

```
transformations=deinflect-japanese,deinflect-migaku(ja.json),kana
```

## Available Transformations

### `deinflect-migaku`

Deinflection based on the language-agnostic format used by the Migaku Dictionary
addon for Anki. The parameter is the path to a deconjugation file and can be either
absolute, or relative to `<mpv config dir>/immersive-data/inflection-tables/`.

The tables (`conjugations.json`) can be taken from the addon's directories or
the Migaku [Mega folder](https://mega.nz/folder/eyYwyIgY#3q4XQ3BhdvkFg9KsPe5avw/folder/bz4ywa5A).

### `deinflect-japanese`

Built-in Japanese-specific deinflection based on the five basic forms (未然形,
連用形, 終止・連体形, 仮定形, 命令形).

The following inflections are supported. The characters enclosed in ｢｣ are
what needs to be selected, everything following is only meant to serve as an
example, e.g. a selection of 迷わ from 迷わず also results in 迷う, even though the
example given is ｢◯わ｣ない:

<table>
	<tr>
		<th>Deinflected</th>
		<th>Inflections</th>
	</tr>
	<tr>
		<th colspan="2">五段</th>
	</tr>
	<tr>
		<td>◯う</td>
		<td>｢◯わ｣ない, ｢◯お｣う, ｢◯い｣ます, ｢◯っ｣て, ｢◯え｣ば</td>
	</tr>
	<tr>
		<td>◯く</td>
		<td>｢◯か｣ない, ｢◯こ｣う, ｢◯き｣ます, ｢◯い｣て, ｢◯け｣ば</td>
	</tr>
	<tr>
		<td>◯ぐ</td>
		<td>｢◯が｣ない, ｢◯ご｣う, ｢◯ぎ｣ます, ｢◯い｣で, ｢◯げ｣ば</td>
	</tr>
	<tr>
		<td>◯す</td>
		<td>｢◯さ｣ない, ｢◯そ｣う, ｢◯し｣ます, ｢◯せ｣ば</td>
	</tr>
	<tr>
		<td>◯つ</td>
		<td>｢◯た｣ない, ｢◯と｣う, ｢◯ち｣ます, ｢◯っ｣て, ｢◯て｣ば</td>
	</tr>
	<tr>
		<td>◯ぬ</td>
		<td>｢◯な｣ない, ｢◯の｣う, ｢◯に｣ます, ｢◯ん｣で, ｢◯ね｣ば</td>
	</tr>
	<tr>
		<td>◯ぶ</td>
		<td>｢◯ば｣ない, ｢◯ぼ｣う, ｢◯び｣ます, ｢◯ん｣で, ｢◯べ｣ば</td>
	</tr>
	<tr>
		<td>◯む</td>
		<td>｢◯ま｣ない, ｢◯も｣う, ｢◯み｣ます, ｢◯ん｣で, ｢◯め｣ば</td>
	</tr>
	<tr>
		<td>◯る</td>
		<td>｢◯ら｣ない, ｢◯ろ｣う, ｢◯り｣ます, ｢◯っ｣て, ｢◯れ｣ば</td>
	</tr>
	<tr>
		<th colspan="2">一段</th>
	</tr>
	<tr>
		<td colspan="2">
			Any stem that could theoretically exist, i.e. all selections
			ending in い・え段 hiragana or non-hiragana (e.g. ｢見｣た or ｢ウケ｣て).
		</td>
	</tr>
	<tr>
		<th colspan="2">サ変</th>
	</tr>
	<tr>
		<td>◯する</td>
		<td>｢◯さ｣ない, ｢◯し｣ます, ｢◯す｣, ｢◯せ｣, ｢◯そ｣う, ｢◯すれ｣ば, ｢◯しろ｣, ｢◯しよ｣, ｢◯せよ｣</td>
	</tr>
	<tr>
		<td>◯ずる</td>
		<td>｢◯じ｣ない, ｢◯ぜ｣ず, ｢◯ずれ｣ば, ｢◯じろ｣, ｢◯じよ｣, ｢◯ぜよ｣</td>
	</tr>
	<tr>
		<th colspan="2">形容詞</th>
	</tr>
	<tr>
		<td>◯い</td>
		<td>｢◯かろ｣う, ｢◯く｣, ｢◯かっ｣た, ｢◯き｣, ｢◯けれ｣ば, ｢◯かれ｣, ｢◯さ｣, ｢◯そう｣</td>
	</tr>
	<tr>
		<th colspan="2">Special Cases</th>
	</tr>
	<tr>
		<td>する</td>
		<td>｢為｣ない, ｢さ｣せる, ｢し｣よう, ｢せ｣ず, ｢為れ｣ば, ｢すれ｣ば, ｢為よ｣, ｢せよ｣, ｢為ろ｣, ｢しろ｣</td>
	</tr>
	<tr>
		<td>来る</td>
		<td>｢来｣ない, ｢來｣ない, ｢こ｣よう, ｢き｣て, ｢来れ｣ば, ｢來れ｣ば, ｢くれ｣ば, ｢来い｣, ｢來い｣, ｢こい｣</td>
	</tr>
	<tr>
		<td>行く</td>
		<td>｢行っ｣た</td>
	</tr>
	<tr>
		<td>逝く</td>
		<td>｢逝っ｣た</td>
	</tr>
	<tr>
		<td>往く</td>
		<td>｢往っ｣た</td>
	</tr>
	<tr>
		<td>いらっしゃる</td>
		<td>いらっしゃい</td>
	</tr>
	<tr>
		<td>おっしゃる</td>
		<td>おっしゃい, 仰っしゃい, 仰しゃい, 仰い, 仰有い</td>
	</tr>
	<tr>
		<td>くださる</td>
		<td>ください, 下ださい, 下さい</td>
	</tr>
	<tr>
		<td>ござる</td>
		<td>ござい, 御座い, ご座い</td>
	</tr>
	<tr>
		<td>なさる</td>
		<td>なさい, 為さい</td>
	</tr>
</table>


### `kana`

Converts any kana in the selection to hiragana and katakana. For example,
あイうエお will result in a lookup of あイうエお, あいうえお, and アイウエオ.
