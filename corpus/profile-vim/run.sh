#!/bin/bash

dir="corpus/profile-vim"

if [[ "$0" != "$dir/run.sh" ]]; then
  echo "Please run this from the project root." >&2
  exit 1
fi

# use test data
HOME=t/

# vim @VIM_OPTIONS source.file -s commands.vim
vim -RXZ -i NONE -u NONE -N -n '+set nomodeline' t/data/tvctestsyn.txt -s "$dir/profile.vim"

diff -u "$dir/expectation.txt" "$dir/out.marked" && echo 'got expected markup'

echo "profile output in $dir/out.prof"
