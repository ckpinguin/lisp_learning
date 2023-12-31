(defparameter *width* 100)
(defparameter *height* 30)
(defparameter *jungle* '(45 10 10 10))
(defparameter *plant-energy* 80)
(defparameter *plants* (make-hash-table :test #'equal))

(defun random-plant (left top width height)
  (let ((pos (cons (+ left (random width)) (+ top (random height)))))
    (setf (gethash pos *plants*) t)))

(defun add-plants ()
  (apply #'random-plant *jungle*)
; only one plant in the rest of the map:
  (random-plant 0 0 *width* *height*))

(defstruct animal x y energy dir genes)

(defparameter *animals*
  (list (make-animal :x      (ash *width*  -1)
		     :y      (ash *height* -1)
		     :energy 1000
		     :dir    0
		     :genes  (loop repeat 8
				  ; collecting and collect look and behave the same to me...
				  collecting (1+ (random 10))))))

(defun move (animal)
  (let ((dir (animal-dir animal))
	(x (animal-x animal))
	(y (animal-y animal)))
    (setf (animal-x animal) (mod (+ x
				    (cond ((and (>= dir 2) (< dir 5)) 1)
					  ((or (= dir 1) (= dir 5)) 0)
					  (t -1)))
				 *width*))
    (setf (animal-y animal) (mod (+ y
				    (cond ((and (>= dir 0) (< dir 3)) -1)
					  ((or (= dir 7) (= dir 3)) 0)
					  (t 1)))
				 *height*))
		    (decf (animal-energy animal))))

(defun turn (animal)
  (let ((x (random (apply #'+ (animal-genes animal)))))
    (labels ((angle (genes x)
	       (let ((xnu (- x (car genes)))) ; xnu be random from genes sum minus first gene
		 (if (< xnu 0) ; recursion anchor
		     0
		     ; recursive for all genes
		     (1+ (angle (cdr genes) xnu))))))
      (setf (animal-dir animal)
	    (mod (+ (animal-dir animal) (angle (animal-genes animal) x))
		 8))))) ; wrap around direction (0-7) if needed

(defun eat (animal)
  (let ((pos (cons (animal-x animal) (animal-y animal))))
    (when (gethash pos *plants*)
      (incf (animal-energy animal) *plant-energy*)
      (remhash pos *plants*))))

(defparameter *reproduction-energy* 200)

(defun reproduce (animal)
  (let ((e (animal-energy animal)))
    (when (>= e *reproduction-energy*)
      (setf (animal-energy animal) (ash e -1))
      (let ((animal-nu (copy-structure animal))
	    (genes     (copy-list (animal-genes animal)))
	    (mutation  (random 8))) ; select a random gene to be mutated
	(setf (nth mutation genes)
	      ; and set it to +-1 or the same
	      (max 1 (+ (nth mutation genes) (random 3) -1)))
	(setf (animal-genes animal-nu) genes)
	(push animal-nu *animals*)))))

(defun update-world ()
  (setf *animals* (remove-if (lambda (animal)
			       (<= (animal-energy animal) 0))
			     *animals*))
  (mapc (lambda (animal)
	  (turn animal)
	  (move animal)
	  (eat animal)
	  (reproduce animal))
	*animals*)
  (add-plants))

(defun draw-world ()
  (loop for y
       below *height*
       do (progn (fresh-line)
		 (princ "|")
		 (loop for x
		      below *width*
		      do (princ (cond ((some (lambda (animal)
					       (and (= (animal-x animal) x)
						    (= (animal-y animal) y)))
					     *animals*)
				       #\M)
				      ((gethash (cons x y) *plants*) #\*)
				      (t #\space))))
		 (princ "|"))))

(defun evolution ()
  (draw-world)
  (fresh-line)
  (let ((str (read-line)))
    (cond ((equal str "quit") ())
	  (t (let ((x (parse-integer str :junk-allowed t)))
	       (if x
		   (loop for i
		      below x
		      do (update-world)
		      if (zerop (mod i 1000))
		      do (princ #\.))
		   (update-world))
	       (evolution))))))