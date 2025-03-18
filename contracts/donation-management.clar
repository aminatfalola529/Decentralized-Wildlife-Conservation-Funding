;; Donation Management Contract
;; Handles contributions to specific projects

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DONATION-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u102))
(define-constant ERR-ALREADY-PROCESSED (err u103))
(define-constant ERR-INVALID-STATUS (err u104))
(define-constant ERR-NOT-PROJECT-OWNER (err u105))

;; Donation status constants
(define-constant STATUS-PENDING u1)
(define-constant STATUS-CONFIRMED u2)
(define-constant STATUS-ALLOCATED u3)
(define-constant STATUS-REFUNDED u4)

;; Data structures
(define-map donations
  { donation-id: uint }
  {
    project-id: uint,
    donor: principal,
    amount: uint,
    donation-date: uint,
    status: uint,
    notes: (string-utf8 100)
  }
)

(define-map project-donations
  { project-id: uint }
  { total-amount: uint, donor-count: uint }
)

(define-map donor-donations
  { donor: principal }
  { total-amount: uint, donation-count: uint }
)

(define-data-var next-donation-id uint u1)

;; Contract administrator
(define-data-var contract-admin principal tx-sender)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-admin))
)

;; Make a donation to a project
(define-public (make-donation
    (project-id uint)
    (amount uint)
    (notes (string-utf8 100))
  )
  (let
    (
      (donation-id (var-get next-donation-id))
      (project-donation (default-to { total-amount: u0, donor-count: u0 }
                        (map-get? project-donations { project-id: project-id })))
      (donor-donation (default-to { total-amount: u0, donation-count: u0 }
                      (map-get? donor-donations { donor: tx-sender })))
    )
    ;; Record the donation
    (map-set donations
      { donation-id: donation-id }
      {
        project-id: project-id,
        donor: tx-sender,
        amount: amount,
        donation-date: block-height,
        status: STATUS-CONFIRMED,
        notes: notes
      }
    )

    ;; Update project donation summary
    (map-set project-donations
      { project-id: project-id }
      {
        total-amount: (+ (get total-amount project-donation) amount),
        donor-count: (+ (get donor-count project-donation) u1)
      }
    )

    ;; Update donor donation summary
    (map-set donor-donations
      { donor: tx-sender }
      {
        total-amount: (+ (get total-amount donor-donation) amount),
        donation-count: (+ (get donation-count donor-donation) u1)
      }
    )

    (var-set next-donation-id (+ donation-id u1))
    (ok donation-id)
  )
)

;; Update donation status
(define-public (update-donation-status (donation-id uint) (new-status uint))
  (let
    (
      (donation (map-get? donations { donation-id: donation-id }))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-some donation) ERR-DONATION-NOT-FOUND)
    (asserts! (or
      (is-eq new-status STATUS-PENDING)
      (is-eq new-status STATUS-CONFIRMED)
      (is-eq new-status STATUS-ALLOCATED)
      (is-eq new-status STATUS-REFUNDED)
    ) ERR-INVALID-STATUS)

    (map-set donations
      { donation-id: donation-id }
      (merge (unwrap-panic donation) { status: new-status })
    )

    (ok true)
  )
)

;; Get donation details
(define-read-only (get-donation (donation-id uint))
  (ok (map-get? donations { donation-id: donation-id }))
)

;; Get project donation summary
(define-read-only (get-project-donation-summary (project-id uint))
  (ok (map-get? project-donations { project-id: project-id }))
)

;; Get donor donation summary
(define-read-only (get-donor-donation-summary (donor principal))
  (ok (map-get? donor-donations { donor: donor }))
)

;; Set contract administrator
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

