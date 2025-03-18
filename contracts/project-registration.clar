;; Project Registration Contract
;; Records details of conservation initiatives

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROJECT-EXISTS (err u101))
(define-constant ERR-PROJECT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

;; Project status constants
(define-constant STATUS-PROPOSED u1)
(define-constant STATUS-ACTIVE u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-SUSPENDED u4)

;; Data structures
(define-map projects
  { project-id: uint }
  {
    name: (string-utf8 50),
    location: (string-utf8 50),
    target-species: (string-utf8 50),
    status: uint,
    start-date: uint,
    end-date: uint,
    coordinator: principal,
    registration-date: uint
  }
)

(define-data-var next-project-id uint u1)

;; Contract administrator
(define-data-var contract-admin principal tx-sender)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-admin))
)

;; Register a new conservation project
(define-public (register-project
    (name (string-utf8 50))
    (location (string-utf8 50))
    (target-species (string-utf8 50))
    (start-date uint)
    (end-date uint)
  )
  (let
    (
      (project-id (var-get next-project-id))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? projects { project-id: project-id })) ERR-PROJECT-EXISTS)

    (map-set projects
      { project-id: project-id }
      {
        name: name,
        location: location,
        target-species: target-species,
        status: STATUS-PROPOSED,
        start-date: start-date,
        end-date: end-date,
        coordinator: tx-sender,
        registration-date: block-height
      }
    )

    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Update project status
(define-public (update-project-status (project-id uint) (new-status uint))
  (let
    (
      (project (map-get? projects { project-id: project-id }))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-some project) ERR-PROJECT-NOT-FOUND)
    (asserts! (or
      (is-eq new-status STATUS-PROPOSED)
      (is-eq new-status STATUS-ACTIVE)
      (is-eq new-status STATUS-COMPLETED)
      (is-eq new-status STATUS-SUSPENDED)
    ) ERR-INVALID-STATUS)

    (map-set projects
      { project-id: project-id }
      (merge (unwrap-panic project) { status: new-status })
    )

    (ok true)
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (ok (map-get? projects { project-id: project-id }))
)

;; Get total number of projects
(define-read-only (get-project-count)
  (ok (- (var-get next-project-id) u1))
)

;; Set contract administrator
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

