# Interface

Immersive's interface consists of menus. These are text overlays that are
drawn on top of the video. If you opened a menu on top of another one (e.g. by
pressing `Ctrl+A` to switch the active dictionary before looking up a word),
you can go back to the previous menu at any time by hitting `ESC`. `Shift+ESC`
clears all active menus. The data of each menu will be preserved until it is
closed with (`Shift+`)`ESC` or by performing an action that closes it
automatically, such as exporting a card.

Internally menus are kept track of with a stack. Every new menu is pushed on
top of the previous one (which is then hidden) and `ESC` removes the last added
menu and reactivates the one before/below. `Shift+ESC` empties the stack.

Each menu has a togglable overview of available key bindings at the top left.
The key bindings listed there are specific to that menu, unless their
description ends in "(global)". Some menus also include a list of information
relevant to the menu at the bottom left.


## Global Menu

The global menu can always be opened using `Ctrl+a`. It contains an overview
of Immersive's global key bindings, as well as information on the series
ID/title and on whether autocopy and screenshots are enabled.


## Dictionary/Target Menu

This menu can be opened with `Ctrl+A`. It allows switching between
dictionaries and Anki targets and also shows which one is currently active for
both. If you have selected the wrong dictionary/target, it's possible to
change it here even if you are about to look up a word/export a card.


## Active Subtitle Lookup

By pressing `k`, you can bring up a menu that allows looking up words from the
current line outside of the card creation process. It functions identically to
the target word selection menu.


## Card Creation Menus

see [this document](/doc/card-export.md)


## Messages

Messages are displayed at the top right of the screen. White text signifies an
informational message, yellow text a warning, red text an error and text that
is bright red and bold a fatal error in the script (which should never happen,
of course).

All messages visible in this interface (and a few others not relevant to the
user) are also printed to the mpv console (`ˋ`) as well as to the system
console/terminal if mpv is connected to one using the mpv's internal messaging
system.
