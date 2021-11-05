# Series Identification

Immersive generates the filenames for the screenshot and audio clip based on a
series ID. This is generally automatically generated, however sometimes the
generation algorithm results in garbage. In that case, or if you want to
change the ID of your series for other reasons, you can configure it in
`immersive-series.conf`.

Each section in the series config represents a series. Global entries are
ignored. The section name is used as the series ID. There is one required
entry, `keywords`, which is used to identify series as described below, and
one optional entry, `title`, which is a human-readable title that can be used
as a template variable on Anki card templates. If `title` is set to
`{{media_title}}`, the mpv property `media-title` will be used instead, or the
auto-generated default title if the video doesn't have a `media-title`.

The entry `keywords` is first converted to lower case, then split on every
space. Each resulting word is then searched for in the name of the currently
opened video file, which is also converted to lower case. If all words are
found, the ID (and title, if set) are used for the current series. If there
are multiple sections that could match a filename the one first defined is
used.

---

Example config section:

```
# streamed video; something similar should work for any platform youtube-dl supports
[youtube]
title={{media_title}}
keywords=youtu be

# local video file
[kaguya-sama]
title=かぐや様は告らせたい
keywords=kaguya sama kokurasetai
```

For the first (pseudo-)series, media files will be named something like
`youtube-####.ext` and the title will be the same as the video title on
YouTube. For the second series the ID is `kaguya-sama` and files will follow
the pattern `kaguya-sama-####.ext`.
