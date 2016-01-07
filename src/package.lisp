(defpackage logging-test
  (:use
   #:common-lisp
   #:roslisp
   #:cl-transforms
   #:cram-utilities
   #:cram-designators
   #:cram-plan-library
   #:cram-plan-occasions-events
   #:cram-prolog)
  (:shadowing-import-from #:cram-designators #:object-designator #:object))
