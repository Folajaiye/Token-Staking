;; Token Staking Smart Contract
;; Allows users to stake tokens and earn rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-found (err u401))
(define-constant err-unauthorized (err u402))
(define-constant err-invalid-amount (err u403))
(define-constant err-insufficient-balance (err u404))
(define-constant err-no-stake (err u405))

;; Data Variables
(define-data-var total-staked uint u0)
(define-data-var reward-rate uint u100) ;; 1% per 1000 blocks
(define-data-var min-stake-amount uint u100)

;; Data Maps
(define-map stakes
  { staker: principal }
  {
    amount: uint,
    start-block: uint,
    last-claim-block: uint,
    total-rewards: uint
  }
)

(define-map token-balances
  { holder: principal }
  { balance: uint }
)

;; Public Functions

;; Mint tokens (for testing)
(define-public (mint-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)

    (let (
      (existing-balance (default-to u0 (get balance (map-get? token-balances { holder: recipient }))))
      (new-balance (+ existing-balance amount))
    )
      (map-set token-balances
        { holder: recipient }
        { balance: new-balance }
      )
    )
    (ok true)
  )
)

;; Stake tokens
(define-public (stake-tokens (amount uint))
  (let
    (
      (user-balance (default-to u0 (get balance (map-get? token-balances { holder: tx-sender }))))
      (existing-stake (map-get? stakes { staker: tx-sender }))
    )
    (asserts! (>= amount (var-get min-stake-amount)) err-invalid-amount)
    (asserts! (>= user-balance amount) err-insufficient-balance)

    ;; Update token balance
    (map-set token-balances
      { holder: tx-sender }
      { balance: (- user-balance amount) }
    )

    ;; Update stake
    (match existing-stake
      stake (map-set stakes
        { staker: tx-sender }
        {
          amount: (+ (get amount stake) amount),
          start-block: (get start-block stake),
          last-claim-block: stacks-block-height,
          total-rewards: (get total-rewards stake)
        }
      )
      (map-set stakes
        { staker: tx-sender }
        {
          amount: amount,
          start-block: stacks-block-height,
          last-claim-block: stacks-block-height,
          total-rewards: u0
        }
      )
    )

    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

;; Unstake tokens
(define-public (unstake-tokens (amount uint))
  (let
    (
      (stake (unwrap! (map-get? stakes { staker: tx-sender }) err-no-stake))
      (user-balance (default-to u0 (get balance (map-get? token-balances { holder: tx-sender }))))
    )
    (asserts! (>= (get amount stake) amount) err-insufficient-balance)

    ;; Claim rewards first
    (try! (claim-rewards))

    ;; Update stake
    (if (is-eq (get amount stake) amount)
      (map-delete stakes { staker: tx-sender })
      (map-set stakes
        { staker: tx-sender }
        (merge stake { amount: (- (get amount stake) amount) })
      )
    )

    ;; Update token balance
    (map-set token-balances
      { holder: tx-sender }
      { balance: (+ user-balance amount) }
    )

    ;; Update total staked
    (var-set total-staked (- (var-get total-staked) amount))
    (ok true)
  )
)

;; Claim staking rewards
(define-public (claim-rewards)
  (let
    (
      (stake (unwrap! (map-get? stakes { staker: tx-sender }) err-no-stake))
      (blocks-staked (- stacks-block-height (get last-claim-block stake)))
      (reward-amount (/ (* (get amount stake) blocks-staked (var-get reward-rate)) u100000))
      (user-balance (default-to u0 (get balance (map-get? token-balances { holder: tx-sender }))))
    )
    (asserts! (> reward-amount u0) err-invalid-amount)

    ;; Update stake
    (map-set stakes
      { staker: tx-sender }
      (merge stake {
        last-claim-block: stacks-block-height,
        total-rewards: (+ (get total-rewards stake) reward-amount)
      })
    )

    ;; Update token balance
    (map-set token-balances
      { holder: tx-sender }
      { balance: (+ user-balance reward-amount) }
    )

    (ok reward-amount)
  )
)

;; Read-only functions

(define-read-only (get-stake (staker principal))
  (map-get? stakes { staker: staker })
)

(define-read-only (get-token-balance (holder principal))
  (default-to u0 (get balance (map-get? token-balances { holder: holder })))
)

(define-read-only (calculate-pending-rewards (staker principal))
  (match (map-get? stakes { staker: staker })
    stake (let
      (
        (blocks-staked (- stacks-block-height (get last-claim-block stake)))
        (reward-amount (/ (* (get amount stake) blocks-staked (var-get reward-rate)) u100000))
      )
      (ok reward-amount)
    )
    (ok u0)
  )
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)
