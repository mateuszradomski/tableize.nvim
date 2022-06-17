if exists("g:loaded_tableize") | finish | endif

command! Tableize lua require("tableize").tableize()

let g:loaded_tableize = 1
