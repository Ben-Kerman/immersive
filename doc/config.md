# Configuration Syntax

Immersive's config files are composed of sections. Each section begins with a
header consisting of a name enclosed in `[` and `]`. A section contains
entries in the form of key-value pairs, one per line. The format is
`key=value`. These are interpreted as follows: First, any leading space is
trimmed, so the key of `    key=value` is is `key`, not `    key`. Then
anything before the `=` becomes the key, anything after it becomes the value.
In particular, quotation marks do too, so the value in `key="value"` is
`"value"` and not `value`. Any whitespace after the key is also stripped, but
this is not the case for the value. So the following entry is parsed as
`key` and `   value   `: `  key  =   value   `. For example:

```
[Section A]
key1=value 1
key2=value 2

[Section B]
Key I=Value B
```

Any entries before the first section are considered to be global to that
config file. How these are interpreted depends on what is being configured.

If there are multiple entries with the same key in a section the value will
be that of the last one.

By setting the value to `[[`, the entries value can span across multiple
lines. In this case leading and trailing spaces are removed from the opening
token (`[[`). The multiline entry's value continues until the closing token
`]]` is encountered on a line. For example the following entry will have the
lines `foo` and `bar` as its value:

```
key=[[
foo
bar
]]
```

If there should be a line containing `]]`, a string can be added between the
`[` of the opening token, which then has to be present in the closing token as
well, like this:

```
key=[foo[
these are part of the value:
]]
] foo]
]foo  ]
→ this is the last line of the value ←
]foo]
```

Any line starting with a `#` is a comment and will be ignored, unless it is
part of a multiline entry.

---

A more complete example config:

```
global_key=global entry

# this is ignored
# as=is this

this line is invalid (missing =)

[section]
entry_1=value
entry_2=[[
line 1
# this part of entry_2
line 3
]]
entry_3=
# entry_3 is empty

# [ignored, not a section]

[another_section]
key=value
```
