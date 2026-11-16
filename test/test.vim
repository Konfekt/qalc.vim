" Headless tests, run by test/run.sh.
scriptencoding utf-8
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let &runtimepath = s:root .. ',' .. &runtimepath
let s:real = $QALC_REAL ==# '1'
let s:results = []
runtime plugin/qalc.vim

" Run {keys} (with mappings) on a scratch buffer holding {lines}.
function! s:run(lines, keys, ...) abort
  enew!
  setlocal buftype=nofile commentstring=
  if a:0 | let &l:commentstring = a:1 | endif
  call setline(1, a:lines)
  call cursor(1, 1)
  execute 'normal' a:keys
  return getline(1, '$')
endfunction

function! s:check(name, got, want) abort
  call add(s:results, (a:got ==# a:want ? 'ok   ' : 'FAIL ') .. a:name
        \ .. (a:got ==# a:want ? '' : ': got ' .. string(a:got) .. ', want ' .. string(a:want)))
endfunction

function! s:test_append_line() abort
  call s:check('append line', s:run(['1+2'], 'q++'), ['1+2 = 3'])
endfunction

function! s:test_replace_line() abort
  call s:check('replace line pads to width', s:run(['1+2'], 'q=='), ['3  '])
endfunction

function! s:test_recompute() abort
  call s:check('recompute result', s:run(['1+2 = 7'], 'q++'), ['1+2 = 3'])
endfunction

function! s:test_table() abort
  call s:check('table append', s:run(['| 1+2 | 2*3 |'], 'q++'), ['| 1+2 = 3 | 2*3 = 6 |'])
  call s:check('table replace', s:run(['| 1+2 | 2*3 |'], 'q=='), ['| 3   | 6   |'])
endfunction

function! s:test_comment() abort
  call s:check('comment', s:run(['# 1+2'], 'q++', '# %s'), ['# 1+2 = 3'])
  call s:check('block comment', s:run(['/* 1+2 */'], 'q++', '/* %s */'), ['/* 1+2 = 3 */'])
endfunction

function! s:test_visual() abort
  call s:check('visual linewise', s:run(['1+2', '2*3'], 'Vjq+'), ['1+2 = 3', '2*3 = 6'])
  call s:check('visual charwise', s:run(['x 1+2 y'], '2|vf2q='), ['x 3   y'])
endfunction

function! s:test_count() abort
  call s:check('count', s:run(['1+2', '2*3', '4+4'], '2q++'), ['1+2 = 3', '2*3 = 6', '4+4'])
endfunction

function! s:test_dot_repeat() abort
  call s:check('dot repeat', s:run(['1+2', '2*3'], 'q++j.'), ['1+2 = 3', '2*3 = 6'])
endfunction

" Bug: comment markers were re-added without the indentation.
function! s:test_indented_comment() abort
  call s:check('indented comment', s:run(['    # 1+2'], 'q++', '# %s'), ['    # 1+2 = 3'])
endfunction

" Bug: 'commentstring' with padding did not match comments without it.
function! s:test_unpadded_comment() abort
  call s:check('unpadded comment', s:run(['#1+2'], 'q++', '# %s'), ['#1+2 = 3'])
endfunction

" Blank lines inside a linewise selection are kept.
function! s:test_blank_lines_kept() abort
  call s:check('blank lines kept', s:run(['1+2', '', '2*3'], 'Vjjq+'), ['1+2 = 3', '', '2*3 = 6'])
  call s:check('blank lines kept (q+G)', s:run(['1+2', '', '2*3'], 'q+G'), ['1+2 = 3', '', '2*3 = 6'])
endfunction

" Bug: text after = was deleted from terms that are not calculated.
function! s:test_non_numeric_term_kept() abort
  call s:check('non-numeric term kept', s:run(['a = b | 1+2'], 'q++'), ['a = b | 1+2 = 3'])
endfunction

" Bug: a regular expression in g:qalc_splits was inserted literally when joining.
function! s:test_split_pattern_joined_by_match() abort
  let saved = g:qalc_splits
  let g:qalc_splits = ['\\', '\s\s\+']
  call s:check('split at backslash', s:run(['1+2\2*3'], 'q++'), ['1+2 = 3\2*3 = 6'])
  call s:check('split at spaces', s:run(['1+2   2*3'], 'q++'), ['1+2 = 3   2*3 = 6'])
  let g:qalc_splits = saved
endfunction

" Bug: registers "0 and "1 were overwritten.
function! s:test_registers_kept() abort
  call setreg('"', 'unnamed')
  call setreg('1', 'one')
  call setreg('0', 'zero')
  call setreg('-', 'dash')
  let want = map(['"', '0', '1', '-'], 'getreg(v:val)')
  call s:run(['1+2', '2*3'], 'q+j')
  call s:check('registers kept', map(['"', '0', '1', '-'], 'getreg(v:val)'), want)
endfunction

" Bug: errors showed the stale v:errmsg instead of the error itself.
function! s:test_error_message() abort
  let saved = g:qalc_splits
  let g:qalc_splits = 0
  let v:errmsg = 'stale'
  messages clear
  call s:run(['1+2'], 'q++')
  let g:qalc_splits = saved
  call s:check('error message', execute('messages') =~# 'qalc: Vim(for):E\d\+: ', 1)
endfunction

" Bug: a failed calculation reused the result of the previous term.
function! s:test_failed_calculation() abort
  if s:real | return | endif
  call s:check('failed calculation', s:run(['1+2 | fail 1'], 'q++'), ['1+2 = 3 | fail 1'])
endfunction

" Bug: multibyte results were padded by bytes, misaligning tables.
function! s:test_multibyte_padding() abort
  if s:real | return | endif
  call s:check('multibyte padding', s:run(['| 1 ohm | 100 C |'], 'q=='), ['| 1 Ω   | 100 °C|'])
endfunction

" Bug: g:qalc_parameters was read only once.
function! s:test_parameters_reread() abort
  if s:real | return | endif
  let $QALC_LOG = tempname()
  let saved = g:qalc_parameters
  let g:qalc_parameters = '--first'
  call s:run(['1+2'], 'q++')
  let g:qalc_parameters = '--second'
  call s:run(['1+2'], 'q++')
  let g:qalc_parameters = saved
  let log = readfile($QALC_LOG)
  let $QALC_LOG = ''
  call s:check('parameters reread', log, ['-terse --first -- 1+2', '-terse --second -- 1+2'])
endfunction

if !exists('g:loaded_qalc') || !hasmapto('<Plug>(QalcAppend)', 'n')
  call add(s:results, 'FAIL plugin not loaded (qalc not in $PATH?)')
else
  for s:name in sort(filter(map(split(execute('function /_test_'), "\n"),
        \ 'matchstr(v:val, ''<SNR>\d\+_test_\w\+'')'), '!empty(v:val)'))
    try
      call call(s:name, [])
    catch
      call add(s:results, 'FAIL ' .. s:name .. ': ' .. v:exception .. ' @ ' .. v:throwpoint)
    endtry
  endfor
endif
call writefile(s:results, $QALC_TEST_LOG)
qall!
