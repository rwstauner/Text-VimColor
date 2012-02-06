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

# use test data
HOME=t/

# vim @VIM_OPTIONS source.file -s commands.vim
vim -RXZ -i NONE -u NONE -N -n '+set nomodeline' "$src" -s "$dir/profile.vim"

if [[ "$diff" ]]; then
  diff -u "$dir/expectation.txt" "$dir/marked.txt" && echo 'got expected markup'
fi

echo "profile output in $dir/out.prof"
