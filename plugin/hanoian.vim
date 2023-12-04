" Last Change:  2023 Nov 01
" Maintainer:   Kiet Do <kietdo0602@gmail.com>
" License:      GNU General Public License v3.0

if exists('g:loaded_hanoian') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

hi HanoianCursorLine ctermbg=238 cterm=none

command! Hanoian lua require'hanoian'.hanoian()

