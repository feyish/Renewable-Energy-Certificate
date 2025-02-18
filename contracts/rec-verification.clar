;; REC Verification Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Maps
(define-map verifiers principal bool)

;; Public Functions

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set verifiers verifier true)
    (ok true)
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete verifiers verifier)
    (ok true)
  )
)

;; Verify a REC
(define-public (verify-rec (rec-id uint))
  (let
    (
      (rec (unwrap! (contract-call? .rec-issuance get-rec rec-id) err-not-found))
    )
    (asserts! (default-to false (map-get? verifiers tx-sender)) err-unauthorized)
    (asserts! (is-eq (get status rec) "active") err-unauthorized)
    (try! (contract-call? .rec-issuance update-rec-status rec-id "verified"))
    (ok true)
  )
)

;; Read-only function to check if an address is a verifier
(define-read-only (is-verifier (address principal))
  (default-to false (map-get? verifiers address))
)

;; Initialize contract
(begin
  (map-set verifiers contract-owner true)
)

