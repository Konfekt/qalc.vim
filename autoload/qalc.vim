function! s:get_selection(t) abort
  silent exe "norm! `["..get({'l': 'V', 'b': "\<C-V>"}, a:t[0], 'v').."`]y"
  redraw
  return @@
endfunction

function! s:uncomment(line)
  let cs = &commentstring
  if cs == "" | return a:line | endif

  " If the commentstring doesn't contain a %s, treat the whole thing as a marker.
  if cs !~# '%s'
    return substitute(a:line, '\V\^\s\*'..escape(cs, '\'), '', '')
  endif

  " Split the commentstring at %s to get the left and (optional) right parts.
  let parts = split(cs, '%s')
  let left = parts[0]
  let right = (len(parts) > 1 ? parts[1] : '')

  let l = a:line
  " Remove the left marker (plus any leading whitespace).
  if left != ""
    let l = substitute(l, '\V\^\s\*'..escape(left, '\'), '', '')
  endif
  " Remove the right marker (plus any trailing whitespace).
  if right != ""
    let l = substitute(l, '\V'..escape(right, '\')..'\s\*\$', '', '')
  endif

  return l
endfunction

function! s:remove_result(line)
  return match(a:line, '=') > 0 ?
        \ substitute(a:line, '\s*=\s*.*$', '', '') .. matchstr(a:line, '\s*$') :
        \ a:line
endfunction

let s:cmd = 'qalc -terse '..g:qalc_parameters..' -- '

function! s:qalc(line, append) abort
  let line = s:uncomment(a:line)
  let was_commented = line !=# a:line
  for s in g:qalc_splits + ['\$']
    if match(line, '\V'..s) != -1
      let terms = split(line, '\V'..s, 1)
      let terms = map(terms, {_, t -> s:remove_result(t)})
      let split = s
      break
    endif
  endfor
  for i in range(0, len(terms)-1)
    if terms[i] !~# '[0-9]' | continue | endif
    silent! let result = systemlist(s:cmd..' '..shellescape(terms[i]))[0]
    if a:append
      let terms[i] = substitute(terms[i], '\s*$', '', '') .. ' = ' .. result .. matchstr(terms[i], '\s*$')
    else
      let start = matchstr(terms[i], '^\s*')
      let terms[i] = start .. result .. repeat(' ', len(terms[i]) - len(start) - len(result))
    endif
  endfor
  let line = join(terms, split ==# '\$' ? '' : split)

  return was_commented ? printf(&commentstring, line) : line
endfunction

function! s:edit_selection(type, append)
  let saved = [&selection, &clipboard, &virtualedit]
  let saved_reg = getreginfo('"')
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus virtualedit=block
    let selection = s:get_selection(a:type)
    let results = join(map(split(selection, '\n'), {_, s -> s:qalc(s, a:append)}), "\n")
    if results !~# '^\n*$'
      call setreg('"', results, getregtype('"')[0])
      normal! gvp
    endif
  catch /^.*/
    echohl ErrorMSG
    echo v:errmsg
    echohl NONE
  finally
    let [&selection, &clipboard, &virtualedit] = saved
    call setreg('"', saved_reg)
  endtry
endfunction

function! qalc#AppendOp(...) abort
  if !a:0
    set opfunc=qalc#AppendOp
    return 'g@'
  endif
  call s:edit_selection(a:1, 1)
endfunction

function! qalc#ReplaceOp(...) abort
  if !a:0
    set opfunc=qalc#ReplaceOp
    return 'g@'
  endif
  call s:edit_selection(a:1, 0)
endfunction
