define-ext: plugin-based embedder of compiled foreign code for newLISP (www.newlisp.org)
Version 0.4
Copyright © 2011 Rowan Thorpe

See USAGE for usage details and examples.
See COPYING for license details.
See INSTALL for installation instructions.
See "tools" directory for installation tools.
See "src" directory for the software of the module.

To report bugs, submit patches or give feedback contact Rowan Thorpe at:
   rowanthorpe - AT _ gmail _ DOT - com

TODO:
  - [FEATURE]
      Add option to manually set whether using stdcall or cdecl (easy fix)
  - [ROBUSTNESS]
      Calculate decorations for stdcall based on arg-byte-sizes, rather than brute-forcing up in jumps
      of 4 bytes.
  - [FIXME]
      Move codetype-specific option sanity-checks into plugin-file functions, then call those from define-ext.lsp
  - [FEATURE]
      Add test scripts.
  - [FIXME?]
      Check if possible to heuristically do a get_symbol on object code (for pre-compiled C, like .o files),
      and then fall back to just making the entry-point at the beginning of the code...?
  - [FEATURE]
      Decide if there is any valid reason to implement define-ext-macro (should be easy, just remove evals).
  - [FEATURE]
      Create installer in tools dir, to automate installation.
  - [PORTABILITY]
      Set the right default obj and asm code for different platforms (presently only sets x86 defaults).
