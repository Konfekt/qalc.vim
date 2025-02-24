"  Put into ~/.vim/ftplugin/qalc.vim to use q+ for calculation of text-objects
"  or selections. For example, q++ on the line `1+2` turns it into `1+2 = 3`.

"  Should work with Vim 7.4 or later.

"  Respects the 'commentstring' option, so that q+ works with comments.
"  Recomputes the result in case there's already one.

"  Pass arguments to it by setting `g:qalc_parameters`, by default 
"  restricting output to have 2 decimal places.

if &compatible || exists('g:loaded_qalc') | finish | endif
let g:loaded_qalc = 1

if !executable('qalc')
  " echohl WarningMsg | echomsg 'qalc(1) is not found in $PATH' | echohl NONE
  finish
endif

if !exists('g:qalc_parameters')
  let g:qalc_parameters = '--set "min decimals 0" --set "max decimals 2"'
endif
if !exists('g:qalc_splits')
  let g:qalc_splits = ['|', ';', "\t"]
endif

nnoremap <expr> <Plug>(QalcReplace) qalc#ReplaceOp()
xnoremap <expr> <Plug>(QalcReplace) qalc#ReplaceOp()
nnoremap <expr> <Plug>(QalcAppend)  qalc#AppendOp()
xnoremap <expr> <Plug>(QalcAppend)  qalc#AppendOp()

if get(g:, 'qalc_no_mappings', 0) | finish | endif

onoremap <SID>(_) _
if empty(mapcheck('q=', 'n'))
  nmap q= <Plug>(QalcReplace)
  nmap q== <Plug>(QalcReplace)<SID>(_)
endif
if empty(mapcheck('q=', 'x'))
  xmap q= <Plug>(QalcReplace)
endif
if empty(mapcheck('q+', 'n'))
  nmap q+ <Plug>(QalcAppend)
  nmap q++ <Plug>(QalcAppend)<SID>(_)
endif
if empty(mapcheck('q+', 'x'))
  xmap q+ <Plug>(QalcAppend)
endif
