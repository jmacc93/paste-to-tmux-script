#!/bin/bash

terminalBin=terminator

thisExeName="$0"

shortDelayMs=3000
longDelayMs=5000
veryLongDelayMs=10000

function showAndExit {
  notify-send -t $longDelayMs "$(fold -s -w 32 <(echo "Error $1"))"
  if [[ $2 != noexit ]]; then
    exit 1
  fi
}

function makeSessionIfNotOpen { # $1 is session name to make, $2 is whether to exit or not (noexit = dont exit)
  tmux has-session -t $1 || {
    {
      res=$(tmux new-session -d -s $1 2>&1) 
    } || {
      showAndExit "Couldn't make new session \"$1\", reason: \"$res\"" $2
    }
    notify-send -t $shortDelayMs "Started session $1"
  } || {
    showAndExit "Couldn't make new session" $2
  }
}

function makeAllSessionsIfNotOpen {
  for makeTarget in $@; do
    makeSessionIfNotOpen $makeTarget noexit
  done
}

function killSession { # $1 is session name to kill, $2 is whether to exit or not (noexit = dont exit)
  notify-send -t $shortDelayMs "Killing paste target $1"
  {
    res=$(tmux kill-session -t "$1" 2>&1)
  } || {
    showAndExit "Couldn't kill target, reason: \"$res\"" $2
  }
}

function pasteTo {
  makeSessionIfNotOpen $1
  
  {
    res=$(tmux set-buffer -b paste "$2" 2>&1) 
  } || {
    showAndExit "Couldn't set paste buffer to \"$2\", reason: \"$res\""
  }

  {
    res=$(tmux paste-buffer -t $1 -b paste 2>&1)
  } || {
    showAndExit "Couldn't paste buffer to \"$1\", reason: \"$res\""
  }

  {
    res=$(tmux send-keys -t $1 Enter 2>&1) 
  } || {
    showAndExit "Couldn't send enter key to \"$1\", reason: \"$res\""
  }

  notify-send -t $shortDelayMs "$1 << $2"

}

function secondWord { echo $2; }

function thirdWord { echo $3; }

if [[ $1 != "" ]]; then
  copiedText="$1"
else
  copiedText="$(xclip -selection c -o)"
fi

{
  pasteTarget="$(cat ~/.tmux-paste-target-session)"
} || {
  pasteTarget=asdf
}

if [[ "$copiedText" == @@* ]]; then 
  doCopy=true
  copiedText="${copiedText:1}"
fi

case "$copiedText" in 
  
  @test* ) # eg: $st asdf # <- switch to asdf
    notify-send -t $shortDelayMs "testing 123"
    exit 0
  ;;
  
  
  @sw* ) ;& # SWitch
  @st* ) # Switch Target eg: $st asdf # <- switch to asdf
    newTarget="$(secondWord $copiedText)"
    
    existMsg="$(tmux has-session -t $newTarget &> /dev/null && echo "" || echo "which doesn't exist")"
    echo "$newTarget" > ~/.tmux-paste-target-session
    notify-send -t $shortDelayMs "Switched paste target to $newTarget $existMsg"
    
    makeSwitchArgument="$(thirdWord $copiedText)"
    if [[ $makeSwitchArgument == m* ]]; then
      makeAllSessionsIfNotOpen "$newTarget"
    fi
    if [ $doCopy ]; then
      xclip -selection c -i <(echo -n "$newTarget")
    fi
    exit 0
  ;;
  
  @ne* ) ;& # NEw
  @ma* )    # MAke each of the given
    makeAllSessionsIfNotOpen ${copiedText#* }
    exit 0
  ;;
  
  @op* ) ;& # OPen
  @tm* ) # TMux eg: $tm asdf # <- shows asdf, or: $tm # <- open active paste target session in tmux
    showTarget="$(secondWord $copiedText)"
    if [[ $showTarget == "" ]]; then
      showTarget="$pasteTarget"
    fi
    makeSessionIfNotOpen $showTarget
    $terminalBin -e "tmux attach-session -t $showTarget" -T "tmux $showTarget"
    exit 0
  ;;
  
  @li* ) ;& # LIst
  @ls* ) # list sessions
    if [ $doCopy ]; then
      xclip -selection c -i <(echo -n "$(tmux list-sessions)")
    fi
    notify-send -t $shortDelayMs "$(tmux list-sessions)"
    exit 0
  ;;
  
  @te* ) ;& # TEmporary
  @ra* ) ;& # RAndom
  @rn* ) # RNg: new random session
    name="$RANDOM$RANDOM"
    if [ $doCopy ]; then
      xclip -selection c -i <(echo -n "$name")
    fi
    makeTarget="$(secondWord $copiedText)"
    if [[ makeTarget == m* ]]; then
      $thisExeName "@st $name make"
    else
      $thisExeName "@st $name"
    fi
    exit 0
  ;;
  
  @sh* ) ;& # SHow current target session
  @cu* ) #    show CUrrent target session
    if [ $doCopy ]; then
      xclip -selection c -i <(echo -n "$pasteTarget")
    fi
    notify-send -t $shortDelayMs "Current paste target: $pasteTarget"
    exit 0
  ;;
  
  @ki* ) ;& # KIll
  @ex* ) # EXit current session
    if [[ $(secondWord $copiedText) != "" ]]; then # kill each word as a session name following @kill
      for killTarget in ${copiedText#* }; do
        killSession $killTarget noexit
      done
    else # kill active paste target session
      killSession $pasteTarget
    fi
    exit 0
  ;;
  
  @ru* ) ;& # RUn command
  @do* )    # DO command
    command="${copiedText#* }"
    res="$(bash -c "$command 2>&1")"
    if [ $doCopy ]; then
      xclip -selection c -i <(echo -n "$res")
      notify-send -t $shortDelayMs "Output copied"
    else
      notify-send -t $veryLongDelayMs "$res"
    fi
    exit 0
  ;;
  
  @* ) # unregnized command
    notify-send -t $shortDelayMs "Unrecognized command in \"$copiedText\""
    exit 0
  ;;
  
esac
# else:

pasteTo "$pasteTarget" "$copiedText"

