# Key Bindings

This is a complete list of key bindings used by Immersive. Unless explicitly
stated all bindings are specific to a single menu. Keys are organized in
groups, with each specific to one menu.

## Global Bindings

Always available no matter which menu is open, unless there is a binding in
that menu with the same key, in which case that one takes precedence.

| ID                           | Key         | Action                                                |
| ---------------------------- | ----------- | ----------------------------------------------------- |
| `begin_sub_select`           | `a`         | Start line selection                                  |
| `open_global_menu`           | `Ctrl+a`    | Open the global menu                                  |
| `copy_active_line`           | `c`         | Copy current subtitle to clipboard                    |
| `toggle_autocopy`            | `C`         | Toggle subtitle auto-copy                             |
| `lookup_word`                | `k`         | Select and look up word from active subtitle          |
| `export_active_line`         | `K`         | Create card from active subtitle, skip line selection |
| `export_active_line_instant` | `Ctrl+k`    | Create card from active subtitle, export immediately  |
| `close_menu`                 | `ESC`       | Go back to previous menu                              |
| `clear_menus`                | `Shift+ESC` | Close all active menus                                |

---

## `global_menu`

Available from the global menu. (`Ctrl+a`)

| ID               | Key        | Action                             |
| ---------------- | ---------- | ---------------------------------- |
| `prev_target`    | `Ctrl+UP`  | Switch to the previous Anki target |
| `next_target`    | `Ctrl+DOWN`| Switch to the next Anki target     |
| `prev_dict`      | `Alt+UP`   | Switch to the previous dictionary  |
| `next_dict`      | `Alt+DOWN` | Switch to the next dictionary      |
| `reimport_dicts` | `r`        | Reimport all imported dictionaries |

---

## `lookup_active`

Available after opening the active line menu with `k`.

| ID        | Key           | Action                                |
| --------- | ------------- | ------------------------------------- |
| `exact`   | `ENTER`       | Look up selected word                 |
| `partial` | `Shift+ENTER` | Look up words starting with selection |
| `copy`    | `c`           | Copy selection to clipboard           |


---

## `definition_select`

Available while selecting a definition after a dictionary search.

| ID         | Key      | Action                  |
| ---------- | -------- | ----------------------- |
| `confirm`  | `ENTER`  | Use selected definition |

---

## `export_menu`

Available in the export menu.

| ID           | Key | Action                     |
| ------------ | --- | -------------------------- |
| `export`     | `f` | Export                     |
| `export_gui` | `g` | Export using the 'Add' GUI |

If there are cards to add to in Anki the following bindings become available:

| ID                 | Key | Action                                  |
| ------------------ | --- | --------------------------------------- |
| export_add         | a   | Export to existing note, choose which   |
| export_add_to_last | s   | Export to existing note, use last added |

---

## `forvo`

Available during Forvo audio selection.

| ID     | Key   | Action                                                    |
| ------ | ----- | --------------------------------------------------------- |
| play   | SPACE | Play currently highlighted audio, fetch if not yet loaded |
| select | ENTER | Confirm selection                                         |

---

## `menu`

Available in any menu, also shown at the top left of the screen.

| ID          | Key | Action                     |
| ----------- | --- | -------------------------- |
| `show_help` | `h` | Show help for current menu |

---

## `note_select`

Available when selecting an existing note to export to.

| ID       | Key     | Action                       |
| ---------| ------- | ---------------------------- |
| `confirm`| `ENTER` | Confirm selection and export |

---

## `sub_select`

Available during subtitle/timing selection.

| ID                    | Key | Action                                        |
| --------------------- | --- | --------------------------------------------- |
| `set_start_sub`       | `q` | Force start to start of active line           |
| `set_end_sub`         | `e` | Force end to end of active line               |
| `set_start_time_pos`  | `Q` | Force start to current time                   |
| `set_end_time_pos`    | `E` | Force end to current time                     |
| `set_scrot`           | `s` | Take screenshot at current time               |
| `select_line`         | `a` | Select current line                           |
| `toggle_autoselect`   | `A` | Toggle automatic selection                    |
| `preview_audio`       | `p` | Preview selection audio                       |
| `reset`               | `k` | Reset selection                               |
| `start_target_select` | `d` | End line selection and enter target selection |
| `instant_export`      | `f` | End line selection and export immediately     |

---

## `target_select`

Available during target selection.

| ID                 | Key           | Action                                       |
| ------------------ | ------------- | -------------------------------------------- |
| `lookup_exact`     | `ENTER`       | Look up selected word                        |
| `lookup_partial`   | `Shift+ENTER` | Look up words starting with selection        |
| `lookup_clipboard` | `v`           | Look up word from clipboard                  |
| `add_word_audio`   | `a`           | Add Forvo audio for target word              |
| `delete_line`      | `DEL`         | Delete selected line                         |
| `export`           | `f`           | Export with selected target words            |
| `export_menu`      | `F`           | Export with selected target words using menu |

---

## `line_select`

Available when there is a choice between multiple option, e.g. during target
selection or when picking Forvo audio.

| ID     | Key    | Action                    |
| ------ | ------ | ------------------------- |
| `prev` | `UP`   | Select line above current |
| `next` | `DOWN` | Select line below current |

---

## `text_select`

Available whenever text is selectable.

| ID              | Key                | Action                                              |
| --------------- | ------------------ | --------------------------------------------------- |
| `prev_char`     | `LEFT`             | Move one character to the left                      |
| `next_char`     | `RIGHT`            | Move one character to the right                     |
| `prev_word`     | `Ctrl+LEFT`        | Move one word to the left                           |
| `next_word`     | `Ctrl+RIGHT`       | Move one word to the right                          |
| `home`          | `HOME`             | Move to the start of the text                       |
| `end`           | `END`              | Move to the end of the text                         |
| `prev_char_sel` | `Shift+LEFT`       | Move selection boundary to the left by a character  |
| `next_char_sel` | `Shift+RIGHT`      | Move selection boundary to the right by a character |
| `prev_word_sel` | `Ctrl+Shift+LEFT`  | Move selection boundary to the left by a word       |
| `next_word_sel` | `Ctrl+Shift+RIGHT` | Move selection boundary to the right by a word      |
| `home_sel`      | `Shift+HOME`       | Select from cursor to the start of the text         |
| `end_sel`       | `Shift+END`        | Select from cursor to the end of the text           |

---

All key bindings used by Immersive can be changed in `immersive-keys.conf`
(replace `immersive` with your script ID if it differs).

Each section defines the bindings for one of the groups listed above. Global
entries before the first group set the global bindings. The values follow the
same syntax as mpv's `input.conf` and are passed to the player as-is.
Initialization of invalid bindings silently fails, though it's possible to see
an error message in the console (`ˋ`).

---

Example config file:

```
reimport_dicts=Ctrl+r

[target_select]
lookup_partial=Ctrl+ENTER

[sub_select]
instant_export=ENTER
```
