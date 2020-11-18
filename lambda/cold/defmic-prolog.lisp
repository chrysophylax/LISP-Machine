;;; -*- Mode: Lisp; Base: 8. ; -*-

;;Distinguish between old and new Lisp systems. New ones have (semi) CommonLisp.
(cond ((neq 'user:x ':x) (sstatus feature COMMONLISP)))

#+(and (not cadr) commonlisp (not symbolics))
(SSTATUS FEATURE LEXICAL)

;#-cadr  this stuff no longer useful, and was causing problems.. --rg 7/30/85.
;(SET-SYNTAX-/#-MACRO-CHAR #/_ 'SI:XR-/#/O-MACRO)

;;; #_label generalizes (MC-LINKAGE label) to work for all labels in original
;;; assembly, not only the MC-LINKAGE declared ones.
;#+cadr
;(SET-SYNTAX-/#-MACRO-CHAR #/_ 'UA:/#/_-READER)

#-Commonlisp
(PROGN 'COMPILE
(DEFMIC OCCURS-IN #+cadr 762 #-cadr 240 (KEY TERM) T)
#-lexical (DEFMIC %INVOKE #+cadr 763 #-cadr 241 (CONTINUATION) T)
(DEFMIC %CELL0 #+cadr 764 #-cadr 447 () T)
(DEFMIC %UNTRAIL #+cadr 765 #-cadr 564 (MARK) T)
(DEFMIC %UNIFY-TERM-WITH-TERM #+cadr 767 #-cadr 753 (TERM-1 TERM-2) T)
(DEFMIC %CONSTRUCT 770 (TEMPLATE) T)
(DEFMIC %UNIFY-TERM-WITH-TEMPLATE 771 (TERM TEMPLATE) T)
(DEFMIC %CELL 772 (VARIABLE-NAME) T)
(DEFMIC %REFERENCE 773 (TERM) T)
(DEFMIC %DEREFERENCE 774 (TERM) T)
(DEFMIC %PROLOG-LIST 775 (&REST ELEMENTS-AND-COUNT) T T)
(DEFMIC %PROLOG-LIST* 776 (ELEMENT &REST ELEMENTS-AND-COUNT) T T)
(DEFMIC %CURRENT-ENTRYPOINT 777 (PREDICATOR ALIST-LOCATION) T)
)


#+Commonlisp
(PROGN 'COMPILE
(DEFMIC OCCURS-IN 1600 (KEY TERM) T)
#-lexical (DEFMIC %INVOKE 1601 (CONTINUATION) T)
(DEFMIC %CELL0 1602 () T)
(DEFMIC %UNTRAIL 1603 (MARK) T)
(DEFMIC %UNIFY-TERM-WITH-TERM 1604 (TERM-1 TERM-2) T)
(DEFMIC %CONSTRUCT 1605 (TEMPLATE) T)
(DEFMIC %UNIFY-TERM-WITH-TEMPLATE 1606 (TERM TEMPLATE) T)
(DEFMIC %CELL 1607 (VARIABLE-NAME) T)
(DEFMIC %REFERENCE 1610 (TERM) T)
(DEFMIC %DEREFERENCE 1611 (TERM) T)
(DEFMIC %CURRENT-ENTRYPOINT 1612 (PREDICATOR ALIST-LOCATION) T)
#+cadr (DEFMIC %PROLOG-LIST 1613 (&REST ELEMENTS-AND-COUNT) T T)
#+cadr (DEFMIC %PROLOG-LIST* 1614 (ELEMENT &REST ELEMENTS-AND-COUNT) T T)
)
