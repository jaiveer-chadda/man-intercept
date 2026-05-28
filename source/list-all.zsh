#!/usr/bin/env zsh

# ——————————————————————————————————————————————————————————————————————————— #

man::list_all  () { echo 'not implemented' >&2; return 1           ; }
help::list_all () { man::make_grid 2 $( run-help -l | tail -n +3 ) ; }
tldr::list_all () { man::make_grid 1 $( command tldr -l          ) ; }

# ——————————————————————————————————————————————————————————————————————————— #

man::make_grid() {
  local -ri 10 column_spacing="$1"; shift
  local -ra all_cmds=( "${(@o)@}" )  # sort the cmds alphabetically

  local -i 10 max_len=-1
  local cmd; for cmd ("${(@)all_cmds}") if (( $#cmd > max_len )) max_len=$#cmd

  # number of columns = screen_width / ( max_len + column_spacing )
  local -ri 10 column_width=$(( max_len + column_spacing ))
  local -ri 10 column_count=$(( COLUMNS / column_width   ))

  local -i 10 i
  for i in {1.."$#"}; {
    # print each command, lef-padded by $column_width
    echo -n "${(r:$column_width:)all_cmds[i]}"
    # if we reach the end of the column, start a new line
    if ! (( i % column_count )) echo
  }

  # this is here in case there aren't exactly `$column_count` columns,
  #  in which case an extra newline will need to be printed
  if (( i % column_count )) echo
}

# ——————————————————————————————————————————————————————————————————————————— #
