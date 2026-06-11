#!/usr/bin/env zsh

[[ "$ZSH_VERSION" == '5.9.1' ]] \
  && export HELPDIR="/usr/share/zsh/5.9/help" \
  || export HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"

source "${0:h}/list-all.zsh"

# ——————————————————————————————————————————————————————————————————————————— #

function man help tldr () {
  setopt local_options warn_create_global

  local -ri 10 exit_code=$?

  # if we were called by the `run-help` command, exit.
  if (( $funcstack[(Ie)run-help] )) return exit_code

  local -r error=$'\e[31m'"$0"$'\e[m:'

  # if the input is `man all`, or `help -l`, etc., then pass the
  #  job onto one of those dedicated functions
  if [[ "$1" == (-(-list|l)|all) ]] {
    "$0::list_all"

  } elif [[ "$0" == 'tldr' ]] {
    # otherwise if the `$0` was `tldr`, then I assume that I actually meant
    #  `tldr`, so run that command as-is
    command tldr --color=always "$@"

  } else {
    # finally, if the input wasn't `man/help all` and `$0` wasn't `tldr`
    # pass it on to the main function, which handles both `man` and `help`
    man::main "$@"
  }

  return $?
}

# ——————————————————————————————————————————————————————————————————————————— #

function man::main() {
  setopt local_options local_traps warn_create_global

  local -ra all_help_funcs=( # spell-checker:disable
    'alias'      'autoload'       'bg'            'bindkey'        'break'
    'builtin'    'bye'            'cap'           'cd'             'chdir'
    'clone'      'colon'          'command'       'comparguments'  'compcall'
    'compctl'    'compdescribe'   'compfiles'     'compgroups'     'compquote'
    'comptags'   'comptry'        'compvalues'    'continue'       'declare'
    'dirs'       'disable'        'disown'        'dot'            'echo'
    'echotc'     'echoti'         'emulate'       'enable'         'eval'
    'exec'       'exit'           'export'        'false'          'fc'
    'fg'         'float'          'functions'     'getcap'         'getln'
    'getopts'    'hash'           'history'       'integer'        'jobs'
    'kill'       'let'            'limit'         'local'          'logout'
    'noglob'     'popd'           'print'         'printf'         'pushd'
    'pushln'     'pwd'            'r'             'read'           'readonly'
    'rehash'     'return'         'sched'         'set'            'setcap'
    'setopt'     'shift'          'source'        'suspend'        'test'
    'times'      'trap'           'true'          'ttyctl'         'type'
    'typeset'    'ulimit'         'umask'         'unalias'        'unfunction'
    'unhash'     'unlimit'        'unset'         'unsetopt'       'vared'
    'wait'       'whence'         'where'         'which'          'zcompile'
    'zformat'    'zftp'           'zle'           'zmodload'       'zparseopts'
    'zprof'      'zpty'           'zregexparse'   'zsocket'        'zstyle'
    'ztcp'        '.'
  ) # spell-checker:enable

  # if we background one of the functions, make sure that we don't
  #  keep trying to check if there's another option
  local -i 10 SIGTSTP=146
  local -r PAGER=${=PAGER:-more}

  # —— Setup & Input Parsing —————————————————————————————————————————— #

  local -l section
  # check if the first input is a valid section, and that there's another input
  if [[ "$1" == [0-9n](|cc|g|m|p(m|cap)|ssl|t(cl|iff|k|ype)|x) && -n "$2" ]] {
    section="$1"; shift
  }

  if ! (( $# )) {
    echo "$error must enter a command" >&2
    return 1
  }

  local page="$1"
  local -ri 2 do_run_help=$(( $all_help_funcs[(Ie)$page] ))

  # —— run-help ——————————————————————————————————————————————————————— #

  # if the inputted page is one of the pages that's covered by run-help, then
  #  use one of those
  # if [[ -z "$section" ]] {
  #
  #   if [[ "$page" == '.' ]] page='dot'
  #   if [[ "$page" == ':' ]] page='colon'
  #
  #   if [[ -r "$HELPDIR/$page" && "$page" != 'compctl' ]] {
  #     less "$HELPDIR/$page"
  #   }
  # }
  #
  # if (( $? == 0 || $? == SIGTSTP )) return 0

  if (( do_run_help && ! section )) { run-help "$page"; return $?; }
  # we're doing it this way, bc run-help has a rly annoying feature where it
  #  runs `man` on failure, which messes w our whole plan

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
