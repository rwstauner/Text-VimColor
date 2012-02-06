:filetype on

:profile start corpus/profile-vim/results/out.prof
:profile! file share/mark.vim

:source share/mark.vim
:write! corpus/profile-vim/marked.txt
:qall!
