" simple syntax file desiged for reliable testing of Text::VimColor marking

if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'tvctestsyn'
endif

syn keyword tvctVim      vim
syn keyword tvctKW       Text VimColor
syn match   tvctChars   "[~!@#$%^&*()_+:;]"
syn match   tvctFile   "\S\/\S*\.\S\+"
syn keyword tvctThisThat this that contained
syn match   tvctArrow   "[-<>]" contained
syn region  tvctParens matchgroup=tvctChars start=/(/ end=/)/ contains=tvctThisThat,tvctVim,tvctArrow

if !exists("b:is_bash")
  syn keyword tvctNotBash isbash
endif

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("tvctestsyn")
  if version < 508
    let tvcttestsyn = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
    HiLink tvctVim        Todo
    HiLink tvctKW         Identifier
    HiLink tvctChars      Special
    HiLink tvctArrow      Statement
    HiLink tvctFile       String
    HiLink tvctThisThat   Type
    HiLink tvctParens     Comment
    if !exists("b:is_bash")
      HiLink tvctNotBash     Error
    endif
  delcommand HiLink
endif

let b:current_syntax = "tvctestsyn"
if main_syntax == 'tvctestsyn'
  unlet main_syntax
endif
