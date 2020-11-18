;;; -*- Mode:LISP; Package:USER; Readtable:CL; Base:10 -*-

;(k-unfasl "jb:k.warm;VANILLA-INTERPRETER.KFASL#74" :output "jb:k.warm;VANILLA-INTERPRETER.unKFASL#74" :for-srccom nil)
;(k-unfasl "jb:k;lisp-internals.KFASL")

(defconstant $$FASL-OP-END-OF-FILE #X00)
;; Followed by nothing, exits the mini-fasloader

(defconstant $$FASL-OP-STRING      #x01)
;; Followed by a fixnum size, and then the characters

(defconstant $$fasl-op-fixnum           #x02)
(defconstant $$fasl-op-string-character #x03)
(defconstant $$fasl-op-nil              #x04)
(defconstant $$fasl-op-cons             #x05)
(defconstant $$fasl-op-end-of-object    #x06)
(defconstant $$fasl-op-create-table     #x07)
(defconstant $$fasl-op-reference-table-index    #x08)
(defconstant $$fasl-op-store-table-index        #x09)
(defconstant $$fasl-op-symbol           #x0a)
(defconstant $$fasl-op-compiled-function #x0b)
(defconstant $$fasl-op-defun            #x0c)
(defconstant $$fasl-op-defmacro         #x0d)
(defconstant $$fasl-op-defconstant      #x0e)
(defconstant $$fasl-op-defsubst         #x0f)
(defconstant $$fasl-op-defafun          #x10)
(defconstant $$fasl-op-eval             #x11)
(defconstant $$fasl-op-in-package       #x12)
(defconstant $$fasl-op-bignum           #x13)
(defconstant $$fasl-op-short-float      #x14)
(defconstant $$fasl-op-single-float     #x15)
(defconstant $$fasl-op-double-float     #x16)
(defconstant $$fasl-op-defvar           #x17)
(defconstant $$fasl-op-defparameter     #x18)
(defconstant $$fasl-op-unbound          #x19)
(defconstant $$fasl-op-list             #x1A)
(defconstant $$fasl-op-simple-vector    #x1f)
;; Followed by a fixnum size, and then the objects

;; For future expansion
(defconstant $$FASL-OP-ESCAPE #xFF)

(defvar *k-unfasl-input-stream* () "The stream that K-UNFASL uses to get its input")
(defvar *k-unfasl-output-stream* T "The stream that K-UNFASL sends its output to")
(defvar *k-unfasl-eof-marker* '(this-is-the-eof) "EOF marker for K-UNFASL")
(defvar *k-unfasl-for-srccom* ()
  "Set this if you want to produce output that will minimize the trivial differences between kfasl files")

(defun k-unfasl (name &key (output t) (for-srccom ()))
  (when (equal name output) (ferror "You have equal input and output!!!"))
  (unwind-protect
      (let ((*k-unfasl-for-srccom* for-srccom))
        (if (not (eq output t))
            (setq *k-unfasl-output-stream* (open output :direction :output)))
        (with-open-file (*k-unfasl-input-stream* name :direction ':input :byte-size 8)
          (k-unfasl-format ";;; -*- Mode:TEXT -*-~%~%")
          (do ((opcode (tyi *k-unfasl-input-stream* '(this-is-the-eof))
                       (tyi *k-unfasl-input-stream* '(this-is-the-eof))))
              ((= opcode 0)
               (format t "~%All done UNKFASLing"))
            (cond ((equal opcode '(this-is-the-eof))
                   (error "Got to EOF before reading eof opcode")))
            (k-unfasl-print-object (k-unfasl-read-object-1 opcode))
            (k-unfasl-format "~%~%"))))
    (if (not (eq output t))
        (close *k-unfasl-output-stream*))))

(defun k-unfasl-print-object (obj)
  (if (atom obj)
      (k-unfasl-format "~A" obj)
    (let ((opcode (car obj)))
      (cond
;;;((eq opcode '[EOF]) (li:error "Unexpected EOF in K-UNFASLOAD"))
;;;((eq opcode $$fasl-op-string) (k-unfasl-read-simple-string))
;;;((eq opcode $$fasl-op-fixnum) (k-unfasl-read-fixnum))
;;;((eq opcode $$fasl-op-bignum) (k-unfasl-read-bignum))
;;;((eq opcode $$fasl-op-nil) 'nil)
;;;((eq opcode $$fasl-op-string-character)(k-unfasl-read-string-character))
        ((eq opcode '[SYMBOL])
         (k-unfasl-print-symbol obj))
        ((eq opcode '[DEFUN])
         (k-unfasl-print-defun obj))
        ((eq opcode '[DEFAFUN])
         (k-unfasl-print-defafun obj))
        ((eq opcode '[DEFMACRO])
         (k-unfasl-print-defmacro obj))
        ((eq opcode '[DEFSUBST])
         (k-unfasl-print-defsubst obj))
        ((eq opcode '[COMPILED-FUNCTION])
         (k-unfasl-print-function obj))
        ((eq opcode '[CONS])
         (k-unfasl-print-cons obj))
        ((eq opcode '[LIST])
         (k-unfasl-print-list obj))
        ((eq opcode '[SHORT-FLOAT])
         (k-unfasl-print-short-float obj))
        ((eq opcode '[SINGLE-FLOAT])
         (k-unfasl-print-single-float obj))
        ((eq opcode '[DOUBLE-FLOAT])
         (k-unfasl-print-double-float obj))
        ((eq opcode '[DEFVAR])
         (k-unfasl-print-defvar obj))
        ((eq opcode '[DEFCONSTANT])
         (k-unfasl-print-defconstant obj))
        ((eq opcode '[DEFPARAMETER])
         (k-unfasl-print-defparameter obj))
        ((eq opcode '[EVAL])
         (k-unfasl-print-eval obj))
        ((eq opcode '[UNBOUND])
         (k-unfasl-print-unbound obj))
        ((eq opcode '[SIMPLE-VECTOR])
         (k-unfasl-print-simple-vector obj))
        ((listp obj)
         (k-unfasl-print-lisp-list obj))
        (t (error "K-UNFASL: Don't know how to print ~S" obj))))))

(defun k-unfasl-read-object ()
  (let ((opcode (k-unfasl-read-opcode)))
    (k-unfasl-read-object-1 opcode)))

(defun k-unfasl-read-object-1 (opcode)
  (cond ((= opcode $$fasl-op-end-of-file) (li:error "Unexpected EOF in K-UNFASLOAD"))
        ((= opcode $$fasl-op-string)            (k-unfasl-read-simple-string))
        ((= opcode $$fasl-op-fixnum)            (k-unfasl-read-fixnum))
        ((= opcode $$fasl-op-bignum)            (k-unfasl-read-bignum))
        ((= opcode $$fasl-op-symbol)            (k-unfasl-read-symbol))
        ((= opcode $$fasl-op-defun)             (k-unfasl-read-defun))
        ((= opcode $$fasl-op-defafun)           (k-unfasl-read-defun))
        ((= opcode $$fasl-op-defmacro)          (k-unfasl-read-defmacro))
        ((= opcode $$fasl-op-defsubst)          (k-unfasl-read-defsubst))
        ((= opcode $$fasl-op-compiled-function) (k-unfasl-read-function))
        ((= opcode $$fasl-op-cons)              (k-unfasl-read-cons))
        ((= opcode $$fasl-op-list)              (k-unfasl-read-list))
        ((= opcode $$fasl-op-nil)               'nil)
        ((= opcode $$fasl-op-short-float)       (k-unfasl-read-short-float))
        ((= opcode $$fasl-op-single-float)      (k-unfasl-read-single-float))
        ((= opcode $$fasl-op-double-float)      (k-unfasl-read-double-float))
        ((= opcode $$fasl-op-defvar)            (k-unfasl-do-defvar))
        ((= opcode $$fasl-op-string-character)  (k-unfasl-read-string-character))
        ((= opcode $$fasl-op-defconstant)       (k-unfasl-do-defconstant))
        ((= opcode $$fasl-op-defparameter)      (k-unfasl-do-defparameter))
        ((= opcode $$fasl-op-eval)              (k-unfasl-fake-eval))
        ((= opcode $$fasl-op-unbound)
         (li:error "K-UNFASL-READ-OBJECT can't cope with FASL-OP-UNBOUND."))
        ((= opcode $$fasl-op-simple-vector)     (k-unfasl-read-simple-vector))
        (t (k-unfasl-opcode-dispatch opcode))))

(defun k-unfasl-opcode-dispatch (opcode)
  (li:error "k-unfasl-opcode-dispatch is missing!" opcode))

(defun k-unfasl-end-of-file? ()
  (let ((opcode (k-unfasl-peek-opcode)))
    (if (= opcode $$fasl-op-end-of-file)
        t
        nil)))

(defun k-unfasl-peek-byte ()
  (tyipeek () *k-unfasl-input-stream* *k-unfasl-eof-marker*))

(defun k-unfasl-read-byte ()
  (read-byte *k-unfasl-input-stream* *k-unfasl-eof-marker*))

(defun k-unfasl-read-opcode ()
  (k-unfasl-read-byte))

(defun k-unfasl-peek-opcode ()
  (k-unfasl-peek-byte))

(defun k-unfasl-read-16-bits ()
  (let ((low-bits  (k-unfasl-read-byte))
        (high-bits (k-unfasl-read-byte)))
    (dpb high-bits (byte 8. 8.) low-bits)))

(defun k-unfasl-read-fixnum ()
  (let ((low-bits    (k-unfasl-read-byte))
        (medium-bits (k-unfasl-read-byte))
        (high-bits   (k-unfasl-read-byte)))
    (k-unfasl-make-fixnum low-bits medium-bits high-bits)))

(defun k-unfasl-make-fixnum (low medium high)
  (dpb high (byte 8. 16.)
       (dpb medium (byte 8. 8.)
            low)))

(defun k-unfasl-read-bignum ()
  (let* ((words-needed (k-unfasl-read-fixnum))
         (bignum 0))
    (do ((i 1 (1+ i))
         (num-base 1 (* num-base 8.)))
        ((> i (* 4. words-needed)))
      (setq bignum (+ bignum (* num-base (k-unfasl-read-byte)))))
    bignum
    ))

(defun k-unfasl-read-cons ()
  (cons (k-unfasl-read-object) (k-unfasl-read-object)))

;;; avoid recursion when reading lists
(defun k-unfasl-read-list ()
  (let ((length (k-unfasl-read-fixnum)))
    (let ((l '()))
      (let ((tail l))
        (dotimes (i length)
          (let ((cons (cons (k-unfasl-read-object)
                                    nil)))
            (if tail
              (rplacd tail cons)
              (setq l cons))
            (setq tail cons))))
      l)))

(defun k-unfasl-read-string-character ()
  (int-char (k-unfasl-read-byte)))

(defun k-unfasl-read-simple-string ()
  (let ((length (k-unfasl-read-fixnum)))
    (let ((string (make-string length)))
      (dotimes (i length)
        (setf (aref string i) (k-unfasl-read-string-character)))
      string)))

(defun k-unfasl-read-simple-vector ()
  (let ((length (k-unfasl-read-fixnum)))
    (let ((vector (make-array length)))
      (dotimes (i length)
        (setf (aref vector i) (k-unfasl-read-object)))
      `([SIMPLE-VECTOR] ,vector))))

(defun k-unfasl-opcode-dispatch (opcode)
  (error "k-unfasl-opcode-dispatch is missing!" opcode))

(defun k-unfasl-read-symbol ()
  `([SYMBOL]
    ,(k-unfasl-read-object)
    ,(k-unfasl-read-object)))

(defun k-unfasl-read-defsubst ()
  `([DEFSUBST]
    ,(k-unfasl-read-object) ;Throw the source away for now (PLIST eventually).
    ,(k-unfasl-read-defun)))

(defun k-unfasl-read-defmacro ()
  (let ((fname  (k-unfasl-read-object))
        (function (k-unfasl-read-object)))
    `([DEFMACRO] ,fname ,function)))

(defun k-unfasl-read-defun ()
  (let ((name     (k-unfasl-read-object))
        (function (k-unfasl-read-object)))
    `([DEFUN] ,name ,function)))

(defun k-unfasl-do-defconstant ()
  (let* ((symbol (k-unfasl-read-object))
         (value (k-unfasl-read-object))
         (documentation (k-unfasl-read-someones-value symbol)))
    `([DEFCONSTANT] ,symbol ,value ,documentation)))

(defun k-unfasl-do-defparameter ()
  (let* ((symbol (k-unfasl-read-object))
         (value (k-unfasl-read-object))
         (documentation (k-unfasl-read-someones-value symbol)))
    `([DEFPARAMETER] ,symbol ,value ,documentation)))

(defun k-unfasl-do-defvar ()
  (let ((symbol (k-unfasl-read-object)))
    ;; if the symbol is bound this shouldn't eval (if it's fasl-op-eval)
    (let ((opcode (k-unfasl-peek-opcode))
          (value (k-unfasl-read-someones-value symbol))
          (documentation (k-unfasl-read-object)))
      opcode
      `([DEFVAR] ,symbol ,value ,documentation))))

(defun k-unfasl-read-someones-value (someone)
  someone
  (let ((opcode (k-unfasl-read-opcode)))
    (cond ((= opcode $$fasl-op-unbound)
           "<UNBOUND WHEN LOADED>")
          (t (k-unfasl-read-object-1 opcode)))))

(defun k-unfasl-fake-eval ()
  `([EVAL] ,(k-unfasl-read-object)))

(defun k-unfasl-read-function ()
  (let* ((name         (k-unfasl-read-object))
         (local-refs   (k-unfasl-read-local-refs))
         (refs         (k-unfasl-read-refs))
         (entry-points (k-unfasl-read-entry-points))
         (length       (k-unfasl-read-fixnum))
         (byte-len (* 8 length)))
    (let ((code-vec (make-array byte-len)))
      (do ((i 0 (1+ i)))
          ((>= i byte-len))
        (setf (aref code-vec i) (k-unfasl-read-byte)))
      `([COMPILED-FUNCTION] ,name ,local-refs ,refs ,entry-points ([FUNCTION-CODE] ,code-vec) ,(k-unfasl-read-immediates)))))

(defun k-unfasl-read-entry-points ()
  (let* ((n (k-unfasl-read-fixnum))
         (len (+ n n))
         (entries '([ENTRIES])))
      (do ((i 0 (+ i 2)))
          ((>= i len))
        (setq entries `(,@entries
                        ([#ARGS] ,(k-unfasl-read-fixnum)    ;number of args
                         [OFFSET] ,(k-unfasl-read-fixnum)))))   ;entry point offset
      entries))

(defun k-unfasl-read-immediates ()
  (let ((list '([IMMEDIATES])))
    (dotimes (i (k-unfasl-read-fixnum))
      (setq list `(,@list
                   (,(k-unfasl-read-fixnum)
                    ,(k-unfasl-read-object)))))
    list))

(defun k-unfasl-read-local-refs ()
  (let* ((n (k-unfasl-read-fixnum))
         (len (+ n n))
         (refs '([LOCAL-REFS])))
      (do ((i 0 (+ i 2)))
          ((>= i len))
        (setq refs `(,@refs
                     (,(k-unfasl-read-fixnum)
                      ,(k-unfasl-read-fixnum)))))
      refs))

(defun k-unfasl-read-refs ()
  (let* ((n (k-unfasl-read-fixnum))
         (len (+ n n n))
         (refs '([REFS])))
      (do ((i 0 (+ i 3)))
          ((>= i len))
        (setq refs `(,@refs ([OFFSET] ,(k-unfasl-read-fixnum)
                             [FUNCTION] ,(k-unfasl-read-object)
                             [#ARGS] ,(k-unfasl-read-fixnum)))))
      refs))

(defun k-unfasl-read-short-float ()
  `([SHORT-FLOAT]
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)))

(defun k-unfasl-read-single-float ()
  `([SINGLE-FLOAT]
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)))

(defun k-unfasl-read-DOUBLE-float ()
  `([DOUBLE-FLOAT]
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)
    ,(k-unfasl-read-byte)))

(defun k-unfasl-format (fmt-string &rest args)
  (apply #'format *k-unfasl-output-stream* fmt-string args))

(defun k-unfasl-print-symbol (obj)
  (k-unfasl-format "~&~A::~A" (caddr obj) (cadr obj)))

(defun k-unfasl-print-defun (obj)
  (k-unfasl-print-defun-1 obj 'defun))

(defun k-unfasl-print-defafun (obj)
  (k-unfasl-print-defun-1 obj 'defafun))

(defun k-unfasl-print-defmacro (obj)
  (k-unfasl-print-defun-1 obj 'defmacro))

(defun k-unfasl-print-defsubst (obj)
;  (k-unfasl-format "~&DEFSUBST NAME: ~&")
;  (k-unfasl-print-object (car obj))
;  (k-unfasl-format "~&DEFSUBST SOURCE: ~&")
;  (k-unfasl-print-object (cadr obj))
  (k-unfasl-print-defun-1 (caddr obj) 'defsubst))

(defun k-unfasl-print-defun-1 (obj type)
  (k-unfasl-format "~&(~A " type)
  (k-unfasl-print-object (cadr obj))
  (k-unfasl-format "~&")
  (k-unfasl-print-function (caddr obj))
  (k-unfasl-format ")" type))

(defun k-unfasl-print-function (obj)
  (k-unfasl-format "~&COMPILED FUNCTION INFO:~&")
  (k-unfasl-format "~&NAME: ") (k-unfasl-print-object (cadr obj))
  (loop for elt in (cddr obj)
        do (k-unfasl-print-function-element elt)))

(defun k-unfasl-print-function-element (elt)
  (progn (k-unfasl-format "~&~A:" (car elt))
         (if (and *k-unfasl-for-srccom*
                  (eq (car elt) '[FUNCTION-CODE]))
             (k-unfasl-format "~&[A-Code-Object]")
           (loop for thing in (cdr elt)
                 do (progn (k-unfasl-format "~&")
                           (k-unfasl-print-object thing))))))

(defun k-unfasl-print-cons (obj)
  (k-unfasl-format "(")
  (k-unfasl-print-object (cadr obj))
  (k-unfasl-format " ")
  (k-unfasl-print-object (caddr obj))
  (k-unfasl-format ")"))

(defun k-unfasl-print-list (obj)
  (k-unfasl-format "(")
  (do ((elt (cdr obj) (cdr elt)))
      ((null (cdr elt))
       (k-unfasl-print-object (car elt)))
    (k-unfasl-format " ")
    (k-unfasl-print-object (car elt)))
  (k-unfasl-format ")"))

(defun k-unfasl-print-short-float (obj)
  (k-unfasl-format "~A" obj))

(defun k-unfasl-print-single-float (obj)
    (k-unfasl-format "~A" obj))

(defun k-unfasl-print-double-float (obj)
  (k-unfasl-format "~A" obj))

(defun k-unfasl-print-defvar (obj)
  (k-unfasl-print-defvar-1 obj 'defvar))

(defun k-unfasl-print-defconstant (obj)
    (k-unfasl-print-defvar-1 obj 'defconstant))

(defun k-unfasl-print-defparameter (obj)
  (k-unfasl-print-defvar-1 obj 'defparameter))

(defun k-unfasl-print-defvar-1 (obj type)
  (k-unfasl-format "(~A" type)
  (do ((elt (cdr obj) (cdr elt)))
      ((null (cdr elt)) ())
    (k-unfasl-format " ")
    (k-unfasl-print-object (car elt)))
  (k-unfasl-format ")"))

(defun k-unfasl-print-eval (obj)
  (k-unfasl-format "~&(eval (")
  (do ((elt (cadr obj) (cdr elt)))
      ((null (cdr elt))
       (k-unfasl-print-object (car elt)))
    (k-unfasl-print-object (car elt))
    (k-unfasl-format " "))
  (k-unfasl-format "))"))

(defun k-unfasl-print-unbound (obj)
  (k-unfasl-format "~A" obj))

(defun k-unfasl-print-simple-vector (obj)
  (k-unfasl-format "~A" obj))

(defun k-unfasl-print-lisp-list (obj)
  (k-unfasl-format "(")
  (do ((elt obj (cdr elt)))
      ((null (cdr elt))
       (k-unfasl-print-object (car elt))
       (k-unfasl-format ")"))
    (k-unfasl-print-object (car elt))
    (k-unfasl-format " ")))
