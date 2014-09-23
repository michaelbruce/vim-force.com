" File: apexComplete.vim
" This file is part of vim-force.com plugin
"   https://github.com/neowit/vim-force.com
" Author: Andrey Gavrikov 
" Maintainers: 
" Last Modified: 2014-09-18
"
" apexComplete.vim - "description goes here"
"
if exists("g:loaded_apexComplete") || &compatible
	  finish
endif
let g:loaded_apexComplete = 1

" This function is used for the 'omnifunc' option.		{{{1
" :h complete-functions
" :h complete-items - description of matches list
function! apexComplete#Complete(findstart, base)
	"throw "called complete"
	let l:column = col('.')
	let l:line = line('.')
	if a:findstart
		return l:column
	else
		let l:filePath = expand("%:p")
		let l:matches = s:listOptions(l:filePath, l:line, l:column)
		
		"return {'words': l:matches, 'refresh': 'always'}
		return {'words': l:matches}
	endif

endfunction

function! s:listOptions(filePath, line, column)
	let attributeMap = {}
	let attributeMap["line"] = a:line
	let attributeMap["column"] = a:column
	let attributeMap["currentFilePath"] = a:filePath

	"save content of current buffer in a temporary file
	let tempFilePath = tempname() . apexOs#splitPath(a:filePath).tail
	silent exe ":w! " . tempFilePath
	
	let attributeMap["currentFileContentPath"] = tempFilePath

	let responseFilePath = apexTooling#listCompletions(a:filePath, attributeMap)

	let subtractLen = s:getSymbolLength(a:column) " this many characters user already entered
	
	let l:completionList = []
	if filereadable(responseFilePath)
		for jsonLine in readfile(responseFilePath)
			if jsonLine !~ "{"
				continue " skip not JSON line
			endif
			let l:option = eval(jsonLine)
			
			let item = {}
			let item["word"] = l:option["identity"]
			if subtractLen > 0
				let item["abbr"] = l:option["identity"]
				let item["word"] = strpart(l:option["identity"], subtractLen-1, len(l:option["identity"]) - subtractLen + 1)
			endif
			let item["menu"] = l:option["signature"]
			let item["info"] = l:option["doc"]
			" let item["kind"] = l:option[""] " TODO
			let item["icase"] = 1 " ignore case
			let item["dup"] = 1 " allow methods with different signatures but same name
			call add(l:completionList, item)
		endfor

		"echomsg "l:completionList=" . string(l:completionList)
	endif
	return l:completionList
endfunction

"Return: length of the symbol under cursor
"e.g. if we are completing: Integer.va|
"then return will be len("va") = 2
function! s:getSymbolLength(column)
	let l:column = a:column
	let l:line = getline('.')
	" move back until get to a character which can not be part of
	" identifier
	let i = l:column-1
	let keepGoing = 1
	
	while keepGoing && i > 0
		let chr = strpart(l:line, i-1, 1)
		
		if chr =~? "\\w\\|_"
			let i -= 1
		else
			let keepGoing = 0
		endif
	endwhile

	return l:column - i
endfunction