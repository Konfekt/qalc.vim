" Split a line at the first pattern of g:qalc_splits that matches it.
" Returns [terms, separators], where separators[i] is the text that
" stood between terms[i] and terms[i+1], so that joining restores the line.
function! s:split(line) abort
  for pat in g:qalc_splits
    if match(a:line, '\V' .. pat) == -1 | continue | endif
    let terms = []
    let seps = []
    let start = 0
    while 1
      let [sep, from, to] = matchstrpos(a:line, '\V' .. pat, start)
      " Skip empty matches so that a pattern such as '\s\*' cannot loop forever.
      if from == -1 || to == from | break | endif
      call add(terms, strpart(a:line, start, from - start))
      call add(seps, sep)
      let start = to
    endwhile
    call add(terms, strpart(a:line, start))
    return [terms, seps]
  endfor
  return [[a:line], []]
endfunction

function! s:join(terms, seps) abort
  let line = a:terms[0]
  for i in range(len(a:seps))
    let line .= a:seps[i] .. a:terms[i + 1]
  endfor
  return line
endfunction

" Split a line into [prefix, body, suffix], where prefix and suffix are the
" (indented) comment markers of 'commentstring' if the line is commented.
function! s:uncomment(line) abort
  let cs = &commentstring
  if empty(cs) | return ['', a:line, ''] | endif

  let parts = split(cs, '%s', 1)
  let left = trim(parts[0])
  let right = len(parts) > 1 ? trim(join(parts[1:], '%s')) : ''
  if empty(left) && empty(right) | return ['', a:line, ''] | endif

  " Accept the markers with or without the padding that 'commentstring' adds.
  let pre_pat = empty(left) ? '' :
        \ '\V\^\s\*' .. escape(left, '\') .. (parts[0] =~# '\s$' ? '\s\?' : '')
  let suf_pat = empty(right) ? '' :
        \ '\V' .. (len(parts) > 1 && parts[1] =~# '^\s' ? '\s\?' : '') .. escape(right, '\') .. '\s\*\$'

  let prefix = empty(pre_pat) ? '' : matchstr(a:line, pre_pat)
  if !empty(pre_pat) && empty(prefix) | return ['', a:line, ''] | endif
  let rest = strpart(a:line, len(prefix))
  let suffix = empty(suf_pat) ? '' : matchstr(rest, suf_pat)
  if empty(prefix) && empty(suffix) | return ['', a:line, ''] | endif
  return [prefix, strpart(rest, 0, len(rest) - len(suffix)), suffix]
endfunction

function! s:remove_result(term) abort
  return match(a:term, '=') > 0 ?
        \ substitute(a:term, '\s*=.*$', '', '') .. matchstr(a:term, '\s*$') :
        \ a:term
endfunction

" Evaluate an expression by qalc; return '' if qalc gives no result.
function! s:evaluate(expr) abort
  let cmd = 'qalc -terse ' .. g:qalc_parameters .. ' -- ' .. shellescape(a:expr)
  let output = filter(systemlist(cmd), 'v:val !~# "^\\s*$"')
  return empty(output) ? '' : output[0]
endfunction

function! s:qalc(line, append) abort
  let [prefix, body, suffix] = s:uncomment(a:line)
  let [terms, seps] = s:split(body)
  for i in range(len(terms))
    let term = s:remove_result(terms[i])
    if term !~# '[0-9]' | continue | endif
    let result = s:evaluate(term)
    if empty(result) | continue | endif
    let lead = matchstr(term, '^\s*')
    let trail = matchstr(term, '\s*$')
    if a:append
      let terms[i] = substitute(term, '\s*$', '', '') .. ' = ' .. result .. trail
    else
      " Pad the result to the width of the expression to keep tables aligned.
      let width = strdisplaywidth(term) - strdisplaywidth(lead) - strdisplaywidth(result)
      let terms[i] = lead .. result .. repeat(' ', width)
    endif
  endfor
  return prefix .. s:join(terms, seps) .. suffix
endfunction

function! s:get_selection(type) abort
  silent exe 'normal! `[' .. get({'l': 'V', 'b': "\<C-V>"}, a:type[0], 'v') .. '`]y'
  redraw
  return getreg('"', 1, 1)
endfunction

function! s:edit_selection(type, append) abort
  let saved = [&selection, &clipboard, &virtualedit]
  " Yanking and putting change the unnamed, yank, small delete and numbered registers.
  let regs = ['0', '-'] + map(range(1, 9), 'string(v:val)') + ['"']
  let saved_regs = map(copy(regs), 'getreginfo(v:val)')
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus virtualedit=block
    let lines = s:get_selection(a:type)
    let results = map(lines, {_, line -> s:qalc(line, a:append)})
    if join(results, '') !=# ''
      call setreg('"', results, getregtype('"')[0])
      normal! gvp
    endif
  catch
    echohl ErrorMsg
    echomsg 'qalc: ' .. v:exception
    echohl NONE
  finally
    let [&selection, &clipboard, &virtualedit] = saved
    for i in range(len(regs))
      call setreg(regs[i], empty(saved_regs[i]) ? [] : saved_regs[i])
    endfor
  endtry
endfunction

function! qalc#AppendOp(...) abort
  if !a:0
    set operatorfunc=qalc#AppendOp
    return 'g@'
  endif
  call s:edit_selection(a:1, 1)
endfunction

function! qalc#ReplaceOp(...) abort
  if !a:0
    set operatorfunc=qalc#ReplaceOp
    return 'g@'
  endif
  call s:edit_selection(a:1, 0)
endfunction
