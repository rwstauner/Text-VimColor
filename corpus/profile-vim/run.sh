#!/bin/bash

dir="corpus/profile-vim"

if [[ "$0" != "$dir/run.sh" ]]; then
  echo "Please run this from the project root." >&2
  exit 1
fi

# defaults
out=out.prof
src=t/data/tvctestsyn.txt
diff=1
# use test data
fakehome=t/

while getopts "o:i:h:" optl; do
  case "$optl" in
  i)
    diff=""
    src="$OPTARG";;
  o)
    out="$OPTARG";;
  h)
    fakehome="$OPTARG";;
  *)
    echo "unknown option '$optl'" 1>&2;
  esac
done

HOME="$fakehome"

# vim @VIM_OPTIONS source.file -s commands.vim
vim -RXZ -i NONE -u NONE -N -n '+set nomodeline' "$src" -s "$dir/profile.vim"

if [[ "$diff" ]]; then
  diff -u "$dir/expectation.txt" "$dir/marked.txt" && echo 'got expected markup'
fi

resd="$dir/results"
if [[ "$out" != "out.prof" ]]; then
  mv -v "$resd/out.prof" "$resd/${out%.prof}.prof"
else
  echo "profile output in $resd/out.prof"
fi
