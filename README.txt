define-ext: plugin-based embedder of compiled foreign code for newLISP (www.newlisp.org)
Version 0.4.2
Copyright (c) 2011-2013 Rowan Thorpe

A newLISP macro which allows the user to "define" callable foreign code inline
just as they would "define" a lambda or macro. C, Assembly and plain Object
Code plugins are included. The Object Code plugin has no external dependencies.
The C and Assembly plugins rely on the existence of a TCC .dll/.so file
somewhere in the PATH - www.tinycc.org (at present standard binary releases of
TCC don't include the .dll/.so file, but it can be easily compiled from the
source releases). New plugins for other compiled languages (like Fortran or
ECL) should be trivially easy to create using the existing ones as templates.

Features
========

* Portable
* Small
* Extensible

See USAGE for usage details and examples.
See COPYING for license details.
See INSTALL for installation instructions.
See "tools" directory for installation tools.
See "src" directory for the software of the module.

To report bugs, submit patches or give feedback contact Rowan Thorpe at:
   rowan - AT _ rowanthorpe _ DOT - com
