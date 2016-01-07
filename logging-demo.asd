(defsystem logging-demo
  :author "Benjamin Brieber"
  :license "BSD"
  :description "A library of actions for collaborative rescue missions"

  :depends-on (roslisp
               split-sequence
               cram-language
               cl-transforms
               cram-prolog
               cram-designators
               geometry_msgs-msg
               cram-plan-library
               cram-plan-occasions-events
               cram-beliefstate)

  :components
  ((:module "src"
    :components
    ((:file "package")
     (:file "foo" :depends-on ("package"))))))
