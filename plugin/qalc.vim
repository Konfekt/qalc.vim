" Calculate text objects and selections with qalc(1) of Qalculate!, see
" :help qalc. For example, q++ on the line `1+2` turns it into `1+2 = 3`.

if &compatible || exists('g:loaded_qalc') | finish | endif
let g:loaded_qalc = 1

if !executable('qalc') | finish | endif

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
