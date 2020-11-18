;;; -*- Mode:LISP; Package:USER; Base:8 -*-

;;; Versatec functions

(DEFVAR VERSATEC-CONTROL-SETTING 0)             ;Has any bits which need to be on in ctl reg
(DEFVAR VERSATEC-PLOTTER-CONTROL 777510)
(DEFVAR VERSATEC-PLOTTER-DATA 777512)
(DEFVAR VERSATEC-PLOTTER-BYTE-COUNT 777500)
(DEFVAR VERSATEC-PRINTER-CONTROL 777514)
(DEFVAR VERSATEC-PRINTER-DATA 777516)
(DEFVAR VERSATEC-PRINTER-BYTE-COUNT 777504)
(DEFVAR VERSATEC-CONTROL)                       ;Bound to appropriate control location
(DEFVAR VERSATEC-BUFFER-ADDRESS 777506)
(DEFVAR VERSATEC-BUFFER-EXT-ADDRESS 777502)

(DEFUN VERSATEC-WAIT ()
  (DO ((STATE))
      (())
;    (PROCESS-WAIT "Versatec" #'(LAMBDA (UL &AUX S)
;                                ;; Wait for ready or error, and dma-busy off
;                                (AND (BIT-TEST (SETQ S (%UNIBUS-READ UL)) 100200)
;                                     (NOT (BIT-TEST S 20000))))
;                 VERSATEC-CONTROL)
    (SETQ STATE (%UNIBUS-READ VERSATEC-CONTROL))
    (COND ((BIT-TEST STATE 100000)
           (FERROR NIL "Versatec error, status is ~O" STATE))
          ((BIT-TEST STATE 200)
           (RETURN T)))))

(DEFUN VERSATEC-PRINT-CHAR (CHAR &AUX (VERSATEC-CONTROL VERSATEC-PRINTER-CONTROL))
  (VERSATEC-WAIT)
  (%UNIBUS-WRITE VERSATEC-PRINTER-DATA CHAR))

(DEFUN VERSATEC-PLOT-BYTE (BYTE &AUX (VERSATEC-CONTROL VERSATEC-PLOTTER-CONTROL))
  (VERSATEC-WAIT)
  (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA BYTE))

(DEFUN VERSATEC-RESET ()
  (%UNIBUS-WRITE VERSATEC-CONTROL 6))           ;Reset interface and buffer

(DEFUN VERSATEC-REMOTE-LINE-TERMINATE ()
  (VERSATEC-WAIT)
  (%UNIBUS-WRITE VERSATEC-CONTROL (LOGIOR VERSATEC-CONTROL-SETTING 40)))

(DEFUN VERSATEC-REMOTE-FORM-FEED ()
  (VERSATEC-WAIT)
  (%UNIBUS-WRITE VERSATEC-CONTROL (LOGIOR VERSATEC-CONTROL-SETTING 20)))

(DEFUN VERSATEC-REMOTE-END-OF-TRANSMISSION ()
  (VERSATEC-WAIT)
  (%UNIBUS-WRITE VERSATEC-CONTROL (LOGIOR VERSATEC-CONTROL-SETTING 10)))

(DEFUN VERSATEC-TEST (&AUX (VERSATEC-CONTROL VERSATEC-PRINTER-CONTROL))
  (VERSATEC-RESET)
  (DOTIMES (I 25.)
    (DOTIMES (I 100)
      (VERSATEC-PRINT-CHAR (+ I 100)))
    (VERSATEC-PRINT-CHAR 15))
  (VERSATEC-PRINT-CHAR 4))

(DEFUN VERSATEC-QWOPY (&OPTIONAL (SCREEN SI:TV-CPT-SCREEN)
                       &AUX ARRAY W H (VERSATEC-CONTROL VERSATEC-PLOTTER-CONTROL))
  (SETQ ARRAY (MAKE-ARRAY
                (LIST (SETQ W (FLOOR (SCREEN-WIDTH SCREEN) 8.))
                      (SETQ H (SCREEN-HEIGHT SCREEN)))
                ':TYPE  'ART-8B
                ':DISPLACED-TO (SCREEN-BUFFER-PIXEL-ARRAY SCREEN)))
  (VERSATEC-RESET)
  (DOTIMES (Y H)
    (DOTIMES (X W)
      (VERSATEC-PLOT-BYTE (AREF ARRAY (- W X 1) (- H Y 1))))
    (VERSATEC-REMOTE-LINE-TERMINATE))
  (VERSATEC-REMOTE-END-OF-TRANSMISSION))

(DEFUN VERSATEC-COPY (&OPTIONAL (INPUT-ARRAY (SCREEN-BUFFER-PIXEL-ARRAY SI:TV-CPT-SCREEN))
                      &AUX ARRAY-8B LINE-ARRAY
                           (W (ARRAY-DIMENSION-N 1 INPUT-ARRAY))
                           (H (ARRAY-DIMENSION-N 2 INPUT-ARRAY))
                           A8W UB-ADR
                           (VERSATEC-CONTROL VERSATEC-PLOTTER-CONTROL))
  (VERSATEC-RESET)
  (SETQ LINE-ARRAY (MAKE-ARRAY (* 2 H) ':TYPE 'ART-1B))
  (SETQ ARRAY-8B (MAKE-ARRAY (SETQ A8W (FLOOR H 4))
                             ':TYPE 'ART-8B
                             ':DISPLACED-TO LINE-ARRAY))
  (UNWIND-PROTECT
    (PROGN
      (SETQ UB-ADR (WIRE-ARRAY-AND-MAP LINE-ARRAY T 766142))
      (DOTIMES (X W)
        ;; Copy sideways line into buffer
        (DOTIMES (Y H)
          (LET ((BIT (AREF INPUT-ARRAY (- W X 1) Y)))
            (ASET BIT LINE-ARRAY (* 2 Y))
            (ASET BIT LINE-ARRAY (1+ (* 2 Y)))))
        ;; Now have line in line buffer, print it twice
        (VERSATEC-WAIT)
        (%UNIBUS-WRITE VERSATEC-BUFFER-ADDRESS UB-ADR)
        (%UNIBUS-WRITE VERSATEC-BUFFER-EXT-ADDRESS 0)
        (%UNIBUS-WRITE VERSATEC-PLOTTER-BYTE-COUNT A8W)
;       (DOTIMES (I A8W)
;         (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA (AREF ARRAY-8B I)))
        (VERSATEC-REMOTE-LINE-TERMINATE)
        (VERSATEC-WAIT)
        (%UNIBUS-WRITE VERSATEC-BUFFER-ADDRESS UB-ADR)
        (%UNIBUS-WRITE VERSATEC-BUFFER-EXT-ADDRESS 0)
        (%UNIBUS-WRITE VERSATEC-PLOTTER-BYTE-COUNT A8W)
;       (DOTIMES (I A8W)
;         (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA (AREF ARRAY-8B I)))
        (VERSATEC-REMOTE-LINE-TERMINATE)))
    (VERSATEC-REMOTE-END-OF-TRANSMISSION)
    (VERSATEC-WAIT)
    (WIRE-ARRAY-AND-MAP LINE-ARRAY NIL)))

(DEFUN VERSATEC-BIG-COPY (&OPTIONAL (INPUT-ARRAY (SCREEN-BUFFER-PIXEL-ARRAY SI:TV-CPT-SCREEN))
                                    (SCALE 9.) (MARGIN 100.)
                          &AUX ARRAY-8B LINE-ARRAY
                               (W (ARRAY-DIMENSION-N 1 INPUT-ARRAY))
                               (H (ARRAY-DIMENSION-N 2 INPUT-ARRAY))
                               (LSIZE (+ MARGIN 7 (* W SCALE)))
                               A8W UB-ADR
                               (VERSATEC-CONTROL VERSATEC-PLOTTER-CONTROL))
  (VERSATEC-RESET)
  (SETQ LINE-ARRAY (MAKE-ARRAY LSIZE ':TYPE 'ART-1B))
  (SETQ ARRAY-8B (MAKE-ARRAY (SETQ A8W (FLOOR LSIZE 8))
                             ':TYPE 'ART-8B
                             ':DISPLACED-TO LINE-ARRAY))
  (UNWIND-PROTECT
    (PROGN
      (SETQ UB-ADR (WIRE-ARRAY-AND-MAP LINE-ARRAY T 766142))
      (DOTIMES (Y H)
        ;; Copy sideways line into buffer
        (DOTIMES (X W)
          (LET ((BIT (AREF INPUT-ARRAY X Y))
                (XPOS (+ MARGIN (* SCALE X))))
            (DOTIMES (I SCALE)
              (ASET BIT LINE-ARRAY (+ I XPOS)))))
        ;; Now have line in line buffer, print it twice
        (DOTIMES (I SCALE)
          (VERSATEC-WAIT)
          (%UNIBUS-WRITE VERSATEC-BUFFER-ADDRESS UB-ADR)
          (%UNIBUS-WRITE VERSATEC-BUFFER-EXT-ADDRESS 0)
          (%UNIBUS-WRITE VERSATEC-PLOTTER-BYTE-COUNT A8W)
;         (DOTIMES (I A8W)
;           (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA (AREF ARRAY-8B I)))
          (VERSATEC-REMOTE-LINE-TERMINATE))))
    (VERSATEC-REMOTE-FORM-FEED)
    (VERSATEC-WAIT)
    (WIRE-ARRAY-AND-MAP LINE-ARRAY NIL)))

(DEFUN WIRE-ARRAY-AND-MAP (ARRAY &OPTIONAL (WIRE-P T) (UB-MAP-LOC 766140))
  (LET ((NPAGES (1+ (- (FLOOR (+ (%POINTER ARRAY) (%STRUCTURE-TOTAL-SIZE ARRAY))
                              SYS:PAGE-SIZE)
                       (FLOOR (%POINTER ARRAY) SYS:PAGE-SIZE))))
        (SWAP-STATUS (COND (WIRE-P SYS:%PHT-SWAP-STATUS-WIRED)
                           (T SYS:%PHT-SWAP-STATUS-NORMAL)))
        (LOC (LOGAND (%POINTER ARRAY) (- SYS:PAGE-SIZE))))
    (DOTIMES (I NPAGES)
      (DO ()
          ((SYS:%CHANGE-PAGE-STATUS LOC SWAP-STATUS NIL)
           (AND WIRE-P
                (%UNIBUS-WRITE (+ (* 2 I) UB-MAP-LOC)
                               (+ 100000 (LSH (SYS:%PHYSICAL-ADDRESS LOC) -8.)))))
        (%P-LDB 1 LOC))  ;If page not swapped in, reference and try again
      (SETQ LOC (+ LOC SYS:PAGE-SIZE))))
  (DPB (LSH UB-MAP-LOC -1)
       1204
       (+ 140000 (LSH (+ (LOGAND (1- SYS:PAGE-SIZE) (%POINTER ARRAY))
                         (%P-LDB-OFFSET SYS:%%ARRAY-NUMBER-DIMENSIONS ARRAY 0)
                         (%P-LDB-OFFSET SYS:%%ARRAY-LONG-LENGTH-FLAG ARRAY 0))
                      2))))

(DEFUN VERSATEC-TEST (&OPTIONAL (I 0)
                      &AUX ARRAY-8B LINE-ARRAY
                           (W 1400)
                           (H 1600)
                           A8W UB-ADR
                           (VERSATEC-CONTROL VERSATEC-PLOTTER-CONTROL))
  (VERSATEC-RESET)
  (SETQ LINE-ARRAY (MAKE-ARRAY (* 2 H) ':TYPE 'ART-1B))
  (SETQ ARRAY-8B (MAKE-ARRAY (SETQ A8W (FLOOR H 4))
                             ':TYPE 'ART-8B
                             ':DISPLACED-TO LINE-ARRAY))
  (UNWIND-PROTECT
    (PROGN
      (SETQ UB-ADR (WIRE-ARRAY-AND-MAP LINE-ARRAY T 766142))
      (DOTIMES (X (* 2 H))
        (ASET (IF (= I (LOGAND X 7)) 0 -1)
              LINE-ARRAY X))
      (DO () ((KBD-TYI-NO-HANG))
        ;; Now have line in line buffer, print it N times
        (VERSATEC-WAIT)
        (%UNIBUS-WRITE VERSATEC-BUFFER-ADDRESS UB-ADR)
        (%UNIBUS-WRITE VERSATEC-BUFFER-EXT-ADDRESS 0)
        (%UNIBUS-WRITE VERSATEC-PLOTTER-BYTE-COUNT A8W)
;       (DOTIMES (I A8W)
;         (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA (AREF ARRAY-8B I)))
        (VERSATEC-REMOTE-LINE-TERMINATE)
        (VERSATEC-WAIT)
        (%UNIBUS-WRITE VERSATEC-BUFFER-ADDRESS UB-ADR)
        (%UNIBUS-WRITE VERSATEC-BUFFER-EXT-ADDRESS 0)
        (%UNIBUS-WRITE VERSATEC-PLOTTER-BYTE-COUNT A8W)
;       (DOTIMES (I A8W)
;         (%UNIBUS-WRITE VERSATEC-PLOTTER-DATA (AREF ARRAY-8B I)))
        (VERSATEC-REMOTE-LINE-TERMINATE)))
    (VERSATEC-REMOTE-FORM-FEED)
    (VERSATEC-WAIT)
    (WIRE-ARRAY-AND-MAP LINE-ARRAY NIL)))
