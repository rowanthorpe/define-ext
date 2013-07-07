; define-ext_obj.lsp: plugin-file for define-ext, plugin-based
;                     foreign code embedder for newLISP (www.newlisp.org)
; Copyright © 2011 Rowan Thorpe
;
;    This file is part of define-ext
;
;    define-ext_obj.lsp is free software: you can redistribute it and/or modify
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
;    along with define-ext_obj.lsp  If not, see <http://www.gnu.org/licenses/>.
;
; To report bugs, submit patches or give feedback contact Rowan Thorpe at:
;    rowanthorpe - AT _ gmail _ DOT - com

(define (codetype-set-default-code)
	(set 'code '(0x31 0xC0 0xC3))) ; x86 No-op, return zero (no args, so same code for stdcall & cdecl)

(define (codetype-validate-code)
	(unless (for-all integer? code) (throw-error-full "Code has incorrect syntax for code-type \"obj\" -> " code)))

(define (codetype-set-local-vars) '())

(define (codetype-source-funcs) true)

(define (codetype-construct-source) code)

(define (codetype-compile-code source-code)
	(set (sym 'obj (sym func)) (pack (dup "b" (length source-code)) source-code)))

(define (codetype-get-func-addr)
	(address (eval (sym 'obj (sym func)))))