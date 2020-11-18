;;; -*- Mode:LISP; Package:TCP-APPLICATION; Base:10;patch-file:t -*-

(DEFMETHOD (SIMPLE-ASCII-STREAM-TERMINAL :SUBTYI) ()
  (LET ((C))
    (IF NEED-FORCE-OUTPUT (SEND SELF :FORCE-OUTPUT))
    (SETQ C (SEND INPUT :TYI))
    (SETQ C (OR (CADR (ASSQ C
                            '((#o10 #\BS)
                              (#o11 #\TAB)
                              (#o12 #\LINE)
                              (#o14 #\FF)
                              (#o15 #\RETURN)
                              (#o177 #\RUBOUT))))
                C))
    (COND ((NULL C))
          ((= C #o33)
           (SETQ C (SET-CHAR-BIT (SEND SELF :SUBTYI) :META 1)))
          ((< C #o40)
           (SETQ C (SET-CHAR-BIT (LOGIOR #O100 C) :CONTROL 1))))
    c))
