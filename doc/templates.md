# Templates

Immersive includes a simple integrated text templating engine.


## Basic Syntax

A template consists of regular text, with substitutions between `{{`/`}}`. In
addition to the regular control character escapes (`\a`, `\b`, `\e`, `\f`,
`\n`, `\r`, `\t`, `\v`), `\{` can be escaped outside of substitution tags.
Inside a tag `\}` and `\:`must be escaped, as well as `\[` depending on the
part of the tag it is in.

The most basic substitution tag is `{{<variable name>}}`. So given a variable
named `foo` with the content `rem ips` the template `Lo{{foo}}um` would render
as `Lorem ipsum`.

Variables can either be single (text) values or lists of values. The names of
list variables are usually plurals. A list variable is simply rendered as all
its elements concatenated together. The template `ab{{list}}gh` would become
`abcdefgh` if the elements of `list` are (`c`, `d`, `e`, `f`).

For the following examples these variables will be used: `text`=`Lorem
ipsum` and `list`=(`A1`, `B2`, `C3`, `D4`).


## Indexing

Both types of variables can be limited using an indexing operator, either a
single index: `{{list[2]}}` → `B2` / `{{text[4]}}` → `e`; or a range of
indices: `{{list[2:3]}}` → `B2C3` / `{{text[1:4]}}` → `Lore`. If either index
is left out (e.g. `[2:]` or `[:4]`), it is assumed to be 1 for the first and
the length of the text/list for the second. Indices can be negative, in which
case they go backwards from the end of the variable: `{{list[:-2]}}` →
`A1B2C3` / `{{text[3:-3]}}` → `rem ips`. If the indices given result in an
empty substitution the variable is effectively ignored. Before the index (or
prefix) is encountered, `[` has to be escaped as `\[` if it is part of the
variable name.


## Affixes & Separators

List substitutions can have a prefix, a suffix, and a separator:
`{{list:pre[:]suf: | }}` → `pre[A1 | B2 | C3 | D4]suf`. Thus `:` has to be
escaped at any position inside a tag. If both index and affixes/a separator
are used the tag looks like this: `{{list[2:3]pre[:]suf: | }}` → `pre[B2 |
C3]suf`.

The prefix and suffix can be left empty if the substitution should only have a
separator: `{{list::: \: }}` → `A1 : B2 : C3 : D4`; and the suffix and
separator can be left out if not needed: `{{list:List\:}}` → `List:A1B2C3D4`.
