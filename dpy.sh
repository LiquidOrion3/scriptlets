#!/bin/bash

usage()
{
  cat << EOF
  Usage: $(basename "$0") [ARGS] [INPUT] ...
  Usage: [INPUT] | $(basename "$0") [ARGS]
  Copies input to system clipboard based on parameter type

  INPUT:
      <COMMAND> | $(basename "$0") : Copies piped text to clipboard
      $(basename "$0") <COMMAND> : Evaluates arguments as cmd w/ args and copies output to clipboard
      $(basename "$0") <FILE(s)> : Concatenates any passed files to clipboard
      $(basename "$0") <RAW> : Copies raw txt to clipboard
      $(basename "$0") <FILE> ... <RAW> ... : Concatenates files and raw txt to clipboar in order

  ARGS:
      -h) print this menu
      -t) output that is copied to clipboard is also output to stdout
EOF
exit
} 
[[ $1 =~ ^-?h ]] && usage

smart_copy() {

  local output
  local res=false
  local msg=""
  local tee=false
  local cmd_args=$#


  #optionally shifts positional argument to tee results
  if [[ $1 = "-t" ]]; then
    tee=true;
    shift
    for arg do
      shift
      set -- "$@" "$arg"
    done
  fi

  if [[ $# == 0 ]]; then #input piped to clipboard
    {
      output=$(cat)
      msg="Input copied to clipboard\n"
      res=true
    }
else #
  local cmd=""
  for arg in $@; do
    cmd+="\"$(echo -en $arg|sed -E 's/"/\\"/g')\" "
  done
  output=$(eval "$cmd" 2> /dev/null) #evaluate input as a command string
  if [[ $? == 0 ]]; then
    msg="Results of $cmd are in the clipboard\n"
    res=true
  else # evaluate input as txt files
    if [[ -f $1 ]]; then
      output=""
      for arg in $@; do
        if [[ -f $arg ]]; then
          output+=$(cat $arg)
          msg+="Contents of $arg are in the clipboard.\n"
          res=true
        else # if FILE and RAW and mixed concatenate them in order
          output+=$arg
          msg+="$arg is in the clipboard.\n"
          res=true
        fi
      done
    else #evaluate input as raw text
      output=$@
      msg="$@ copied to clipboard\n"
      res=true
    fi
  fi
  fi

  if [[ $tee -eq true ]]; then
    $res && echo -ne "$output\n" |tee >(xclip -selection clipboard)
  else
    $res && echo -ne "$output\n" | xclip -selection clipboard
  fi

  echo -e "$msg"
}
smart_copy $@
