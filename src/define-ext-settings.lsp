; define-ext-settings.lsp: config for define-ext, plugin-based
;                          foreign code embedder for newLISP (www.newlisp.org)
; Copyright (c) 2011-2013 Rowan Thorpe
;
;    This file is part of define-ext
;
;    define-ext-settings.lsp is free software: you can redistribute it and/or modify
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
;    along with define-ext-settings.lsp  If not, see <http://www.gnu.org/licenses/>.
;
; To report bugs, submit patches or give feedback contact Rowan Thorpe at:
;    rowan - AT _ rowanthorpe _ DOT - com

(context 'define-ext)

;; Edit the below line to include your plugin - e.g. "ecl", "java" (GCJ), "rpython" (libpypy), "ada" (GNAT),
;; "fortran", "forth", maybe "rnewlisp"? (restricted subset of newlisp), so contexts could be saved/loaded like fasls..?
;; e.g. (set 'plugins '("obj" "c" "asm"))
(set 'plugins '("obj" "c" "asm"))

;; Edit the below line to update which directory to load code-type plugins from (nil means load from
;;  (append (env "NEWLISPDIR") "/modules")
;; directory).
;; e.g. (set 'plugins-load-dir nil)
;(set 'plugins-load-dir nil)

(set 'import-once-syms '())
(define (import-once)
	(unless (find (nth 1 (args)) import-once-syms)
		(eval (cons 'import (args)))
		(push (nth 1 (args)) import-once-syms -1)))

(define (warn)
	(println "define-ext: " (append (args))))
	
(define (set-cstring) (append (string (nth 0 (args))) "\000"))

(define-macro (calloc) (letex (sym-name (nth 0 (args))) (set sym-name (dup "\000" (eval (nth 1 (args)))))))

(define (check-nl-ffi) (not (zero? (& 0x400 (sys-info -1)))))

(define (get-nl-ver)
	(let (nl-ver-num (nth 8 (sys-info)))
		(list
			(or (integer (replace "^0*(.+)$" (slice (string nl-ver-num) 0 2) $1 0)) 0)
			(or (integer (slice (string nl-ver-num) 2 1)) 0)
			(or (integer (replace "^0*(.+)$" (slice (string nl-ver-num) 3) $1 0)) 0))))

(define (check-nl-ver->= major minor revision , nl-ver-list)
	(let ((major (or major 0)) (minor (or minor 0)) (revision (or revision 0)) (nl-ver-list (get-nl-ver)))
		(or
			(> (nth 0 nl-ver-list) major)
			(and (= (nth 0 nl-ver-list) major) (> (nth 1 nl-ver-list) minor))
			(and (= (nth 0 nl-ver-list) major) (= (nth 1 nl-ver-list) minor) (>= (nth 2 nl-ver-list) revision)))))

(define (check-nl-ver-= major minor revision , nl-ver-num nl-ver-list)
	(let ((major (or major 0)) (minor (or minor 0)) (revision (or revision 0)) (nl-ver-list (get-nl-ver)))
		(and 
			(= (nth 0 nl-ver-list) major)
			(= (nth 1 nl-ver-list) minor)
			(= (nth 2 nl-ver-list) revision))))

(define (throw-error-full) (eval (cons 'throw-error (eval (cons 'append (map string (args)))))))

(define-macro (first-or-val val in-list eval-flag) (local (temp-val)
	(if (list? in-list) (if (catch (first in-list) 'temp-val) (if eval-flag (eval temp-val) temp-val) val) val)))

(define (first-or-emptystring in-list eval-flag) (letex ((y in-list) (z eval-flag)) (first-or-val "" y z)))

(define (first-or-emptylist in-list eval-flag) (letex ((y in-list) (z eval-flag)) (first-or-val () y z)))

(define (first-or-nil in-list eval-flag) (letex ((y in-list) (z eval-flag)) (first-or-val nil y z)))

(define (first-or-zero in-list eval-flag) (letex ((y in-list) (z eval-flag)) (first-or-val 0 y z)))

;; Possibly useful for plugins, not yet used
;(define (type) (let (types '("bool" "bool" "integer" "float" "string" "symbol" "context" "primitive" "cdecl" "stdcall" "quote" "list" "lambda" "macro" "array")) (nth (& 0xf (nth 1 (dump (nth 0 (args))))) types)))
