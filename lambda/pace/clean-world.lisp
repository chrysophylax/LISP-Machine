;;; -*- Mode:LISP; Package:GARBAGE-COLLECTOR; Base:10; Readtable:CL -*-

(defun map-over-all-stack-groups (func)
  (labels ((do-func (sg)
             (cond ((eq sg current-stack-group)
                    (process-run-function "SG Map" func sg))
                   (t
                    (funcall func sg)))))
    (let (sg-list)
      (without-interrupts
        (dolist (proc all-processes)
          (when (not (send proc :simple-p))
            (let ((sg1 (send proc :stack-group))
                  (sg2 (send proc :initial-stack-group)))
              (push sg1 sg-list)
              (when (not (eq sg1 sg2))
                (push sg2 sg-list))))))
      (mapcar #'do-func sg-list))))

(defun clobber-binding-in-sg (sg bound-location func)
  (when (eq sg current-stack-group)
    (ferror nil "must not be current stack group"))
  (block nil
    (let ((sp (sg-special-pdl sg))
          (spp (sg-special-pdl-pointer sg)))
      (do ((index spp))
          ((< index 0)
           (if (not (= index -1))
               (ferror nil "something wrong with bottom of special pdl")))
        ;;skip over any saved microstack
        (do ()
            ((not (fixp (aref sp index))))
          (if (= index 0) (return nil))
          (decf index))
        (if (or (not (locativep (aref sp index)))
                (= index 0))
            (ferror nil "can't understand special-pdl"))

        (when (eq (aref sp index) bound-location)
          (funcall func (locf (aref sp (1- index)))))

        (decf index 2)))))

(defun chop-off-*values*-in-sg (sg &aux (n-found 0))
  (clobber-binding-in-sg sg (locf (symbol-value '*values*))
                         #'(lambda (location)
                             (setq location (follow-cell-forwarding location t))
                             (when (and (not (eq (%p-data-type location) dtp-list))
                                        (not (eq (%p-data-type location) dtp-symbol)))
                               (ferror nil "bad *values*"))
                             (when (not (null (contents location)))
                               (rplacd (nthcdr 10. (contents location)) nil))
                             (incf n-found)
                             ))
  n-found)

(defun clear-*values* ()
  (map-over-all-stack-groups #'chop-off-*values*-in-sg))

(defun find-external-value-cell-for-location-in-process (process location)
  (let ((closure (send process :eval-inside-yourself 'si:closure))
        cell)
    (when (not (closurep closure))
      (ferror nil "bad process closure ~s" closure))
    (let ((bindings (closure-bindings closure)))
      (do ((b bindings (cddr b)))
          ((null b))
        (when (or (not (locativep (car b)))
                  (not (locativep (cadr b))))
          (ferror nil "bad closure bindings"))
        (when (eq (car b) location)
          (when cell
            (ferror nil "two closures bindings for the same variable"))
          (setq cell (cadr b)))))
    (when cell
      (when (not (eq (%p-cdr-code cell) cdr-nil))
        (ferror nil "external-value-cell does not have cdr-nil"))
      cell)))


(defun clean-world ()
  (clear-*values*)
  (report-elapsed-time standard-output 4 "removal of previous method definitions"
    #'remove-previous-method-definitions)
  (report-elapsed-time standard-output 4 "removal of previous symbol function definitions"
    #'remove-previous-symbol-definitions)
  )



(defun describe-region-bits (bits)
  (format t "Map: ~a " (ecase (ldb %%region-access-and-status-bits bits)
                    (   0 "MISS")
                    (   1 "META")
                    (   2 "BAD ")
                    (   3 "BAD ")
                    (   4 "BAD ")
                    (   5 "PDL ")
                    (   6 "MAR ")
                    (   7 "BAD ")
                    (#o10 "BAD ")
                    (#o11 "BAD ")
                    (#o12 "RO  ")
                    (#o13 "RWF ")
                    (#o14 "RW  ")
                    (#o15 "BAD ")
                    (#o16 "BAD ")
                    (#o17 "BAD ")))

  (format t "~a " (ecase (ldb %%region-oldspace-meta-bit bits)
                    (0 "OLD ")
                    (1 "NEW ")))
  (if (not (ldb-test %%region-extra-pdl-meta-bit bits))
      (format t "EXPDL "))

  (format t "Rep ~a; " (ldb %%region-representation-type bits))
  (format t "Vol ~a; " (ldb %%region-volatility bits))

  (format t "Type ~a " (ecase (ldb %%REGION-SPACE-TYPE bits)
                    (   0 "FREE ")
                    (   1 "OLD  ")
                    (   2 "NEW  ")
                    (#o11 "STAT ")
                    (#o12 "FIX  ")
                    (#o13 "XPDL ")
                    (#o14 "COPY ")
                    (#o15 "MFX  ")
                    (#o16 "MNEW ")
                    ))
  (format t "Scav ~a " (ldb %%region-scavenge-enable bits))
  (format t "Flip ~a " (ldb %%region-flip-enable bits))
  (format t "Care ~a " (ldb %%region-scavenge-carefully bits))
  (format t "Swap ~d." (ldb %%region-swapin-quantum bits)))

(defun describe-region-bits-short (bits)
  (format t "~a " (ecase (ldb %%region-oldspace-meta-bit bits)
                    (0 "OLD ")
                    (1 "NEW ")))
  (if (not (ldb-test %%region-extra-pdl-meta-bit bits))
      (format t "EXPDL "))

  (format t "Vol ~a " (ldb %%region-volatility bits))

  (format t "~a " (ecase (ldb %%REGION-SPACE-TYPE bits)
                    (   0 "FREE ")
                    (   1 "OLD  ")
                    (   2 "NEW  ")
                    (#o11 "STAT ")
                    (#o12 "FIX  ")
                    (#o13 "XPDL ")
                    (#o14 "COPY ")
                    (#o15 "MFX  ")
                    (#o16 "MNEW ")
                    ))
  )


(DEFUN xROOM ()
  (do ((area working-storage-area (1+ area)))
      ((= area (system-communication-area %sys-com-number-areas)))
    (let ((name (area-name area)))
      (when name
        (format t "~&~30a " name)
        (describe-region-bits (si:%area-region-bits area))
        (for-every-region-in-area (region area)
          (format t "~&~8o " region)
          (describe-region-bits-short (%region-bits region))
          (let ((used (%region-free-pointer region))
                (size (%region-length region)))
            (format t "~6f%   ~9d/~9d = ~3d% "
                    (* 100.0 (/ (float size) (^ 2 24.)))
                    used size (round (* 100. (/ (float used) size))))))))))


(defun describe-pathname-area ()
  (si:map-over-all-objects-in-area
    fs:pathname-area
    #'(lambda (obj)
        (cond ((typep obj 'fs:pathname) (format t "~&###PATHNAME###"))
              ((and (consp obj)
                    (typep (car obj) 'fs:pathname))
               (print (cons '|###PATHNAME###| (cdr obj))))
              (t (print obj))))))
