(library
  (harlan middle flatten-lets)
  (export flatten-lets)
  (import (rnrs) (elegant-weapons helpers)
    (harlan helpers))

;; parse-harlan takes a syntax tree that a user might actually want
;; to write and converts it into something that's more easily
;; analyzed by the type inferencer and the rest of the compiler.
;; This subsumes the functionality of the previous
;; simplify-literals mini-pass.

;; unnests lets, checks that all variables are in scope, and
;; renames variables to unique identifiers
  
(define-match flatten-lets
  ((module ,[Decl -> decl*] ...)
   `(module . ,decl*)))

(define-match Decl
  ((fn ,name ,args ,type ,[Stmt -> stmt])
   `(fn ,name ,args ,type ,(make-begin `(,stmt))))
  (,else else))

(define-match Stmt
  ((let ((,x* ,t* ,[Expr -> e*]) ...) ,[stmt])
   `(begin
      ,@(map (lambda (x t e) `(let ,x ,t ,e)) x* t* e*)
      ,stmt))
  ((if ,[Expr -> test] ,[conseq])
   `(if ,test ,conseq))
  ((if ,[Expr -> test] ,[conseq] ,[alt])
   `(if ,test ,conseq ,alt))
  ((begin ,[stmt*] ...)
   (make-begin stmt*))
  ((print ,[Expr -> expr])
   `(print ,expr))
  ((assert ,[Expr -> expr])
   `(assert ,expr))
  ((return) `(return))
  ((return ,[Expr -> expr])
   `(return ,expr))
  ((for (,x ,start ,end) ,[stmt])
   `(for (,x ,start ,end) ,stmt))
  ((while ,test ,[stmt])
   `(while ,test ,stmt))
  ((kernel ,dims (((,x ,tx) (,[Expr -> e*] ,te) ,dim) ...)
     (free-vars . ,fv*) ,[stmt])
   `(kernel ,dims (((,x ,tx) (,e* ,te) ,dim) ...)
      (free-vars . ,fv*)
      ,stmt))
  ((do ,[Expr -> expr]) `(do ,expr))
  ((set! ,[Expr -> e1] ,[Expr -> e2]) `(set! ,e1 ,e2)))

(define-match Expr
  ((,t ,n) (guard (scalar-type? t)) `(,t ,n))
  ((var ,type ,x) `(var ,type ,x))
  ((c-expr ,type ,x) `(c-expr ,type ,x))
  ((if ,[test] ,[conseq] ,[alt])
   `(if ,test ,conseq ,alt))
  ((cast ,t ,[expr])
   `(cast ,t ,expr))
  ((sizeof ,t)
   `(sizeof ,t))
  ((addressof ,[expr])
   `(addressof ,expr))
  ((let ((,x* ,t* ,[e*]) ...) ,[expr t])
   `(begin
      ,@(map (lambda (x t e) `(let ,x ,t ,e)) x* t* e*)
      ,expr))
  ((vector-ref ,type ,[e1] ,[e2])
   `(vector-ref ,type ,e1 ,e2))
  ((length ,n)
   `(length ,n))
  ((,op ,[e1] ,[e2]) (guard (binop? op))
   `(,op ,e1 ,e2))
  ((,op ,[e1] ,[e2]) (guard (relop? op))
   `(,op ,e1 ,e2))
  ((call ,[expr] ,[expr*] ...)
   `(call ,expr . ,expr*)))

;; end library

)