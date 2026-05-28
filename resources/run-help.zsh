#!/usr/bin/env zsh

# /opt/homebrew/Cellar/zsh/5.9/share/zsh/functions/run-help

function run-help () {
    emulate -RL zsh
    local HELPDIR="${HELPDIR:-/opt/homebrew/Cellar/zsh/5.9/share/zsh/help}" 
    [[ $1 == "." ]] && 1="dot" 
    [[ $1 == ":" ]] && 1="colon" 
    if [[ $# == 0 || $1 == "-l" ]]; then
        if [[ -d $HELPDIR ]]; then
            echo "Here is a list of topics for which special help is available:"
            echo ""
            print -rc $HELPDIR/*(:t)
        else
            echo "There is no list of special help topics available at this time."
        fi
        return 0
    elif [[ -n "${HELPDIR:-}" && -r $HELPDIR/$1 && $1 != compctl ]]; then
        ${=PAGER:-more} $HELPDIR/$1
        return $?
    fi
    local what places noalias newline='
' 
    integer i=0 didman=0 
    places=("${(@f)$(builtin whence -va $1)}") 
    if [[ $places = *"not found"* && $1 != ${(Q)1} ]]; then
        places=("${(@f)$(builtin whence -va ${(Q)1})}") 
        if (( ${#places} )); then
            set -- "${(Q)@}"
        fi
        noalias=1 
    fi
    {
        while ((i++ < $#places)); do
            what=$places[$i] 
            [[ -n $noalias && $what = *" is an alias "* ]] && continue
            builtin print -r $what
            case $what in
                (*( is an alias for (noglob|nocorrect))*) [[ ${what[(w)7]:t} != ${what[(w)1]} ]] && run_help_orig_cmd=${what[(w)1]} run-help ${what[(w)7]:t} ;;
                (*( is an alias)*) [[ ${what[(w)6]:t} != ${what[(w)1]} ]] && run_help_orig_cmd=${what[(w)1]} run-help ${what[(w)6]:t} ;;
                (*( is a * function)) case ${what[(w)1]} in
                        (comp*) man zshcompsys ;;
                        (zf*) man zshftpsys ;;
                        (run-help) man zshcontrib ;;
                        (*) builtin functions ${what[(w)1]} | ${=PAGER:-more} ;;
                    esac ;;
                (*( is a * builtin)) case ${what[(w)1]} in
                        (compctl) man zshcompctl ;;
                        (comp*) man zshcompwid ;;
                        (bindkey|vared|zle) man zshzle ;;
                        (*setopt) man zshoptions ;;
                        (cap|getcap|setcap)  ;&
                        (clone)  ;&
                        (ln|mkdir|mv|rm|rmdir|sync)  ;&
                        (sched)  ;&
                        (echotc|echoti|sched|stat|zprof|zpty|zsocket|zstyle|ztcp) man zshmodules ;;
                        (zftp) man zshftpsys ;;
                        (*) man zshbuiltins ;;
                    esac ;;
                (*( is hashed to *)) man ${what[(w)-1]:t} ;;
                (*( is a reserved word)) man zshmisc ;;
                (*) if ((! didman++)); then
                        if whence "run-help-$1:t" > /dev/null; then
                            local cmd_args
                            builtin getln cmd_args
                            builtin print -z "$cmd_args"
                            cmd_args=(${(z)cmd_args}) 
                            shift $cmd_args[(i)${run_help_orig_cmd:-$1}] cmd_args || return
                            cmd_args=(${cmd_args[@]:#([-+]*|*=*|*/*|\~*)}) 
                            eval "run-help-$1:t ${(@q)cmd_args}"
                        else
                            POSIXLY_CORRECT=1 man $@:t
                        fi
                    fi ;;
            esac
            if ((i < $#places && ! didman)); then
                builtin print -nP "%SPress any key for more help or q to quit%s"
                builtin read -k what
                [[ $what != $newline ]] && echo
                [[ $what == [qQ] ]] && break
            fi
        done
    } always {
        unset run_help_orig_cmd
    }
}
