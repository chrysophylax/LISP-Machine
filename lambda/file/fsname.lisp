;;; -*- Mode: Lisp; Package: File-System; Base: 10.; Readtable: T -*-

;; This file contains the access interface to the local file system.

(DEFFLAVOR LOCAL-FILE-ACCESS () (DIRECTORY-LIST-MIXIN BASIC-ACCESS))

(DEFINE-FILE-ACCESS LOCAL-FILE-ACCESS .95S0 (:LOCAL))

(DEFMETHOD (LOCAL-FILE-ACCESS :RESET) () (SEND SELF :CLOSE-ALL-FILES))

(DEFMETHOD (LOCAL-FILE-ACCESS :OPEN-STREAMS) ()
  LM-FILE-STREAMS-LIST)

(DEFMETHOD (LOCAL-FILE-ACCESS :ACCESS-DESCRIPTION) ()
  "Direct access to the file system on this disk.")

(DEFMETHOD (LOCAL-FILE-ACCESS :CLOSE-ALL-FILES) ()
  (DOLIST (S LM-FILE-STREAMS-LIST)
    (CLOSE S)))

(DEFMETHOD (LOCAL-FILE-ACCESS :HOMEDIR) (&OPTIONAL (USER USER-ID))
  (FERROR NIL "Should not get here."))

(DEFMETHOD (LOCAL-FILE-ACCESS :CHANGE-PROPERTIES) (PATHNAME ERROR-P &REST PLIST)
  (IDENTIFY-FILE-OPERATION :CHANGE-PROPERTIES
    (HANDLING-ERRORS ERROR-P
      (OPEN-INPUT-FILE (FILE PATHNAME)
        (LMFS-CHANGE-FILE-PROPERTIES FILE PLIST)))))

(DEFMETHOD (LOCAL-FILE-ACCESS :PROPERTIES) (PATHNAME &OPTIONAL ERROR-P)
  (IDENTIFY-FILE-OPERATION :PROPERTIES
    (HANDLING-ERRORS ERROR-P
      (OPEN-INPUT-FILE (F PATHNAME)
        (VALUES (CONS (FILE-TRUENAME F) (LMFS-FILE-PROPERTIES F))
                LM-UNSETTABLE-PROPERTIES)))))

(DEFMETHOD (LOCAL-FILE-ACCESS :COMPLETE-STRING) (PATHNAME STRING OPTIONS)
  (MULTIPLE-VALUE-BIND (DEV DIR NAM TYP VER)
      (SEND PATHNAME :PARSE-NAMESTRING HOST STRING)
    (MULTIPLE-VALUE-BIND (NEW-DIRECTORY NEW-NAME NEW-TYPE COMPLETION)
        (LMFS-COMPLETE-PATH (OR DIR (PATHNAME-DIRECTORY PATHNAME) "")
                            (OR NAM "") (OR TYP "")
                            NAME TYPE OPTIONS)
      (VALUES (LM-NAMESTRING HOST (OR DEV DEVICE) NEW-DIRECTORY NEW-NAME NEW-TYPE VER)
              COMPLETION))))

(DEFMETHOD (LOCAL-FILE-ACCESS :CREATE-DIRECTORY) (PATHNAME &OPTIONAL (ERROR T))
  (IDENTIFY-FILE-OPERATION :CREATE-DIRECTORY
    (HANDLING-ERRORS ERROR
      (LMFS-CREATE-DIRECTORY (PATHNAME-DIRECTORY PATHNAME))
      T)))

(DEFMETHOD (LOCAL-FILE-ACCESS :CREATE-LINK) (PATHNAME TARGET (ERROR T))
  TARGET
  (HANDLING-ERRORS ERROR
    (LM-SIGNAL-ERROR 'LINKS-NOT-SUPPORTED NIL NIL :CREATE-LINK)))

(DEFMETHOD (LOCAL-FILE-ACCESS :REMOTE-CONNECT) (&REST IGNORE)
  TARGET
  (HANDLING-ERRORS ERROR
    (LM-SIGNAL-ERROR 'REMOTE-CONNECT-NOT-SUPPORTED NIL NIL :CREATE-LINK)))

(DEFMETHOD (LOCAL-FILE-ACCESS :OPEN) (FILE PATHNAME &REST OPTIONS)
  (APPLY 'LMFS-OPEN-FILE PATHNAME
         (PATHNAME-RAW-DIRECTORY PATHNAME)
         (PATHNAME-RAW-NAME PATHNAME)
         (PATHNAME-RAW-TYPE PATHNAME)
         (PATHNAME-RAW-VERSION PATHNAME)
         OPTIONS))

(DEFMETHOD (LOCAL-FILE-ACCESS :DIRECTORY-LIST) (PATHNAME OPTIONS)
  (LMFS-DIRECTORY-LIST SELF HOST
         (PATHNAME-RAW-DIRECTORY PATHNAME)
         (PATHNAME-RAW-NAME PATHNAME)
         (PATHNAME-RAW-TYPE PATHNAME)
         (PATHNAME-RAW-VERSION PATHNAME)
         OPTIONS))

(DEFMETHOD (LOCAL-FILE-ACCESS :RENAME) (PATHNAME NEW-NAME &OPTIONAL (ERROR-P T))
  (IDENTIFY-FILE-OPERATION :RENAME
    (HANDLING-ERRORS ERROR-P
      (OPEN-INPUT-FILE (FILE PATHNAME)
        (LMFS-RENAME-FILE FILE
                          (PATHNAME-DIRECTORY NEW-NAME)
                          (OR (PATHNAME-NAME NEW-NAME) "FOO")
                          (OR (PATHNAME-TYPE NEW-NAME) :UNSPECIFIC)
                          (PATHNAME-VERSION NEW-NAME))))))

(DEFMETHOD (LOCAL-FILE-ACCESS :DELETE) (PATHNAME &OPTIONAL (ERROR-P T))
  (IDENTIFY-FILE-OPERATION :DELETE
    (HANDLING-ERRORS ERROR-P
      (OPEN-INPUT-FILE (FILE PATHNAME)
        (LMFS-DELETE-FILE FILE)))))

(DEFMETHOD (LOCAL-FILE-ACCESS :UNDELETE) (PATHNAME &OPTIONAL (ERROR-P T))
  (IDENTIFY-FILE-OPERATION :UNDELETE
    (HANDLING-ERRORS ERROR-P
      (OPEN-INPUT-FILE (FILE PATHNAME)
        (LMFS-UNDELETE-FILE FILE)))))

(DEFMETHOD (LOCAL-FILE-ACCESS :EXPUNGE) (PATHNAME &OPTIONAL (ERROR T))
  (IDENTIFY-FILE-OPERATION :EXPUNGE
    (HANDLING-ERRORS ERROR
      (LMFS-EXPUNGE-DIRECTORY
        (PATHNAME-RAW-DIRECTORY PATHNAME)
        (PATHNAME-RAW-NAME PATHNAME)
        (PATHNAME-RAW-TYPE PATHNAME)
        (PATHNAME-RAW-VERSION PATHNAME)))))

;;;???
(DEFMETHOD (LOCAL-FILE-ACCESS :DELETE-MULTIPLE-FILES) (ERROR-P PATHNAMES)
  (IDENTIFY-FILE-OPERATION :DELETE
    (HANDLING-ERRORS ERROR-P
       (LOOP FOR PATHNAME IN PATHNAMES
             WITH FILES-OF-DIRECTORY-TO-WRITE = NIL
             DO (OPEN-INPUT-FILE (FILE PATHNAME)
                   (LMFS-DELETE-FILE FILE NIL)
                   (LOOP FOR ENTRY IN FILES-OF-DIRECTORY-TO-WRITE
                         WHEN (EQUAL (FILE-DIRECTORY FILE) (FILE-DIRECTORY ENTRY))
                         RETURN NIL
                         FINALLY (PUSH FILE FILES-OF-DIRECTORY-TO-WRITE)))
             FINALLY
             (DOLIST (FILE FILES-OF-DIRECTORY-TO-WRITE)
               (WRITE-DIRECTORY-OF-FILE FILE))))))

(DEFMETHOD (LOCAL-FILE-ACCESS :ALL-DIRECTORIES) (OPTIONS)
  (LMFS-ALL-DIRECTORIES HOST (NOT (MEMQ :NOERROR OPTIONS))))

(DEFMETHOD (LOCAL-FILE-ACCESS :MULTIPLE-FILE-PLISTS) (PATHNAMES OPTIONS)
  "This is a hack to speed up DIRED.
There are no currently meaningful options." OPTIONS
  (IDENTIFY-FILE-OPERATION :PROPERTIES
    (MAPCAR #'(LAMBDA (PATHNAME)
                (LET ((TPATHNAME (SEND PATHNAME :TRANSLATED-PATHNAME)))
                  (OPEN-INPUT-FILE (FILE TPATHNAME)
                    (IF (NULL FILE)
                        (LIST PATHNAME)
                      (LIST* PATHNAME
                             :TRUENAME (FILE-TRUENAME FILE)
                             (LMFS-FILE-PROPERTIES FILE))))))
            PATHNAMES)))

(COMPILE-FLAVOR-METHODS LOCAL-FILE-ACCESS)
