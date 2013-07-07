; define-ext_asm.lsp: plugin-file for define-ext, plugin-based
;                     foreign code embedder for newLISP (www.newlisp.org)
; Copyright © 2011 Rowan Thorpe
;
;    This file is part of define-ext
;
;    define-ext_asm.lsp is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with define-ext_asm.lsp  If not, see <http://www.gnu.org/licenses/>.
;
; To report bugs, submit patches or give feedback contact Rowan Thorpe at:
;    rowanthorpe - AT _ gmail _ DOT - com
;
; NB:
; (1) If creating an "asm" plugin to use an assembler rather than the embedded
;     asm function in the TCC compiler, then include the code which the
;     embedded asm() function would have done for you ("ret", and
;     setup/completion code), for example:
;        "pushl %ebp\n\t"
;        "movl %esp, %ebp\n\t"
;         ...main code as before...
;        "popl %ebp\n\t"
;        "ret" (cdecl) or "ret $[number of arg-bytes]" (stdcall)
;
; (2) Use this plugin for standard AT&T assembly code - for extended assembly
;     (in the form understood by GCC) it is easier to just use the "c" plugin
;     and embed code within that using the asm("w" : ="x" : "y" : "z") format
;     of the asm function. This plugin uses that function in its unextended
;     form, asm("w").

(define (csym-addr) ; [0]=addr, [1]=mangling-number ([1] only for stdcall/Win32)
	(if (= ostype "Win32")
		(let ((decorator 0) (addr 0)) (list
			(begin (do-while
					(and (< decorator 260) (= addr 0))
					(set 'addr (tcc_get_symbol (eval (sym 'obj (sym func))) (set-cstring (append "_" func "@" (string decorator)))))
					(++ decorator 4))
				addr)
			decorator))
		(list (tcc_get_symbol (eval (sym 'obj (sym func))) (set-cstring func)) nil)))

(define (codetype-set-default-code)
	(let (mangle-num (nth 1 (csym-addr)))
		(set 'code (list (append
			"\"\txorl %eax, %eax"
			(when (and (= ostype "Win32") (> mangle-num 0)) (append ";\n\tpopl %ebp;\n\tret $" (string mangle-num)))
			"\"")))))

(define (codetype-validate-code)
	(unless (for-all string? code) (throw-error-full "Code has incorrect syntax for code-type \"" code-type "\" -> " code)))

(define (codetype-set-local-vars)
	'(tcc-obj))

(define (codetype-source-funcs)
	(let (lib-file (append "libtcc." (case ostype ("Win32" "dll") ("OSX" "dylib") (true "so"))))
		(import-once lib-file "tcc_new" "cdecl")
		(import-once lib-file "tcc_set_output_type" "cdecl")
		(import-once lib-file "tcc_compile_string" "cdecl")
		(import-once lib-file "tcc_add_symbol" "cdecl")
		(import-once lib-file "tcc_relocate" "cdecl")
		(import-once lib-file "tcc_get_symbol" "cdecl")
		(import-once lib-file "tcc_delete" "cdecl")))

(define (codetype-construct-source)
	(append
		(join (append
			(map (fn (x) (append "#include <" x ">\n")) sys-includes) (map (fn (x) (append "#include \"" x "\"\n")) priv-includes) '("\n")))
		preamble "\n"
		(append out-type " " (when (= ostype "Win32") "__attribute__((stdcall)) ") func "(" (join in-types ", ") ") {\n__asm__ __volatile__(\n" (join code) "\n);\n}\n")))

(define (codetype-compile-code source-code)
	(set 'tcc-obj (tcc_new))
	(when (not (and (integer? tcc-obj) (> tcc-obj 0))) (throw-error "Problem with tcc_new"))
	(tcc_set_output_type tcc-obj 0)
	(when (= (tcc_compile_string tcc-obj (set-cstring source-code)) -1) (throw-error "Problem with tcc_compile_string"))
	(local (insert-sym) (dolist (insert-sym insert-symbols) (tcc_add_symbol tcc-obj (set-cstring (nth 0 insert-sym)) (nth 1 insert-sym))))
	(let (size (tcc_relocate tcc-obj 0))
		(when (< size 0) (throw-error "Problem finding size using tcc_relocate NULL (0)"))
		(calloc (sym 'obj (sym func)) size))
	(tcc_relocate tcc-obj (eval (sym 'obj (sym func)))))

(define (codetype-get-func-addr)
	(let (func-addr (nth 0 (csym-addr)))
		(when (not (and (integer? func-addr) (> func-addr 0))) (throw-error "Problem with tcc_get_symbol"))
		(tcc_delete tcc-obj)
		func-addr))