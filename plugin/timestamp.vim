" TimeStamp 1.14: Vim plugin for automated time stamping.
" Maintainor:		Gautam Iyer <gautam@math.uchicago.edu>
" Created:		Fri 06 Feb 2004 02:46:27 PM CST
" Last Modified:	Thu 20 May 2004 01:27:05 PM CDT
" License:		This file is placed in the public domain.
"
" Credits:		Thanks to Guido Van Hoecke for writing the original
"			vim script "timstamp.vim".
" Discription:
"   When a file is written, and the filename matches "timestamp_automask",
"   this plugin will search the first and last "timestamp_modelines" lines of
"   your file. If it finds the regexp "timestamp_regexp" then it will replace
"   it with a timestamp. The timestamp is computed by first doing a
"   "token_substitution" on "timestamp_rep" and passing the result to
"   "strftime()". See the documentation for details.

" provide load control
if exists("loaded_timestamp")
    finish
endif
let loaded_timestamp = 1

let s:cpo_save = &cpo
set cpo&vim		" line continuation is used

function s:getValue(deflt, globl, ...)
    " helper function to define script variables by using first any specified
    " global value, any non zero value from the optional parameters, and
    " finally if all these fail to provide a value, by using the default value
    if exists(a:globl)
	let work = "let value = " . a:globl
	exe work
	return value
    endif
    let indx = 1
    while indx <= a:0
	let work = "let value = a:" . indx
	exe work
	if value != ""
	    return value
	endif
	let indx = indx + 1
    endwhile
    return a:deflt 
endfunction

" Default timestamp expressions
let s:timestamp_regexp = s:getValue('\v\C%(<Last %([cC]hanged?|[Mm]odified):\s+)@<=\a{3} \d{2} \a{3} \d{4} \d{2}:\d{2}:\d{2} [AP]M ?%(\a+)?|TIMESTAMP', 'g:timestamp_regexp')
" %c seems to be different on different systems. Use a full form instead.
let s:timestamp_rep = s:getValue('%a %d %b %Y %I:%M:%S %p %Z', 'g:timestamp_rep')

" Plugin Initialisations.
let s:automask   = s:getValue('*', 'g:timestamp_automask')
let s:hostname   = s:getValue(substitute(hostname(), '.* ', '', ''), 
			\ 'g:timestamp_hostname', $HOSTNAME)
let s:Hostname   = s:getValue(hostname(), 'g:timestamp_hostname', $HOSTNAME)
let s:modelines  = s:getValue(&modelines, 'g:timestamp_modelines')
let s:userid     = s:getValue($LOGNAME, 'g:timestamp_userid')
let s:username   = s:getValue($USERNAME, 'g:timestamp_username')

let s:autocomm   = "autocmd BufWrite " . s:automask . " :call s:timestamp()"
augroup TimeStamp
    " this autocommand triggers the update of the requested timestamps
    au!
    exec s:autocomm
augroup END

" Free up memory and delete unused functions / variables
delfunction s:getValue
unlet s:autocomm

" Function that does the timestamping
function s:timestamp()
    " Get search and replacement patterns. Buffer local pattern overrides
    let pat = exists("b:timestamp_regexp") ? b:timestamp_regexp : s:timestamp_regexp
    let rep = exists("b:timestamp_rep") ? b:timestamp_rep : s:timestamp_rep

    " Process the replacement pattern
    let rep = strftime(rep)
    let rep = substitute(rep, "#f", expand("%:p:t"), "g")
    let rep = substitute(rep, "#h", s:hostname, "g")
    let rep = substitute(rep, "#H", s:Hostname, "g")
    let rep = substitute(rep, "#n", s:username, "g")
    let rep = substitute(rep, "#u", s:userid, "g")

    " Escape forward slashes
    let pat = escape(pat, '/')
    let rep = escape(rep, '/')

    " Get ranges for timestamp to be located
    let l:modelines = (s:modelines == '%') ? line('$') : s:modelines

    if line('$') > 2 * l:modelines
	call s:subst(1, l:modelines, pat, rep)
	call s:subst(line('$') + 1 - l:modelines, line('$'), pat, rep)
    else
	call s:subst(1, line('$'), pat, rep)
    endif
endfunction

function s:subst(start, end, pat, rep)
    let lineno = a:start
    while lineno <= a:end
	let curline = getline(lineno)
	if match(curline, a:pat) != -1
	    call setline(lineno, substitute(curline, a:pat, a:rep, 'g'))
	endif
	let lineno = lineno + 1
    endwhile
endfunction

" Restore compatibility options
let &cpo = s:cpo_save
