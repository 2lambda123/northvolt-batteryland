(begin
#| should be counterclockwise, somehow isnt; fixed for now by negating angle |#
(define rotateAround (lambda (pivot point angle)
    (let ((s (sin (- 0 angle)))
          (c (cos (- 0 angle)))
          (px (car point))
          (py (cdr point))
          (cx (car pivot))
          (cy (cdr pivot)))
      (let ((x (- px cx))
            (y (- py cy)))
        (cons
          (+ cx (- (* c x) (* s y)))
          (+ cy (+ (* s x) (* c y))))))))

(define point-add (lambda (p q)
    (cons
      (+ (car p) (car q))
      (+ (cdr p) (cdr q)))))

(define point-sub (lambda (p q)
    (cons
      (- (car p) (car q))
      (- (cdr p) (cdr q)))))

(define point-mul (lambda (p n)
    (cons (* (car p) n) (* (cdr p) n))))

(define point-div (lambda (p n)
    (cons (/ (car p) n) (/ (cdr p) n))))

(define midpoint (lambda (points)
  (point-div (foldl point-add points (cons 0 0)) (length points))))

(define points->rect (lambda (points)
  (let ((rects (map (lambda (p)
    (let ((min (point-add p (cons -1 -1))) (max (point-add p (cons 1 1))))
      (make-rectangle (car min) (cdr min) (car max) (cdr max)))) points)))
        #| (foldl rects rect:union (car rects)) |#
        (rect:union (rect:union (rect:union (car rects) (car (cdr rects))) (car (cdr (cdr rects)))) (car (cdr (cdr (cdr rects)))))
       )))

#| TODO: illu (ie gocv.Mat) is not hashable, so cant store it in claim in db. pass by ref? |#

(when ((highlighted ,?page ,?color) ((page points) ,?page ,?points) ((page angle) ,?page ,?angle)) do
    (let ((center (midpoint (quote ,?points)))
          (unangle (* -360 (/ ,?angle (* 2 pi))))
          (illu (make-illumination)))
      (let ((rotated (map (lambda (p) (rotateAround center p ,?angle)) (quote ,?points)))
            (m (gocv:rotation_matrix2D (car center) (cdr center) unangle 1.0)))
        #| TODO: make p->center a unit vector, add in projector-space inches instead of a percentage |#
        (define inset (lambda (p) (point-add p (point-mul (point-sub center p) 0.2))))
        (gocv:rect illu (points->rect (map inset rotated)) ,?color -1)
        (gocv:text illu "TEST" (point2d (car center) (cdr center)) 0.5 green 2)
        #| might not work because it doesnt support inplace |#
        (gocv:warp_affine illu illu m 1280 720)
        (claim ,?page 'has-illumination 'illu))))

(when ((outlined ,?page ,?color) ((page points) ,?page ,?points)) do
    (let ((pts (quote ,?points))
          (illu (make-illumination)))
      (let ((ulhc (car pts))
            (urhc (car (cdr pts)))
            (lrhc (car (cdr (cdr pts))))
            (llhc (car (cdr (cdr (cdr pts))))))
        (let ((ulhc (point2d (car ulhc) (cdr ulhc)))
              (urhc (point2d (car urhc) (cdr urhc)))
              (lrhc (point2d (car lrhc) (cdr lrhc)))
              (llhc (point2d (car llhc) (cdr llhc))))
          (gocv:line illu ulhc urhc ,?color 5)
          (gocv:line illu urhc lrhc ,?color 5)
          (gocv:line illu lrhc llhc ,?color 5)
          (gocv:line illu llhc ulhc ,?color 5)))))

(when ((pointing ,?page ,?cm) ((page points) ,?page ,?points)) do
    (let ((pts (quote ,?points))
          (illu (make-illumination)))
      (let ((ulhc (car pts))
            (urhc (car (cdr pts)))
            (lrhc (car (cdr (cdr pts)))))
        (let ((mid (point-div (point-add ulhc urhc) 2))
              (line (point-sub lrhc urhc)))
          (let ((norm (point-div line (sqrt (+ (* (car line) (car line)) (* (cdr line) (cdr line)))))))
            (let ((end (point-add mid (point-mul norm (* pixelsPerCM ,?cm)))))
                (gocv:line illu (point2d (car mid) (cdr mid)) (point2d (car end) (cdr end)) green 5)
                (claim ,?page 'points-dot end)
                ))))))

(when ((points-dot ,?page ,?dot) ((page points) ,?other ,?points) ((page angle) ,?other ,?angle)) do
  (if (not (eqv? ,?page ,?other))
    (if (contained (quote ,?points) ,?angle (quote ,?dot))
      (claim ,?page 'points-at ,?other))))

(define contained (lambda (points angle dot)
    (let ((center (midpoint points)))
      (let ((rotated (map (lambda (p) (rotateAround center p angle)) points))
            (p (rotateAround center dot angle)))
        (let ((min (car rotated))
              (max (car (cdr (cdr rotated)))))
          (and (and (and (< (car min) (car p))
                    (< (car p) (car max)))
                    (< (cdr min) (cdr p)))
                    (< (cdr p) (cdr max))))))))

(define print-results (lambda (illu results p d)
  (let ((offset (+ d 20)))
    (if (not (null? results))
      (begin
        (gocv:text illu (pr:kind (car results)) (point2d (+ 20 (car p)) (+ offset (cdr p))) 0.5 red 2)
        (print-results illu (cdr results) p offset))))))

(define processdata (lambda (id points angle)
    (let ((center (midpoint points))
          (ulhc (car points))
          (cellid (symbol->string id))
          (unangle (* -360 (/ angle (* 2 pi))))
          (illu (make-illumination)))
      (let ((m (gocv:rotation_matrix2D (car center) (cdr center) unangle 1.0))
            (results (ps:results cellid))
            (cell (identity->cell (dt:identity cellid))))
        (gocv:text illu (cell:id cell) (point2d (+ 20 (car ulhc)) (+ 20 (cdr ulhc))) 0.5 red 2)
        (print-results illu results ulhc 20)
        (gocv:warp_affine illu illu m 1280 720)))))

(when ((modifies ,?page ,?func)) do
  (claim ,?page 'pointing 30))

(when ((modifies ,?page ,?func) (points-at ,?page ,?cellpage) (cell ,?cellpage ,?id) ((page points) ,?cellpage ,?points) ((page angle) ,?cellpage ,?angle)) do
  (,?func (quote ,?id) (quote ,?points) ,?angle))

)
