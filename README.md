# paste-to-tmux-script
Bash script to paste stuff from the system clipboard to a tmux target

Dependencies:

* `notify-send` -- apt: `libnotify-bin`
* `xclip` -- apt: `xclip`
* `tmux` -- apt: `tmux`

Put `paste-to-tmux.sh` into your `~/bin` (assuming that bin is on your `PATH`)

Change the first nonempty line (the `terminalBin=terminator` line) in the script to reference your preferred terminal

Note: on use it creates the file `~/.tmux-paste-target-session` which stores the target tmux session that will be pasted to

---

If you're using xbindkeys, and you want a hotkey, put the following in your `~/.xbindkeysrc.scm`:
```lisp
(xbindkey '(control apostrophe) "paste-to-tmux.sh")
```
Or your `~/.xbindkeysrc`
```
"paste-to-tmux.sh"
  control + apostrophe
```

---

Line that starts with `@` are "command lines" and execute various other actions. Here are the possible actions:

* `@test` -- Shows a test notification
* `@sw` short for `@switch`, or `@st` -- Switch target to the first argument. eg: `@swi asdf` switches to session `asdf`
* `@ma` short for `@make`, or `@ne` short for `@new` -- Make all of the arguments as sessions. eg: `@make asdf zxcv` makes `asdf` and `zxcv` sessions
* `@op` short for `@open`, or `@tm` short for `@tmux` -- Open tmux to the current target session
* `@li` short for `@list`, or `@ls` short for `@lst` -- List all open tmux sessions
* `@ra` short for `@random`, or `@rn` short for `@rng`, or `@te` short for `@temporary` -- Target a random string (for temporary sessions)
* `@sh` short for `@show`, or `@cu` short for `@current` -- Display the current paste target session
* `@ki` short for `@kill`, or `@ex` short for `@exit` -- Stops the paste target session or all of the argument sessions. eg: `@ki asdf zxcv` kills `asdf`, and `zxcv`
* `@ru` short for `@run`, or `@do` -- Execute the remainder of the line in bash. eg: `@run cd ~ && ls` runs `cd ~ && ls` in bash

Some of the commands have a copy-to-clipboard variant starting with an additional `@`, which copy their results to the clipboard:

* `@@sw` -- Copies the new target name
* `@@li` -- Copies the result of `tmux list-sessions`
* `@@t1` -- Copies the new random session's name
* `@@cu` -- Copies the current paste target name
* `@@do` -- Copies the captured stdout of the program