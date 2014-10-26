""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:        plugin/cavemanparens.vim
"
" Description: Special treatment of parens and other matchable characters.
"              Character pairs defined in b:caveman_pairs get a matching close
"              when the opening character is typed in insert mode.  Typing a
"              close character also advances past an already-present close
"              character.  Backspace removes both pairs if they are adjacent so
"              typing '(' followed by backspace is the same as doing nothing.
"              Carriage returns can also be handled specially for block
"              delimiting characters like '{' in C.
"
" Maintainer:  Stephen Cave
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


if exists("g:loaded_caveman_parens")
    finish
endif
let g:loaded_caveman_parens = 1


" Provide sane defaults.  Most languages pair these up most of the time
" whereas many languages allow '<' to be used as a less-than symbol and
" English allows ' to be used as an apostrophe.
if !exists("g:caveman_pairs")
    let g:caveman_pairs=['[]', '()', '{}', '""']
endif
if !exists("g:caveman_block_pairs")
    let g:caveman_block_pairs=['{}']
endif


" If the character is part of a pair, insert it and its mate otherwise just
" insert it.
function cavemanparens#InsertPair(pair)
    if !exists("b:caveman_pairs")
        let b:caveman_pairs=g:caveman_pairs
    endif
    if count(b:caveman_pairs, a:pair) == 0
        return strpart(a:pair,0,1)
    endif
    return a:pair . "\e" . 'i'
endfunction


" Advance past a closing character of a pair.
function cavemanparens#ClosePair(pair)
    if !exists("b:caveman_pairs")
        let b:caveman_pairs=g:caveman_pairs
    endif
    let s:pairsecond = strpart(a:pair,1,1)
    if count(b:caveman_pairs, a:pair) == 0
        return s:pairsecond
    endif
    if strpart(getline('.'), col('.')-1, 1) == s:pairsecond
        if col('.') == 1
            return "\e" . 'a'
        else
            return "\e" . 'la'
        endif
    else
        return s:pairsecond
    endif
endfunction


" Single and double quotes have identical open and close characters so they
" are treated differently.  Nesting is usually forbidden so if a quote is the
" next character advance past it otherwise treat the input character as the
" start of a new pair.
function cavemanparens#HandleAmbiguousPair(pair)
    if !exists("b:caveman_pairs")
        let b:caveman_pairs=g:caveman_pairs
    endif
    let s:pairsecond = strpart(a:pair,1,1)
    if count(b:caveman_pairs, a:pair) == 0
        return s:pairsecond
    endif
    if strpart(getline('.'), col('.')-1, 1) == s:pairsecond
        return "\e" . 'la'
    else
        return a:pair . "\e" . 'i'
    endif
endfunction


" Delete adjacent characters if they form a pair
function cavemanparens#DeletePair()
    if !exists("b:caveman_pairs")
        let b:caveman_pairs=g:caveman_pairs
    endif
    let s:current_adjacents = strpart(getline('.'),col('.')-2, 2)
    if count(b:caveman_pairs, s:current_adjacents) != 0
        return "\<BS>\<Del>"
    else
        return "\<BS>"
    endif
endfunction


" For block delimiters like '{', inserting a newline directly in between will
" open up a block indented region with the close character on its own line.
function cavemanparens#InsertNewline()
    if !exists("b:caveman_block_pairs")
        let b:caveman_block_pairs=g:caveman_block_pairs
    endif
    let s:current_adjacents = strpart(getline('.'),col('.')-2, 2)
    if count(b:caveman_block_pairs, s:current_adjacents) != 0
        return "\<Del>\<CR>" . strpart(s:current_adjacents, 1, 1) . "\eO"
    else
        return "\<CR>"
endfunction


"A little heavy-handed: handle deletions and newlines specially
inoremap <expr> <CR> cavemanparens#InsertNewline()
inoremap <expr> <BS> cavemanparens#DeletePair()


"Define insert mode remappings based on pair settings
inoremap <expr> ( cavemanparens#InsertPair('()')
inoremap <expr> ) cavemanparens#ClosePair('()')
inoremap <expr> [ cavemanparens#InsertPair('[]')
inoremap <expr> ] cavemanparens#ClosePair('[]')
inoremap <expr> { cavemanparens#InsertPair('{}')
inoremap <expr> } cavemanparens#ClosePair('{}')
inoremap <expr> < cavemanparens#InsertPair('<>')
inoremap <expr> > cavemanparens#ClosePair('<>')
inoremap <expr> " cavemanparens#HandleAmbiguousPair('""')
inoremap <expr> ' cavemanparens#HandleAmbiguousPair("''")

