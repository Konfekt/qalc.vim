# QALC Plugin for Vim

This Vim plugin lets you quickly calculate expressions inside your text by calling the external program **qalc** (from the [Qalculate!](http://qalculate.github.io/) project).
You can select an expression like `1 + 2`, press the configured mappings (by default, `q+` for appending or `q=` for replacing), and the plugin will either append or replace the expression's result right there in your file.

![Qalc.vim in Action](https://i.imgur.com/fbvmOcr.gif)

For example, if you have a line with `1+2`, pressing `q++` turns it into:

    1+2 = 3

It also allows you to split lines at certain punctuation (like `|`, `;`, or tabs, as set in `g:qalc_splits`) so you can calculate multiple expressions on one line, and the table

```
| 100 USD to EUR       | 1 inch to cm | 5 mi to km           |
| 1 + 2i * 3 - 4i      | abs(3 + 4i)  | arg(1 + sqrt(3) * i) |
| 2 hours + 30 minutes | 500 kB to MB | 1 year to seconds    |
```

becomes after hitting `q=ip` and realigning (say, with vim-table-mode)

```
| 90.07 EUR          | 2.54 cm | 8.05 km  |
| 1.00 + 2.00i       | 5.00    | 1.05     |
| 2.00 h + 30.00 min | 0.50 MB | 3.16E7 s |
```

respectively after hitting `q+ip`

```
| 100 USD to EUR = 90.07 EUR                | 1 inch to cm = 2.54 cm | 5 mi to km = 8.05 km         |
| 1 + 2i * 3 - 4i = 1.00 + 2.00i            | abs(3 + 4i) = 5.00     | arg(1 + sqrt(3) * i) = 1.05  |
| 2 hours + 30 minutes = 2.00 h + 30.00 min | 500 kB to MB = 0.50 MB | 1 year to seconds = 3.16E7 s |
```

The plugin also respects the existing `commentstring` setting.
That means if your expression is inside a commented line, the plugin will temporarily remove the comment markers (and the indentation before them), calculate the expression, and then put them back.
If there was already a result, it will be removed and replaced with a fresh calculation.

By default, the plugin shows results with 2 decimal places, but you can configure different parameters or decimal precision by changing `g:qalc_parameters`.

## Requirements

- Vim 8.2.0924 or later, or Neovim 0.5 or later.
- The [`qalc`](https://github.com/Qalculate/qalculate-gtk) command must be installed and available in your PATH.

## Usage

By default, the plugin provides the following mappings:

### Normal Mode
- `nmap q=` → Replace expression(s) with their result
- `nmap q+` → Append " = result" to each expression

### Visual Mode
- `xmap q=` → Replace expression(s) with their result
- `xmap q+` → Append " = result" to each expression

Doubling these mappings (e.g. `q++` or `q==`) applies to an entire line as a text-object in Normal mode.

## Customization

- **Override default qalc arguments:**

  ```vim
  let g:qalc_parameters = '--set "min decimals 0" --set "max decimals 2"'
  ```

  This changes the precision of results.

- **Provide your own set of split characters:**
    To change which characters split multiple expressions on the same line:

  ```vim
  let g:qalc_splits = ['|', ';', "\t"]
  ```

    Each entry is a very nomagic (`:help \V`) regular expression in which only the backslash `\` needs escaping.
    The first entry that matches a line splits it, and the matched text is kept between the results.

- **Disable default mappings:**

    ```vim
    let g:qalc_no_mappings = 1
    ```

    Then you can manually map the plugin:

    ```vim
    nmap <Leader>+ <Plug>(QalcAppend)
    xmap <Leader>+ <Plug>(QalcAppend)
    nmap <Leader>= <Plug>(QalcReplace)
    xmap <Leader>= <Plug>(QalcReplace)
    ```

    `<Plug>` mappings only work with `nmap`/`xmap`, not with `nnoremap`/`xnoremap`.

## Tests

Run `test/run.sh` to test in headless Vim and Neovim.
It uses a stand-in for `qalc` in `test/bin`; set `QALC_REAL=1` to use the real `qalc` in your `PATH` instead.
