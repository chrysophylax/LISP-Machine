;;; -*- Mode:LISP; Package:LISP-INTERNALS; Base:10; Readtable:CL -*-


;;;Need throw and catch.




;;;;; TAK ;;;;;;;;;;

(defun tak (x y z)
  (if (not (< y x))
      z
    (tak (tak (1- x) y z)
         (tak (1- y) z x)
         (tak (1- z) x y))))

;;;;; TAKL ;;;;;;;;;;

(defun listn (n)
  (if (not (= 0 n))
      (cons n (listn (1- n)))))

(defvar 18l nil)
(defvar 12l nil)
(defvar  6l nil)

(defun mas (x y z)
  (if (not (shorterp y x))
      z
    (mas (mas (cdr x)
              y z)
         (mas (cdr y)
              z x)
         (mas (cdr z)
              x y))))

(defun shorterp (x y)
  (and y (or (null x)
             (shorterp (cdr x)
                       (cdr y)))))

;;;;;;;;;; STAK ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar stak-x)
(defvar stak-y)
(defvar stak-z)

(defun stak ()
       (cond ((not (< stak-y stak-x))   ;stak-x  stak-y
              stak-z)
             (t (let ((stak-x (let ((stak-x (1- stak-x))
                               (stak-y stak-y)
                               (stak-z stak-z))
                              (stak)))
                      (stak-y (let ((stak-x (1- stak-y))
                               (stak-y stak-z)
                               (stak-z stak-x))
                              (stak)))
                      (stak-z (let ((stak-x (1- stak-z))
                               (stak-y stak-x)
                               (stak-z stak-y))
                              (stak))))
                     (stak)))))

;;;;;;;;;; STAK ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ctak (x y z)
 (catch 'ctak-aux (tak1 x y z)))

(defun ctak-aux (x y z)
       (cond ((not (< y x))     ;xy
              (throw 'ctak z))
             (t (tak1
                 (catch 'ctak
                         (ctak-aux (1- x)
                               y
                               z))
                 (catch 'ctak
                         (ctak-aux (1- y)
                               z
                               x))
                 (catch 'ctak
                         (ctak-aux (1- z)
                               x
                               y))))))

;;;;;;;;;; TAKR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 (DEFUN TAK0 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK1 (TAK37 (1- X) Y Z)
                   (TAK11 (1- Y) Z X)
                   (TAK17 (1- Z) X Y)))))
  (DEFUN TAK1 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK2 (TAK74 (1- X) Y Z)
                   (TAK22 (1- Y) Z X)
                   (TAK34 (1- Z) X Y)))))
  (DEFUN TAK2 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK3 (TAK11 (1- X) Y Z)
                   (TAK33 (1- Y) Z X)
                   (TAK51 (1- Z) X Y)))))
  (DEFUN TAK3 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK4 (TAK48 (1- X) Y Z)
                   (TAK44 (1- Y) Z X)
                   (TAK68 (1- Z) X Y)))))
  (DEFUN TAK4 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK5 (TAK85 (1- X) Y Z)
                   (TAK55 (1- Y) Z X)
                   (TAK85 (1- Z) X Y)))))
  (DEFUN TAK5 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK6 (TAK22 (1- X) Y Z)
                   (TAK66 (1- Y) Z X)
                   (TAK2 (1- Z) X Y)))))
  (DEFUN TAK6 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK7 (TAK59 (1- X) Y Z)
                   (TAK77 (1- Y) Z X)
                   (TAK19 (1- Z) X Y)))))
  (DEFUN TAK7 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK8 (TAK96 (1- X) Y Z)
                   (TAK88 (1- Y) Z X)
                   (TAK36 (1- Z) X Y)))))
  (DEFUN TAK8 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK9 (TAK33 (1- X) Y Z)
                   (TAK99 (1- Y) Z X)
                   (TAK53 (1- Z) X Y)))))
  (DEFUN TAK9 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK10 (TAK70 (1- X) Y Z)
                    (TAK10 (1- Y) Z X)
                    (TAK70 (1- Z) X Y)))))
  (DEFUN TAK10 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK11 (TAK7 (1- X) Y Z)
                    (TAK21 (1- Y) Z X)
                    (TAK87 (1- Z) X Y)))))
  (DEFUN TAK11 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK12 (TAK44 (1- X) Y Z)
                    (TAK32 (1- Y) Z X)
                    (TAK4 (1- Z) X Y)))))
  (DEFUN TAK12 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK13 (TAK81 (1- X) Y Z)
                    (TAK43 (1- Y) Z X)
                    (TAK21 (1- Z) X Y)))))
  (DEFUN TAK13 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK14 (TAK18 (1- X) Y Z)
                    (TAK54 (1- Y) Z X)
                    (TAK38 (1- Z) X Y)))))
  (DEFUN TAK14 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK15 (TAK55 (1- X) Y Z)
                    (TAK65 (1- Y) Z X)
                    (TAK55 (1- Z) X Y)))))
  (DEFUN TAK15 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK16 (TAK92 (1- X) Y Z)
                    (TAK76 (1- Y) Z X)
                    (TAK72 (1- Z) X Y)))))
  (DEFUN TAK16 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK17 (TAK29 (1- X) Y Z)
                    (TAK87 (1- Y) Z X)
                    (TAK89 (1- Z) X Y)))))
  (DEFUN TAK17 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK18 (TAK66 (1- X) Y Z)
                    (TAK98 (1- Y) Z X)
                    (TAK6 (1- Z) X Y)))))
  (DEFUN TAK18 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK19 (TAK3 (1- X) Y Z)
                    (TAK9 (1- Y) Z X)
                    (TAK23 (1- Z) X Y)))))
  (DEFUN TAK19 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK20 (TAK40 (1- X) Y Z)
                    (TAK20 (1- Y) Z X)
                    (TAK40 (1- Z) X Y)))))
  (DEFUN TAK20 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK21 (TAK77 (1- X) Y Z)
                    (TAK31 (1- Y) Z X)
                    (TAK57 (1- Z) X Y)))))
  (DEFUN TAK21 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK22 (TAK14 (1- X) Y Z)
                    (TAK42 (1- Y) Z X)
                    (TAK74 (1- Z) X Y)))))
  (DEFUN TAK22 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK23 (TAK51 (1- X) Y Z)
                    (TAK53 (1- Y) Z X)
                    (TAK91 (1- Z) X Y)))))
  (DEFUN TAK23 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK24 (TAK88 (1- X) Y Z)
                    (TAK64 (1- Y) Z X)
                    (TAK8 (1- Z) X Y)))))
  (DEFUN TAK24 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK25 (TAK25 (1- X) Y Z)
                    (TAK75 (1- Y) Z X)
                    (TAK25 (1- Z) X Y)))))
  (DEFUN TAK25 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK26 (TAK62 (1- X) Y Z)
                    (TAK86 (1- Y) Z X)
                    (TAK42 (1- Z) X Y)))))
  (DEFUN TAK26 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK27 (TAK99 (1- X) Y Z)
                    (TAK97 (1- Y) Z X)
                    (TAK59 (1- Z) X Y)))))
  (DEFUN TAK27 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK28 (TAK36 (1- X) Y Z)
                    (TAK8 (1- Y) Z X)
                    (TAK76 (1- Z) X Y)))))
  (DEFUN TAK28 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK29 (TAK73 (1- X) Y Z)
                    (TAK19 (1- Y) Z X)
                    (TAK93 (1- Z) X Y)))))
  (DEFUN TAK29 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK30 (TAK10 (1- X) Y Z)
                    (TAK30 (1- Y) Z X)
                    (TAK10 (1- Z) X Y)))))
  (DEFUN TAK30 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK31 (TAK47 (1- X) Y Z)
                    (TAK41 (1- Y) Z X)
                    (TAK27 (1- Z) X Y)))))
  (DEFUN TAK31 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK32 (TAK84 (1- X) Y Z)
                    (TAK52 (1- Y) Z X)
                    (TAK44 (1- Z) X Y)))))
  (DEFUN TAK32 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK33 (TAK21 (1- X) Y Z)
                    (TAK63 (1- Y) Z X)
                    (TAK61 (1- Z) X Y)))))
  (DEFUN TAK33 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK34 (TAK58 (1- X) Y Z)
                    (TAK74 (1- Y) Z X)
                    (TAK78 (1- Z) X Y)))))
  (DEFUN TAK34 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK35 (TAK95 (1- X) Y Z)
                    (TAK85 (1- Y) Z X)
                    (TAK95 (1- Z) X Y)))))
  (DEFUN TAK35 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK36 (TAK32 (1- X) Y Z)
                    (TAK96 (1- Y) Z X)
                    (TAK12 (1- Z) X Y)))))
  (DEFUN TAK36 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK37 (TAK69 (1- X) Y Z)
                    (TAK7 (1- Y) Z X)
                    (TAK29 (1- Z) X Y)))))
  (DEFUN TAK37 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK38 (TAK6 (1- X) Y Z)
                    (TAK18 (1- Y) Z X)
                    (TAK46 (1- Z) X Y)))))
  (DEFUN TAK38 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK39 (TAK43 (1- X) Y Z)
                    (TAK29 (1- Y) Z X)
                    (TAK63 (1- Z) X Y)))))
  (DEFUN TAK39 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK40 (TAK80 (1- X) Y Z)
                    (TAK40 (1- Y) Z X)
                    (TAK80 (1- Z) X Y)))))
  (DEFUN TAK40 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK41 (TAK17 (1- X) Y Z)
                    (TAK51 (1- Y) Z X)
                    (TAK97 (1- Z) X Y)))))
  (DEFUN TAK41 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK42 (TAK54 (1- X) Y Z)
                    (TAK62 (1- Y) Z X)
                    (TAK14 (1- Z) X Y)))))
  (DEFUN TAK42 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK43 (TAK91 (1- X) Y Z)
                    (TAK73 (1- Y) Z X)
                    (TAK31 (1- Z) X Y)))))
  (DEFUN TAK43 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK44 (TAK28 (1- X) Y Z)
                    (TAK84 (1- Y) Z X)
                    (TAK48 (1- Z) X Y)))))
  (DEFUN TAK44 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK45 (TAK65 (1- X) Y Z)
                    (TAK95 (1- Y) Z X)
                    (TAK65 (1- Z) X Y)))))
  (DEFUN TAK45 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK46 (TAK2 (1- X) Y Z)
                    (TAK6 (1- Y) Z X)
                    (TAK82 (1- Z) X Y)))))
  (DEFUN TAK46 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK47 (TAK39 (1- X) Y Z)
                    (TAK17 (1- Y) Z X)
                    (TAK99 (1- Z) X Y)))))
  (DEFUN TAK47 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK48 (TAK76 (1- X) Y Z)
                    (TAK28 (1- Y) Z X)
                    (TAK16 (1- Z) X Y)))))
  (DEFUN TAK48 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK49 (TAK13 (1- X) Y Z)
                    (TAK39 (1- Y) Z X)
                    (TAK33 (1- Z) X Y)))))
  (DEFUN TAK49 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK50 (TAK50 (1- X) Y Z)
                    (TAK50 (1- Y) Z X)
                    (TAK50 (1- Z) X Y)))))
  (DEFUN TAK50 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK51 (TAK87 (1- X) Y Z)
                    (TAK61 (1- Y) Z X)
                    (TAK67 (1- Z) X Y)))))
  (DEFUN TAK51 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK52 (TAK24 (1- X) Y Z)
                    (TAK72 (1- Y) Z X)
                    (TAK84 (1- Z) X Y)))))
  (DEFUN TAK52 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK53 (TAK61 (1- X) Y Z)
                    (TAK83 (1- Y) Z X)
                    (TAK1 (1- Z) X Y)))))
  (DEFUN TAK53 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK54 (TAK98 (1- X) Y Z)
                    (TAK94 (1- Y) Z X)
                    (TAK18 (1- Z) X Y)))))
  (DEFUN TAK54 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK55 (TAK35 (1- X) Y Z)
                    (TAK5 (1- Y) Z X)
                    (TAK35 (1- Z) X Y)))))
  (DEFUN TAK55 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK56 (TAK72 (1- X) Y Z)
                    (TAK16 (1- Y) Z X)
                    (TAK52 (1- Z) X Y)))))
  (DEFUN TAK56 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK57 (TAK9 (1- X) Y Z)
                    (TAK27 (1- Y) Z X)
                    (TAK69 (1- Z) X Y)))))
  (DEFUN TAK57 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK58 (TAK46 (1- X) Y Z)
                    (TAK38 (1- Y) Z X)
                    (TAK86 (1- Z) X Y)))))
  (DEFUN TAK58 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK59 (TAK83 (1- X) Y Z)
                    (TAK49 (1- Y) Z X)
                    (TAK3 (1- Z) X Y)))))
  (DEFUN TAK59 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK60 (TAK20 (1- X) Y Z)
                    (TAK60 (1- Y) Z X)
                    (TAK20 (1- Z) X Y)))))
  (DEFUN TAK60 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK61 (TAK57 (1- X) Y Z)
                    (TAK71 (1- Y) Z X)
                    (TAK37 (1- Z) X Y)))))
  (DEFUN TAK61 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK62 (TAK94 (1- X) Y Z)
                    (TAK82 (1- Y) Z X)
                    (TAK54 (1- Z) X Y)))))
  (DEFUN TAK62 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK63 (TAK31 (1- X) Y Z)
                    (TAK93 (1- Y) Z X)
                    (TAK71 (1- Z) X Y)))))
  (DEFUN TAK63 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK64 (TAK68 (1- X) Y Z)
                    (TAK4 (1- Y) Z X)
                    (TAK88 (1- Z) X Y)))))
  (DEFUN TAK64 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK65 (TAK5 (1- X) Y Z)
                    (TAK15 (1- Y) Z X)
                    (TAK5 (1- Z) X Y)))))
  (DEFUN TAK65 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK66 (TAK42 (1- X) Y Z)
                    (TAK26 (1- Y) Z X)
                    (TAK22 (1- Z) X Y)))))
  (DEFUN TAK66 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK67 (TAK79 (1- X) Y Z)
                    (TAK37 (1- Y) Z X)
                    (TAK39 (1- Z) X Y)))))
  (DEFUN TAK67 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK68 (TAK16 (1- X) Y Z)
                    (TAK48 (1- Y) Z X)
                    (TAK56 (1- Z) X Y)))))
  (DEFUN TAK68 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK69 (TAK53 (1- X) Y Z)
                    (TAK59 (1- Y) Z X)
                    (TAK73 (1- Z) X Y)))))
  (DEFUN TAK69 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK70 (TAK90 (1- X) Y Z)
                    (TAK70 (1- Y) Z X)
                    (TAK90 (1- Z) X Y)))))
  (DEFUN TAK70 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK71 (TAK27 (1- X) Y Z)
                    (TAK81 (1- Y) Z X)
                    (TAK7 (1- Z) X Y)))))
  (DEFUN TAK71 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK72 (TAK64 (1- X) Y Z)
                    (TAK92 (1- Y) Z X)
                    (TAK24 (1- Z) X Y)))))
  (DEFUN TAK72 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK73 (TAK1 (1- X) Y Z)
                    (TAK3 (1- Y) Z X)
                    (TAK41 (1- Z) X Y)))))
  (DEFUN TAK73 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK74 (TAK38 (1- X) Y Z)
                    (TAK14 (1- Y) Z X)
                    (TAK58 (1- Z) X Y)))))
  (DEFUN TAK74 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK75 (TAK75 (1- X) Y Z)
                    (TAK25 (1- Y) Z X)
                    (TAK75 (1- Z) X Y)))))
  (DEFUN TAK75 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK76 (TAK12 (1- X) Y Z)
                    (TAK36 (1- Y) Z X)
                    (TAK92 (1- Z) X Y)))))
  (DEFUN TAK76 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK77 (TAK49 (1- X) Y Z)
                    (TAK47 (1- Y) Z X)
                    (TAK9 (1- Z) X Y)))))
  (DEFUN TAK77 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK78 (TAK86 (1- X) Y Z)
                    (TAK58 (1- Y) Z X)
                    (TAK26 (1- Z) X Y)))))
  (DEFUN TAK78 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK79 (TAK23 (1- X) Y Z)
                    (TAK69 (1- Y) Z X)
                    (TAK43 (1- Z) X Y)))))
  (DEFUN TAK79 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK80 (TAK60 (1- X) Y Z)
                    (TAK80 (1- Y) Z X)
                    (TAK60 (1- Z) X Y)))))
  (DEFUN TAK80 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK81 (TAK97 (1- X) Y Z)
                    (TAK91 (1- Y) Z X)
                    (TAK77 (1- Z) X Y)))))
  (DEFUN TAK81 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK82 (TAK34 (1- X) Y Z)
                    (TAK2 (1- Y) Z X)
                    (TAK94 (1- Z) X Y)))))
  (DEFUN TAK82 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK83 (TAK71 (1- X) Y Z)
                    (TAK13 (1- Y) Z X)
                    (TAK11 (1- Z) X Y)))))
  (DEFUN TAK83 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK84 (TAK8 (1- X) Y Z)
                    (TAK24 (1- Y) Z X)
                    (TAK28 (1- Z) X Y)))))
  (DEFUN TAK84 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK85 (TAK45 (1- X) Y Z)
                    (TAK35 (1- Y) Z X)
                    (TAK45 (1- Z) X Y)))))
  (DEFUN TAK85 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK86 (TAK82 (1- X) Y Z)
                    (TAK46 (1- Y) Z X)
                    (TAK62 (1- Z) X Y)))))
  (DEFUN TAK86 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK87 (TAK19 (1- X) Y Z)
                    (TAK57 (1- Y) Z X)
                    (TAK79 (1- Z) X Y)))))
  (DEFUN TAK87 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK88 (TAK56 (1- X) Y Z)
                    (TAK68 (1- Y) Z X)
                    (TAK96 (1- Z) X Y)))))
  (DEFUN TAK88 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK89 (TAK93 (1- X) Y Z)
                    (TAK79 (1- Y) Z X)
                    (TAK13 (1- Z) X Y)))))
  (DEFUN TAK89 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK90 (TAK30 (1- X) Y Z)
                    (TAK90 (1- Y) Z X)
                    (TAK30 (1- Z) X Y)))))
  (DEFUN TAK90 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK91 (TAK67 (1- X) Y Z)
                    (TAK1 (1- Y) Z X)
                    (TAK47 (1- Z) X Y)))))
  (DEFUN TAK91 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK92 (TAK4 (1- X) Y Z)
                    (TAK12 (1- Y) Z X)
                    (TAK64 (1- Z) X Y)))))
  (DEFUN TAK92 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK93 (TAK41 (1- X) Y Z)
                    (TAK23 (1- Y) Z X)
                    (TAK81 (1- Z) X Y)))))
  (DEFUN TAK93 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK94 (TAK78 (1- X) Y Z)
                    (TAK34 (1- Y) Z X)
                    (TAK98 (1- Z) X Y)))))
  (DEFUN TAK94 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK95 (TAK15 (1- X) Y Z)
                    (TAK45 (1- Y) Z X)
                    (TAK15 (1- Z) X Y)))))
  (DEFUN TAK95 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK96 (TAK52 (1- X) Y Z)
                    (TAK56 (1- Y) Z X)
                    (TAK32 (1- Z) X Y)))))
  (DEFUN TAK96 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK97 (TAK89 (1- X) Y Z)
                    (TAK67 (1- Y) Z X)
                    (TAK49 (1- Z) X Y)))))
  (DEFUN TAK97 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK98 (TAK26 (1- X) Y Z)
                    (TAK78 (1- Y) Z X)
                    (TAK66 (1- Z) X Y)))))
  (DEFUN TAK98 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK99 (TAK63 (1- X) Y Z)
                    (TAK89 (1- Y) Z X)
                    (TAK83 (1- Z) X Y)))))
  (DEFUN TAK99 (X Y Z)
    (COND ((NOT (< Y X)) Z)
          (T (TAK0 (TAK0 (1- X) Y Z)
                   (TAK0 (1- Y) Z X)
                   (TAK0 (1- Z) X Y)))))

;;;;;;;;;; BENCHMARK the machine ;;;;;;;;;;;;;;

(defmacro run-test (info func)
  `(progn

     (li:error
       ,info
       ,func
       (hw:read-microsecond-clock))))


(defun test-taks ()

  (unless 18l (setq 18l (listn 18)))
  (unless 12l (setq 12l (listn 12)))
  (unless 6l  (setq 6l  (listn 6)))

  (hw:write-microsecond-clock (hw:unboxed-constant 0))
  (li:error "TAK complete." (tak 18 12 6) (hw:read-microsecond-clock))

  (hw:write-microsecond-clock (hw:unboxed-constant 0))
  (li:error "TAKL complete." (mas 18l 12l 6l) (hw:read-microsecond-clock))

  (setq stak-x 18.)
  (setq stak-y 12.)
  (setq stak-z 6.)
  (hw:write-microsecond-clock (hw:unboxed-constant 0))
  (li:error "STAK complete." (stak) (hw:read-microsecond-clock))

  (hw:write-microsecond-clock (hw:unboxed-constant 0))
  (li:error "CTAK complete." (ctak 18 12 6) (hw:read-microsecond-clock))

  (hw:write-microsecond-clock (hw:unboxed-constant 0))
  (li:error "TAKR complete." (tak0 18 12 6) (hw:read-microsecond-clock))

  (li:error "All Done, no more tests.")
  (loop))
