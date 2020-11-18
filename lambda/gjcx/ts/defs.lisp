;;; -*- Mode:LISP; Package:SYSTEM-INTERNALS; Readtable:CL; Base:10 -*-

;;; A FIRST PASS AT THIS.
;;; ALLOW A SUBSET OF THE POSSIBLE CAPABILITIES OF DTP-INDEX-FORWARD.

;;; EXAMPLE USAGE:
;;; A PROGRAM IS LOADED. E.G. MACSYMA.
;;; AS NEW SYMBOLS ARE CREATED IN THAT PACKAGE THEY ARE GIVEN INDEXES AND FORWARDED.
;;; THE PROGRAM IS LOADED WITHOUT BINDING *INDEXED-CELL-ARRAY*.
;;; THEN WHEN YOU WANT TO RUN YOUR OWN COPY OF THE PROGRAM
;;; LET ((*INDEXED-CELL-ARRAY* (NEW-INDEXED-CELL-ARRAY))).


;;; 12-Sep-86 10:57:22 -GJC
;;; now working with DOE-MACSYMA.
;;; TO DO:
;;;  hack SI:FASL-OP-FRAME to call RELINK-FEF-EXIT-VECTOR
;;;  hack DISASSEMBLE-ADDRESS-CONTENTS and DISASSEMBLE-POINTER
;;;       to handle DTP-INDEXED-FORWARD in fef exit vectors.
;;;  hack FIND-CALLERS-OF-SYMBOLS-AUX-FEF and ANALYZE-COMPILED-FUNCTION
;;;  what are other things that look at FEF's like that?
;;;  all references to DTP-EXTERNAL-VALUE-CELL-POINTER?

(DEFVAR *DEFAULT-INDEX-ARRAY-SIZE*)

(DEFVAR *GLOBAL-INDEXED-CELL-ARRAY*)

(DEFVAR *INDEX-NAME-TABLE*)

(DEFVAR *INDEXED-CELL-ARRAY*)

(DEFVAR *INDEX-ALLOCATION-TABLE*)

(DEFVAR *INDEX-UNALLOCATED*)

(DEFSTRUCT (CELL-PLACE (:CONC-NAME CELL-PLACE.)
                       (:PRINT "#<CELL-PLACE ~S ~O>"
                               (LENGTH (CELL-PLACE.ARRAY CELL-PLACE))
                               (%POINTER (CELL-PLACE.ARRAY CELL-PLACE))))
  ARRAY)

(DEFVAR *CELL-ARRAYS*)


(DEFVAR *ASSOCIATED-INDEXED-CELL-ARRAYS*)
