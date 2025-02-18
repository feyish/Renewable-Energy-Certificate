;; REC Trading Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var trade-nonce uint u0)

;; Data Maps
(define-map trades
  { trade-id: uint }
  {
    seller: principal,
    buyer: principal,
    rec-id: uint,
    price: uint,
    status: (string-ascii 10)
  }
)

;; Public Functions

;; Create a new trade offer
(define-public (create-trade-offer (rec-id uint) (price uint))
  (let
    (
      (trade-id (var-get trade-nonce))
      (rec (unwrap! (contract-call? .rec-issuance get-rec rec-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get issuer rec)) err-unauthorized)
    (asserts! (is-eq (get status rec) "active") err-unauthorized)
    (map-set trades
      { trade-id: trade-id }
      {
        seller: tx-sender,
        buyer: tx-sender,
        rec-id: rec-id,
        price: price,
        status: "open"
      }
    )
    (var-set trade-nonce (+ trade-id u1))
    (ok trade-id)
  )
)

;; Accept a trade offer
(define-public (accept-trade (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? trades { trade-id: trade-id }) err-not-found))
    )
    (asserts! (is-eq (get status trade) "open") err-unauthorized)
    (try! (stx-transfer? (get price trade) tx-sender (get seller trade)))
    (try! (contract-call? .rec-issuance update-rec-status (get rec-id trade) "traded"))
    (map-set trades
      { trade-id: trade-id }
      (merge trade { buyer: tx-sender, status: "completed" })
    )
    (ok true)
  )
)

;; Cancel a trade offer
(define-public (cancel-trade (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? trades { trade-id: trade-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get seller trade)) err-unauthorized)
    (asserts! (is-eq (get status trade) "open") err-unauthorized)
    (map-set trades
      { trade-id: trade-id }
      (merge trade { status: "cancelled" })
    )
    (ok true)
  )
)

;; Read-only function to get trade details
(define-read-only (get-trade (trade-id uint))
  (ok (unwrap! (map-get? trades { trade-id: trade-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set trade-nonce u0)
)

