;; REC Issuance Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Variables
(define-data-var rec-nonce uint u0)

;; Data Maps
(define-map recs
  { rec-id: uint }
  {
    issuer: principal,
    energy-amount: uint,
    generation-date: uint,
    expiration-date: uint,
    facility-id: (string-ascii 20),
    status: (string-ascii 10)
  }
)

;; Public Functions

;; Issue a new REC
(define-public (issue-rec (energy-amount uint) (generation-date uint) (expiration-date uint) (facility-id (string-ascii 20)))
  (let
    (
      (rec-id (var-get rec-nonce))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set recs
      { rec-id: rec-id }
      {
        issuer: tx-sender,
        energy-amount: energy-amount,
        generation-date: generation-date,
        expiration-date: expiration-date,
        facility-id: facility-id,
        status: "active"
      }
    )
    (var-set rec-nonce (+ rec-id u1))
    (ok rec-id)
  )
)

;; Update REC status
(define-public (update-rec-status (rec-id uint) (new-status (string-ascii 10)))
  (let
    (
      (rec (unwrap! (map-get? recs { rec-id: rec-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set recs
      { rec-id: rec-id }
      (merge rec { status: new-status })
    )
    (ok true)
  )
)

;; Read-only function to get REC details
(define-read-only (get-rec (rec-id uint))
  (ok (unwrap! (map-get? recs { rec-id: rec-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set rec-nonce u0)
)

