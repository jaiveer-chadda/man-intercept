#!/usr/bin/env zsh

export HELPDIR="/usr/share/zsh/5.9/help"

if ! [[ -d "${HELPDIR:a:h}" ]] {
  print -ru2 "${${(%):-%x}:t}: warning: path '${HELPDIR:a:h}' doesn't exist"
  print -ru2 $'\t'" \$HELPDIR ($HELPDIR) is an invalid dir"
}

source "${${(%):-%x}:a:h}/list-all.zsh"

# ——————————————————————————————————————————————————————————————————————————— #

function man help tldr () {
  setopt local_options warn_create_global

  # the name with which this function was called
  #  (usually the same as `$0`, but this is just to make sure)
  local -r funcname="${(%):-%N}"

  # if we were called by `run-help`, then call `man` directly & quit
  #  this prevents the recursion issue that's been bugging me for so long
  if [[ "$funcname" == 'man' ]] && (( $funcstack[(Ie)run-help] )) {
    command man "$@"
    return $?
  }

  local -r error=$'\e[31m'"$funcname"$'\e[m:'

  # if the input is `man all`, or `help -l`, etc., then pass the
  #  job onto one of those dedicated functions
  if [[ "$1" == (-(-list|l)|all) ]] {
    "$funcname::list_all"

  } elif [[ "$funcname" == 'tldr' ]] {
    # otherwise if the `$0` was `tldr`, then I assume that I actually meant
    #  `tldr`, so run that command as-is
    command tldr --color=always "$@"

  } else {
    # finally, if the input wasn't `man/help all` and `$0` wasn't `tldr`,
    #  pass it on to the main function, which handles both `man` and `help`
    man::main "$@"
  }

  return $?
}

# ——————————————————————————————————————————————————————————————————————————— #

function man::main() {
  setopt local_options local_traps warn_create_global

  # if we background one of the functions, make sure that we don't
  #  keep trying to check if there's another option
  local -ri 10 SIGTSTP=$(( 128 + signals[(i)TSTP] - 1 ))
  local -r pager=${=PAGER:-less}

  # —— Setup & Input Parsing —————————————————————————————————————————— #

  local -l section
  # check if the first input is a valid section, and that there's another input
  if [[ "$1:l" == [0-9n](|cc|g|m|p(m|cap)|ssl|t(cl|iff|k|ype)|x) && "$2" ]] {
    section="$1"; shift
  }

  if ! (( $# )) {
    echo "$error must enter a command" >&2
    return 1
  }

  local page="$1"

  # —— run-help ——————————————————————————————————————————————————————— #

  # if a section was specified, then it can't be `run-help`
  if [[ -n "$HELPDIR" && -z "$section" ]] {
    if   [[ "$page" == '.' ]] { page='dot'   } \
    elif [[ "$page" == ':' ]] { page='colon' }

    if [[ -r "$HELPDIR/$page" && "$page" != 'compctl' ]] {
      ${=pager} "$HELPDIR/$page"
      if (( $? == 0 || $? == SIGTSTP )) return 0
    } else {
      # go fish
    }
  }

  # —— man ———————————————————————————————————————————————————————————— #

  # if a section was explicitly passed, assume u wanted `man`
  # nb: `$section` is unquoted here, so we don't have issues w it being empty
  command man $section "$page" 2>/dev/null
  if (( $? == 0 || $? == SIGTSTP )) return 0

  # —— tldr ——————————————————————————————————————————————————————————— #

  command tldr --color=always "$page" 2>/dev/null
  if (( $? == 0 || $? == SIGTSTP )) return 0

  # —— No Matches ————————————————————————————————————————————————————— #

  # finally, if none of the commands had an entry, throw an error
  echo -nE "$error no entry for '$page'" >&2

  # if they passed a section, use a different error message
  if [[ "$section" ]] { echo -E " in section $section" >&2
  } else { echo $'.\n'"Checked 'man', 'run-help', and 'tldr'" >&2; }

  return 1
}

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore TSTP
