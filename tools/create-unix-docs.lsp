;; create-unix-docs.lsp
;
; Run this from within a directory to create "\n" docs from any "\r\n" docs
; which are there.
(dolist	(filename (filter (fn () (regex ".txt$" (nth 0 (args)))) (directory)))
	(write-file (append (real-path) "/" (replace ".txt$" (copy filename) "" 0))
		(replace "\r\n" (read-file (append (real-path) "/" filename)) "\n" 0)))