;;; Lisp Machine mail reader -*- Mode:LISP; Package:ZWEI; Base:8 ; Readtable : ZL-*-
;;; Some special ZMAIL windows, definition are in DEFS
;;; ** (c) Copyright 1980 Massachusetts Institute of Technology **

(DEFFLAVOR ZMAIL-OVERLYING-WINDOW () (EDITOR-STREAM-WINDOW)
  (:DEFAULT-INIT-PLIST :MORE-P NIL))

(DEFMETHOD (ZMAIL-OVERLYING-WINDOW :DELETE-TEXT) ()
  (SYS:%USING-BINDING-INSTANCES (CLOSURE-BINDINGS EDITOR-CLOSURE))
  (DELETE-INTERVAL *INTERVAL*)
  (MUST-REDISPLAY SELF DIS-ALL))

(DEFMETHOD (ZMAIL-OVERLYING-WINDOW :MOVE-TO-END) ()
  (SYS:%USING-BINDING-INSTANCES (CLOSURE-BINDINGS EDITOR-CLOSURE))
  (MOVE-BP *STREAM-BP* (INTERVAL-LAST-BP *INTERVAL*))
  (MUST-REDISPLAY SELF DIS-BPS)
  (STREAM-REDISPLAY))

(DEFMETHOD (ZMAIL-OVERLYING-WINDOW :VIEW-STREAM) (STREAM
                                                  &OPTIONAL RETURN-IF-NO-MORE
                                                  &AUX (*STANDARD-INPUT* SI:SYN-TERMINAL-IO)
                                                       (*TERMINAL-IO* *STREAM-SHEET*))
  (SYS:%USING-BINDING-INSTANCES (CLOSURE-BINDINGS EDITOR-CLOSURE))
  ;; If everything has been typed out correctly, update the window datastructure
  (AND (< (WINDOW-REDISPLAY-DEGREE *WINDOW*) DIS-TEXT)
       (FAKE-OUT-TOP-LINE *WINDOW* *INTERVAL*))
  (VIEW-WINDOW *WINDOW* STREAM RETURN-IF-NO-MORE))

(DEFMETHOD (ZMAIL-OVERLYING-WINDOW :TRUNCATED-FORMAT) (&REST FORMAT-ARGS)
  (UNWIND-PROTECT
    (PROGN
      (SETF (TV:SHEET-TRUNCATE-LINE-OUT-FLAG) 1)
      (AND (*CATCH 'LINE-OVERFLOW
             (PROG1 NIL
               (APPLY 'FORMAT SELF FORMAT-ARGS)))
           (LET ((LINE (BP-LINE *STREAM-BP*)))
             (MULTIPLE-VALUE-BIND (NIL NIL I)
                 (TV:SHEET-COMPUTE-MOTION SELF 0 0 LINE 0 NIL NIL
                                          TV:(- CURSOR-X (SHEET-INSIDE-LEFT)) 0)
               (LET ((*INTERVAL* INTERVAL))
                 (AND I (DELETE-INTERVAL (CREATE-BP LINE I) (END-OF-LINE LINE))))))))
    (SETF (TV:SHEET-TRUNCATE-LINE-OUT-FLAG) 0)))

(DEFMETHOD (ZMAIL-OVERLYING-WINDOW :BEFORE :END-OF-LINE-EXCEPTION) ()
  (OR (ZEROP (TV:SHEET-TRUNCATE-LINE-OUT-FLAG))
      (*THROW 'LINE-OVERFLOW T)))

(DEFFLAVOR TRUNCATING-MOUSE-SENSITIVE-ITEMS ((TRUNCATE-P NIL)) ()
  (:REQUIRED-FLAVORS TV:BASIC-MOUSE-SENSITIVE-ITEMS))

(DEFMETHOD (TRUNCATING-MOUSE-SENSITIVE-ITEMS :TRUNCATED-ITEM) (TYPE ITEM &REST FORMAT-ARGS)
  ;; Do this before recording the Y position in case of more processing and wraparound
  (SEND SELF :HANDLE-EXCEPTIONS)
  (LET ((ENTRY (LIST TYPE ITEM TV:CURSOR-X TV:CURSOR-Y TV:(SHEET-INSIDE-RIGHT)
                     TV:(+ CURSOR-Y LINE-HEIGHT))))
    (PUSH ENTRY TV:ITEM-LIST)
    (*CATCH 'LINE-OVERFLOW
      (LET-GLOBALLY ((TRUNCATE-P T))
        (IF FORMAT-ARGS (APPLY 'FORMAT SELF FORMAT-ARGS) (PRINC ITEM SELF))
        (SETF (FIFTH ENTRY) TV:CURSOR-X)))))

(DEFMETHOD (TRUNCATING-MOUSE-SENSITIVE-ITEMS :BEFORE :END-OF-LINE-EXCEPTION) ()
  (AND TRUNCATE-P
       (*THROW 'LINE-OVERFLOW T)))

(DEFFLAVOR ZMAIL-TYPEOUT-WINDOW () (TRUNCATING-MOUSE-SENSITIVE-ITEMS EDITOR-TYPEOUT-WINDOW
                                    ARROW-PRINTING-MIXIN)
  (:DEFAULT-INIT-PLIST :ITEM-TYPE-ALIST *ZMAIL-TYPEOUT-ITEM-ALIST*))

(DEFMETHOD (ZMAIL-TYPEOUT-WINDOW :MORE-TYI) ()
  (DO ((CH)) (NIL)
    (AND (OR (NUMBERP (SETQ CH (SEND SELF :ANY-TYI)))
             (AND (CONSP CH)
                  (MEMQ (CAR CH) '(:TYPEOUT-EXECUTE SUMMARY-EXECUTE :MENU :MOUSE
                                   SUMMARY-MOUSE MODE-LINE :MOUSE-BUTTON))))
         (RETURN CH))))

(DEFFLAVOR ZMAIL-WHO-LINE-OVERRIDE-MIXIN
        ((WHO-LINE-OVERRIDE-DOCUMENTATION-STRING NIL))
        ()
  (:REQUIRED-FLAVORS TV:SHEET)
  :SETTABLE-INSTANCE-VARIABLES)

(DEFMETHOD (ZMAIL-WHO-LINE-OVERRIDE-MIXIN :OVERRIDE :WHO-LINE-DOCUMENTATION-STRING) ()
  (AND (SEND SELF :WHO-LINE-OVERRIDE-P)
       WHO-LINE-OVERRIDE-DOCUMENTATION-STRING))

(DEFMETHOD (ZMAIL-WHO-LINE-OVERRIDE-MIXIN :WHO-LINE-OVERRIDE-P) ()
  T)

(DEFFLAVOR ZMAIL-WINDOW () (ZWEI-WINDOW
                            ZMAIL-WHO-LINE-OVERRIDE-MIXIN)
  (:DEFAULT-INIT-PLIST :ITEM-TYPE-ALIST *ZMAIL-TYPEOUT-ITEM-ALIST*
    :TYPEOUT-WINDOW `(ZMAIL-TYPEOUT-WINDOW)))

(DEFMETHOD (ZMAIL-WINDOW :BEFORE :INIT) (IGNORE)
  (SETQ TV:TYPEOUT-WINDOW `(ZMAIL-TYPEOUT-WINDOW :IO-BUFFER ,TV:IO-BUFFER))
;; Is this the right place for this? -rpp
  (setq base-tick 0))


(DEFMETHOD (ZMAIL-WINDOW :AFTER :INIT) (IGNORE)
  (PUSH SELF *ALL-ZMAIL-WINDOWS*))

(DEFMETHOD (ZMAIL-WINDOW :BEFORE :KILL) ()
  (SETQ *ALL-ZMAIL-WINDOWS*
        (DELQ SELF *ALL-ZMAIL-WINDOWS*))
  (SETQ *EDITORS-WHOSE-MODES-TO-RESET*
        (DELQ EDITOR-CLOSURE *EDITORS-WHOSE-MODES-TO-RESET*)))

(DEFMETHOD (ZMAIL-WINDOW :SET-EDITOR-CLOSURE) (NEW-CLOSURE)
  (SETQ EDITOR-CLOSURE NEW-CLOSURE))

(DEFMETHOD (ZMAIL-WINDOW :FUNCALL-INSIDE-YOURSELF) (FUNCTION &REST ARGS)
  (APPLY EDITOR-CLOSURE FUNCTION ARGS))

(DEFMETHOD (ZMAIL-WINDOW :MOUSE-CLICK) (BUTTON X Y)
  (COND ((AND (= BUTTON #/MOUSE-1-1)
              (NOT (SEND (SEND SELF :ALIAS-FOR-SELECTED-WINDOWS)
                         :SELF-OR-SUBSTITUTE-SELECTED-P)))
         (TV:MOUSE-SELECT TV:SUPERIOR)
         T)
        ((AND (NOT (EDITOR-WINDOW-SELECTED-P SELF))
              (= BUTTON #/MOUSE-1-1))
         (COMMAND-BUFFER-PUSH `(SELECT-WINDOW ,SELF))
         T)
        (T (COMMAND-BUFFER-PUSH `(:MOUSE-BUTTON ,BUTTON ,SELF ,X ,Y)) T)))

(DEFMETHOD (ZMAIL-WINDOW :TOP-LEVEL-P) () T)

(DEFMETHOD (ZMAIL-WINDOW :TOP-OF-EDITOR-HIERARCHY) ()
  (SEND TV:SUPERIOR :TOP-OF-EDITOR-HIERARCHY))

(DEFMETHOD (ZMAIL-WINDOW :MODE-LINE-WINDOW) ()
  (SEND TV:SUPERIOR :MODE-LINE-WINDOW))

(DEFMETHOD (ZMAIL-WINDOW :HEADER-WINDOW-HEIGHT) (&REST IGNORE)
  (+ TV:TOP-MARGIN-SIZE TV:BOTTOM-MARGIN-SIZE
     (* TV:LINE-HEIGHT (COUNT-LINES INTERVAL))))

(DEFMETHOD (ZMAIL-WINDOW :BEFORE :EDIT) (&REST IGNORE)
  (MAKE-WINDOW-CURRENT SELF)
  (SETQ BASE-TICK (TICK))
  (SELECT-WINDOW SELF))

(DEFMETHOD (ZMAIL-WINDOW :AROUND :EDIT) (CONT MT ARGS &REST IGNORE)
  (SYS:%BIND (LOCF (TV:BLINKER-DESELECTED-VISIBILITY POINT-BLINKER))
             :ON)
  (setf (get 'ZMAIL-SUMMARY-MOUSE :WHO-LINE-DOCUMENTATION)
        #.(let ((str (make-empty-string 0.)))
            (format str "Click to save changes and jump to this message")
            str))
  (let-globally ((who-line-override-documentation-string
                   #.(string-append "Edit message in buffer; press "
                                    #/end
                                    " to save changes, or click in summary window to save and jump.")))
    (LET ((*SELECTABLE-MODE-LINE-ELEMENTS* NIL))
      (AROUND-METHOD-CONTINUE CONT MT ARGS))))

;;; >> The :PROCESS-SPECIAL-COMMAND really ought to use :OR method combination, so that
;;; there's no need to use :AROUND methods to call the original ZWEI:ZWEI-WINDOW method for
;;; this, which handles the special commands like scrolling and so on.
(defmethod (zmail-window :around :process-special-command)
           (cont mt args &rest ignore)  ;used to have TYPE arg after ARGS.
  (let ((item (cdr args)))
    (selectq (car-safe item)
      (zwei:summary-mouse
       ;; We really can't handle menu commands when we're composing mail or replying, because
       ;; many of the commands refer to the current messsage, and so on.
       (progn (zmail-select-msg (msg-displayed-index (cadadr item)))
              (com-quit-zmail-edit)))
      (:menu            ; blip type
       (if (fquery '(:type :tyi) "To execute the command /"~A/", ~
                                  you must first return from editing this message.~
                                ~%Return from editing this message now? " (car (second item)))
           (progn (cleanup-message-window)
                  (format *query-io* "Click again to execute the /"~A/" command" (car (second item)))
                  (com-quit-zmail-edit))
         (format *query-io* "Type ~\lozenged-character\ to abort, or ~\lozenged-character\ to save ~
                             and return from editing this message."
                 #/Abort #/End)))
      (read-background-response-queue
       ;;Gross crock!  This command manages to filter through here, and ZWEI doesnt have
       ;; a handler, so it bombs.  Right thing is to ignore it here so it filters
       ;; thru the main loop.  --rg 12/08/86
       nil)
      (otherwise (lexpr-funcall-with-mapping-table cont mt args)))))

(DEFMETHOD (ZMAIL-WINDOW :EDITOR-WINDOWS) ()
  (SEND TV:SUPERIOR :EDITOR-WINDOWS))

;;; Make the mode line correct when inside reply edit
(DEFMETHOD (ZMAIL-WINDOW :AFTER :RESELECT) ()
  (SETQ *ZMAIL-INTERVAL-NAME* (SEND INTERVAL `:SEND-IF-HANDLES :NAME))
  (AND *INSIDE-MAIL*
       (SETQ *END-SENDS-MESSAGE-P* (NEQ SELF *DRAFT-HEADER-WINDOW*))))

;;; Stuff related to the summary window
(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION-UPDATER COM-ZMAIL-CONFIGURE (STRING)
  (FORMAT STRING "Change window configuration:  L: ~A; R: menu."
          (NAME-FROM-MENU-VALUE (IF (EQ *WINDOW-CONFIGURATION* :BOTH)
                                    :MSG :BOTH)
                                *WINDOW-CONFIGURATION-ALIST*)))

(DEFINE-ZMAIL-TOP-LEVEL-COMMAND COM-ZMAIL-CONFIGURE "Change window configuration.
Left both summary and message displayed.
Right gives menu of window configurations." (NO-ZMAIL-BUFFER-OK)
  (LET ((CONFIG (COND ((EQ *ZMAIL-COMMAND-BUTTON* :RIGHT)
                       (OR (TV:MENU-CHOOSE *WINDOW-CONFIGURATION-ALIST*
                                           NIL (RECTANGLE-NEAR-COMMAND-MENU TV:MOUSE-SHEET))
                           (ABORT-CURRENT-COMMAND)))
                      ((EQ *WINDOW-CONFIGURATION* :BOTH)
                       :MSG)
                      (T
                       :BOTH))))
    (SET-MAIN-WINDOW-CONFIGURATION CONFIG))
  DIS-NONE)

(DEFUN SET-MAIN-WINDOW-CONFIGURATION (CONFIG &OPTIONAL FORCE-P)
  (COND ((OR (NEQ CONFIG *WINDOW-CONFIGURATION*) FORCE-P)
         (SEND *ZMAIL-WINDOW* :SET-WINDOW-CONFIGURATION CONFIG)
         (UPDATE-COMMAND-WHO-LINE-DOCUMENTATION 'COM-ZMAIL-CONFIGURE))))

;;; The summary window.

(DEFINE-ZMAIL-GLOBAL *STATUS-LETTER-PROPERTY-ALIST*
  '((DELETED . #\D)
    (ANSWERED . #\A)
    (UNSEEN . #\-)
    (OTHERWISE . #\:))
  "Alist of MSG-STATUS properties vs letter to appear as status in summary.
The first property in this alist which is found on the message wins.")

(DEFUN STATUS-LETTER (STATUS)
  (LOOP FOR (IND . LETTER) IN *STATUS-LETTER-PROPERTY-ALIST*
        WHEN (OR (EQ IND 'OTHERWISE)
                 (GET STATUS IND))
        RETURN LETTER))

;; A summary template contains alternating keywords and arguments.
;; The keywords allowed are :SIZE, :RECIPIENTS, :KEYWORDS, :SUBJECT, :DATE.
;; For :SIZE and :RECIPIENTS, the argument is the number of columns to use.
;; for :DATE, the argument is :DATE, :TIME or :DATE-AND-TIME.
;; :KEYWORDS and :SUBJECT ignore the argument.
(DEFVAR *SUMMARY-WITHOUT-DATE-TEMPLATE*
        '(:SIZE 5 :RECIPIENTS 23. :KEYWORDS T :SUBJECT T)
  "A summary template without the date.")

(DEFVAR *SUMMARY-WITH-DATE-TEMPLATE*
        '(:SIZE 5 :DATE :DATE :RECIPIENTS 23. :KEYWORDS T :SUBJECT T)
  "A summary template with the date.")

(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION SET-MSG-SUMMARY-LINE *SUMMARY-WINDOW-LABEL*)

(ASSOCIATE-OPTION-WITH-COMMAND-DOCUMENTATION *DEFAULT-SUMMARY-TEMPLATE* SET-MSG-SUMMARY-LINE)

(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION-UPDATER SET-MSG-SUMMARY-LINE (STRING)
  (APPEND-TO-ARRAY STRING "   No. ")
  (SET-MSG-SUMMARY-LINE (AND *ZMAIL-BUFFER* (PLUSP (ZMAIL-BUFFER-NMSGS *ZMAIL-BUFFER*))
                             (AREF (ZMAIL-BUFFER-ARRAY *ZMAIL-BUFFER*) 0))
                        NIL STRING)
  (AND (SEND *SUMMARY-WINDOW* :EXPOSED-P)
       (NOT (STRING-EQUAL STRING (TV:LABEL-STRING (SEND *SUMMARY-WINDOW* :LABEL))))
       ;;Make a copy of the string for the label, since ours gets ASET here.
       (SEND *SUMMARY-WINDOW* :SET-LABEL (STRING-APPEND STRING)))
  STRING)

;;; Compute the summary line for a message, given the msg and the status plist
;;; If STATUS is nil, we make a heading line instead of a body line,
;;; using the same template.
(DEFUN SET-MSG-SUMMARY-LINE (MSG STATUS &OPTIONAL LINE &AUX TEMPLATE)
  (OR LINE (SETQ LINE (MAKE-SUMMARY-LINE)))
  (SETQ TEMPLATE (OR (AND MSG (GET (LOCF (ZMAIL-BUFFER-OPTIONS (MSG-MAIL-FILE-BUFFER MSG)))
                                   :SUMMARY-window-format))
                     *DEFAULT-SUMMARY-TEMPLATE*))
  (COND ((EQ TEMPLATE NIL)
         (SETQ TEMPLATE *SUMMARY-WITHOUT-DATE-TEMPLATE*))
        ((EQ TEMPLATE T)
         (SETQ TEMPLATE *SUMMARY-WITH-DATE-TEMPLATE*)))
  (LOOP FOR (KEY VAL) ON TEMPLATE BY 'CDDR
        DO (SEND (GET KEY 'SUMMARY-PRINTER) LINE VAL MSG STATUS)
        COLLECT `(,KEY ,VAL ,(SUMMARY-LINE-LENGTH LINE)) INTO TEMP
        FINALLY (SETF (SUMMARY-LINE-TEMPLATE LINE) TEMP))
  (AND STATUS (SETF (MSG-SUMMARY-LINE MSG) LINE))
  LINE)

(DEFVAR *SPACES* "                       "
  "Contains enough spaces to make the date and/or time look nice in ZMail.")

(DEFUN (:SIZE SUMMARY-PRINTER) (LINE COLS MSG STATUS)
  (COND (STATUS
         (NUMBER-INTO-ARRAY LINE (COUNT-LINES (MSG-INTERVAL MSG)) 10.
                            (SUMMARY-LINE-LENGTH LINE) COLS)
         (SETF (SUMMARY-LINE-LENGTH LINE) (+ (SUMMARY-LINE-LENGTH LINE) COLS)))
        (T
         (APPEND-TO-ARRAY LINE "Lines" 0 (MIN COLS 5))
         (APPEND-TO-ARRAY LINE *SPACES* 0 (MIN (- COLS 5) 0))))
  (VECTOR-PUSH-EXTEND #\Space LINE))

(DEFUN (:DATE SUMMARY-PRINTER) (LINE TYPE IGNORE STATUS &AUX DATE)
  (COND ((NULL STATUS)
         (AND (MEMQ TYPE '(:DATE :DATE-AND-TIME))
              (APPEND-TO-ARRAY LINE " Date "))
         (AND (MEMQ TYPE '(:DATE-AND-TIME :TIME))
              (APPEND-TO-ARRAY LINE "Time ")))
        ((AND (SETQ DATE (CADR (GETL STATUS '(:DATE :DRAFT-COMPOSITION-DATE))))
              (NOT (STRINGP DATE)))
         (AND (CONSP DATE) (SETQ DATE (CAR DATE)))
         (MULTIPLE-VALUE-BIND (NIL MINUTES HOURS DAY MONTH)
             (TIME:DECODE-UNIVERSAL-TIME DATE)
           (FORMAT LINE "~:[~2D-~A ~]~:[~2,0D~2,0D ~]"
                   (NOT (MEMQ TYPE '(:DATE :DATE-AND-TIME)))
                   DAY (TIME:MONTH-STRING MONTH :SHORT)
                   (NOT (MEMQ TYPE '(:DATE-AND-TIME :TIME)))
                   HOURS MINUTES)))
        ((EQ TYPE :DATE) (APPEND-TO-ARRAY LINE *SPACES* 0 7))
        ((EQ TYPE :TIME) (APPEND-TO-ARRAY LINE *SPACES* 0 5))
        ((EQ TYPE :DATE-AND-TIME) (APPEND-TO-ARRAY LINE *SPACES* 0 12.))))

(DEFUN (:RECIPIENTS SUMMARY-PRINTER) (LINE SIZE IGNORE STATUS &AUX STR1 STR2 LEN1 LEN2)
  (IF STATUS
      (SETQ STR1 (SUMMARIZE-RECIPIENTS (GET STATUS :FROM) (1- SIZE))
            STR2 (SUMMARIZE-RECIPIENTS (GET STATUS :TO) (1- SIZE)))
    (SETQ STR1 "From"
          STR2 "To"))
  (SETQ LEN1 (MIN (MAX (TRUNCATE (1- SIZE) 2)
                       (- SIZE (SETQ LEN2 (STRING-LENGTH STR2)) 1))
                  (STRING-LENGTH STR1))
        LEN2 (MIN (- SIZE LEN1 1) LEN2))
  (APPEND-TO-ARRAY LINE STR1 0 LEN1)
  (APPEND-TO-ARRAY LINE "" 0 1)
  (APPEND-TO-ARRAY LINE STR2 0 LEN2)
  (APPEND-TO-ARRAY LINE *SPACES* 0 (- SIZE (+ LEN1 LEN2)))
  ;(RETURN-ARRAY STR2)
  ;(RETURN-ARRAY STR1)
  )

(DEFUN (:KEYWORDS SUMMARY-PRINTER) (LINE IGNORE IGNORE STATUS &AUX KEYSTR)
    (COND ((AND STATUS (SETQ KEYSTR (GET STATUS 'KEYWORDS-STRING)))
           (APPEND-TO-ARRAY LINE KEYSTR)
           (VECTOR-PUSH-EXTEND #\Space LINE))))

(DEFUN (:SUBJECT SUMMARY-PRINTER) (LINE IGNORE MSG STATUS &AUX SUBJ)
  (SETQ SUBJ (GET STATUS :SUBJECT))
  (COND ((NULL STATUS)
         (SETQ SUBJ "Subject or Text"))
        ((get status 'losing-headers)
         (setq subj "Parsing error"))
        ((NULL SUBJ)
         (SETQ SUBJ (FIRST-TEXT-LINE (MSG-INTERVAL MSG))))
        ((CONSP SUBJ)
         (SETQ SUBJ (CAR SUBJ))))
  (APPEND-TO-ARRAY LINE SUBJ 0 (MIN (STRING-LENGTH SUBJ) 60.)))

(DEFUN UPDATE-MSG-SUMMARY-LINE (MSG FIELD-KEYWORD &AUX OLD-LINE NEW-LINE IDX FIELD)
  (SETQ OLD-LINE (MSG-SUMMARY-LINE MSG))
  (LOOP AS OF = NIL THEN F
        FOR F IN (SUMMARY-LINE-TEMPLATE OLD-LINE)
        WHEN (EQ (CAR F) FIELD-KEYWORD)
        DO (RETURN (SETQ IDX (IF OF (THIRD OF) 0)
                         FIELD F)))
  (COND (FIELD
         (SETQ NEW-LINE (MAKE-SUMMARY-LINE :MAKE-ARRAY
                                           (:LENGTH (SUMMARY-LINE-LENGTH OLD-LINE))))
         (APPEND-TO-ARRAY NEW-LINE OLD-LINE 0 IDX)
         (FUNCALL (GET FIELD-KEYWORD 'SUMMARY-PRINTER) NEW-LINE (SECOND FIELD)
                  MSG (LOCF (MSG-STATUS MSG)))
         (APPEND-TO-ARRAY NEW-LINE OLD-LINE (THIRD FIELD))
         (LOOP WITH TEMP = (SUMMARY-LINE-TEMPLATE OLD-LINE)
               FOR ELEM IN TEMP
               WITH DELTA = NIL
               WHEN (EQ ELEM FIELD)
               DO (SETQ DELTA (- (SUMMARY-LINE-LENGTH OLD-LINE)
                                 (SUMMARY-LINE-LENGTH NEW-LINE)))
               WHEN DELTA
               DO (DECF (THIRD ELEM) DELTA)
               FINALLY (SETF (SUMMARY-LINE-TEMPLATE NEW-LINE) TEMP))
         (SETF (MSG-SUMMARY-LINE MSG) NEW-LINE)
         (SEND *SUMMARY-WINDOW* :NEED-TO-REDISPLAY-MSG MSG))))

;;; Compress a list of recipients
(DEFINE-SITE-HOST-LIST *HOSTS-IGNORED-IN-SUMMARY* :LOCAL-MAIL-HOSTS
  "A list of the hosts that are ignored in summaries.")

(DEFUN SUMMARIZE-RECIPIENTS (LIST MAXL &AUX (STR (MAKE-EMPTY-STRING MAXL)))
  (DO-NAMED THE-LIST
      ((LIST LIST (CDR LIST))
       (PLIST)
       (COMMA NIL)
       (NAME))
      ((NULL LIST))
    (UNLESS (CONSP LIST) (RETURN))
    (SETQ PLIST (LOCF (CAR LIST)))
    (IF COMMA (OR (ARRAY-PUSH STR #/,) (RETURN-FROM THE-LIST)) (SETQ COMMA T))
    (COND ((SETQ NAME (GET PLIST :NAME))
           (OR (STRING-EQUAL NAME USER-ID)
               (DO ((I (1+ (or (string-reverse-search-char #/! name) -1)) (1+ I))
                    (LEN (STRING-LENGTH NAME)))
                   (( I LEN))
                 (OR (ARRAY-PUSH STR (AREF NAME I)) (RETURN-FROM THE-LIST))))
           (DO ((HS (GET PLIST :HOST) (CDR HS)))
               ((NULL HS))
             (LET ((HOST (CAR HS)))
               ;; Stop accumulating names when we run into one we know.
               (AND (SEND FS:USER-LOGIN-MACHINE :PATHNAME-HOST-NAMEP HOST)
                    (RETURN))
               (AND (LOOP FOR KNOWN IN *HOSTS-IGNORED-IN-SUMMARY*
                          THEREIS (SEND KNOWN :PATHNAME-HOST-NAMEP HOST))
                    (RETURN))
               (OR (ARRAY-PUSH STR (IF (CDR HS) #/% #/@))
                   (RETURN-FROM THE-LIST))
               (DO ((I 0 (1+ I))
                    (LEN (STRING-LENGTH HOST)))
                   (( I LEN))
                 (OR (ARRAY-PUSH STR (AREF HOST I)) (RETURN-FROM THE-LIST))))))))
  STR)

;;; Returns the first line that is likely to be meaningful
(DEFUN FIRST-TEXT-LINE (BP1 &OPTIONAL BP2 IN-ORDER-P)
  (GET-INTERVAL BP1 BP2 IN-ORDER-P)
  (DO ((LINE (BP-LINE BP1) (LINE-NEXT LINE))
       (END-LINE (BP-LINE BP2))
       (STATE :START))
      ((EQ LINE END-LINE) "")
    (COND ((AND (MEMQ STATE '(:START :RESTART))
                (PROBABLE-ITS-HEADER-P LINE))
           (SETQ STATE :RESTART))
          ((LINE-BLANK-P LINE)
           (SETQ STATE :RESTART))
          ;; Recognize start of *MSG's
          ((AND (MEMQ STATE '(:START :RESTART))
                (STRING-EQUAL-START LINE "MSG: ")))
          ((OR (MEMQ STATE '(:START :HEADERS-START))
               (LET ((COLON (STRING-SEARCH-CHAR #/: LINE)))
                 (AND COLON
                      (ASS 'EQUALP (SUBSTRING LINE
                                              (STRING-SEARCH-NOT-SET '(#/SP #/TAB) LINE)
                                              COLON)
                             *HEADER-NAME-ALIST*))))
           (SETQ STATE (IF (MEMQ STATE '(:START :HEADERS-START)) :HEADERS-START :HEADERS)))
          ;; Recognize Lisp Machine bug reports.  This could perhaps be more general.
          ((AND (STRING-EQUAL-START LINE "In " (STRING-SEARCH-NOT-SET '(#/SP #/TAB) LINE))
                (STRING-SEARCH " System " LINE))
           ;; Skip down to the line where the version info ends
           ;; The following line will be returned.
           (DO () (())
             (IF (STRING-SEARCH "microcode " LINE)
                 (RETURN))
             (IF (EQ (LINE-NEXT LINE) END-LINE)
                 (RETURN))
             (SETQ LINE (LINE-NEXT LINE))))
          (T (RETURN LINE)))))

(ASSOCIATE-OPTION-WITH-COMMAND-DOCUMENTATION *DEFAULT-SUMMARY-TEMPLATE*
                                             CHANGE-MSGS-SUMMARY-LINES)

(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION-UPDATER CHANGE-MSGS-SUMMARY-LINES (IGNORE)
  (AND *EXPLICIT-OPTION-UPDATE*                 ;Only if from profile mode
       (LOOP FOR ZMAIL-BUFFER IN *ZMAIL-BUFFER-LIST*
             WITH ASKED-P = NIL
             WHEN (ZMAIL-BUFFER-DISK-P ZMAIL-BUFFER)
             DO (COND ((NULL ASKED-P)
                       (OR (TYPEOUT-BEEP-YES-OR-NO-P
                             "Also change any summary lines already computed? ")
                           (RETURN (VALUES)))
                       (SETQ ASKED-P T)))
             (CHANGE-ZMAIL-BUFFER-MSGS-SUMMARY-LINES ZMAIL-BUFFER T))))

(DEFUN CHANGE-ZMAIL-BUFFER-MSGS-SUMMARY-LINES (ZMAIL-BUFFER &OPTIONAL NO-ASK-P)
  (COND ((OR NO-ASK-P
             (TYPEOUT-BEEP-YES-OR-NO-P "Also change any summary lines already computed? "))
         (LOOP FOR MSG BEING THE MSGS IN ZMAIL-BUFFER
               WHEN (MSG-PARSED-P MSG)
               DO (SET-MSG-SUMMARY-LINE MSG (ASSURE-MSG-PARSED MSG)))
         (SEND *SUMMARY-WINDOW* :NEED-FULL-REDISPLAY))))

(DEFFLAVOR ARROW-PRINTING-MIXIN () ()
  (:REQUIRED-FLAVORS TV:STREAM-MIXIN))

(DEFMETHOD (ARROW-PRINTING-MIXIN :PRINT-ARROW) (TYPE &AUX CH)
  (SETQ CH (CASE TYPE
             ((:CURRENT T) #\_)
             (:MARKED #\x)))
  (TV:PREPARE-SHEET (SELF)
    (SYS:%DRAW-CHAR FONTS:NARROW CH TV:CURSOR-X TV:CURSOR-Y TV:CHAR-ALUF SELF)
    (TV:SHEET-INCREMENT-BITPOS SELF TV:CHAR-WIDTH 0)))

(DEFFLAVOR ZMAIL-SUMMARY-TYPEOUT-WINDOW () (ZMAIL-TYPEOUT-WINDOW))

;;; Normal scroll redisplay is the one that knows about the typeout window
(DEFMETHOD (ZMAIL-SUMMARY-TYPEOUT-WINDOW :AFTER :MAKE-COMPLETE) ()
  (SEND TV:SUPERIOR :NEED-FULL-REDISPLAY))

;; Copied from LAD: RELEASE-3.ZMAIL; WINDOW.LISP#349 on 2-Oct-86 03:00:49
(DEFFLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW
        ((CURRENT-ZMAIL-BUFFER NIL)
         (CURRENT-MSG NIL)
         (MSGS-TO-BE-REDISPLAYED NIL)
         (RECENTER-P NIL)
         (LAST-DISPLAYED-TOP-ZMAIL-BUFFER NIL))
        (TV:BORDERS-MIXIN TV:TOP-BOX-LABEL-MIXIN
         ARROW-PRINTING-MIXIN TV:SCROLL-MOUSE-MIXIN TV:SCROLL-WINDOW-WITH-TYPEOUT-MIXIN
         TV:WINDOW-WITH-TYPEOUT-MIXIN TV:BASIC-SCROLL-WINDOW TV:BASIC-SCROLL-BAR
         ZMAIL-WHO-LINE-OVERRIDE-MIXIN TV:WINDOW)
  (:DEFAULT-INIT-PLIST :TRUNCATION T :SAVE-BITS :DELAYED :CR-NOT-NEWLINE-FLAG 1
                       :LABEL '(:string "Zmail Summary Pane" :centered)
                       :SCROLL-BAR 2 :DISPLAY-ITEM (SUMMARY-DISPLAY-ITEM)))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :BEFORE :INIT) (IGNORE)
  (SETQ TV:TYPEOUT-WINDOW
        `(ZMAIL-SUMMARY-TYPEOUT-WINDOW :IO-BUFFER ,TV:IO-BUFFER)))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :SET-CURRENT-ZMAIL-BUFFER) (ZMAIL-BUFFER)
  (COND ((NEQ CURRENT-ZMAIL-BUFFER ZMAIL-BUFFER)
         (SETQ MSGS-TO-BE-REDISPLAYED T
               RECENTER-P T)
         (SETQ CURRENT-ZMAIL-BUFFER ZMAIL-BUFFER))))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :BEFORE :REDISPLAY) (&AUX TOP-ZMAIL-BUFFER)
;                                                                 OTHER-ZMAIL-BUFFER)
  (COND ((AND CURRENT-ZMAIL-BUFFER (PLUSP (ZMAIL-BUFFER-NMSGS CURRENT-ZMAIL-BUFFER)))
         (SETQ TOP-ZMAIL-BUFFER (MSG-MAIL-FILE-BUFFER (SUMMARY-DISPLAY-ITEM-STEPPER 0)))
;        (AND (TYPEP TOP-ZMAIL-BUFFER 'INBOX-BUFFER)
;             (SETQ OTHER-ZMAIL-BUFFER (SEND TOP-ZMAIL-BUFFER :ASSOCIATED-MAIL-FILE-BUFFER))
;             (SETQ TOP-ZMAIL-BUFFER OTHER-ZMAIL-BUFFER))
         ))
  (OR (EQ LAST-DISPLAYED-TOP-ZMAIL-BUFFER TOP-ZMAIL-BUFFER)
      (SETQ TV:TOP-ITEM NIL TV:TARGET-TOP-ITEM NIL))
  (SETQ LAST-DISPLAYED-TOP-ZMAIL-BUFFER TOP-ZMAIL-BUFFER))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :SET-CURRENT-MSG) (MSG)
  (COND ((NEQ CURRENT-MSG MSG)
         (COND ((NEQ MSGS-TO-BE-REDISPLAYED T)
                (AND CURRENT-MSG (PUSH* CURRENT-MSG MSGS-TO-BE-REDISPLAYED))
                (AND MSG (PUSH* MSG MSGS-TO-BE-REDISPLAYED))))
         (SETQ CURRENT-MSG MSG)))
  (SETQ RECENTER-P T))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :NEED-TO-REDISPLAY-MSG) (MSG)
  (OR (EQ MSGS-TO-BE-REDISPLAYED T)
      (PUSH* MSG MSGS-TO-BE-REDISPLAYED)))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :NEED-FULL-REDISPLAY) (&OPTIONAL RECENTER-TOO)
  (SETQ MSGS-TO-BE-REDISPLAYED T)
  (AND RECENTER-TOO (SETQ RECENTER-P T)))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :REDISPLAY-AS-NECESSARY) ()
  (AND (SEND TV:TYPEOUT-WINDOW :BOTTOM-REACHED)
       (SETQ MSGS-TO-BE-REDISPLAYED T))
  (COND (MSGS-TO-BE-REDISPLAYED
         (AND RECENTER-P (NEQ MSGS-TO-BE-REDISPLAYED T)
              (SUMMARY-DISPLAY-VALIDATE-CURRENT-MSG-POSITION))
         (IF (EQ MSGS-TO-BE-REDISPLAYED T)      ;Full redisplay needed
             (SEND SELF :REDISPLAY)
           (TV:SCROLL-MAINTAIN-LIST-UPDATE-STATES MSGS-TO-BE-REDISPLAYED SELF))
         (SETQ MSGS-TO-BE-REDISPLAYED NIL
               RECENTER-P NIL))))

(DEFUN SUMMARY-DISPLAY-ITEM ()
  (TV:SCROLL-MAINTAIN-LIST
    'SUMMARY-DISPLAY-ITEM-INITIALIZER
    'SUMMARY-DISPLAY-ITEM-DISPLAYER
    NIL
    'SUMMARY-DISPLAY-ITEM-STEPPER
    T
    'SUMMARY-DISPLAY-ITEM-PRE-PROCESS-FUNCTION))

(DEFUN SUMMARY-DISPLAY-ITEM-INITIALIZER ()
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (AND CURRENT-ZMAIL-BUFFER (PLUSP (ZMAIL-BUFFER-NMSGS CURRENT-ZMAIL-BUFFER))
       0))

(DEFUN SUMMARY-DISPLAY-ITEM-DISPLAYER (MSG)
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (TV:SCROLL-PARSE-ITEM
    :MOUSE `(SUMMARY-MOUSE ,MSG)
    `(:FUNCTION SUMMARY-DISPLAY-UPDATE (,MSG) 1 ("~\ARROW\"))
    `(:VALUE 0 4 ("~4D"))
    `(:VALUE 1 1 ("~C"))
    `(:VALUE 2 NIL NIL)))

(DEFUN SUMMARY-DISPLAY-UPDATE (MSG &AUX STATUS)
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (SETQ STATUS (ASSURE-MSG-PARSED MSG))
  (SETF (TV:VALUE 2) (MSG-SUMMARY-LINE MSG))
  (SETF (TV:VALUE 1) (STATUS-LETTER STATUS))
  (SETF (TV:VALUE 0) (1+ (MSG-DISPLAYED-INDEX MSG)))
  (COND ((GET STATUS 'MARKED) :MARKED)
        ((EQ MSG CURRENT-MSG) :CURRENT)))

(DEFPROP FORMAT:ARROW FORMAT-CTL-ARROW FORMAT:FORMAT-CTL-ONE-ARG)
(DEFUN FORMAT-CTL-ARROW (ARG IGNORE)
  (COND ((NULL ARG)
         (SEND *STANDARD-OUTPUT* :TYO #/SP))
        ((MEMQ :PRINT-ARROW (SEND *STANDARD-OUTPUT* :WHICH-OPERATIONS))
         (SEND *STANDARD-OUTPUT* :PRINT-ARROW ARG))
        (T
         (SEND *STANDARD-OUTPUT* :TYO (CASE ARG
                                       ((:CURRENT T) #\)
                                       (:MARKED #\x))))))

(DEFUN SUMMARY-DISPLAY-ITEM-STEPPER (INDEX &AUX ZMAIL-BUFFER LENGTH OTHER-ZMAIL-BUFFER NEW-INDEX
                                                DISPLAYED-INDEX MSG)
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (SETQ ZMAIL-BUFFER CURRENT-ZMAIL-BUFFER
        DISPLAYED-INDEX INDEX
        LENGTH (ZMAIL-BUFFER-NMSGS ZMAIL-BUFFER))
  (COND ((AND (TYPEP ZMAIL-BUFFER 'INBOX-BUFFER)
              (SETQ OTHER-ZMAIL-BUFFER (SEND ZMAIL-BUFFER :ASSOCIATED-MAIL-FILE-BUFFER)))
;Better to show them out of order
;than to keep glitching the summary of the inbox buffer
;as messages are read into the mail file buffer by the background process.
;        (AND (ZMAIL-BUFFER-APPEND-P OTHER-ZMAIL-BUFFER)
;             (PSETQ ZMAIL-BUFFER OTHER-ZMAIL-BUFFER
;                    OTHER-ZMAIL-BUFFER ZMAIL-BUFFER
;                    LENGTH (ZMAIL-BUFFER-NMSGS OTHER-ZMAIL-BUFFER)))
         (AND ( INDEX LENGTH)
              (SETQ DISPLAYED-INDEX (- INDEX LENGTH)
                    ZMAIL-BUFFER OTHER-ZMAIL-BUFFER))
         (SETQ LENGTH (+ LENGTH (ZMAIL-BUFFER-NMSGS OTHER-ZMAIL-BUFFER)))))
  (SETQ MSG (AREF (ZMAIL-BUFFER-ARRAY ZMAIL-BUFFER) DISPLAYED-INDEX))
  (SETF (MSG-DISPLAYED-INDEX MSG) DISPLAYED-INDEX)
  (VALUES MSG
          (SETQ NEW-INDEX (1+ INDEX))
          ( NEW-INDEX LENGTH)))

(DEFUN SUMMARY-DISPLAY-ITEM-PRE-PROCESS-FUNCTION (ITEM)
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (TV:SCROLL-MAINTAIN-LIST-UPDATE-FUNCTION ITEM)        ;Do numbering pass
  (AND CURRENT-MSG (PLUSP (ZMAIL-BUFFER-NMSGS CURRENT-ZMAIL-BUFFER)) RECENTER-P
       (SUMMARY-DISPLAY-VALIDATE-CURRENT-MSG-POSITION)))

(DEFUN SUMMARY-DISPLAY-VALIDATE-CURRENT-MSG-POSITION ()
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (AND *SUMMARY-SCROLL-FRACTION*
       (LET* ((CURRENT-INDEX (MSG-DISPLAYED-INDEX CURRENT-MSG))
              (TOP-INDEX (OR TV:TOP-ITEM 0))
              (N-LINES (TV:SHEET-NUMBER-OF-INSIDE-LINES))
              (BOTTOM-INDEX (+ TOP-INDEX N-LINES))
              NEW-TARGET
;             OTHER-ZMAIL-BUFFER
              )
;        (AND (TYPEP CURRENT-ZMAIL-BUFFER 'INBOX-BUFFER)
;             (SETQ OTHER-ZMAIL-BUFFER
;                   (SEND CURRENT-ZMAIL-BUFFER :ASSOCIATED-MAIL-FILE-BUFFER))
;             (ZMAIL-BUFFER-APPEND-P OTHER-ZMAIL-BUFFER)
;             CURRENT-INDEX
;             (SETQ CURRENT-INDEX (+ CURRENT-INDEX (ZMAIL-BUFFER-NMSGS OTHER-ZMAIL-BUFFER))))
         (COND ((NULL CURRENT-INDEX))           ;Not displayed yet
               ((< CURRENT-INDEX TOP-INDEX)
                (SETQ NEW-TARGET (- CURRENT-INDEX
                                    (FIX (* *SUMMARY-SCROLL-FRACTION* N-LINES)))))
               (( CURRENT-INDEX BOTTOM-INDEX)
                (SETQ NEW-TARGET (+ (- CURRENT-INDEX N-LINES)
                                    (FIX (* *SUMMARY-SCROLL-FRACTION* N-LINES))))))
         (AND NEW-TARGET
              (SETQ TV:TARGET-TOP-ITEM (MAX 0 NEW-TARGET)
                    MSGS-TO-BE-REDISPLAYED T)))))

;;; If told to scroll explicitly, don't jump back
(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :AFTER :SCROLL-TO) (&REST IGNORE)
  (SETQ RECENTER-P NIL))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :BEFORE :HANDLE-MOUSE) ()
  (SEND SELF :MOUSE-STANDARD-BLINKER))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :AFTER :MOUSE-MOVES) (X Y)
  (ZMAIL-SUMMARY-SCROLL-WINDOW-MOUSE-BLINKER X Y NIL))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :MOUSE-STANDARD-BLINKER) ()
  (MULTIPLE-VALUE-BIND (XOFF YOFF)
      (TV:SHEET-CALCULATE-OFFSETS SELF TV:MOUSE-SHEET)
    (ZMAIL-SUMMARY-SCROLL-WINDOW-MOUSE-BLINKER (- TV:MOUSE-X XOFF) (- TV:MOUSE-Y YOFF) T)))

(DEFUN ZMAIL-SUMMARY-SCROLL-WINDOW-MOUSE-BLINKER (X Y &OPTIONAL (FORCE-P T) &AUX CHAR)
  (DECLARE (:SELF-FLAVOR ZMAIL-SUMMARY-SCROLL-WINDOW))
  (SETQ CHAR (COND (( Y (TV:SHEET-INSIDE-TOP)) 6)
                   ((AND ( X (TRUNCATE TV:WIDTH 4)) (< X (TRUNCATE (* 3 TV:WIDTH) 4))) 0)
                   (T 2)))
  (WITHOUT-INTERRUPTS
    (AND (OR FORCE-P
             (NEQ TV:MOUSE-BLINKER (TV:MOUSE-GET-BLINKER :CHARACTER))
             ( CHAR (SEND TV:MOUSE-BLINKER :CHARACTER)))
         ;; Only flash blinker if something changed
         (TV:MOUSE-SET-BLINKER-DEFINITION :CHARACTER 0 0 :ON
                                          :SET-CHARACTER CHAR 'FONTS:MOUSE))))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :MOUSE-CLICK) (BUTTON X Y)
  (COND ((AND (= BUTTON #/MOUSE-1-1)
              (< Y (TV:SHEET-INSIDE-TOP)))      ;If clicked inside the label
         (COMMAND-BUFFER-PUSH
           `(SUMMARY-EXECUTE CHANGE-SUMMARY-LAYOUT
                             ,(AND ( X (TRUNCATE TV:WIDTH 4))
                                   (< X (TRUNCATE (* 3 TV:WIDTH) 4)))))
         T)))

;;; If button is clicked inside the label of the summary window, change the layout
(DEFUN CHANGE-SUMMARY-LAYOUT (UP-P)
  (SET-MAIN-WINDOW-CONFIGURATION (IF UP-P
                                     (IF (EQ *WINDOW-CONFIGURATION* :BOTH)
                                         :SUMMARY
                                       :BOTH)
                                   :MSG))
  DIS-NONE)

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :WHO-LINE-DOCUMENTATION-STRING) (&AUX X Y)
  (MULTIPLE-VALUE (X Y)
    (TV:SHEET-CALCULATE-OFFSETS SELF TV:MOUSE-SHEET))
  (SETQ X (- TV:MOUSE-X X)
        Y (- TV:MOUSE-Y Y))
  (COND ((< Y (TV:SHEET-INSIDE-TOP))
         (IF ( (TRUNCATE TV:WIDTH 4) X (TRUNCATE (* 3 TV:WIDTH) 4))
             (IF (EQ (SYMEVAL-IN-CLOSURE (SEND TV:SUPERIOR :EDITOR-CLOSURE)
                                         '*WINDOW-CONFIGURATION*)
                     :BOTH)
                 "Change layout to display just summary window."
               "Change layout to display both summary and message.")
           "Change layout to display just message."))
        (TV:CURRENT-ITEM
         (GET 'ZMAIL-SUMMARY-MOUSE :WHO-LINE-DOCUMENTATION))))

(DEFMETHOD (ZMAIL-SUMMARY-SCROLL-WINDOW :WHO-LINE-OVERRIDE-P) ()
  TV:CURRENT-ITEM)

;;; This "command's" mouse documentation is used when the mouse
;;; is in the summary window.
(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION-UPDATER ZMAIL-SUMMARY-MOUSE (STRING)
  (FORMAT STRING "Operate on this message: L: Select;  M: ~A; Right: menu."
          (NAME-FROM-MENU-VALUE *SUMMARY-MOUSE-MIDDLE-MODE*
                                *SUMMARY-MOUSE-MIDDLE-MENU-ALIST*)))

(ASSOCIATE-OPTION-WITH-COMMAND-DOCUMENTATION *SUMMARY-MOUSE-MIDDLE-MODE* ZMAIL-SUMMARY-MOUSE)

(DEFUN ZMAIL-SUMMARY-MOUSE (MSG &AUX OPTION DELETED-P)
  (SETQ DELETED-P (MSG-GET MSG 'DELETED))
  (IF (EQ *ZMAIL-COMMAND-BUTTON* :LEFT)
      (SETQ OPTION :SELECT)
    (MULTIPLE-VALUE (OPTION *LAST-SUMMARY-MOUSE-ITEM*)
      (ZMAIL-MENU-CHOOSE NIL
                         (IF (EQ *ZMAIL-COMMAND-BUTTON* :MIDDLE)
                             *SUMMARY-MOUSE-MIDDLE-MENU-ALIST*
                           `(,(SECOND *SUMMARY-MOUSE-MENU-ALIST*)       ;Keywords
                             ,(IF DELETED-P
                                  (FOURTH *SUMMARY-MOUSE-MENU-ALIST*)   ;Undelete
                                (THIRD *SUMMARY-MOUSE-MENU-ALIST*))     ;Delete
                             ,@(AND (NOT (ZMAIL-BUFFER-DISK-P *ZMAIL-BUFFER*))
                                    `(,(FIFTH *SUMMARY-MOUSE-MENU-ALIST*)))     ;Remove
                             ,(IF (MSG-DRAFT-MSG-P MSG)
                                  (FIRST *SUMMARY-MOUSE-MENU-ALIST*)    ;Continue
                                (SIXTH *SUMMARY-MOUSE-MENU-ALIST*))     ;Reply
                             . ,(NTHCDR 6 *SUMMARY-MOUSE-MENU-ALIST*))) ;Append,Filter
                           *LAST-SUMMARY-MOUSE-ITEM* '(:MOUSE) *SUMMARY-MOUSE-MIDDLE-MODE*)))
  (COND (OPTION
         (AND (EQ OPTION :DELETE-OR-REMOVE)
              (SETQ OPTION (IF (ZMAIL-BUFFER-DISK-P *ZMAIL-BUFFER*)
                               :DELETE-OR-UNDELETE
                             :REMOVE)))
         (AND (EQ OPTION :DELETE-OR-UNDELETE)
              (SETQ OPTION (IF DELETED-P :UNDELETE :DELETE)))
         (CASE OPTION
           (:SELECT
            (AND (EQ *WINDOW-CONFIGURATION* :SUMMARY)
                 (SEND *ZMAIL-WINDOW* :SET-WINDOW-CONFIGURATION :MSG))
            (SELECT-MSG-AND-POSSIBLY-ZMAIL-BUFFER MSG)
            (MUST-REDISPLAY *MSG-WINDOW* DIS-ALL))
           (:DELETE
            (OR DELETED-P (ZMAIL-DELETE-MSG MSG)))
           (:UNDELETE
            (AND DELETED-P (ZMAIL-UNDELETE-MSG MSG)))
           (:REMOVE
            (REMOVE-MSG *ZMAIL-BUFFER* MSG (MSG-DISPLAYED-INDEX MSG)))
           (:KEYWORDS
            (ZMAIL-KEYWORDS-MSG MSG))
           (:REPLY
            (ZMAIL-SELECT-MSG MSG)
            (COM-ZMAIL-REPLY))
           (:MOVE
            (LET ((BUFFER (GET-DEFAULTED-MOVE-ZMAIL-BUFFER MSG)))
              (SEND BUFFER :ADD-MSG MSG)
              (FORMAT *QUERY-IO* "~&Moved to ~A" (SEND BUFFER :NAME))))
           (:APPEND
            (ZMAIL-CONCATENATE-MSG MSG))
           (:FILTER
            (SELECT-ZMAIL-BUFFER (MAKE-ZMAIL-BUFFER-FROM-FILTER-FROM-MSG MSG))))))
  DIS-TEXT)

(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION SUMMARY-REPLY-DOCUMENTATION
                                       *SUMMARY-REPLY-DOCUMENTATION*)

(DEFINE-COMMAND-WHO-LINE-DOCUMENTATION-UPDATER SUMMARY-REPLY-DOCUMENTATION
                                               (STRING &OPTIONAL RECURSIVE)
  (OR RECURSIVE (UPDATE-COMMAND-WHO-LINE-DOCUMENTATION 'NORMAL-REPLY NIL T))
  (STRING-NCONC STRING "Select and reply to this message: "
                (GET 'NORMAL-REPLY :WHO-LINE-DOCUMENTATION)))

;;; The mouse sensitive mode line
;;; When the mode line is updated, the value of *SENSITIVE-MODE-LINE-ELEMENTS*
;;; is saved in the mode line.  This is an alist which says what to do
;;; about mouse clicks.

(DEFFLAVOR MOUSE-SENSITIVE-MODE-LINE-WINDOW
       ((CURRENT-ITEM NIL)                      ;The item the mouse is currently near
        ITEM-BLINKER                            ;Rectangular blinker for it
        SELECTABLE-ELEMENTS
        )
       (MODE-LINE-WINDOW-MIXIN ECHO-AREA-WINDOW))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :AFTER :INIT) (IGNORE)
  (SETQ ITEM-BLINKER (TV:MAKE-BLINKER SELF 'TV:HOLLOW-RECTANGULAR-BLINKER
                                      :VISIBILITY NIL)))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :MOUSE-MOVES) (X Y &AUX STRING X1
                                                                (X0 (TV:SHEET-INSIDE-LEFT)))
  (TV:MOUSE-SET-BLINKER-CURSORPOS)
  (COND ((AND ( Y (TV:SHEET-INSIDE-TOP))
              (< Y TV:(+ (SHEET-INSIDE-TOP) LINE-HEIGHT))
              (SETQ STRING (DOLIST (STRING PREVIOUS-MODE-LINE)
                             (IF (AND (CONSP STRING) (EQ (CAR STRING) :RIGHT-FLUSH))
                                 (SETQ X1 (TV:SHEET-INSIDE-RIGHT)
                                       STRING (CADR STRING))
                               (SETQ X1 (+ X0 (TV:SHEET-STRING-LENGTH SELF STRING))))
                             (AND (> X1 X) (RETURN STRING))
                             (SETQ X0 X1)))
              (DOLIST (ELEMENT SELECTABLE-ELEMENTS)
                (AND (EQ STRING (SYMEVAL-IN-CLOSURE (SEND TV:SUPERIOR :EDITOR-CLOSURE)
                                                    (CAR ELEMENT)))
                     (RETURN (SETQ CURRENT-ITEM (CDR ELEMENT))))))
         (TV:BLINKER-SET-CURSORPOS ITEM-BLINKER (- X0 (TV:SHEET-INSIDE-LEFT)) 0)
         (TV:BLINKER-SET-SIZE ITEM-BLINKER (- X1 X0) (FONT-BLINKER-HEIGHT TV:CURRENT-FONT))
         (TV:BLINKER-SET-VISIBILITY ITEM-BLINKER T))
        (T
         (TV:BLINKER-SET-VISIBILITY ITEM-BLINKER NIL)
         (SETQ CURRENT-ITEM NIL))))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :MOUSE-CLICK) (BUTTON X Y)
  X Y
  (COND ((AND CURRENT-ITEM (NOT (LDB-TEST %%KBD-MOUSE-N-CLICKS BUTTON)))
         (COMMAND-BUFFER-PUSH `(MODE-LINE ,CURRENT-ITEM ,BUTTON))
         T)))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :WHO-LINE-DOCUMENTATION-STRING) ()
  (AND CURRENT-ITEM
       (OR (GET CURRENT-ITEM :WHO-LINE-DOCUMENTATION)
           (GET CURRENT-ITEM :DOCUMENTATION))))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :AFTER :HANDLE-MOUSE) ()
  (TV:BLINKER-SET-VISIBILITY ITEM-BLINKER NIL))

(DEFMETHOD (MOUSE-SENSITIVE-MODE-LINE-WINDOW :AFTER :REDISPLAY) (IGNORE &OPTIONAL FORCE-P)
  (AND FORCE-P (TV:MOUSE-WAKEUP)))

(DEFFLAVOR ZMAIL-MOUSE-SENSITIVE-MODE-LINE-PANE
        ()
        (TV:BORDERS-MIXIN MODE-LINE-SUPERIOR-MIXIN MOUSE-SENSITIVE-MODE-LINE-WINDOW))

(DEFMETHOD (ZMAIL-MOUSE-SENSITIVE-MODE-LINE-PANE :BEFORE :REDISPLAY) (&REST IGNORE &AUX EXP-P)
  (SETQ SELECTABLE-ELEMENTS *SELECTABLE-MODE-LINE-ELEMENTS*)
  (AND (OR (NOT (SETQ EXP-P (SEND *MSG-WINDOW* :EXPOSED-P)))
           (< (WINDOW-REDISPLAY-DEGREE *MSG-WINDOW*) DIS-BPS))
       (SETQ *MSG-MORE-STRING*
             (AND EXP-P
                  (LET ((TOP-IS-TOP (BP-= (WINDOW-START-BP *MSG-WINDOW*)
                                          (INTERVAL-FIRST-BP (WINDOW-INTERVAL *MSG-WINDOW*))))
                        (BOT-IS-BOT (WINDOW-LAST-BP-DISPLAYED-P *MSG-WINDOW*)))
                    (COND ((AND (NOT TOP-IS-TOP) (NOT BOT-IS-BOT)) "--More above and below--")
                          ((NOT TOP-IS-TOP) "--More above--")
                          ((NOT BOT-IS-BOT) "--More below--")))))))

(DEFFLAVOR ZMAIL-MAIN-COMMAND-MENU-PANE () (MENU-COMMAND-MENU-MIXIN TV:COMMAND-MENU))

;;; Keyword hacking menu

(DEFFLAVOR ZMAIL-MULTIPLE-MENU-MIXIN
        (NEW-FUNCTION)
        ()
  (:REQUIRED-FLAVORS TV:MARGIN-MULTIPLE-MENU-MIXIN)
  (:SETTABLE-INSTANCE-VARIABLES NEW-FUNCTION)
  (:DEFAULT-INIT-PLIST :COLUMNS 3
                       :SPECIAL-CHOICES '(("Abort" :VALUE :ABORT
                                                   :DOCUMENTATION "Abort this command.")
                                          ("Do It" :VALUE :DO-IT
                                           :DOCUMENTATION "Use highlighted items.")
                                          ("New" :VALUE :NEW
                                                 :DOCUMENTATION "Add a new item."))))

(DEFFLAVOR ZMAIL-MULTIPLE-MENU () (ZMAIL-MULTIPLE-MENU-MIXIN TV:MULTIPLE-MENU))

(DEFFLAVOR POP-UP-ZMAIL-MULTIPLE-MENU () (ZMAIL-MULTIPLE-MENU-MIXIN TV:TEMPORARY-WINDOW-MIXIN TV:MULTIPLE-MENU))

;;; This is the message to call, it takes a keyword alist and a list of currently on
;;; keywords, and returns updated versions of each.
(DEFMETHOD (ZMAIL-MULTIPLE-MENU-MIXIN :MULTIPLE-CHOOSE) (old-ITEM-LIST CURRENTLY-ACTIVE
                                                         &OPTIONAL (NEAR-MODE '(:MOUSE))
                                                         &AUX OLD-STATUS CHOICE
                                                         )
  (SETQ OLD-STATUS (SEND SELF :STATUS))
  (UNWIND-PROTECT
    (PROGN (SEND SELF :SET-ITEM-LIST old-ITEM-LIST)
           (SEND SELF :SET-HIGHLIGHTED-VALUES CURRENTLY-ACTIVE)
           (TV:EXPOSE-WINDOW-NEAR SELF NEAR-MODE)
           (DO-FOREVER
             (SETQ CHOICE (SEND SELF :CHOOSE))
             (COND ((EQ CHOICE :DO-IT)
                    (RETURN (SETQ CURRENTLY-ACTIVE (SEND SELF :HIGHLIGHTED-VALUES))))
                   ((EQ CHOICE :ABORT)
                    (RETURN (SETQ tv:ITEM-LIST OLD-ITEM-LIST)))
                   ((EQ CHOICE :NEW)
                    (LET ((NEW (FUNCALL NEW-FUNCTION SELF tv:ITEM-LIST CURRENTLY-ACTIVE)))
                      (COND (NEW
                             ;(PUSH NEW ITEM-LIST) - add-item nconc's
                             (SEND SELF :ADD-ITEM NEW)
                             (SEND SELF :ADD-HIGHLIGHTED-ITEM NEW))))))))
    (SEND SELF :SET-STATUS OLD-STATUS))
  (VALUES tv:ITEM-LIST CURRENTLY-ACTIVE))

(DEFUN ZMAIL-MULTIPLE-MENU-CHOOSE (ITEM-LIST CURRENTLY-ACTIVE NEW-FUNCTION
                                   &OPTIONAL (NEAR-MODE '(:MOUSE)) LABEL)
  (USING-RESOURCE (MENU POP-UP-ZMAIL-MULTIPLE-MENU *ZMAIL-WINDOW*)
    (SEND MENU :SET-NEW-FUNCTION NEW-FUNCTION)
    (SEND MENU :SET-LABEL LABEL)
    (SEND MENU :MULTIPLE-CHOOSE ITEM-LIST CURRENTLY-ACTIVE NEAR-MODE)))

(DEFUN MULTIPLE-MENU-NEW-KEYWORD (WINDOW KEYWORD-ALIST &OPTIONAL IGNORE
                                                       &AUX STR SYM ITEM)
  (SETQ STR (*CATCH 'ZWEI-COMMAND-LOOP
              (CALL-POP-UP-MINI-BUFFER-EDITOR
                WINDOW 'TYPEIN-LINE-READLINE "New keyword:")))
  (COND ((NOT (STRINGP STR)) NIL)
        ((> (STRING-LENGTH STR) 0)
         (SETQ SYM (INTERN (STRING-UPCASE STR) ""))
         (SETQ ITEM (RASSQ SYM KEYWORD-ALIST))
         (IF ITEM                               ;If already have such an item,
             (PROGN (BEEP) ITEM)                ;BEEP and return it
           (CONS STR SYM)))                     ;Otherwise cons new item
        (T (BEEP) NIL)))                        ;He just typed RETURN

(DEFUN MULTIPLE-MENU-NEW-PATHNAME (WINDOW ITEM-LIST &OPTIONAL IGNORE &AUX STR PATH)
  (SETQ PATH (*CATCH 'ZWEI-COMMAND-LOOP
               (CALL-POP-UP-MINI-BUFFER-EDITOR
                 WINDOW 'READ-DEFAULTED-PATHNAME "New file:"
                 (DEFAULT-ZMAIL-MOVE-PATHNAME))))
  (COND ((SYMBOLP PATH) NIL)
        ((NOT (ASSOC (SETQ STR (STRING PATH)) ITEM-LIST))
         (CONS STR PATH))
        (T (BEEP) NIL)))

(DEFFLAVOR CLICK-REMEMBERING-MIXIN
        (LAST-BUTTONS)
        ()
  :GETTABLE-INSTANCE-VARIABLES
  (:REQUIRED-FLAVORS TV:ESSENTIAL-MOUSE))

(DEFMETHOD (CLICK-REMEMBERING-MIXIN :AFTER :MOUSE-BUTTONS) (BD IGNORE IGNORE)
  (SETQ LAST-BUTTONS BD))

(DEFFLAVOR CLICK-REMEMBERING-POP-UP-MENU () (CLICK-REMEMBERING-MIXIN TV:POP-UP-MENU))

(DEFFLAVOR ZMAIL-MOMENTARY-MENU () (CLICK-REMEMBERING-MIXIN TV:MOMENTARY-MENU))

(DEFFLAVOR ZMAIL-MOMENTARY-COMMAND-MENU () (MENU-COMMAND-MENU-MIXIN ZMAIL-MOMENTARY-MENU))

(DEFFLAVOR ZMAIL-DYNAMIC-MOMENTARY-COMMAND-MENU () (TV:DYNAMIC-ITEM-LIST-MIXIN
                                                    ZMAIL-MOMENTARY-COMMAND-MENU))

(DEFUN ZMAIL-MENU-CHOOSE (MENU &OPTIONAL ITEM-LIST DEFAULT-ITEM NEAR-MODE MIDDLE)
  (COND ((SYMBOLP MENU)
         (OR MENU (SETQ MENU 'ZMAIL-MOMENTARY-MENU))
         (SETQ MENU (ALLOCATE-RESOURCE MENU *ZMAIL-WINDOW*))
         (SEND MENU :SET-LABEL NIL)
         (SEND MENU :SET-ITEM-LIST ITEM-LIST)
         (SEND MENU :SET-LAST-ITEM DEFAULT-ITEM))
        (T
         (SETQ ITEM-LIST (SEND MENU :ITEM-LIST))))
  (COND ((AND (EQ *ZMAIL-COMMAND-BUTTON* :MIDDLE) MIDDLE)
         (DO L ITEM-LIST (CDR L) (NULL L)
           (AND (EQ MIDDLE (SEND MENU :EXECUTE-NO-SIDE-EFFECTS (CAR L)))
                (RETURN (SETQ DEFAULT-ITEM (CAR L))))))
        ((MEMQ *ZMAIL-COMMAND-BUTTON* '(:RIGHT :MIDDLE))
         (TV:EXPOSE-WINDOW-NEAR MENU (OR NEAR-MODE (RECTANGLE-NEAR-COMMAND-MENU)))
         (AND DEFAULT-ITEM
              (MULTIPLE-VALUE-BIND (X Y)
                  (SEND MENU :ITEM-CURSORPOS DEFAULT-ITEM)
                (AND X Y
                     (SEND MENU :SET-MOUSE-POSITION
                           (+ X (TV:SHEET-INSIDE-LEFT MENU))
                           (+ Y (TV:SHEET-INSIDE-TOP MENU))))))
         (OR (SEND MENU :CHOOSE) (ABORT-CURRENT-COMMAND))
         (SETQ DEFAULT-ITEM (SEND MENU :LAST-ITEM))
         (SET-COMMAND-BUTTON (SEND MENU :LAST-BUTTONS)))
        ((NULL DEFAULT-ITEM)
         (BARF "There is no default for this command yet")))
  (VALUES (SEND MENU :EXECUTE DEFAULT-ITEM)
          DEFAULT-ITEM))

(DEFUN SET-COMMAND-BUTTON (BUTTON)
  (SETQ *ZMAIL-COMMAND-BUTTON*
        (IF (SYMBOLP BUTTON) BUTTON
          (NTH (IF (TV:CHAR-MOUSE-P BUTTON)
                   (LDB %%KBD-MOUSE-BUTTON BUTTON)
                 (1- (HAULONG BUTTON)))
               '(:LEFT :MIDDLE :RIGHT)))))

;;; Return location of last selected item for use as a near-mode
(DEFUN RECTANGLE-NEAR-COMMAND-MENU (&OPTIONAL (TOP-SHEET *ZMAIL-WINDOW*)
                                    &AUX LEFT TOP RIGHT BOTTOM)
  (IF (NOT (AND (CONSP *LAST-COMMAND-CHAR*) (EQ (FIRST *LAST-COMMAND-CHAR*) :MENU)))
      '(:MOUSE)
    (MULTIPLE-VALUE (LEFT TOP RIGHT BOTTOM)
      (SEND (FOURTH *LAST-COMMAND-CHAR*) :ITEM-RECTANGLE (SECOND *LAST-COMMAND-CHAR*)))
    (MULTIPLE-VALUE-BIND (XOFF YOFF)
        (TV:SHEET-CALCULATE-OFFSETS (FOURTH *LAST-COMMAND-CHAR*) TOP-SHEET)
      (SETQ LEFT (+ LEFT XOFF)
            RIGHT (+ RIGHT XOFF))
      (SETQ TOP (+ TOP YOFF)
            BOTTOM (+ BOTTOM YOFF)))
    (LIST :RECTANGLE LEFT TOP RIGHT BOTTOM)))

(DEFUN DEFAULTED-MULTIPLE-MENU-CHOOSE-NEAR-MENU (ALIST &REST DEFAULTS)
  (SETQ DEFAULTS (TV:DEFAULTED-MULTIPLE-MENU-CHOOSE ALIST DEFAULTS
                   (RECTANGLE-NEAR-COMMAND-MENU TV:MOUSE-SHEET)))
  (OR DEFAULTS (ABORT-CURRENT-COMMAND))
  (VALUES-LIST DEFAULTS))

(DEFUN MENU-CHOOSE-WITH-NEW (ITEM-LIST NEW-FUNCTION &OPTIONAL (NEAR-MODE '(:MOUSE)) LABEL
                                                    &AUX VALUE)
  (USING-RESOURCE (MENU ZMAIL-MOMENTARY-MENU *ZMAIL-WINDOW*)
    (SEND MENU :SET-LABEL LABEL)
    (SEND MENU :SET-ITEM-LIST (CONS '("New" :VALUE :NEW :FONTS FONTS:TR12I
                                       :DOCUMENTATION "Specify a new item.")
                                     ITEM-LIST))
    (SEND MENU :SET-LAST-ITEM NIL)
    (TV:EXPOSE-WINDOW-NEAR MENU NEAR-MODE)
    (OR (SETQ VALUE (SEND MENU :CHOOSE)) (ABORT-CURRENT-COMMAND))
    (IF (EQ VALUE :NEW)
        (SEND MENU :EXECUTE-NO-SIDE-EFFECTS (FUNCALL NEW-FUNCTION MENU ITEM-LIST))
      VALUE)))
