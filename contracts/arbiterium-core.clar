;; ============================================================
;; Contract: arbiterium-core.clar
;; Purpose : Universal arbitration layer for Web3 contracts
;; ============================================================

;; -------------------------
;; ERRORS
;; -------------------------
(define-constant ERR-NOT-ARBITRATOR     (err u13001))
(define-constant ERR-CASE-NOT-FOUND     (err u13002))
(define-constant ERR-ALREADY-VOTED      (err u13003))
(define-constant ERR-CASE-CLOSED        (err u13004))
(define-constant ERR-NOT-OPEN           (err u13005))

;; -------------------------
;; STATE
;; -------------------------

(define-data-var contract-owner (optional principal) none)
(define-data-var case-counter uint u0)

;; -------------------------
;; INITIALIZATION
;; -------------------------

(define-public (init-owner)
  (begin
    (var-set contract-owner (some tx-sender))
    (ok true)
  )
)
(define-map arbitrators
  { arbitrator: principal }
  { active: bool }
)

;; case-id => case data
(define-map cases
  { id: uint }
  {
    opener: principal,
    subject: principal, ;; contract under dispute
    open: bool,
    votes-yes: uint,
    votes-no: uint
  }
)

;; case-id + arbitrator => voted?
(define-map votes
  { id: uint, arbitrator: principal }
  { voted: bool }
)

;; -------------------------
;; ARBITRATOR MANAGEMENT
;; -------------------------

(define-public (add-arbitrator (arbitrator principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap-panic (var-get contract-owner))) ERR-NOT-ARBITRATOR)
    (map-set arbitrators { arbitrator: arbitrator } { active: true })
    (ok true)
  )
)

(define-public (remove-arbitrator (arbitrator principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap-panic (var-get contract-owner))) ERR-NOT-ARBITRATOR)
    (map-delete arbitrators { arbitrator: arbitrator })
    (ok true)
  )
)

;; -------------------------
;; OPEN CASE
;; -------------------------

(define-public (open-case (subject principal))
  (let ((id (+ (var-get case-counter) u1)))
    (begin
      (asserts! (not (is-eq subject tx-sender)) (err u13100))
      (var-set case-counter id)
      (map-set cases
        { id: id }
        {
          opener: tx-sender,
          subject: subject,
          open: true,
          votes-yes: u0,
          votes-no: u0
        }
      )
      (ok id)
    )
  )
)

;; -------------------------
;; VOTE
;; -------------------------

(define-public (vote
  (id uint)
  (support bool)
)
  (let ((case (map-get? cases { id: id })))
    (begin
      (asserts! (> id u0) (err u13100))
      (asserts!
        (is-some (map-get? arbitrators { arbitrator: tx-sender }))
        ERR-NOT-ARBITRATOR
      )
      (asserts! (is-some case) ERR-CASE-NOT-FOUND)
      (asserts!
        (get open (unwrap! case ERR-CASE-NOT-FOUND))
        ERR-CASE-CLOSED
      )
      (asserts!
        (is-none (map-get? votes { id: id, arbitrator: tx-sender }))
        ERR-ALREADY-VOTED
      )

      (map-set votes
        { id: id, arbitrator: tx-sender }
        { voted: true }
      )

      (if support
        (map-set cases
          { id: id }
          (merge (unwrap! case ERR-CASE-NOT-FOUND)
            { votes-yes: (+ (get votes-yes (unwrap! case ERR-CASE-NOT-FOUND)) u1) }
          )
        )
        (map-set cases
          { id: id }
          (merge (unwrap! case ERR-CASE-NOT-FOUND)
            { votes-no: (+ (get votes-no (unwrap! case ERR-CASE-NOT-FOUND)) u1) }
          )
        )
      )

      (ok support)
    )
  )
)

;; -------------------------
;; CLOSE CASE
;; -------------------------

(define-public (close-case (id uint))
  (let ((case (map-get? cases { id: id })))
    (begin
      (asserts! (> id u0) (err u13100))
      (asserts! (is-some case) ERR-CASE-NOT-FOUND)
      (asserts!
        (get open (unwrap! case ERR-CASE-NOT-FOUND))
        ERR-NOT-OPEN
      )

      (map-set cases
        { id: id }
        (merge (unwrap! case ERR-CASE-NOT-FOUND)
          { open: false }
        )
      )

      (ok
        (>=
          (get votes-yes (unwrap! case ERR-CASE-NOT-FOUND))
          (get votes-no (unwrap! case ERR-CASE-NOT-FOUND))
        )
      )
    )
  )
)

;; -------------------------
;; READ-ONLY INTERFACE
;; -------------------------

(define-read-only (case-result (id uint))
  (map-get? cases { id: id })
)

(define-read-only (is-arbitrator (arbitrator principal))
  (is-some (map-get? arbitrators { arbitrator: arbitrator }))
)
