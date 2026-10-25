#!/usr/bin/env zsh

# /opt/homebrew/Cellar/zsh/5.9/share/zsh/functions/run-help

# ——————————————————————————————————————————————————————————————————————————— #

# note: all comments beginning with uppercase letters are default comments,
#       and comments beginning with lowercase letters are _my_ comments

# ——————————————————————————————————————————————————————————————————————————— #

#
# Figure out where to get the best help, and get it.
#
# Install this function by placing it in your FPATH and then
# adding to your .zshrc the lines:
#        unalias run-help
#        autoload -Uz run-help
#
function -T run_help_ () {

  # —— Setup & Constants ——————————————————————————————————————————————————— #

  emulate -RL zsh
  setopt local_options warn_create_global warn_nested_var

  local -r HELPDIR="${HELPDIR:-/opt/homebrew/Cellar/zsh/5.9/share/zsh/help}"

  # —— Set & Normalise Arg ————————————————————————————————————————————————— #

  local cmd="$1"

  if [[ "$cmd" == '.' ]] cmd='dot'
  if [[ "$cmd" == ':' ]] cmd='colon'

  # —— Check $HELPDIR / List Files ————————————————————————————————————————— #

  # Check whether Util/helpfiles has been used to generate zsh help
  if [[ $# -eq 0 || "$cmd" == '-l' ]] {

    # check that `$HELPDIR` is a valid dir
    if ! [[ -d "$HELPDIR" ]] {
      echo 'There is no list of special help topics available at this time.'
      echo -E "\$HELPDIR ('$HELPDIR') is an invalid dir"
      return 1
    }

    # print a list of available commands
    echo $'Here is a list of topics for which special help is available:\n'
    print -rc "$HELPDIR"/*(:t)

    return 0
  }

  # —— Normal Lookup ——————————————————————————————————————————————————————— #

  if [[ -n "${HELPDIR:-}" && -r "$HELPDIR/$1" && "$cmd" != 'compctl' ]] {
    ${=PAGER:-less} "$HELPDIR/$cmd"
    return $?
  }

  # ———————————————————————————————————————————————————————————————————————— #
  # —— Not in $HELPDIR ————————————————————————————————————————————————————— #

  # No zsh help; use "whence" to figure out where else we might look

  local noalias
  # find every instance of `$cmd`
  local -a places=( "${(@f)$( whence -va "$cmd" )}" )

  # if we couldn't find `$cmd`, and the unquoted version of `$cmd` is different
  #  then try unquoting it, and trying again
  if [[ "$places" == *"not found"* && "$cmd" != "${(Q)cmd}" ]] {
    # Different when unquoted, so try stripping quotes.
    places=( "${(@f)$( whence -va "${(Q)cmd}" )}" )

    # if it worked this time, then set all arguments to their unquoted forms
    if (( $#places )) set -- "${(Q)@}"

    # Quotation is significant to aliases, so suppress lookup.
    noalias=1
  }

  # ———————————————————————————————————————————————————————————————————————— #

  local what
  local -i 10 i=0 didman=0

  {
    while (( i++ < $#places )) {

      what="$places[i]"
      if [[ -n "$noalias" && "$what" == *' is an alias '* ]] continue

      print -r "$what"

      case "$what" {
        ( *( is an alias for (noglob|nocorrect))* ) {

          if [[ "${what[(w)7]:t}" != "${what[(w)1]}" ]] {
            run_help_orig_cmd="${what[(w)1]}" run-help "${what[(w)7]:t}"
          }
        } ;;

        ( *( is an alias)* ) {
          if [[ "${what[(w)6]:t}" != "${what[(w)1]}" ]] {
            run_help_orig_cmd="${what[(w)1]}" run-help "${what[(w)6]:t}"
          }
        } ;;

        ( *( is a * function) ) { #
          case ${what[(w)1]} {
            ( comp*    ) man zshcompsys ;;
            ( zf*      ) man zshftpsys  ;;
            ( run-help ) man zshcontrib ;;
            ( *        ) functions ${what[(w)1]} | ${=PAGER:-less};;
          }
        } ;;

        ( *( is a * builtin) ) { #
          case "${what[(w)1]}" {
            ( compctl                          ) man zshcompctl ;;
            ( comp*                            ) man zshcompwid ;;
            ( vared | zle | bindkey            ) man zshzle     ;;
            ( *setopt                          ) man zshoptions ;;
            ( (set|get|)cap                    ) ;& # fallthrough
            ( clone                            ) ;& # fallthrough
            ( (mk|rm)dir | sync | mv | rm | ln ) ;& # fallthrough
            ( sched                            ) ;& # fallthrough
            ( echot[ci] | sched | stat         ) ;& # fallthrough
            ( z(socket|style|prof|pty|tcp)     ) man zshmodules  ;;
            ( zftp                             ) man zshftpsys   ;;
            ( *                                ) man zshbuiltins ;;
          }
        } ;;

        ( *( is hashed to *)     ) man "${what[(w)-1]:t}" ;;
        ( *( is a reserved word) ) man zshmisc ;;

        ( * )
          if ! (( didman++ )) {
            if { whence "run-help-$1:t" >/dev/null; } {
              local cmd_args

              getln cmd_args
              print -z "$cmd_args"

              cmd_args=( ${(z)cmd_args} )

              # Discard the command itself & everything before it.
              shift $cmd_args[(i)${run_help_orig_cmd:-$1}] cmd_args \
                || return

              # Discard options, parameter assignments & paths.
              cmd_args=( ${(@)cmd_args:#([-+]*|*=*|*/*|\~*)} )

              eval "run-help-$1:t ${(@q)cmd_args}"

            } else {
              POSIXLY_CORRECT=1 man $@:t
            }
          }
        ;;
      }

      # ————————————————————————————————————————————————————————————————————— #

      if (( i < $#places && ! didman )) {

        print -nP '%SPress any key for more help or q to quit%s'
        read -k what

        if [[ "$what" != $'\n' ]] echo
        if [[ "$what" == [qQ]  ]] break
      }

    }

  } always {
    unset run_help_orig_cmd
  }
}

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore noalias nocorrect echot sched vared getln
# spell:ignoreRegExp /\bz\w+\b/g
