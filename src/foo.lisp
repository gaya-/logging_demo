
;;; rosrun semrec semrec
;;; (small-script)
;;; (start-logging)
;;; (the-mission)
;;; (extract t)

(in-package :logging-test)

(defvar *log-id* nil)

(defvar *scanned-areas* () "this contains all areas that have been scaned actively")


(defun small-script ()
  (start-ros-node "rescue-pm")
  (start-logging))

(defun start-logging()
  (subscribe "/extract_files" "std_msgs/Bool" #'extract)
  ;;(cram-beliefstate::change-planlogging-namespace); :use-roslisp-ns t)
  (beliefstate:set-metadata
   :robot "bender"
   :creator "Benjamin Brieber"
   :experiment "logging test"
   :description "This Experiment shows some basic reasoning caps in action.")
  ;; (ros-info param-test "namespace:~a~%" roslisp::*namespace*)
  (setq *log-id* (beliefstate::start-node "START-EXPERIMENT" nil 2)))

(defun extract (data)
  (ros-info param-test "Stop logging~%")
  (cram-beliefstate::stop-node *log-id*)
  (cram-beliefstate::extract-files))

(export 'cram-plan-occasions-events::area-scanned (find-package :cram-plan-occasions-events))

(def-fact-group template-group (area-scanned)
  (<- (cram-plan-occasions-events::area-scanned ?area)
    nil))



(defstruct area
  (id nil)
  (name nil)
  (type nil)
  (points nil)
  (scanned nil))

(defun area-eq (area1 area2)
  (= (area-id area1) (area-id area2)))

(defun check-area (area)
  (member area *scanned-areas* :test #'area-eq))

(defvar *av-bottom* (make-area :id 1 :name "av_bottom" :type "avalanche-scan" :scanned nil))
(defvar *av-mast* (make-area :id 2 :name "av_mast" :type "avalanche-scan" :scanned nil))
(defvar *av-top* (make-area :id 3 :name "av_top" :type "avalanche-scan" :scanned nil))
(defvar *known-areas* (list *av-bottom* *av-mast* *av-top*))

(defun get-area (id)
  (let ((area (make-area :id id)))
    (loop for a in *known-areas* do
      (when (area-eq area a)
        (return-from get-area a)))))


(def-fact-group area-positions ()

  (<- (area-id 1))
  (<- (area-id 2))
  (<- (area-id 3))

  (<- (scan-area ?a)
    (area-id ?id)
    (lisp-fun get-area ?id ?a)))

(def-fact-group area-group (area-scanned)
  (<- (area-scanned ?area)
    (lisp-pred check-area ?area)))


(def-fact-group high-nav-actions (action-desig)
  (<- (action-desig ?desig (scan-area ?name))
    (desig-prop ?desig (:type :scan))
    (desig-prop ?desig (:area ?name))))

(defvar *victim-found* (cpl:make-fluent :name :victim-found) "changed when a victim is found")

(cpl:def-goal (plan-lib:achieve (area-scanned ?area))
  (format t "scanning-area ~a~%" ?area)
  (let ((goal (make-designator :action `((:type :scan)  (:area ,(area-name ?area))))))
    (cpm:pm-execute :scan goal)))

(cpl:def-cram-function scan-foo (area)
  (format t "scanning foo ~a~%" area))

(cram-process-modules:def-process-module scan-area-pm (action-designator)
  (roslisp:ros-info (cram-rescue-highlevel)
                    "area scan invoked with action designator `~a'."
                    action-designator)
  (destructuring-bind (cmd area) (reference action-designator)
    (ecase cmd
      (scan-area
       (scan-foo area)))))


(defun do-cool-stuff ()
  (plan-lib:achieve `(area-scanned ,*av-mast*))
  (roslisp:wait-duration 5)
  (setf (cpl:value *victim-found*) t)
  (plan-lib:achieve `(area-scanned ,*av-top*))
  (roslisp:wait-duration 5)
  ;; (roslisp:loop-at-most-every 5
  ;;   )
  )

(defun end-mission ()
  (format t "YEAH the mission is over~%"))

(cpl:define-policy victim-pol ()
  "This is an example policy."
  (:init (format t "Initializing policy~%")
         t)
  (:check  (cpl:value *victim-found*))
  (:recover (format t "Yeah nothing to recover~%"))
  (:clean-up (format t "end the mission here~%")))

(defun the-mission ()
  (cpl:top-level
    (cpl:with-failure-handling
        ((cpl:policy-check-condition-met (f)
           (declare (ignore f))
           (end-mission)
           (return)))
      (cpl:with-named-policy 'victim-pol ()
        (cpm:with-process-modules-running
            (scan-area-pm)
          (cpm:process-module-alias :scan 'scan-area-pm)
          (progn
            (do-cool-stuff)))))))
