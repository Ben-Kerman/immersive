# Key Bindings

This is a complete list of key bindings used by Immersive. Unless explicitly
stated all bindings are specific to a single menu. Keys are organized in
groups, with each group specific to one menu.

## Global Bindings

Always available no matter which menu is open, unless there is a binding in
that menu with the same key, in which case that one takes precedence.


| ID                           | Key         | Action                                                |
| ---------------------------- | ----------- | ----------------------------------------------------- |
| `begin_sub_select`           | `a`         | start line selection                                  |
| `open_global_menu`           | `Ctrl+a`    | open the global menu                                  |
| `show_dict_target`           | `Ctrl+A`    | show dictionary/target menu                           |
| `copy_active_line`           | `c`         | copy current subtitle to clipboard                    |
| `toggle_autocopy`            | `C`         | toggle subtitle auto-copy                             |
| `lookup_word`                | `k`         | select and look up word from active subtitle          |
| `export_active_line`         | `K`         | create card from active subtitle, skip line selection |
| `export_active_line_instant` | `Ctrl+k`    | create card from active subtitle, export immediately  |
| `export_active_line_menu`    | `Ctrl+K`    | create card from active subtitle, open export menu    |
| `close_menu`                 | `ESC`       | go back to previous menu                              |
| `clear_menus`                | `Shift+ESC` | close all active menus                                |

---

## `global_menu`

Available in the global menu. (`Ctrl+a`)

| ID             | Key | Action                    |
| -------------- | --- | ------------------------- |
| `toggle_scrot` | `s` | toggle screenshots on/off |

---

## `dict_target_menu`

Available in the dictionary/target menu. (`Ctrl+A`)

| ID                | Key        | Action                              |
| ----------------- | ---------- | ----------------------------------- |
| `prev_target`     | `Ctrl+UP`  | switch to previous Anki target      |
| `next_target`     | `Ctrl+DOWN`| switch to next Anki target          |
| `prev_dict_group` | `Alt+UP`   | switch to previous dictionary group |
| `next_dict_group` | `Alt+DOWN` | switch to next dictionary group     |
| `reimport_dicts`  | `r`        | reimport all cached dictionaries    |

---

## `lookup_active`

Available after opening the active line menu with `k`.

| ID           | Key           | Action                                       |
| ------------ | ------------- | -------------------------------------------- |
| `toggle_raw` | `r`           | toggle sentence substitutions                |
| `exact`      | `ENTER`       | look up selected word                        |
| `partial`    | `Shift+ENTER` | look up words starting with selection        |
| `transform`  | `Ctrl+ENTER`  | look up words after applying transformations |
| `copy`       | `c`           | copy selection to clipboard                  |

---

## `definition_select`

Available while selecting a definition after a dictionary search.

| ID          | Key          | Action                             |
| ----------- | ------------ | ---------------------------------- |
| `prev_dict` | `LEFT`       | switch to previous dictionary      |
| `next_dict` | `RIGHT`      | switch to next dictionary          |
| `add_def`   | `Ctrl+ENTER` | add selected definition            |
| `confirm`   | `ENTER`      | add selected definition and return |

---

## `export_menu`

Available in the export menu.

| ID           | Key | Action                     |
| ------------ | --- | -------------------------- |
| `export`     | `f` | export                     |
| `export_gui` | `g` | export using the 'Add' GUI |

If there are cards to add to in Anki the following bindings become available:

| ID                   | Key | Action                                  |
| -------------------- | --- | --------------------------------------- |
| `export_add`         | `a` | export to existing note, choose which   |
| `export_add_to_last` | `s` | export to existing note, use last added |

---

## `forvo`

Available during Forvo audio selection.

| ID       | Key     | Action                                                    |
| -------- | ------- | --------------------------------------------------------- |
| `play`   | `SPACE` | play currently highlighted audio, fetch if not yet loaded |
| `select` | `ENTER` | confirm selection                                         |

---

## `menu`

Available in any menu, also shown at the top left of the screen.

| ID          | Key | Action                     |
| ----------- | --- | -------------------------- |
| `show_help` | `h` | show help for current menu |

---

## `note_select`

Available when selecting an existing note to export to.

| ID       | Key     | Action                       |
| ---------| ------- | ---------------------------- |
| `confirm`| `ENTER` | confirm selection and export |

---

## `sub_select`

Available during subtitle/timing selection.

| ID                    | Key | Action                                            |
| --------------------- | --- | ------------------------------------------------- |
| `set_start_sub`       | `q` | force start to start of active line               |
| `set_end_sub`         | `e` | force end to end of active line                   |
| `set_start_time_pos`  | `Q` | force start to current time                       |
| `set_end_time_pos`    | `E` | force end to current time                         |
| `set_scrot`           | `s` | take screenshot at current time                   |
| `select_line`         | `a` | select current line                               |
| `toggle_autoselect`   | `A` | toggle automatic selection                        |
| `preview_audio`       | `p` | preview selection audio                           |
| `reset`               | `y` | reset selection                                   |
| `start_target_select` | `d` | end subtitle selection and enter target selection |
| `instant_export`      | `f` | end subtitle selection and export immediately     |
| `instant_export_menu` | `F` | end subtitle selection and open export menu       |

---

## `target_select`

Available during target selection.

| ID                 | Key           | Action                                       |
| ------------------ | ------------- | -------------------------------------------- |
| `lookup_exact`     | `ENTER`       | look up selected word                        |
| `lookup_partial`   | `Shift+ENTER` | look up words starting with selection        |
| `lookup_transform` | `Ctrl+ENTER`  | look up words after applying transformations |
| `lookup_clipboard` | `v`           | look up word from clipboard                  |
| `copy`             | `c`           | copy selection to clipboard                  |
| `add_word_audio`   | `a`           | add Forvo audio for target word              |
| `delete_line`      | `Alt+DEL`     | delete selected line                         |
| `preview_audio`    | `p`           | preview selection audio                      |
| `undo_selection`   | `Alt+BS`      | delete last target word                      |
| `export`           | `f`           | export with selected target words            |
| `export_menu`      | `F`           | export with selected target words using menu |

---

## `line_select`

Available when there is a choice between multiple option, e.g. during target
selection or when picking Forvo audio.

| ID     | Key    | Action                    |
| ------ | ------ | ------------------------- |
| `prev` | `UP`   | select line above current |
| `next` | `DOWN` | select line below current |

---

## `text_select`

Available whenever text is selectable.

| ID              | Key                | Action                                                |
| --------------- | ------------------ | ----------------------------------------------------- |
| `prev_char`     | `LEFT`             | move one character to the left                        |
| `next_char`     | `RIGHT`            | move one character to the right                       |
| `prev_word`     | `Ctrl+LEFT`        | move one word to the left                             |
| `next_word`     | `Ctrl+RIGHT`       | move one word to the right                            |
| `home`          | `HOME`             | move to the start of the text                         |
| `end`           | `END`              | move to the end of the text                           |
| `prev_char_sel` | `Shift+LEFT`       | move selection boundary to the left by one character  |
| `next_char_sel` | `Shift+RIGHT`      | move selection boundary to the right by one character |
| `prev_word_sel` | `Ctrl+Shift+LEFT`  | move selection boundary to the left by one word       |
| `next_word_sel` | `Ctrl+Shift+RIGHT` | move selection boundary to the right by one word      |
| `home_sel`      | `Shift+HOME`       | select from cursor to the start of the text           |
| `end_sel`       | `Shift+END`        | select from cursor to the end of the text             |

If the text can be changed (e.g. during target selection) the following keys
become available:

| ID              | Key        | Action                                                             |
| --------------- | ---------- | ------------------------------------------------------------------ |
| `del_prev_char` | `BS`       | delete character left of the cursor, or selection if there is one  |
| `del_next_char` | `DEL`      | delete character right of the cursor, or selection if there is one |
| `del_prev_word` | `Ctrl+BS`  | delete from cursor to previous word boundary                       |
| `del_next_word` | `Ctrl+DEL` | delete from cursor to next word boundary                           |

---

All key bindings used by Immersive can be changed in `immersive-keys.conf`
(replace `immersive` with your script ID if it differs).

Each section defines the bindings for one of the groups listed above. Global
entries before the first group set the global bindings. The values follow the
same syntax as mpv's `input.conf` and are passed to the player as-is.
Initialization of invalid bindings silently fails, though it's possible to see
an error message on the console (`ˋ`).

---

Example config file:

```
copy_active_line=Ctrl+c

[target_select]
lookup_partial=Ctrl+ENTER

[sub_select]
instant_export=ENTER
```
