#!/usr/bin/env zsh

source "${0:h}/list-all.zsh"

# ——————————————————————————————————————————————————————————————————————————— #

# using `function` here, in case `man` or `help` are already aliases
function man help tldr () {
  local -ri 10 exit_code=$?
  local -r run_help='run-help'

  # if we were called by the run-help command, exit.
  if (( $funcstack[(Ie)$run_help] )) return exit_code

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

man::main() {
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

  local -l section
  if [[ "$1" == [0-9n](cc|g|m|p(m|cap)|ssl|t(cl|iff|k|ype)|x|) && -n "$2" ]] {
    section="$1"; shift
  }

  if ! (( $# )) { echo "$error must enter a command"; return 1; }

  local -r page="$1"
  local -ri 2 do_run_help=$(( $all_help_funcs[(Ie)$page] ))

  # if the inputted page is one of the pages that's covered by run-help, then
  #  use one of those
  if (( do_run_help && ! section )) { run-help "$page"; return $?; }
  # we're doing it this way, bc run-help has a rly annoying feature where it
  #  runs `man` on failure, which messes w our whole plan

  if (( $? == 146 )) return 0  #r)FIXME

  # if a section was explicitly passed, assume u wanted `man`
  # nb: `$section` is unquoted here, so we don't have issues w it being empty
  command man $section        "$page" 2>/dev/null && return 0
  if (( $? == 146 )) return 0  #r)FIXME

  command tldr --color=always "$page" 2>/dev/null && return 0

  if (( $? == 146 )) return 0  #r)FIXME

  # finally, if none of the commands had an entry, throw an error
  echo -nE "$error no entry for '$page'" >&2

  # if they passed a section, use a different error message
  if [[ "$section" ]] { echo -E " in section $section"
  } else              { echo $'.\n'"Checked 'man', 'run-help', and 'tldr'"; }

  return 1
}

# ——————————————————————————————————————————————————————————————————————————— #

# $HOME/Desktop/CS/y_settings_etc/Resources/Man-Pages/All-Builtins
# spell-checker:disable
#  By-Section
#  ├─ 1
#  │  ├─ 1.txt
#  │  ├─ 1m.txt
#  │  ├─ 1ssl.txt
#  │  ├─ 1tcl.txt
#  │  └─ 1tk.txt
#  ├─ 2
#  │  └─ 2.txt
#  ├─ 3
#  │  ├─ 3.txt
#  │  ├─ 3G.txt
#  │  ├─ 3cc.txt
#  │  ├─ 3pcap.txt
#  │  ├─ 3pm.txt
#  │  ├─ 3ssl.txt
#  │  ├─ 3tcl.txt
#  │  ├─ 3tiff.txt
#  │  ├─ 3tk.txt
#  │  ├─ 3type.txt
#  │  └─ 3x.txt
#  ├─ 4
#  │  └─ 4.txt
#  ├─ 5
#  │  ├─ 5.txt
#  │  └─ 5ssl.txt
#  ├─ 6
#  │  └─ 6.txt
#  ├─ 7
#  │  ├─ 7.txt
#  │  └─ 7ssl.txt
#  ├─ 8
#  │  └─ 8.txt
#  ├─ 9
#  │  └─ 9.txt
#  ├─ n
#  │  ├─ n.txt
#  │  ├─ ntcl.txt
#  │  └─ ntk.txt
#  └─ _simpl-sort-by-section.txt
#
#  By-Category
#  ├─ TTF.txt
#  ├─ ansi.txt
#  ├─ bench.txt
#  ├─ bundle.txt
#  ├─ canvas.txt
#  ├─ cargo.txt
#  ├─ cc.txt
#  ├─ cryptexctl.txt
#  ├─ dbus.txt
#  ├─ docidx.txt
#  ├─ doctoc.txt
#  ├─ doctools.txt
#  ├─ export.txt
#  ├─ ffmpeg.txt
#  ├─ fido2.txt
#  ├─ gh.txt
#  ├─ git.txt
#  ├─ gnutls.txt
#  ├─ idx.txt
#  ├─ iwidgets.txt
#  ├─ ldns.txt
#  ├─ libcurl.txt
#  ├─ libssh2.txt
#  ├─ llvm.txt
#  ├─ lwp.txt
#  ├─ nns.txt
#  ├─ npm.txt
#  ├─ oo.txt
#  ├─ openpam.txt
#  ├─ openssl.txt
#  ├─ os.txt
#  ├─ page.txt
#  ├─ pam.txt
#  ├─ posix.txt
#  ├─ pt.txt
#  ├─ pthread.txt
#  ├─ sasl.txt
#  ├─ shazam.txt
#  ├─ slapd.txt
#  ├─ slapo.txt
#  ├─ sndfile.txt
#  ├─ ssh.txt
#  ├─ tapi.txt
#  ├─ tcl.txt
#  ├─ tdbc.txt
#  ├─ tk.txt
#  ├─ toc.txt
#  ├─ ttk.txt
#  ├─ unbound.txt
#  ├─ unibilium.txt
#  ├─ uuid.txt
#  ├─ xcb.txt
#  ├─ zmq.txt
#  └─ zsh.txt
#  all-builtin-man-pages.txt
#  simplified-no-duplicates.txt
#  simplified.txt
# spell-checker:enable
