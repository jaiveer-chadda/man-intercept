#!/usr/bin/env zsh

# ——————————————————————————————————————————————————————————————————————————— #

function compile-run-help () {

  setopt local_options warn_create_global extended_glob

  local -r NL=$'\n'

  # if we're directly executing this file, rather than running the function,
  #  then it should be considered to be in debug mode
  local -i 2 debug=0
  if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel:shfunc' && ! -v NODEBUG ]] debug=1

  # ———————————————————————————————————————————————————————————————————————— #

  local -r output_dir="${XDG_STATE_HOME:-${HOME?}/.local/state}/run-man-help"
  local -r output_file="$output_dir/zshbuiltins-parsed"

  local -ri 10 col_adj=${1:--2}
  local -ri 10 width=$(( COLUMNS + col_adj ))

  # ———————————————————————————————————————————————————————————————————————— #

  if [[ $debug -ne 1      # if we're not in debugging mode
    && -r "$output_file"  # the output file exists, & is readable
    #                     # and the output width hasn't changed since last time
    && "${${"$(< "$output_file" )"%%$NL*}#\#}" -eq $width
  ]] return 0  # then the file is already compiled - there's nothing to be done

  # ———————————————————————————————————————————————————————————————————————— #

  # how much the name and description are indented by
  local -ri 10 name_pad=5 desc_pad=12

  # LESS_COLUMNS
  local -r page="${"$(
    MANWIDTH=$width command man 1 zshbuiltins
    echo -n __END__
  )"%__END__}"

  local -ra lines=( "${(@f)page}" )
  local -ri 10 ln_count=$#lines

  local name desc
  local -a names
  local -A mapping
  local -i 10 i=0 tail

  # ———————————————————————————————————————————————————————————————————————— #

  setopt rematch_pcre

  local MATCH
  local -i 10 MBEGIN MEND

  # set `tail` to `i`, then increment it by 1, then check that `i` is in range
  while (( ( tail = i++ ) <= ln_count )) {

    # 1ˢᵗ line should be blank (or just spaces)
    if [[ "$lines[++tail]" != ' '# ]] continue

    # 2ⁿᵈ line should start with 5 spaces
    if [[ "$lines[++tail]" != ' '(#c$name_pad)[^' ']* ]] continue

    # 3ʳᵈ line should start with 12 spaces
    if [[ "$lines[++tail]" != ' '(#c$desc_pad)[^' ']* ]] {
      # if it doesn't, there are two other possibilities:
      #  1. the whole section fits on one line
      #      e.g. `     chdir  Same as cd.`
      #     in this case, this ^ char will be `$desc_pad` characters after the
      #      start of the line, and will be followed by a newline
      #
      #  2. there are multiple definitions for the command
      #      e.g. `     jobs [ -dlprs ] [ job ... ]`
      #           `     jobs -Z string             `
      #           `            Lists...            `
      #     note that each of these definitions can have different names, so
      #      all of them need to be checked
      #
      # in both cases, the definition(s) will be preceeded by `\n`
      #   but this has already been checked by the 1st `if` statement

      (( tail-- )) # roll `tail` back by one, so we can check the line again

      # —————————————————————————————————————————————— #

      # To check the first possibility (the whole section fits on one line):
      #
      #  - firstly, check that the next line is a blank line
      #     - this is by far the easiest check, so its done first
      #
      #  - start the regex check by removing the backspaced characters from
      #    the test string `//?$'\b'`
      #
      #  - then make sure there are exactly `$name_pad` spaces at the start
      #    of the line `^[ ]{$name_pad}`
      #     - we know this to be true, but we have to check it again anyways
      #
      #  - then a variable-length name `[^ ]+`
      #  - then at least one space `[ ]+`
      #  - then the description `[^ ]`
      #
      #  - however, _before_ the description, check that we've used exactly
      #    `$desc_pad` chars since the start of the line `(?<=^.{$desc_pad})`
      #     - this is the reason we had to remove the backspaces,
      #        - because it would have turned out being farr too complicated
      #          to figure out a regex that could multiply the name length
      #          by 3, then check whether it still matched
      #
      #  - I rly couldn't figure out a way to do this w/o backtracking :(
      #     - since I don't know how long the name or name-desc padding are
      #       going to be individually (only their sum), I need to backtrack
      #     - and that's even without handling the backspace characters,
      #       which would likely be a whole nother nightmare
      if [[ "${lines[tail+1]}" == ' '#
        &&  "${lines[tail  ]//?$'\b'}"
          =~ "^[ ]{$name_pad}[^ ]+[ ]+(?<=^.{$desc_pad})[^ ]"
      ]] {
        # success!
        name="${${lines[tail]/# ##}%% *}"
        desc="${lines[tail]/# ##$name ##}"

        mapping[$name]="$desc"
        continue
      }

      # —————————————————————————————————————————————— #

      # if it wasn't the first possibility, then check if there are multiple
      #  definitions for the command
      if [[ "$lines[tail]" != ' '(#c$name_pad)[^' ']* ]] continue
      # if there aren't, then continue immediately

      # otherwise, keep looking through lines until we find a description line
      until [[ "$lines[++tail]" == ' '(#c$desc_pad)[^' ']* ]] {
        # if we find a NL before a description line, go back down to `while`
        if [[ "$lines[tail]" == ' '# ]] continue 2
      }
      # now that we're on a description line,
      #  we can continue parsing like normal
    }

    # —————————————————————————————————————————————— #

    # until we reach the next name
    #  (check that the current line is empty, and the next line is a name line)
    until [[ "$lines[tail++]" == ' '# \
      && "$lines[tail]" == ' '(#c$name_pad)[^' ']* ]] {}

    (( tail-- )) # we've hit the next name, go back one line

    # —————————————————————————————————————————————— #

    name="${${${lines[i+1]/# ##}%% *}//?$'\b'}"
    desc="${(F)lines[i+1,tail]//%$'\n'}"

    mapping[$name]="$desc"

    # —————————————————————————————————————————————— #

    # we actually shouldn't need to go back another line, but since `i++` is
    #  being called in the `while` condition, we have to counteract it by 1
    (( i = tail - 1 ))
    # at this point, `i` is pointing at the blank line before a name.
    #  by the first `if` condition of the next iteration, it'll be at a name
  }

  # stringify the `$mapping` assoc
  #  and replace the long `\C-H` escape sequence with the shorter `\b`
  local -r output="${"$( typeset -Ap0 mapping )"//\\C-H/\b}"

  mkdir -p "$output_dir"

  # set the 1st line of `$output_file` to `$width`, creating the file if needed
  # then copy the `$mapping` assoc into the rest of the file
  >| "$output_file" <<< "#$width$NL$output"

  # print out the output file if we're debugging
  # if (( debug )) echo -E - "$(< "$output_file" )"
}

# ——————————————————————————————————————————————————————————————————————————— #

if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]] compile-run-help
