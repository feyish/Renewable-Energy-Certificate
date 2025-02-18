;; REC Retirement Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var retirement-nonce uint u0)

;; Data Maps
(define-map retirements
  { retirement-id: uint }
  {
    rec-id: uint,
    retiree: principal,
    retirement-date: uint,
    reason: (string-utf8 100)
  }
)

;; Public Functions

;; Retire a REC
(define-public (retire-rec (rec-id uint) (reason (string-utf8 100)))
  (let
    (
      (retirement-id (var-get retirement-nonce))
      (rec (unwrap! (contract-call? .rec-issuance get-rec rec-id) err-not-found))
    )
    (asserts! (or (is-eq tx-sender (get issuer rec)) (is-eq tx-sender contract-owner)) err-unauthorized)
    (asserts! (is-eq (get status rec) "verified") err-unauthorized)
    (try! (contract-call? .rec-issuance update-rec-status rec-id "retired"))
    (map-set retirements
      { retirement-id: retirement-id }
      {
        rec-id: rec-id,
        retiree: tx-sender,
        retirement-date: block-height,
        reason: reason
      }
    )
    (var-set retirement-nonce (+ retirement-id u1))
    (ok retirement-id)
  )
)

;; Read-only function to get retirement details
(define-read-only (get-retirement (retirement-id uint))
  (ok (unwrap! (map-get? retirements { retirement-id: retirement-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set retirement-nonce u0)
)

