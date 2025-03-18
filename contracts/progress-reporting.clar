;; Progress Reporting Contract
;; Provides transparent updates to supporters

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REPORT-EXISTS (err u101))
(define-constant ERR-REPORT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

;; Report status constants
(define-constant STATUS-PLANNED u1)
(define-constant STATUS-IN-PROGRESS u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-DELAYED u4)

;; Data structures
(define-map reports
  { report-id: uint }
  {
    project-id: uint,
    title: (string-utf8 50),
    description: (string-utf8 500),
    milestone: (string-utf8 100),
    status: uint,
    report-date: uint,
    author: principal,
    media-hash: (buff 32)
  }
)

(define-map project-reports
  { project-id: uint }
  { report-count: uint, last-report-date: uint }
)

(define-data-var next-report-id uint u1)

;; Contract administrator
(define-data-var contract-admin principal tx-sender)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-admin))
)

;; Submit a new progress report
(define-public (submit-report
    (project-id uint)
    (title (string-utf8 50))
    (description (string-utf8 500))
    (milestone (string-utf8 100))
    (status uint)
    (media-hash (buff 32))
  )
  (let
    (
      (report-id (var-get next-report-id))
      (project-report (default-to { report-count: u0, last-report-date: u0 }
                      (map-get? project-reports { project-id: project-id })))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (or
      (is-eq status STATUS-PLANNED)
      (is-eq status STATUS-IN-PROGRESS)
      (is-eq status STATUS-COMPLETED)
      (is-eq status STATUS-DELAYED)
    ) ERR-INVALID-STATUS)

    ;; Record the report
    (map-set reports
      { report-id: report-id }
      {
        project-id: project-id,
        title: title,
        description: description,
        milestone: milestone,
        status: status,
        report-date: block-height,
        author: tx-sender,
        media-hash: media-hash
      }
    )

    ;; Update project reports summary
    (map-set project-reports
      { project-id: project-id }
      {
        report-count: (+ (get report-count project-report) u1),
        last-report-date: block-height
      }
    )

    (var-set next-report-id (+ report-id u1))
    (ok report-id)
  )
)

;; Update report status
(define-public (update-report-status (report-id uint) (new-status uint))
  (let
    (
      (report (map-get? reports { report-id: report-id }))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-some report) ERR-REPORT-NOT-FOUND)
    (asserts! (or
      (is-eq new-status STATUS-PLANNED)
      (is-eq new-status STATUS-IN-PROGRESS)
      (is-eq new-status STATUS-COMPLETED)
      (is-eq new-status STATUS-DELAYED)
    ) ERR-INVALID-STATUS)

    (map-set reports
      { report-id: report-id }
      (merge (unwrap-panic report) { status: new-status })
    )

    (ok true)
  )
)

;; Get report details
(define-read-only (get-report (report-id uint))
  (ok (map-get? reports { report-id: report-id }))
)

;; Get project report summary
(define-read-only (get-project-report-summary (project-id uint))
  (ok (map-get? project-reports { project-id: project-id }))
)

;; Set contract administrator
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

