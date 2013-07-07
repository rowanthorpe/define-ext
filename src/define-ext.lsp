; define-ext.lsp: plugin-based foreign code embedder for newLISP
;                 (www.newlisp.org)
; Copyright (c) 2011-2013 Rowan Thorpe
;
;    This file is part of define-ext
;
;    define-ext.lsp is free software: you can redistribute it and/or modify
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
;    along with define-ext.lsp  If not, see <http://www.gnu.org/licenses/>.
;
; To report bugs, submit patches or give feedback contact Rowan Thorpe at:
;    rowan - AT _ rowanthorpe _ DOT - com

(set 'MAIN:define-ext-oldcontext (context))
(context 'define-ext)

;;;; BEGIN EDITING HERE
;; Edit the below line to hardwire which directory to load code-type plugins from (nil means load from
;;  (append (env "NEWLISPDIR") "/modules")
;; directory).
;; e.g. (set 'plugins-load-dir nil)
(set 'plugins-load-dir nil)
;;;; END EDITING HERE

(local (err)
	(catch (load (append
		(cond
			(plugins-load-dir (append plugins-load-dir "/"))
			((env "NEWLISPDIR") (append (env "NEWLISPDIR") "/modules/"))
			(true ""))
		"define-ext-settings.lsp")) 'err))
(set 'plugins-combined-code
	(let ( (plugins-to-load '()) (plugins-to-load-files '()) (buffer "") (plugin) (x))
		(dolist (plugin plugins)
			(let (plugin-file
					(append (cond
							(plugins-load-dir
								(append plugins-load-dir "/"))
							((env "NEWLISPDIR")
								(append (env "NEWLISPDIR") "/modules/"))
							(true
								""))
						"define-ext_" plugin ".lsp"))
				(when (and (file? plugin-file) (not (directory? plugin-file)) (> (file-info plugin-file 0 true) 0))
					(push plugin plugins-to-load -1)
					(push plugin-file plugins-to-load-files -1))))
		(if (> (length plugins-to-load) 1)
			(begin
				(extend buffer "(case code-type\n")
				(dotimes (x (length plugins-to-load))
					(extend buffer
						(append
							"(\"" (nth x plugins-to-load) "\"\n"
							(read-file (nth x plugins-to-load-files)) ")\n")))
				(extend buffer ")\n"))
			(throw-error "No loadable plugins found"))
		(append buffer "\n")))
(set 'define-ext:define-ext
	'(lambda-macro ()
;; setup and sanity-check options
		(let (	(codetype-validate-code) (codetype-set-local-vars) (codetype-set-default-code) (codetype-source-funcs)
				(codetype-construct-source) (codetype-compile-code) (codetype-get-func-addr)
				(valid-code-types (append '(() nil "") plugins))
				(code (map eval (rest (args))))
				(args-len (length (args)))
				(params (first-or-emptylist (args))))
			(unless (> args-len 0)
				(throw-error-full "Wrong number of arguments -> " args-len " (should be 1 or more)"))
			(unless (list? params)
				(throw-error-full "Params are not a list -> " params))
			(let (	(params-len (length params))
					(func (first-or-nil params))
					(opts (first-or-emptylist (rest params))))
				(unless (find params-len '(1 2))
					(throw-error-full "Wrong number of parameters -> " params-len " (should be 1 or 2)"))
				(unless (symbol? func)
					(throw-error-full "Function parameter is not a symbol -> " func))
				(set 'func (term func))
				(when (find "[^a-zA-Z0-9_]" func 0)
					(throw-error-full "Unusable character in func -> " func " (should only include [a-zA-Z0-9_])"))
				(unless (list? opts)
					(throw-error-full "Options are not a list -> " opts))
				(let (	(opts-len (length opts))
						(code-type (first-or-emptystring opts true))
						(out-type (first-or-emptystring (slice opts 1) true))
						(in-types (map eval (first-or-emptylist (slice opts 2))))
						(sys-includes (map eval (first-or-emptylist (slice opts 3))))
						(priv-includes (map eval (first-or-emptylist (slice opts 4))))
						(preamble (first-or-emptystring (slice opts 5) true))
						(insert-symbols (map (lambda (x) (map eval x)) (first-or-emptylist (slice opts 6)))))
					(when (> opts-len 0) (unless (find code-type valid-code-types)
						(throw-error-full "Code-type option has incorrect syntax -> " code-type)))
					(when (> opts-len 1)
						(when (find code-type '("obj" () nil ""))
							(throw-error-full "Options were specified for " code-type " code-type, which is not allowed"))
						(unless (or (find out-type '(() nil)) (string? out-type))
							(throw-error-full "Output-type option has incorrect syntax -> " out-type)))
					(when (> opts-len 2) (unless (and (list? in-types) (for-all (lambda (x) (or (find x '(() nil)) (string? x))) in-types))
						(throw-error-full "Input-types option has incorrect syntax -> " in-types)))
					(when (> opts-len 3) (unless (and (list? sys-includes) (for-all (lambda (x) (or (find x '(() nil)) (string? x))) sys-includes))
						(throw-error-full "System-includes option has incorrect syntax -> " sys-includes)))
					(when (> opts-len 4) (unless (and (list? priv-includes) (for-all (lambda (x) (or (find x '(() nil)) (string? x))) priv-includes))
						(throw-error-full "Private-includes option has incorrect syntax -> " priv-includes)))
					(when (> opts-len 5) (unless (or (find preamble '(() nil)) (string? preamble))
						(throw-error-full "Preamble option has incorrect syntax -> " preamble)))
					(when (> opts-len 6) (unless (and (list? insert-symbols) (for-all (lambda (x) (or (find x '("" () nil)) (and (list? x) (= (length x) 2) (string? (nth 0 x)) (integer? (nth 1 x))))) insert-symbols))
						(throw-error-full "Insert-symbols has incorrect syntax -> " insert-symbols)))
;; set defaults and type-dependent functions
					(when (find out-type '(() nil "")) (set 'out-type "void"))
					(when (find in-types '((()) (nil) ("") ())) (set 'in-types '("void")))
					(when (find code-type '("asm")) (unless (and (= out-type "void") (= in-types '("void"))) (warn "A non-void type was specified for code-type " code-type " which is pointless because it doesn't use in or output in that way")))
					(when (find sys-includes '((()) (nil) (""))) (set 'sys-includes '()))
					(when (find priv-includes '((()) (nil) (""))) (set 'priv-includes '()))
					(when (find preamble '(() nil)) (set 'preamble ""))
					(when (find insert-symbols '((()) (nil) ("") () nil "")) (set 'insert-symbols '()))
					(when (find code-type '(() nil "")) (set 'code-type "obj"))
					(eval-string plugins-combined-code)
					(when (find code '((()) (nil) ("") ())) (codetype-set-default-code))
					(codetype-validate-code)
;; main
					(set (sym 'name (sym func)) (string func))
					(if (check-nl-ver->= 10 3 10)
						(begin ; don't need pull-through lambda
							(set (sym func (sym func)) print)
							(letex (local-var-list (codetype-set-local-vars))
								(local local-var-list
									(codetype-source-funcs)
									(codetype-compile-code (codetype-construct-source))
									(set (sym 'addr (sym func)) (codetype-get-func-addr))
									(let (caller-addr (first (dump (eval (sym func (sym func))))))
										(cpymem (pack "ld" (if (= ostype "Win32") 2312 1288)) caller-addr 4)
										(cpymem (pack "ld" (eval (sym 'name (sym func)))) (+ caller-addr 8) 4)
										(cpymem (pack "ld" (eval (sym 'addr (sym func)))) (+ caller-addr 12) 4))))
							true)
						(begin ; use pull-through lambda
							(set (sym 'caller (sym func)) print)
							(letex (local-var-list (codetype-set-local-vars))
								(local local-var-list
									(codetype-source-funcs)
									(codetype-compile-code (codetype-construct-source))
									(set (sym 'addr (sym func)) (codetype-get-func-addr))
									(let (caller-addr (first (dump (eval (sym 'caller (sym func))))))
										(if	(and
												(check-nl-ffi)
												(check-nl-ver-= 10 3 9))
											(throw-error "newLISP v10.3.9 with libffi support has a bug preventing define-ext from being able to link in foreign code. It is not a problem on any newLISP version other than 10.3.9 (before or after), and also on 10.3.9 if it is compiled without libffi support. Please use one of those options."))
										(cpymem (pack "ld" (if (= ostype "Win32") 265 264)) caller-addr 4)
										(cpymem (pack "ld" (eval (sym 'name (sym func)))) (+ caller-addr 8) 4)
										(cpymem (pack "ld" (eval (sym 'addr (sym func)))) (+ caller-addr 12) 4))))
							(letex ((func-func (sym func (sym func)))
									(func-caller (sym 'caller (sym func))))
								(define-macro (func-func) (eval (cons func-caller (args)))))
							true)))))))
(context MAIN:define-ext-oldcontext)
(delete 'MAIN:define-ext-oldcontext)