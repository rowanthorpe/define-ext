define-ext: plugin-based embedder of compiled foreign code for newLISP (www.newlisp.org)
Version 0.4
Copyright (c) 2011 Rowan Thorpe

A newLISP (www.newlisp.org) macro which allows the user to "define" callable
foreign code inline just as they would "define" a lambda or macro. C, Assembly
and plain Object Code plugins are included. The Object Code plugin has no
external dependencies. The C and Assembly plugins rely on the existence of a
TCC .dll/.so file somewhere in the PATH - www.tinycc.org (at present standard
binary releases of TCC don't include the .dll/.so file, but it can be easily
compiled from the source releases). New plugins for other compiled languages
(like Fortran or ECL) should be trivially easy to create using the existing
ones as templates.

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
      Calculate decorations for stdcall based on arg-byte-sizes, rather than
      brute-forcing up in jumps of 4 bytes.
  - [FIXME]
      Move codetype-specific option sanity-checks into plugin-file functions,
      then call those from define-ext.lsp
  - [FEATURE]
      Add test scripts.
  - [FIXME?]
      Check if possible to heuristically do a get_symbol on object code (for
      pre-compiled C, like .o files), and then fall back to just making the
      entry-point at the beginning of the code...?
  - [FEATURE]
      Decide if there is any valid reason to implement define-ext-macro (should
      be easy, just remove evals).
  - [FEATURE]
      Create installer in tools dir, to automate installation.
  - [PORTABILITY]
      Set the right default obj and asm code for different platforms (presently
      only sets x86 defaults).
