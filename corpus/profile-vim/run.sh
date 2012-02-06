#!/bin/bash

dir="corpus/profile-vim"

if [[ "$0" != "$dir/run.sh" ]]; then
  echo "Please run this from the project root." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  src=t/data/tvctestsyn.txt
  diff=1
else
  src="$1"
fi

# defaults
out=out.prof
# use test data
HOME=t/

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
