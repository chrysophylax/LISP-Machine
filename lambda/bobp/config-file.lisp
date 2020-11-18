;;; -*- Mode:LISP; Package:SDU; Base:10; Readtable:ZL -*-

;; making menus fancier by including :name in labels
;; set up constraint frame:
;;   window for read/write/exit and in-core update stuff
;;   config-file contents
;;   sysconfig struct: in-file vs. in-core
;;   updating slot/option words vs in-file sysconf vs in-core sysconf

;; 1. print-from-list vs. in-line for cf-header , cf-slot, option stuff...
;; 2. make names nicer

;; smarts for redisplay only when required?
;; split into panes, display only one slot at a time?

;; uggh ... slot-stuff and options is only useful if changes
;; are propagated into sysconf, both in config file image and
;; in core.

;; one possibility is for accessor to have property to update
;; file and/or in-core sysconf; if only for certain entries.

;;; Copyright LISP Machine, Inc. 1986
;;;   See filename "Copyright.Text" for
;;; licensing and release information.

; bobp
; read and print sdu config file
; edit config file and in-core config structures
;
; requires unix-fs.lisp and c-funcs.lisp (now part of lambda-diag)
;
; (edit-config-file)
;    sets up mouse-sensitive display of config file
;
; (print-config-file)
;    prints most useful info from config file.
;
; (get-list-of-boards)
;    returns a list of the per-slot structures for all nubus slots.
;    use the per-slot defstruct to access them.
;
; (all-disabled-memory-boards)
;    returns a list of the disabled memory boards
;       each element of list is a list of (slot-number board-type)
;    see board-type-qs for the board types.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; per-slot structure in "resource map" section of config file
;; see /usr/86include/sys/lmi-config.h

;; art-8b image of the file
(defvar config-image nil)

(defvar n-slots 16.)

(defvar *config-alist* nil)

(eval-when (compile load eval)
(defun cf-assign-values (qs)
  (loop for q in qs
        for i from 0
        when q do
          (set q i)
          (putprop q t 'special)))
 )

; board names: position in list is board-type value
(defconst board-type-qs
          '(unknown none lmi-lambda mc68000 sdu vcmem half-meg-memory
             two-meg-memory medium-resolution-color bus-coupler
             ti-eight-meg-memory lmi-four-meg-memory lmi-sixteen-meg-memory
             quad-video nil lmi-eight-meg-memory nil lmi-twelve-meg-memory))
(cf-assign-values board-type-qs)

(defprop half-meg-memory 512. :memory-size)
(defprop two-meg-memory 2048. :memory-size)
(defprop ti-eight-meg-memory 8192. :memory-size)
(defprop lmi-four-meg-memory 4096. :memory-size)
(defprop lmi-sixteen-meg-memory 16380. :memory-size)
(defprop lmi-eight-meg-memory 8192. :memory-size)
(defprop lmi-twelve-meg-memory 12288. :memory-size)

(defun mem-board-p (ar)
  "return size in 1k pages if memory board, nil if not"
  (get (cf-slot-board-type ar) :memory-size))

(defconst mem-boards
          (loop for l in board-type-qs
                when (get l :memory-size)
                   collect l and do (putprop l 'print-memory-options :option-func)))

(defprop mc68000 print-68000-options :option-func)
(defprop lmi-lambda print-lambda-options :option-func)
(defprop vcmem print-vcmem-options :option-func)
(defprop quad-video print-quad-options :option-func)
(defprop sdu print-sdu-options :option-func)

(defprop lmi-lambda t :has-mem-size-assigned)
(defprop mc68000 t :has-mem-size-assigned)
(defprop sdu t :has-mem-size-assigned)

;;;;;;;;;;;;;;;;

(defconst console-type-qs '(sdu-serial-port-a
                             vcmem-screen
                             quad-video-screen
                             share-tty
                             sdu-serial-port-b))
(cf-assign-values console-type-qs)

(defprop vcmem 1 :number-of-screens)
(putprop 'vcmem vcmem-screen :console-type)
(defprop quad-video 4 :number-of-screens)
(putprop 'quad-video quad-video-screen :console-type)

(defvar y-n-qs '(no yes))
(cf-assign-values y-n-qs)

;;;;;;;;;;;;;;;;

(defvar ac-offset)

(eval-when (compile load eval)
(defun make-byte-accessor-forms (sym-def)
  (let* ((sym (car sym-def))
         (set-sym (intern (string-append "SET-" sym) (symbol-package sym)))
         (size 4)
         (offs ac-offset)
         (mult (or (get sym-def :repeat) size))
         args)
    (when (or (null (cadr sym-def)) (numberp (cadr sym-def)))
      (setq offs (or (cadr sym-def) offs)
            size (or (caddr sym-def) size)))
    (setq ac-offset (+ offs size))

    (do ((p (cdr sym-def) (cddr p)))
        ((null p))
      (cond
        ((and (symbolp (car p)) (car p))
         (putprop sym (cadr p) (car p)))))

    (cond
      ((get sym-def :repeat)
       (setq offs `(+ ,offs (* i ,mult)))
       (setq args `(i))))

    (selectq (get sym-def :type)
      (:string
       `((declare (special ,sym))
         (defun ,sym (ar ,@args)
           (get-string ar ,offs ,size))
         (defun ,set-sym (ar ,@args val)
           (set-string ar ,offs ,size val))
         (defsetf ,sym ,set-sym)))
      (:choice
       `((declare (special ,sym))
         (defun ,sym (ar ,@args)
           (get-choice ar ,offs ,size (get ',sym :choice-list)))
         (defun ,set-sym (ar ,@args val)
           (set-bytes ar ,offs ,size val))
         (defsetf ,sym ,set-sym)))
;;      (:switch
;;       `((declare (special ,sym))
;;       (defun ,sym (ar ,@args)
;;         (get-switch ar ,offs ,size (get ',sym :bits)))
;;       (defun ,set-sym (ar ,@args val)
;;         (set-bytes ar ,offs ,size val))
;;       (defsetf ,sym ,set-sym)))
      (t
       `((declare (special ,sym))
         (defun ,sym (ar ,@args)
           (get-bytes ar ,offs ,size))
         (defun ,set-sym (ar ,@args val)
           (set-bytes ar ,offs ,size val))
         (defsetf ,sym ,set-sym))))))
)

(defun get-choice (ar offs size choices)
  (let ((n (get-bytes ar offs size)))
    (or (nth n (symeval choices)) n)))

(defun get-bit-list (ar accessor)
  (let ((w (funcall accessor ar))
        (bits (symeval (get accessor :bits))))
    (loop for b in bits
          when (plusp (ldb (symeval b) w))
          collect (or (get b :name) b))))

;;(defun get-switch (ar offs size bits)
;;  (let ((w (get-bytes ar offs size)))
;;    (loop for b in bits
;;        when (not (zerop (ldb (symeval b) w)))
;;        collect (or (get b :name) b))))

(defun get-bytes (ar offs size)
  (loop for i from 0 below size
        for b from 0 by 8
        sum (ash (aref ar (+ i offs)) b)))

(defun set-bytes (ar offs size new)
  (loop for i from 0 below size
        for b from 0 by 8
        do (setf (aref ar (+ i offs)) (ldb (byte 8 b) new)))
  new)

(defun get-string (ar offs ignore)
  (ascii-string (c-str-copy ar offs)))  ;; size

(defun set-string (ar offs size new)
  (copy-array-portion new 0 (string-length new) ar offs (+ offs size)))

(defun set-up-names (qs f)
  (let ((base-len
          (loop for q in qs
                for diff = (abs (string-compare (funcall f q) (funcall f (car qs))))
                when (plusp diff) minimize diff)))
    (loop for q in qs
          do (putprop (funcall f q)
                      (string-subst-char #/space #/- (substring (funcall f q) (1- base-len)))
                      :name))))

(defmacro make-byte-accessors (qs)
  `(progn
     (set-up-names ,qs #'car)
     ,@(let ((ac-offset 0))
         (loop for q in (eval qs)
               append (make-byte-accessor-forms q)))))

;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;

; radix: default base to print and edit in
; verbose: only print in verbose mode
; type: string or screen; default is number
;   string: data is converted to/from a string array
;   screen: data is a number, but print and edit as a vcm_slot structure

; accessors for config file structures

;; config-file header
;; starts at 0 in file
(defconst cf-header-qs
          `((cf-header-version 0 4)
             (cf-header-bootable 4 4)
             (cf-header-whole-shared-area-address 8 4 :radix 16)
             (cf-header-whole-shared-area-size 12 4 :type :memory-size)
             (cf-header-sys-config-address 16 4 :radix 16)
             (cf-header-sys-config-size 20 4 :type :memory-size)
             (cf-header-slot-array-file-offset 24 4)
             (cf-header-slot-array-per-slot-size 28 4)
             (cf-header-sys-config-file-offset 32 4)
             (cf-header-slot-map-file-offset 36 4)
             (cf-header-slot-map-size 40 4)))
(make-byte-accessors cf-header-qs)

;; per-slot structure in config file
;; starts at (cf-header-slot-array-file-offset)
(defconst cf-slot-qs
          `((cf-slot-board-type 0 2 :type :choice :choice-list board-type-qs)
             (cf-slot-disabled 2 2 :type :choice :choice-list y-n-qs)
             (cf-slot-slot-number 4 2)
             (cf-slot-assigned-memory-size 12 4 :type :memory-size)
             (cf-slot-option-file-offset 16 4)
             (cf-slot-option-size 20 4)
             (cf-slot-major-version 24 2)
             (cf-slot-minor-version 28 2)))
(make-byte-accessors cf-slot-qs)

;; mc68000 option struct
(defconst cf-68000-qs
          `((cf-68000-screen 0 4 :type :screen)
            (cf-68000-devmap-size 4 4)
;;          (cf-68000-bootcons-size 8 4)
;;          (cf-68000-devmap 12 748)
;;          (cf-68000-boot-console 760 20 :type :string)
            (cf-68000-number-of-sharettys 780 2)
            (cf-68000-console-type 782 2 :type :choice :choice-list console-type-qs)
            (cf-68000-multibus-map-size 784 2)
            (cf-68000-console-baud-rate 786 2)))
(make-byte-accessors cf-68000-qs)

;; lambda parity enable bits in procconf and lambda options
(defconst lam-parity-qs '(mi-parity cm-parity dp-parity mid-parity treg-parity))
(set-up-names lam-parity-qs #'(lambda (x) x))
(set-up-names si:lambda-processor-switches-bits-symbols #'(lambda (x) x))

(assign-alternate `(mi-parity ,(byte 1 0)
                     cm-parity ,(byte 1 1)
                     dp-parity ,(byte 1 2)
                     mid-parity ,(byte 1 3)
                     treg-parity ,(byte 1 4)))

;; lambda option struct
(defconst cf-lambda-qs
          `((lam-opt-source-cycles 0 2)
            (lam-opt-exec-cycles 4 2)
            (lam-opt-screen 8 4 :type :screen)
            (lam-opt-processor-switches 12 4 :radix 8 :type :switch
                                        :bits si:lambda-processor-switches-bits-symbols)
            (lam-opt-timing-ram-file 20 60 :type :string)
            (lam-opt-micro-part 80 6 :type :string)
            (lam-opt-load-part 86 6 :type :string)
            (lam-opt-page-part 92 6 :type :string)
            (lam-opt-file-part 98 6 :type :string)
            (lam-opt-base-multibus-map-reg 104 4)
            (lam-opt-parity-enables 108 4 :radix 8 :type :switch :bits lam-parity-qs)
            (lam-opt-multibus-map-size 112 2)
            (lam-opt-scan-line-size 114 2)))
(make-byte-accessors cf-lambda-qs)

;; vcmem and quad-video option struct
(defconst cf-vcmem-qs
          `((vcm-opt-size nil 4)
            (vcm-opt-location nil 80 :repeat 80 :type :string)))
(make-byte-accessors cf-vcmem-qs)

;; SDU option structure in config file
(defconst cf-sdu-qs
  `((sdu-opt-newboot-code-size 0 4 :type :memory-size)
    (sdu-opt-user-area-size 4 4 :type :memory-size)
    (sdu-opt-user-map-size 8 4)))
(make-byte-accessors cf-sdu-qs)

;; memory board option struct
(defconst cf-bad-mem-qs
  `((mem-opt-list-size 0 2)
    (mem-opt-number-of-bad-sections 2 2)
    (mem-opt-bad-mem-addr 12 4 :repeat 8 :radix 16)
    (mem-opt-bad-mem-size 16 4 :repeat 8 :type :memory-size)))
(make-byte-accessors cf-bad-mem-qs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun print-config-file ()
  "read and print contents of sdu config file"
  (read-config-file)
  (print-config-image *standard-output*))

(defun edit-config-file ()
  (catch 'cf-exit
    (read-config-file)
    (setup-alist)
    (cf-redisplay *standard-output*)
    (do-forever
      (let ((x (send *standard-output* :any-tyi)))
        (when (listp x)
          (when (apply (cadr x) (caddr x))
            (cf-redisplay *standard-output*))
          )))))

(defun cf-redisplay (w)
  (send w :clear-screen)
  (print-commands w)
  (print-config-image w))

(defun print-slot-info (w)
  (dotimes (slot n-slots)
    (let ((ar (slot-array slot)))
      (print-one-slot w ar))))

(defun get-config-file (op)
  (let ((file (open-unix-file "//sdu//lambda//shr-config.1")))
    (when (null config-image)
      (if (neq op :read)
          (ferror nil "Attemp to write config file with garbage"))
      (setq config-image (make-array (unix-file-size file) :type :art-8b)))
    (rw-file op file config-image (unix-file-size file)))
  config-image)

(defun print-config-image (w)
  (format w "~2&")
  (print-from-list w cf-header-qs config-image)
  (format w "~2&")
  (print-slot-info w))

;; make indir array for sys-conf
(defun sys-conf-image ()
  (let ((offs (cf-header-sys-config-file-offset config-image))
        (size (cf-header-sys-config-size config-image)))
    (make-array size
                :type :art-8b
                :displaced-to config-image
                :displaced-index-offset offs)))

;; make indir array for a slot
(defun slot-array (slot)
  (let ((offs (cf-header-slot-array-file-offset config-image))
        (size (cf-header-slot-array-per-slot-size config-image)))
    (make-array size
                :type :art-8b
                :displaced-to config-image
                :displaced-index-offset (+ offs (* slot size)))))

(defun option-image (ar)
  (make-array (cf-slot-option-size ar)
              :type :art-8b
              :displaced-to config-image
              :displaced-index-offset (cf-slot-option-file-offset ar)))

;;;;;;;;;;;;;;;;

(defun get-list-of-boards ()
  "return a list of slot arrays for slots that contain boards"
  (read-config-file)
  (loop for slot from 0 below n-slots
        for ar = (slot-array slot)
        when (neq (cf-slot-board-type ar) 'none)
          collect ar))

; top level function for memory diagnostic

(defun all-disabled-mem-boards ()
  "return list of lists of car slot-number, cdr board-type symbol, for disabled memory boards"
  (read-config-file)
  (loop for slot from 0 below n-slots
        for ar = (slot-array slot)
        when (and (eq 'yes (cf-slot-disabled ar))
                  (mem-board-p ar))
        collect (cons (cf-slot-slot-number ar) (cf-slot-board-type ar))))

;;;;;;;;;;;;;;;;

(defun print-from-list (w qs ar)
  (let ((len (loop for q in qs
                   maximize (string-length (get (car q) :name)))))
    (dolist (q qs)
      (format w "~&")
      (send w :item 'number (list ar (car q))
            "~@(~Va~) ~a"
            (+ 2 len)
            (get (car q) :name)
            (fancy-print-in-base (funcall (car q) ar) (or (get q :radix) 10.))
            ))))

;; maybe try printing multiple times if b is a list of radices.
(defun fancy-print-in-base (v b)
  (selectq b
    (16.
     (format nil "#x~x" v))
    (10.
     (format nil "~d." v))
    (8
     (format nil "#o~o" v))
    (t
     (format nil "#~dr~Vr" b b v))
    ))

;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;

(defun mem-size-to-print (n)
  (if (= #xffffffff n)
      nil
    (format nil "~d KB" (ash n -10))))

(defun print-one-slot (w ar)
  (let ((board-type (cf-slot-board-type ar)))
    (format w "~&Slot ~d: " (cf-slot-slot-number ar))
    (send w :item 'choose-symbol-value (list ar 'cf-slot-board-type)
          "~@(~s~), " (cf-slot-board-type ar))
    (when (neq board-type 'none)
      (send w :item 'choose-symbol-value (list ar 'cf-slot-disabled)
            "Disabled: ~@(~a~), " (cf-slot-disabled ar))
      (send w :item 'number (list ar 'cf-slot-major-version)
            "Version: ~d" (cf-slot-major-version ar))
      (send w :item 'number (list ar 'cf-slot-minor-version)
            ".~d, " (cf-slot-minor-version ar))

      (format w "~&")
      (when (get board-type :has-mem-size-assigned)
        (send w :item 'memory-size (list ar 'cf-slot-assigned-memory-size)
              "~8tMemory size: ~a, " (mem-size-to-print (cf-slot-assigned-memory-size ar))))

      (when (or (get board-type 'has-options)
                (not (zerop (cf-slot-option-file-offset ar))))
        (send w :item 'number (list ar 'cf-slot-option-file-offset)
              "Option offset: ~d., " (cf-slot-option-file-offset ar))
        (when (not (zerop (cf-slot-option-file-offset ar)))
          (send w :item 'number (list ar 'cf-slot-option-size)
                "size: ~d., " (cf-slot-option-size ar))))

      (format w "~&")
      (let ((opt-func (get board-type :option-func)))
        (when (and opt-func
                   (not (zerop (cf-slot-option-file-offset ar))))
          (funcall opt-func w ar)))
    )))

;;;;;;;;;;;;;;;;

(defun print-68000-options (w ar)
  (let ((oa (option-image ar)))
    (format w "~&~16t")
    (send w :item 'screen (list oa 'cf-68000-screen)
          "Screen: ~a, " (screen-slot-string (cf-68000-screen oa)))
    (send w :item 'number (list oa 'cf-68000-devmap-size)
          "Devmap size: ~d., " (cf-68000-devmap-size oa))
    (format w "~&~16t")
    (send w :item 'number (list oa 'cf-68000-multibus-map-size)
          "Multibus map size: ~d., " (cf-68000-multibus-map-size oa))
    (send w :item 'choose-symbol-value (list oa 'cf-68000-console-type)
          "Console: ~@(~a~), " (cf-68000-console-type oa))))

;;;;;;;;;;;;;;;;

(defun print-lambda-options (w ar)
  (let ((op (option-image ar)))
    (format w "~&~16t")
    (send w :item 'string (list op 'lam-opt-micro-part)
          "Microload: ~s, " (lam-opt-micro-part op))
    (send w :item 'string (list op 'lam-opt-load-part)
          "Band: ~s, " (lam-opt-load-part op))
    (send w :item 'string (list op 'lam-opt-page-part)
          "Page: ~s, " (lam-opt-page-part op))
    (send w :item 'string (list op 'lam-opt-file-part)
          "File: ~s, " (lam-opt-file-part op))
    (format w "~&~16t")
    (send w :item 'screen (list op 'lam-opt-screen)
          "Screen: ~a, " (screen-slot-string (lam-opt-screen op)))
    (send w :item 'number (list op 'lam-opt-source-cycles)
          "Speed: ~d-" (lam-opt-source-cycles op))
    (send w :item 'number (list op 'lam-opt-exec-cycles)
          "~d, " (lam-opt-exec-cycles op))
    (format w "~&~16t")
    (send w :item 'string (list op 'lam-opt-timing-ram-file)
          "Timing-ram file: ~s, " (lam-opt-timing-ram-file op))
    (format w "~&~16t")
    (send w :item 'number (list op 'lam-opt-base-multibus-map-reg)
          "Base map reg: ~d., " (lam-opt-base-multibus-map-reg op))
    (send w :item 'number (list op 'lam-opt-multibus-map-size)
          "Map size: ~d., " (lam-opt-multibus-map-size op))
    (send w :item 'number (list op 'lam-opt-scan-line-size)
          "Scan line size: ~d., " (lam-opt-scan-line-size op))
    (format w "~&~16t")
    (send w :item 'switches (list op 'lam-opt-processor-switches)
          "Switches: #o~o:" (lam-opt-processor-switches op))
    (format w "~{~&~24t~@(~a~)~}" (get-bit-list op 'lam-opt-processor-switches))
    (format w "~&~16t")
    (send w :item 'switches (list op 'lam-opt-parity-enables)
          "Parity enables: #o~o:" (lam-opt-parity-enables op))
    (format w "~{~&~24t~@(~a~)~}" (get-bit-list op 'lam-opt-parity-enables))
    ))

;;;;;;;;;;;;;;;;

;; byte-fields for console type descriptor word in sysconfig and option structures
(defconst vcs-slot-number (byte 8 0))           ;slot number of board
(defconst vcs-type (byte 8 8))                  ;vcmem, quad, serial etc.
(defconst vcs-screen-number (byte 8 16))        ;screen number, for quad
(defconst vcs-hi-byte (byte 8 24))              ;#xff if no board, 0=port, 1=land

(defun vcs-present-p (vcm-slot)
  (not (or (zerop vcm-slot)
           (= #xff (ldb vcs-hi-byte vcm-slot)))))

(defun screen-slot-string (vcm-slot)
    (cond ((vcs-present-p vcm-slot)
           (select (ldb vcs-type vcm-slot)
             (vcmem-screen ;;1
              (format nil "Vcmem in slot ~d" (ldb vcs-slot-number vcm-slot)))
             (quad-video-screen ;;2
              (format nil "Screen ~d of quad-video in slot ~d"
                      (ldb vcs-screen-number vcm-slot)
                      (ldb vcs-slot-number vcm-slot)))
             ((0 3 4)
              (format nil "~@(~a~)" (nth (ldb vcs-type vcm-slot) console-type-qs)))
             ))
          (t
           "<none assigned>")))

(defun make-vcm-slot (type slot screen)
  (dpb type vcs-type
       (dpb slot vcs-slot-number
            (dpb screen vcs-screen-number 0))))

;;;;;;;;;;;;;;;;

(defun print-vcmem-options (w ar)
  (let ((oa (option-image ar)))
    (format w "~&~16t")
    (send w :item 'string (list oa 'vcm-opt-location)
          "Location: ~a" (vcm-opt-location oa 0))))

(defun print-quad-options (w ar)
  (let ((oa (option-image ar)))
    (dotimes (i 4)
      (format w "~&~16t")
      (send w :item 'string (list oa 'vcm-opt-location i)
            "Screen ~d location: ~a" i (vcm-opt-location oa i)))))

;;;;;;;;;;;;;;;;

(defun print-sdu-options (w ar)
  (let ((oa (option-image ar)))
    (format w "~&~16t")
    (send w :item 'memory-size (list oa 'sdu-opt-newboot-code-size)
          "Nubus code size: ~a, " (mem-size-to-print (sdu-opt-newboot-code-size oa)))
    (send w :item 'memory-size (list oa 'sdu-opt-user-area-size)
          "User-def area size: ~a, " (mem-size-to-print (sdu-opt-user-area-size oa)))
    (send w :item 'number (list oa 'sdu-opt-user-map-size)
          "User-def map pages: ~d." (sdu-opt-user-map-size oa))))

;;;;;;;;;;;;;;;;

(defun print-memory-options (w ar)
  (let ((op (option-image ar)))
    (format w "~&~16t")
    (send w :item 'number (list op 'mem-opt-list-size)
          "Bad list size: ~d., " (mem-opt-list-size op))
    (send w :item 'number (list op 'mem-opt-number-of-bad-sections)
          "Number of sections: ~d., " (mem-opt-number-of-bad-sections op))
    (dotimes (i (mem-opt-number-of-bad-sections op))
      (format w "~&~24t")
      (send w :item 'number (list op 'mem-opt-bad-mem-addr i)
            "addr=#x~x  " (mem-opt-bad-mem-addr op i))
      (send w :item 'memory-size (list op 'mem-opt-bad-mem-size i)
            "size=~a, " (mem-size-to-print (mem-opt-bad-mem-size op i))))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; item-types:
;;   number, screen, switches, string, console, memory-size, choose-symbol-value

(defconst edstring-info "Type  to complete; type  to abort")

(tv:add-typeout-item-type *config-alist* number "Change Number" cf-change-number t
                          "Change this number")

(defun cf-change-number (ar accessor &rest args &aux msg)
  (when (eq (get accessor :type) :memory-size)
    (setq msg (or (mem-size-to-print (apply accessor ar args)) "")))
  (do-forever
    (let ((new-string
            (zwei:pop-up-edstring
              (fancy-print-in-base (apply accessor ar args) (or (get accessor :radix) 10.))
              '(:mouse)
              `("Type a number" ,edstring-info)
              500
              nil
              msg)))
      (cond
        (new-string
         (let ((new (eval (read-from-string new-string nil))))
           (when (numberp new)
             (funcall (get accessor 'si:setf-method) ar new)
             (return-from cf-change-number t))))
        (t
         (return-from cf-change-number nil)))
      (setq msg "Not a number!")))))

;;;;;;;;;;;;;;;;

(tv:add-typeout-item-type *config-alist* memory-size "Change Memory Size" cf-change-number t
                          "Change assigned memory size")

;;;;;;;;;;;;;;;;

(tv:add-typeout-item-type *config-alist* screen "Change screen" cf-change-screen t
                          "Change the selected screen")

;; build list of possible video screens
;; choose from list
(defun cf-change-screen (ar accessor &aux old)
  (let ((choose-list
          (loop for i from 0 below n-slots
                for a = (slot-array i)
                for board-type = (cf-slot-board-type a)
                append (loop for j from 0 below (or (get board-type :number-of-screens) 0)
                             for vcs = (make-vcm-slot (get board-type :console-type) i j)
                             for elt = `(,(screen-slot-string vcs) ,vcs)
                             collect elt
                             when (eq vcs (funcall accessor ar))
                               do (setq old elt)))))
    (let ((new
            (tv:menu-choose choose-list "Choose screen:" '(:mouse) old)))
      (when new
        (funcall (get accessor 'si:setf-method)
                 ar
                 new)
        t))))

;;;;;;;;;;;;;;;;

(tv:add-typeout-item-type *config-alist* switches "Change Bits" cf-hack-switch t
                          "Change bits in the word")

(tv:add-typeout-item-type *config-alist* switches "Set Value" cf-change-number nil
                          "Set word to a new value")

(defun cf-hack-switch (ar accessor)
  (catch 'abort
    (let* ((w (funcall accessor ar))
           (bits (symeval (get accessor :bits)))
           (ca (make-array (length bits))))
      (tv:choose-variable-values
        (loop for b in bits
              for i from 0
              do (setf (aref ca i) (ldb (symeval b) w))
              collect `(,(locf (aref ca i))
                        ,(format nil
                                 "~@(~a~) (~db)"
                                 (get b :name)
                                 (ldb (byte 6 0) (symeval b)))
                        :number))
        :label (format nil "Edit bit-field values for ~:(~a~)" (or (get accessor :name) accessor))
        :margin-choices `("Done" ("Abort" (,#'(lambda () (throw 'abort nil))))))
      (loop for b in bits
            for i from 0
            do (funcall (get accessor 'si:setf-method)
                        ar
                        (dpb (aref ca i) (symeval b) (funcall accessor ar))))
      t)))

;;;;;;;;;;;;;;;;

(tv:add-typeout-item-type *config-alist* string "Change String" cf-change-string t
                          "Change this string")

(defun cf-change-string (ar accessor &rest args)
  (let ((new-string
          (zwei:pop-up-edstring
            (apply accessor ar args)
            '(:mouse)
            `(,(format nil "Edit value for ~:(~a~)." (or (get accessor :name) accessor)))
            500
            nil
            edstring-info)))
    (when new-string
      (apply (get accessor 'si:setf-method) ar (append args `(,new-string)))
      t)))

;;;;;;;;;;;;;;;;

;;choose-symbol-value
(tv:add-typeout-item-type *config-alist* choose-symbol-value "Choose Value" cf-choose-value t
                          "Choose value from a list")

(tv:add-typeout-item-type *config-alist* choose-symbol-value "Set Value" cf-change-number nil
                          "Set value to a number you type")

(defun cf-choose-value (ar accessor &aux dflt)
  (let* ((qs (symeval (get accessor :choice-list)))
         (cl (loop for q in qs
                   for elt = `(,(format nil "~@(~a~)" (or (get q :name) q)) ,(symeval q))
                   when q collect elt
                   when (eq q (funcall accessor ar))
                     do (setq dflt elt)))
         (label (format nil "Choose value for ~:(~a~):" (or (get accessor :name) accessor)))
         (new (tv:menu-choose cl label '(:mouse) dflt)))
    (when new
      (funcall (get accessor 'si:setf-method) ar new)
      t)))

;;;;;;;;;;;;;;;;

(defun print-commands (w)
  (send w :item 'com-exit nil "Exit without changing")
  (format w "~2&")
  (send w :item 'com-read nil "Read config file")
  (format w "~2&")
  (send w :item 'com-save nil "Write config file"))

(tv:add-typeout-item-type *config-alist* com-exit "Exit" cf-com-exit t
                          "Exit from config-file editor")

(tv:add-typeout-item-type *config-alist* com-read "Read config file" read-config-file t
                          "Reread config file")

(tv:add-typeout-item-type *config-alist* com-save "Write config file" write-config-file t
                          "Write config file")

(defun cf-com-exit ()
  (throw 'cf-exit nil))

(defun read-config-file ()
  (get-config-file :read)
  t)

(defun write-config-file ()
  (get-config-file :write)
  nil)

;;;;;;;;;;;;;;;;

(defun setup-alist ()
  (send *standard-output* :set-item-type-alist *config-alist*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun rand ()
  (ash (random (ash 2 32)) (- (random 32))))

;;;;;;;;;;;;;;;;

(defun undef (x)
  (makunbound x)
  (fmakunbound x)
  (do ((p (plist x) (cddr p)))
      ((null p))
    (remprop x (car p))))

;;;;;;;;;;;;;;;;
