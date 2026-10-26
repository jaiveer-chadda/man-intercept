#!/usr/bin/env zsh

# ——————————————————————————————————————————————————————————————————————————— #

function fmt-run-help () {

  setopt local_options warn_create_global extended_glob

  # how much the name and description are indented by
  local -ri 10 name_pad=5
  local -ri 10 desc_pad=12

  # LESS_COLUMNS
  local -r cmd='popd'
  local -r page="${"$(
    MANWIDTH=$(( COLUMNS - 2 )) command man 1 zshbuiltins
    echo -n __END__
  )"%__END__}"

  local -a lines=( "${(@f)page}" )
  local -ri 10 ln_count=$#lines
  # local -ri 10 ln_count=100

  local section
  local -a buffer=() words=()
  local -i 10 i=0 head tail

  ;: DEBUG :; local -ra colours=( 1 3 2 6 4 5 )

  # ———————————————————————————————————————————————————————————————————————— #

  setopt rematch_pcre

  local MATCH
  local -i 10 MBEGIN MEND

  while (( i++ <= ln_count )) {

    (( head = i, tail = i - 1 ))
    buffer=()

    # —————————————————————————————————————————————— #

    # 1ˢᵗ line should be blank (or just spaces)
    if [[ "$lines[++tail]" != ' '# ]] continue
    (( head++ )) # we don't care about the blank line, so increment past it

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

      # # To check the first possibility (the whole section fits on one line):
      # #
      # #  - firstly, check that the next line is a blank line
      # #     - this is by far the easiest check, so its done first
      # #
      # #  - start the regex check by removing the backspaced characters from
      # #    the test string `//?$'\b'`
      # #
      # #  - then make sure there are exactly `$name_pad` spaces at the start
      # #    of the line `^[ ]{$name_pad}`
      # #     - we know this to be true, but we have to check it again anyways
      # #
      # #  - then a variable-length name `[^ ]+`
      # #  - then at least one space `[ ]+`
      # #  - then the description `[^ ]`
      # #
      # #  - however, _before_ the description, check that we've used exactly
      # #    `$desc_pad` chars since the start of the line `(?<=^.{$desc_pad})`
      # #     - this is the reason we had to remove the backspaces,
      # #        - because it would have turned out being farr too complicated
      # #          to figure out a regex that could multiply the name length
      # #          by 3, then check whether it still matched
      # #
      # #  - I rly couldn't figure out a way to do this w/o backtracking :(
      # #     - since I don't know how long the name or name-desc padding are
      # #       going to be individually (only their sum), I need to backtrack
      # #     - and that's even without handling the backspace characters,
      # #       which would likely be a whole nother nightmare
      if [[ "${lines[tail+1]}" == ' '#
        &&  "${lines[tail  ]//?$'\b'}"
          =~ "^[ ]{$name_pad}[^ ]+[ ]+(?<=^.{$desc_pad})[^ ]"
      ]] {
        # success!
        ;: DBG :; words+=( "${${lines[tail]/# ##}%% *}" )
        ;: DBG :; echo $'\e[2;38;5;105m'"${(r:COLUMNS::─:)}"$'\e[22m'
        ;: DBG :; echo -E "${(r:name_pad:)}$words[-1]"
        ;: DBG :; echo -E "${(r:desc_pad:)}${lines[tail]/# ##$words[-1] ##}"
        continue;
      }

      # if it wasn't the first possibility, then check if there are multiple
      #  definitions for `$cmd`
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
    until [[ "$lines[tail++]" == ' '# \
      && "$lines[tail]" == ' '(#c$name_pad)[^' ']* ]] {}

    (( tail-- )) # we've hit the next name, go back one line

    ;: DEBUG :; echo -n $'\e[3'"$colours[ ( ( $#words ) % $#colours ) + 1 ]m"
    ;: DEBUG :; echo $'\e[2m'"${(r:COLUMNS::─:)}"$'\e[22m'
    ;: DEBUG :; words+=( "${${lines[head]/# ##}%% *}" )

    print -r -- "${(F)lines[head,tail]//%$'\n'}"

    # we actually shouldn't need to go back one line, but since `i++` is
    #  being called in the `while` condition, we have to counteract it by 1
    (( i = tail - 1 ))
    # at this point, `i` is pointing at the blank line before a name.
    #  by the first `if` condition of the next iteration, it'll be at a name
  }

  ;: DEBUG :; echo $'\e[2m'"${(r:COLUMNS::─:)}"$'\e[m'
  ;: DEBUG :; print -r -- "${(@)words}"
  ;: DEBUG :; echo $#words
}

# ——————————————————————————————————————————————————————————————————————————— #

if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]] { fmt-run-help "$@"; }
