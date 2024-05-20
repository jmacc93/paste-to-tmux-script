#!/usr/bin/fish

# used state:
# * send_eof
# * send_target
# * cmd_prefix_string (defaults to !)
# * post_paste_cmd


set state_path_base ~/.paste-to-tmux
set spb $state_path_base

set terminal_bin "alacritty"
set short_delay_ms 3000
set long_delay_ms 5000
set verylong_delay_ms 10000

if not test -e $state_path_base
  mkdir $state_path_base
end



function starts_with
  set start "$argv[1]"
  set str   "$argv[2]"
  string match --entire --regex "^$start.+" "$str" >/dev/null
  return $status
end

function show_notification
  set msg $argv[1]
  set delay $argv[2]

  notify-send -t $delay $msg
end

function copy_to_clipboard
  echo "$argv" | xclip -selection c -i
end

alias copy "copy_to_clipboard"
alias co   "copy_to_clipboard"
alias c    "copy_to_clipboard"

function shown
  set msg "$argv[1..]"
  show_notification $msg $short_delay_ms
end

alias s "shown"

function shownc
  shown $argv
  copy_to_clipboard $argv
end

alias sc "shownc"

function list_sessions
  shownc "$(tmux list-sessions)"
  # echo -n "$(tmux list-sessions)" | xclip -selection c -i
  # notify-send -t $shortDelayMs "$(tmux list-sessions)"
end

alias li "list_sessions"
alias l  "list_sessions"

function kill_sessions
  for session in $argv
    shown "Killing tmux session $session"
    set res (tmux kill-session -t "$session" 2>&1)
    if test $status -ne 0
      show_notification "Couldn't kill target, reason: \"$res\"" $long_delay_ms
    end
  end
end

alias ki "kill_sessions"
alias k  "kill_sessions"

function make_session_if_not_open
  set session_name $argv[1]

  tmux has-session -t $session_name 2>&1
  if test $status -ne 0
    set res (tmux new-session -d -s $session_name)
    if test $status -ne 0
      show_notification "Couldn't make new session \"$session_name\", reason: \"$res\"" $long_delay_ms
    end
    show_notification "Started session $session_name" $short_delay_ms
  end
end


function switch_target
  set session_name $argv[1]
  set_state send_target $session_name
  notify-send -t $short_delay_ms "Set paste target to $session_name"
end
alias swit "switch_target"
alias sw   "switch_target"
alias s    "switch_target"

function open_target
  set session_name $argv[1]
  make_session_if_not_open $session_name
  $terminal_bin
end
alias op "open_target"
alias o  "open_target"

alias start_target "make_session_if_not_open"
alias st "make_session_if_not_open"
alias s  "make_session_if_not_open"

function open_target
  set session_name $argv[1]
  make_session_if_not_open $session_name
  $terminal_bin -T "tmux $session_name" -e tmux attach-session -t $session_name
end
alias op "open_target"
alias o  "open_target"


function send_enter_key_to
  set session_name $argv[1]
  set res (tmux send-keys -t $session_name Enter 2>&1)
  if test $status -ne 0
    show_notification "Couldn't send enter key to \"$session_name\", reason: \"$res\"" $long_delay_ms
    return 1
  end
end

function auto_send_enter_key
  if test (get_state send_enter true) = true
    set res (send_enter_key_to $argv)
    if test $status -ne 0
      show_notification "Couldn't send Enter to \"$session_name\", reason: \"$res\"" $long_delay_ms
      return 1
    end
  end
end

function send_eof_to
  set session_name $argv[1]
  set res (tmux send-keys -t $session_name C-D 2>&1)
  if test $status -ne 0
    show_notification "Couldn't send EOF to \"$session_name\", reason: \"$res\"" $long_delay_ms
    return 1
  end
end

function send_key_to
  set session_name $argv[1]
  set key_names    $argv[2..]
  echo "session $session_name"
  echo "keys $key_names"
  set res (tmux send-keys -t $session_name $key_names 2>&1)
  if test $status -ne 0
    show_notification "Couldn't send $key_names to \"$session_name\", reason: \"$res\"" $long_delay_ms
    return 1
  end
end

function send_ctrlc_to; send_key_to $argv[1] C-C; end
function ctrlc
  set session_name $argv[1]
  if test -n session_name; set session_name "$send_target"; end
  send_key_to "$session_name" C-C
end
function ctrld
  set session_name $argv[1]
  if test -n session_name; set session_name "$send_target"; end
  send_key_to "$session_name" C-D
end
alias c-d "ctrld"
alias c-c "ctrlc"


function set_paste_buffer_to
  set text_to_paste $argv[1]
  # set paste buffer
  set res (tmux set-buffer -b paste "$text_to_paste" 2>&1)
  if test $status -ne 0
    show_notification "Couldn't set paste buffer to \"$text_to_paste\", reason: \"$res\"" $long_delay_ms
    return 1
  end
end

function paste_to_session
  set session_name $argv[1]
  set res (tmux paste-buffer -t $session_name -b paste 2>&1)
  if test $status -ne 0
    show_notification "Couldn't paste to \"$session_name\", reason: \"$res\"" $long_delay_ms
    return 1
  end
end

function paste_to
  set session_name $argv[1]
  set text_to_paste $argv[2]
  
  make_session_if_not_open $session_name "noexit"
  
  # set paste buffer
  set_paste_buffer_to "$text_to_paste"
  if test $status -ne 0; return 1; end
  
  # paste to session
  paste_to_session $session_name
  if test $status -ne 0; return 2; end
  
  # eval post paste cmd -- defaults to sending enter key (if set to do so)
  eval $(get_state post_paste_cmd "auto_send_enter_key $session_name")
  if test $status -ne 0; return 3; end
  
  # optionally send eof
  if test (get_state send_eof false) = true
    # send_eof_to $session_name
    send_key_to $session_name C-D
    if test $status -ne 0; return 4; end
  end
  
  if test (get_state report_sent true) != false
    notify-send -t $short_delay_ms "$session_name << $text_to_paste"
  end
end


###### state loading, saving

function set_state
  set name $argv[1]
  set value $argv[2]
  set --global $name $value
  echo "$value" > "$state_path_base/$name"
end

function get_state
  set name $argv[1]
  set default $argv[2] # optional
  if set --query $name
    echo "$$name"
  else
    echo "$default"
  end
end

function unset_state
  set name $argv[1]
  set --global --erase $name
  rm "$state_path_base/$name"
end

# load all state
for f in (ls $state_path_base/*)
  set name (basename $f)
  set --global $name (cat $f | string trim)
end

# set default state items if they aren't defined
if not set --query send_eof
  set_state send_eof false
end

if not set --query send_target
  set_state send_target asdf
end




###### target and payload normalization

set target  $argv[1]
set payload $argv[2]

# if no arg target given, use the state target
if test -z "$target"
  set target "$send_target"
end

# Normalize payload
if test -z "$payload"
  set payload "$(xclip -selection c -o | string trim)"
end


###### main action:

# eval here mode
if test "$target" = "--" # interpret everything here
  if test "$argv[1]" = "--"
    set payload "$argv[2..]"
  else # `target == -- must` have been loaded from state, so we all the args open
    set payload "$argv[1..]"
  end
  eval "$payload"
  if test $status -ne 0
    show_notification "Eval failed!" $short_delay_ms
    exit 1
  end
  exit 0
end
# otherwise,

# pasted eval here mode
set pfs (get_state cmd_prefix_string !)
if starts_with $pfs "$payload"
  set payload "$(string sub --start (math 1 + (string length $pfs)) "$payload")"
  eval "$payload"
  if test $status -ne 0
    show_notification "Eval failed!" $short_delay_ms
    exit 1
  end
  exit 0
end
# otherwise,

# send to tmux mode
paste_to $target "$payload"
if test $status -ne 0; exit 1; end
