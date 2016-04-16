;; Add support for complex numbers to use any lower number type for real or imag arguments

(define (square x) (mul x x))

(define (variable? x) (symbol? x))

(define (same-variable? v1 v2)
  (and (variable? v1) (variable? v2) (eq? v1 v2)))
(define (=number? exp num)
  (and (number? exp) (= exp num)))

(define (attach-tag type-tag contents)
  (if (number? contents)
      contents
      (cons type-tag contents)))

(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (cond ((number? datum) 'scheme-number)
	    	(else
	    	  #f))))

(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (cond ((number? datum) datum)
	    ((symbol? datum)
	     (error "Bad tagged datum -- CONTENTS" datum)))))


(define op-table (make-hash))
(define (put op type item)
  (hash-set! op-table (list op type) item))
(define (get op type)
  (if (hash-has-key? op-table (list op type))
      (hash-ref op-table (list op type))
      #f))
      
(define tower-level (make-hash))
(define (put-tower-level type level)
  (hash-set! tower-level type level))
(define (get-tower-level item)
  (if (hash-has-key? tower-level (type-tag item))
  	  ((hash-ref tower-level (type-tag item)) item)
  	  #f))

(define (install-scheme-number-package)
  (define (tag x)
    (attach-tag 'scheme-number x))
  (define (raise x)
  	(cond ((exact-integer? x) (make-rational x 1))
  		  (else
  			(make-complex-from-real-imag x 0))))
  			
  (define (project x)
  	(cond ((exact-integer? x) x)
  		  (else
  		  	(inexact->exact (round x)))))

  (put 'add '(scheme-number scheme-number) +)
  (put 'sub '(scheme-number scheme-number) -)
  (put 'mul '(scheme-number scheme-number) *)
  (put 'div '(scheme-number scheme-number) /)
  (put 'equ? '(scheme-number scheme-number) =)		;just uses the built-in = for numbers
  (put '=zero? '(scheme-number) (lambda (x) (= x 0)))
  (put 'exp '(scheme-number scheme-number) expt)
  (put 'raise '(scheme-number) raise)
  (put 'project '(scheme-number) project)
  (put-tower-level 'scheme-number (lambda (x)
  									  (cond ((exact-integer? x) 1)
  		  								(else
		  								  3))))
  (put 'cosine '(scheme-number) cos)
  (put 'sine '(scheme-number) sin)
  (put 'square-root '(scheme-number) sqrt)
  (put 'arctan '(scheme-number) atan)
  (put 'arctan '(scheme-number scheme-number) atan)
  'done)

(define (install-rational-package)
  ;; internal procedures
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d)
    (let ((g (gcd n d)))
      (cons (/ n g) (/ d g))))
  (define (add-rat x y)
    (make-rat (+ (* (numer x) (denom y))
		 (* (numer y) (denom x)))
	      (* (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (- (* (numer x) (denom y))
		 (* (numer y) (denom x)))))
  (define (mul-rat x y)
    (make-rat (* (numer x) (numer y))
	      (* (denom x) (denom y))))

  (define (div-rat x y)
    (make-rat (* (numer x) (denom y))
	      (* (denom x) (numer y))))
  (define (rat-equ? x y)
    (and (= (numer x) (numer y))
	 (= (denom x) (denom y))))
  (define (=zero? x)
    (= (numer x) 0))
  (define (raise x)
  	(exact->inexact (/ (numer x) (denom x))))
  (define (project x)
  	(numer x))
  (define (cosine x)
  	(cos (div (numer x) (denom x))))
  (define (sine x)
    (sin (div (numer x) (denom x))))
  (define (square-root x)
    (sqrt (div (numer x) (denom x))))
  (define (arctan y x)
    (atan (div (numer y) (denom y)) (div (numer x) (denom x))))

  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational)
       (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational)
       (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational)
       (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational)
       (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational
       (lambda (n d) (tag (make-rat n d))))
  (put 'equ? '(rational rational) rat-equ?)
  (put '=zero? '(rational) =zero?)
  (put 'raise '(rational) raise)
  (put 'project '(rational) project)
  (put-tower-level 'rational (lambda (x) 2))
  (put 'cosine '(rational) cosine)
  (put 'sine '(rational) sine)
  (put 'square-root '(rational) square-root)
  (put 'arctan '(rational rational) arctan)
  'done)

(define (install-rectangular-package)
  (define (real-part z)  (car z))
  (define (imag-part z)  (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude z)
    (square-root (add (square (real-part z))
	     (square (imag-part z)))))
  (define (angle z)
    (arctan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (mul r (cosine a)) (mul r (sine a))))
  (define (rect-equ? z1 z2)
    (and (equ? (real-part z1) (real-part z2))
	 (equ? (imag-part z1) (imag-part z2))))
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular
       (lambda (x y)
	 (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a)
	 (tag (make-from-mag-ang r a))))
  (put 'equ? '(rectangular rectangular) rect-equ?)
  'done)

(define (install-polar-package)
  (define (magnitude z) (car z))
  (define (angle z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part z)
    (mul (magnitude z) (cosine (angle z))))
  (define (imag-part z)
    (mul (magnitude z) (sine (angle z))))
  (define (make-from-real-imag x y)
    (cons (square-root (add (square x) (square y)))
	  (arctan y x)))
  (define (polar-equ? z1 z2)
    (and (equ? (magnitude z1) (magnitude z2))
	 (equ? (angle z1) (angle z2))))

  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y)
	 (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a)
	 (tag (make-from-mag-ang r a))))
  (put 'equ? '(polar polar) polar-equ?)
  'done)

(define (install-complex-package)
  ;; imported procedures from rectangular and polar packages
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'polar) r a))

  (define (add-complex z1 z2)
    (make-from-real-imag (add (real-part z1) (real-part z2))
			 (add (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (sub (real-part z1) (real-part z2))
			 (sub (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (mul (magnitude z1) (magnitude z2))
		       (add (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (div (magnitude z1) (magnitude z2))
		       (sub (angle z1) (angle z2))))
  (define (complex-equ? z1 z2)
    (or (and (equ? (real-part z1) (real-part z2))
	 		(equ? (imag-part z1) (imag-part z2)))
	 	(and (equ? (magnitude z1) (magnitude z2))
	 		 (equ? (angle z1) (angle z2)))))
  (define (=zero? z)
    (equ? z (make-complex-from-real-imag 0 0)))
  (define (raise x)
  	x)
  (define (project x)
  	(real-part x))
  	
  (define (tag z) (attach-tag 'complex z))
  (put 'add '(complex complex)
       (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex)
       (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex)
       (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex)
       (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang r a))))
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle)
  (put 'equ? '(complex complex) complex-equ?)   ;added change for this exercise.
  (put '=zero? '(complex) =zero?)	;added for exercise 2.80.
  (put 'project '(complex) project)
  (put 'raise '(complex) raise)
  (put-tower-level 'complex (lambda (x) 4))
  'done)

(define (make-rational n d)
  ((get 'make 'rational) n d))
(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))
(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))


(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
	  (apply proc (map contents args))
	  (if (and (= (length args) 2) (not (eq? (car type-tags) (cadr type-tags)))) ;Exericise 2.81 c)
	      (let ((type1 (car type-tags))
		    (type2 (cadr type-tags))
		    (a1 (car args))
		    (a2 (cadr args)))
			(let ((t1->t2 (get-coercion type1 type2))
		      	  (t2->t1 (get-coercion type2 type1)))
		  		 (cond (t1->t2
			 			(apply-generic op (t1->t2 a1) a2))
					   (t2->t1
			 			(apply-generic op a1 (t2->t1 a2)))
					   (else
			 			(error "No method for these types"
								(list op type-tags))))))
	      (error "No method for these types"
		     (list op type-tags)))))))


(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))
(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))
(define (equ? x y) (apply-generic 'equ? x y))
(define (=zero? x) (apply-generic '=zero? x))
(define (raise x) (apply-generic 'raise x))
(define (project x) (apply-generic 'project x))
(define (cosine x) (apply-generic 'cosine x))
(define (sine x) (apply-generic 'sine x))
(define (square-root x) (apply-generic 'square-root x))
(define (arctan y x) (apply-generic 'arctan y x))

(define (scheme-number->complex n)
  (make-complex-from-real-imag (contents n) 0))

(define coercion-table (make-hash))
(define (put-coercion type1 type2 proc)
  (hash-set! coercion-table (list type1 type2) proc))
(define (get-coercion type1 type2)
  (if (hash-has-key? coercion-table (list type1 type2))
      (hash-ref coercion-table (list type1 type2))
      #f))

(put-coercion 'scheme-number 'complex scheme-number->complex)

(define (successive-raise item n)	
  (define (iter x i)
 	(if (> i n)
			x
			(iter (raise x) (+ i 1))))
	(iter item 1))

(define (drop x)
  (cond ((not (type-tag x)) x)
  		((= (get-tower-level x) 1) x)
  		((equ? (raise (project x)) x)
  		 (drop (project x)))
  		(else
  		 x)))

(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
      	(if (or (eq? op 'raise) (eq? op 'project)) 
	   		(apply proc (map contents args))
	   		(drop (apply proc (map contents args))))
	    (if (and (= (length args) 2) (not (eq? (car type-tags) (cadr type-tags)))) ;Exericise 2.81 c)
	  	  (let ((a1 (car args))
	  	  		(a2 (cadr args)))
	  	  	(let ((tdiff (- (get-tower-level a1) (get-tower-level a2))))
	   	  		(cond ((= tdiff 0) (apply-generic op a1 a2))
	  	  			  ((> tdiff 0) (apply-generic op a1 (successive-raise a2 tdiff)))
	  	  			  ((< tdiff 0) (apply-generic op (successive-raise a1 (abs tdiff)) a2)))))
	  	  (error "No op found for these types -- APPLY-GENERIC" (list op type-tags args)))))))
	  	  

(install-scheme-number-package)
(install-rational-package)
(install-rectangular-package)
(install-polar-package)
(install-complex-package)

;;> (div (make-complex-from-real-imag (make-rational 2 3) (make-rational 1 2)) (make-rational 1 3))
;;'(complex polar 2.5000000000000004 . 0.6435011087932844)
;;> (real-part (div (make-complex-from-real-imag (make-rational 2 3) (make-rational 1 2)) (make-rational 1 3)))
;;2.0000000000000004
;;> (imag-part (div (make-complex-from-real-imag (make-rational 2 3) (make-rational 1 2)) (make-rational 1 3)))
;;1.5000000000000002

;; Calling this exercise good for now.