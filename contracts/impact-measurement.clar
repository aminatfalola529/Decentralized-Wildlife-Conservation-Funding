;; Impact Measurement Contract
;; Tracks effectiveness of conservation efforts

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-METRIC-EXISTS (err u101))
(define-constant ERR-METRIC-NOT-FOUND (err u102))
(define-constant ERR-INVALID-METRIC-TYPE (err u103))
(define-constant ERR-INVALID-VALUE (err u104))

;; Metric type constants
(define-constant METRIC-SPECIES-COUNT u1)
(define-constant METRIC-HABITAT-AREA u2)
(define-constant METRIC-THREAT-REDUCTION u3)
(define-constant METRIC-COMMUNITY-ENGAGEMENT u4)
(define-constant METRIC-BIODIVERSITY-INDEX u5)

;; Data structures
(define-map metrics
  { metric-id: uint }
  {
    project-id: uint,
    metric-type: uint,
    value: uint,
    measurement-date: uint,
    verifier: principal,
    notes: (string-utf8 100)
  }
)

(define-map project-metrics
  { project-id: uint, metric-type: uint }
  { count: uint, total-value: uint }
)

(define-data-var next-metric-id uint u1)

;; Contract administrator
(define-data-var contract-admin principal tx-sender)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-admin))
)

;; Record a new impact metric
(define-public (record-metric
    (project-id uint)
    (metric-type uint)
    (value uint)
    (notes (string-utf8 100))
  )
  (let
    (
      (metric-id (var-get next-metric-id))
      (project-metric (default-to { count: u0, total-value: u0 }
                      (map-get? project-metrics { project-id: project-id, metric-type: metric-type })))
    )
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (or
      (is-eq metric-type METRIC-SPECIES-COUNT)
      (is-eq metric-type METRIC-HABITAT-AREA)
      (is-eq metric-type METRIC-THREAT-REDUCTION)
      (is-eq metric-type METRIC-COMMUNITY-ENGAGEMENT)
      (is-eq metric-type METRIC-BIODIVERSITY-INDEX)
    ) ERR-INVALID-METRIC-TYPE)

    ;; Record the metric
    (map-set metrics
      { metric-id: metric-id }
      {
        project-id: project-id,
        metric-type: metric-type,
        value: value,
        measurement-date: block-height,
        verifier: tx-sender,
        notes: notes
      }
    )

    ;; Update project metrics summary
    (map-set project-metrics
      { project-id: project-id, metric-type: metric-type }
      {
        count: (+ (get count project-metric) u1),
        total-value: (+ (get total-value project-metric) value)
      }
    )

    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

;; Get metric details
(define-read-only (get-metric (metric-id uint))
  (ok (map-get? metrics { metric-id: metric-id }))
)

;; Get project metric summary
(define-read-only (get-project-metric-summary (project-id uint) (metric-type uint))
  (ok (map-get? project-metrics { project-id: project-id, metric-type: metric-type }))
)

;; Calculate average value for a project metric
(define-read-only (get-metric-average (project-id uint) (metric-type uint))
  (let
    (
      (summary (map-get? project-metrics { project-id: project-id, metric-type: metric-type }))
    )
    (if (and (is-some summary) (> (get count (unwrap-panic summary)) u0))
      (ok (/ (get total-value (unwrap-panic summary)) (get count (unwrap-panic summary))))
      (ok u0)
    )
  )
)

;; Set contract administrator
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

