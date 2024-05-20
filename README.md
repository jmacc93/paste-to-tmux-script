# paste-to-tmux-script
Bash script to paste stuff from the system clipboard to a tmux target

Dependencies:

* `fish` -- apt: `fish`; pacman: `pacman`
* `notify-send` -- apt: `libnotify-bin`
* `xclip` -- apt: `xclip`
* `tmux` -- apt: `tmux`

Put `paste-to-tmux.fish` into your `~/bin` (assuming that bin is on your `PATH`)

Change the first nonempty line (the `set terminal_bin alacritty` line) in the script to reference your preferred terminal

Note: on use it creates the directory `~/.paste-to-tmux` which stores the script' current state

---

If you're using xbindkeys, and you want a hotkey, put the following in your `~/.xbindkeysrc.scm`:
```lisp
(xbindkey '(control apostrophe) "paste-to-tmux.fish
```
Or your `~/.xbindkeysrc`
```
"paste-to-tmux.fish
  control + apostrophe
```

---

This version (version 2) works like:

* Every file in `~/.paste-to-tmux/` represents a variable the script creates
* The target is:
  * The first argument to the script, if given
  * Otherwise is the send_target variable (set in the `~/.paste-to-tmux/send_target` file
* The payload is:
  * The remaining script arguments if given
  * Otherwise, is the clipboard's contents
* If the target is `--` or the payload starts with `!`, the payload is `eval`d in the script as a fish source code string
* Otherwise, the payload is pasted into the target tmux session, and an enter (and optionally an eof) is sent to tmux

---

The usage-flow is like:
* Set the target by copying `!sw some_target_name` into your clipboard and running `paste-to-tmux.fish` with no arguments, which uses the shortcut function `sw` to set the target
* Copy some text and send it to `some_target_name` by calling `paste-to-tmux,fish` without arguments
