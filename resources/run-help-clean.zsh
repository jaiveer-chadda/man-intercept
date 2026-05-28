#!/usr/bin/env zsh

# /opt/homebrew/Cellar/zsh/5.9/share/zsh/functions/run-help

function -T _run-help () {
  emulate -RL zsh

  local -r HELPDIR="${HELPDIR:-/opt/homebrew/Cellar/zsh/5.9/share/zsh/help}"

  if [[ "$1" == '.' ]] 1='dot'
  if [[ "$1" == ':' ]] 1='colon'

  # ———————————————————————————————————————————————————————————————————————— #

  if [[ $# -eq 0 || "$1" == '-l' ]] {
    if [[ -d "$HELPDIR" ]] {
      echo $'Here is a list of topics for which special help is available:\n'
      print -rc "$HELPDIR"/*(:t)
    } else {
      echo 'There is no list of special help topics available at this time.'
    }
    return 0

  } elif [[ -n "${HELPDIR:-}" && -r "$HELPDIR/$1" && "$1" != compctl ]] {
    ${=PAGER:-more} "$HELPDIR/$1"
    return $?
  }

  # ———————————————————————————————————————————————————————————————————————— #

  local what noalias newline=$'\n'
  local -i 10 i=0 didman=0

  local -a places=( "${(@f)$( builtin whence -va "$1" )}" )

  if [[ $places = *"not found"* && $1 != ${(Q)1} ]] {
    places=( "${(@f)$( builtin whence -va "${(Q)1}" )}" )

    if (( $#places )) set -- "${(Q)@}"
    noalias=1
  }

  # ———————————————————————————————————————————————————————————————————————— #

  {
    while (( i++ < $#places )) {

      what="$places[i]"
      if [[ -n "$noalias" && "$what" = *" is an alias "* ]] continue

      builtin print -r "$what"

      case "$what" in
        ( *( is an alias for (noglob|nocorrect))* )
          if [[ "${what[(w)7]:t}" != "${what[(w)1]}" ]] {
            run_help_orig_cmd="${what[(w)1]}" run-help "${what[(w)7]:t}"
          }
        ;;

        ( *( is an alias)* )
          if [[ "${what[(w)6]:t}" != "${what[(w)1]}" ]] {
            run_help_orig_cmd="${what[(w)1]}" run-help "${what[(w)6]:t}"
          }
        ;;

        ( *( is a * function) )
          case "${what[(w)1]}" in
            ( comp*    ) man zshcompsys ;;
            ( zf*      ) man zshftpsys  ;;
            ( run-help ) man zshcontrib ;;
            ( *        ) builtin functions ${what[(w)1]} | ${=PAGER:-more} ;;
          esac
        ;;

        (*( is a * builtin))
          case "${what[(w)1]}" in
            ( compctl                                ) man zshcompctl ;;
            ( comp*                                  ) man zshcompwid ;;
            ( bindkey | vared | zle                  ) man zshzle     ;;
            ( *setopt                                ) man zshoptions ;;
            ( cap | getcap | setcap                  ) ;&
            ( clone                                  ) ;&
            ( ln | mkdir | mv | rm | rmdir | sync    ) ;&
            ( sched                                  ) ;&
            ( echotc | echoti | sched | stat         ) man zshmodules  ;;
            ( zprof | zpty | zsocket | zstyle | ztcp ) man zshmodules  ;;
            ( zftp                                   ) man zshftpsys   ;;
            ( *                                      ) man zshbuiltins ;;
          esac
        ;;

        ( *( is hashed to *)     ) man "${what[(w)-1]:t}" ;;
        ( *( is a reserved word) ) man zshmisc ;;

        (*)
          if ! (( didman++ )) {
            if { whence "run-help-${1:t}" >/dev/null; } {
              local cmd_args

              builtin getln cmd_args
              builtin print -z "$cmd_args"

              cmd_args=( ${(z)cmd_args} )

              shift $cmd_args[(i)${run_help_orig_cmd:-$1}] cmd_args \
                || return

              cmd_args=( ${(@)cmd_args:#([-+]*|*=*|*/*|\~*)} )
              eval "run-help-${1:t} ${(@q)cmd_args}"

            } else {
              POSIXLY_CORRECT=1 man $@:t
            }
          }
        ;;
      esac

      if (( i < $#places && ! didman )) {

        builtin print -nP '%SPress any key for more help or q to quit%s'
        builtin read -k what

        if [[ "$what" != "$newline" ]] echo
        if [[ "$what" ==  [qQ]      ]] break
      }
    }
  } always {
    unset run_help_orig_cmd
  }
}

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore noalias nocorrect echotc echoti sched vared getln
# spell:ignoreRegExp /\bz\w+\b/g
