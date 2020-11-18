;;; -*- Mode:LISP; Package:SYSTEM-INTERNALS; Base:10; Readtable:ZL; Cold-Load:T -*-

;;; VERSIONS OF MINI THIS-AND-THAT TO GO WITH COLD-BI-INPUT-STREAM.

(DEFVAR MINI-FILE-ID)
(DEFVAR MINI-FASLOAD-FILENAME)
(DEFVAR MINI-PLIST-RECEIVER-POINTER)

(DEFUN MINI-OPEN-FILE (FILENAME BINARY-P)
  (SETUP-COLD-SHARED-MEMORY)
  (PRIN1 (LIST :OPEN FILENAME BINARY-P) 'COLD-BI-STREAM)
  (SETQ MINI-FILE-ID (READ 'COLD-BI-STREAM NIL))
  'COLD-BI-STREAM)

(DEFUN MINI-VIEWF (FILENAME)
  ;; this is mainly for testing the code.
  (LET ((F (mini-open-file filename nil)))
    (stream-copy-until-eof f standard-output)))

(DEFUN MINI-LOAD-FILE-ALIST (ALIST)
  (LOOP FOR (FILE PACK QFASLP) IN ALIST
        DO (PRINT FILE)
        DO (FUNCALL (IF QFASLP #'MINI-FASLOAD #'MINI-READFILE) FILE PACK)))


(DEFVAR *COLD-LOADED-FILE-PROPERTY-LISTS*)

(DEFUN MINI-FASLOAD (MINI-FASLOAD-FILENAME PKG
                     &AUX FASL-STREAM TEM)
  ;; Set it up so that file properties get remembered for when there are pathnames
  (OR (SETQ TEM (ASSOC MINI-FASLOAD-FILENAME *COLD-LOADED-FILE-PROPERTY-LISTS*))
      (PUSH (SETQ TEM (NCONS MINI-FASLOAD-FILENAME)) *COLD-LOADED-FILE-PROPERTY-LISTS*))
  (SETQ MINI-PLIST-RECEIVER-POINTER TEM)
  ;;Open the input stream in binary mode, and load from it.
  (SETQ FASL-STREAM (MINI-OPEN-FILE MINI-FASLOAD-FILENAME T))
  (FASLOAD-INTERNAL FASL-STREAM PKG T)
  ;; FASLOAD Doesn't really read to EOF, must read rest to avoid getting out of phase
  (DO ()
      ((NOT (SEND FASL-STREAM :TYI))))
  MINI-FASLOAD-FILENAME)

(DEFUN MINI-READFILE (FILE-NAME PKG &AUX (FDEFINE-FILE-PATHNAME FILE-NAME) TEM)
  (LET ((EOF '(()))
        (STANDARD-INPUT (MINI-OPEN-FILE FILE-NAME NIL))
        (PACKAGE (PKG-FIND-PACKAGE PKG)))
    (DO ((FORM))
        ((EQ (SETQ FORM (READ STANDARD-INPUT EOF)) EOF))
      (EVAL FORM))
    (OR (SETQ TEM (ASSOC FILE-NAME *COLD-LOADED-FILE-PROPERTY-LISTS*))
        (PUSH (SETQ TEM (NCONS FILE-NAME)) *COLD-LOADED-FILE-PROPERTY-LISTS*))
    (LET ((MINI-PLIST-RECEIVER-POINTER TEM))
      (SET-FILE-LOADED-ID 'MINI-PLIST-RECEIVER MINI-FILE-ID PACKAGE))))

;This kludge simulates the behavior of PROPERTY-LIST-MIXIN.
;It is used instead of the generic-pathname in fasloading and readfiling;
;it handles the same messages that generic-pathnames are typically sent.

(DEFUN MINI-PLIST-RECEIVER (OP &REST ARGS)
  (SELECTQ OP
    (:GET (GET MINI-PLIST-RECEIVER-POINTER (CAR ARGS)))
    (:GETL (GETL MINI-PLIST-RECEIVER-POINTER (CAR ARGS)))
    (:PUTPROP (PUTPROP MINI-PLIST-RECEIVER-POINTER (CAR ARGS) (CADR ARGS)))
    (:REMPROP (REMPROP MINI-PLIST-RECEIVER-POINTER (CAR ARGS)))
    (:PLIST (CAR MINI-PLIST-RECEIVER-POINTER))
    (:PUSH-PROPERTY (PUSH (CAR ARGS) (GET MINI-PLIST-RECEIVER-POINTER (CADR ARGS))))
    (OTHERWISE
     (PRINT "Bad op to MINI-PLIST-RECEIVER ")
     (PRINT OP)
     (%HALT))))
