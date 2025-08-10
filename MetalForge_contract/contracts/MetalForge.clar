
;; title: MetalForge
;; version: 1.0.0
;; summary: Synthetic Assets for Precious Metals
;; description: Create synthetic exposure to traditional precious metals (silver, platinum, palladium)

;; traits
;;

;; token definitions
(define-fungible-token synthetic-silver)
(define-fungible-token synthetic-platinum)
(define-fungible-token synthetic-palladium)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-METAL (err u104))
(define-constant ERR-PRICE-TOO-OLD (err u105))
(define-constant ERR-COLLATERAL-INSUFFICIENT (err u106))

;; Collateral ratio: 150% (1.5x collateralization)
(define-constant COLLATERAL-RATIO u150)
(define-constant PRICE-VALIDITY-WINDOW u144) ;; blocks (~24 hours)

;; Metal identifiers
(define-constant SILVER u1)
(define-constant PLATINUM u2)
(define-constant PALLADIUM u3)

;; data vars
(define-data-var contract-owner principal CONTRACT-OWNER)

;; Oracle prices (in micro-STX per ounce)
(define-data-var silver-price uint u30000000) ;; $30 * 1M micro-STX
(define-data-var platinum-price uint u1000000000) ;; $1000 * 1M micro-STX
(define-data-var palladium-price uint u2000000000) ;; $2000 * 1M micro-STX

;; Price update timestamps
(define-data-var silver-price-updated uint block-height)
(define-data-var platinum-price-updated uint block-height)
(define-data-var palladium-price-updated uint block-height)

;; Authorized oracle addresses
(define-data-var oracle-address principal CONTRACT-OWNER)

;; data maps
;; Track collateral deposited by users for each metal
(define-map user-collateral { user: principal, metal: uint } uint)

;; Track total synthetic tokens minted for each metal
(define-map total-synthetic uint uint)

;; public functions

;; Admin function to set oracle address
(define-public (set-oracle-address (new-oracle principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (var-set oracle-address new-oracle)
        (ok true)
    )
)

;; Oracle function to update metal prices
(define-public (update-price (metal uint) (new-price uint))
    (begin
        (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq metal SILVER) (is-eq metal PLATINUM) (is-eq metal PALLADIUM)) ERR-INVALID-METAL)
        (asserts! (> new-price u0) ERR-INVALID-AMOUNT)
        
        (if (is-eq metal SILVER)
            (begin
                (var-set silver-price new-price)
                (var-set silver-price-updated block-height)
            )
            (if (is-eq metal PLATINUM)
                (begin
                    (var-set platinum-price new-price)
                    (var-set platinum-price-updated block-height)
                )
                (begin
                    (var-set palladium-price new-price)
                    (var-set palladium-price-updated block-height)
                )
            )
        )
        (ok true)
    )
)

;; Mint synthetic metal tokens by depositing STX collateral
(define-public (mint-synthetic (metal uint) (amount uint))
    (let (
        (collateral-needed (calculate-collateral-needed metal amount))
        (current-collateral (default-to u0 (map-get? user-collateral { user: tx-sender, metal: metal })))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (or (is-eq metal SILVER) (is-eq metal PLATINUM) (is-eq metal PALLADIUM)) ERR-INVALID-METAL)
        (asserts! (is-price-valid metal) ERR-PRICE-TOO-OLD)
        (asserts! (>= (stx-get-balance tx-sender) collateral-needed) ERR-COLLATERAL-INSUFFICIENT)
        
        ;; Transfer STX collateral to contract
        (try! (stx-transfer? collateral-needed tx-sender (as-contract tx-sender)))
        
        ;; Update user's collateral
        (map-set user-collateral 
            { user: tx-sender, metal: metal } 
            (+ current-collateral collateral-needed)
        )
        
        ;; Mint synthetic tokens based on metal type
        (if (is-eq metal SILVER)
            (try! (ft-mint? synthetic-silver amount tx-sender))
            (if (is-eq metal PLATINUM)
                (try! (ft-mint? synthetic-platinum amount tx-sender))
                (try! (ft-mint? synthetic-palladium amount tx-sender))
            )
        )
        
        ;; Update total synthetic tokens
        (map-set total-synthetic metal (+ (default-to u0 (map-get? total-synthetic metal)) amount))
        
        (ok amount)
    )
)

;; Burn synthetic tokens and withdraw collateral
(define-public (burn-synthetic (metal uint) (amount uint))
    (let (
        (current-collateral (default-to u0 (map-get? user-collateral { user: tx-sender, metal: metal })))
        (collateral-to-return (calculate-collateral-needed metal amount))
        (user-balance (get-user-balance tx-sender metal))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (or (is-eq metal SILVER) (is-eq metal PLATINUM) (is-eq metal PALLADIUM)) ERR-INVALID-METAL)
        (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (>= current-collateral collateral-to-return) ERR-COLLATERAL-INSUFFICIENT)
        
        ;; Burn synthetic tokens
        (if (is-eq metal SILVER)
            (try! (ft-burn? synthetic-silver amount tx-sender))
            (if (is-eq metal PLATINUM)
                (try! (ft-burn? synthetic-platinum amount tx-sender))
                (try! (ft-burn? synthetic-palladium amount tx-sender))
            )
        )
        
        ;; Update user's collateral
        (map-set user-collateral 
            { user: tx-sender, metal: metal } 
            (- current-collateral collateral-to-return)
        )
        
        ;; Return STX collateral
        (try! (as-contract (stx-transfer? collateral-to-return tx-sender tx-sender)))
        
        ;; Update total synthetic tokens
        (map-set total-synthetic metal (- (default-to u0 (map-get? total-synthetic metal)) amount))
        
        (ok collateral-to-return)
    )
)

;; Transfer synthetic tokens
(define-public (transfer-synthetic (metal uint) (amount uint) (recipient principal))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (or (is-eq metal SILVER) (is-eq metal PLATINUM) (is-eq metal PALLADIUM)) ERR-INVALID-METAL)
        
        (if (is-eq metal SILVER)
            (try! (ft-transfer? synthetic-silver amount tx-sender recipient))
            (if (is-eq metal PLATINUM)
                (try! (ft-transfer? synthetic-platinum amount tx-sender recipient))
                (try! (ft-transfer? synthetic-palladium amount tx-sender recipient))
            )
        )
        
        (ok true)
    )
)

;; read only functions

;; Get current price for a metal
(define-read-only (get-price (metal uint))
    (if (is-eq metal SILVER)
        (var-get silver-price)
        (if (is-eq metal PLATINUM)
            (var-get platinum-price)
            (var-get palladium-price)
        )
    )
)

;; Get price update timestamp for a metal
(define-read-only (get-price-updated (metal uint))
    (if (is-eq metal SILVER)
        (var-get silver-price-updated)
        (if (is-eq metal PLATINUM)
            (var-get platinum-price-updated)
            (var-get palladium-price-updated)
        )
    )
)

;; Check if price is valid (not too old)
(define-read-only (is-price-valid (metal uint))
    (<= (- block-height (get-price-updated metal)) PRICE-VALIDITY-WINDOW)
)

;; Calculate collateral needed for minting amount of synthetic tokens
(define-read-only (calculate-collateral-needed (metal uint) (amount uint))
    (/ (* (get-price metal) amount COLLATERAL-RATIO) u100)
)

;; Get user's synthetic token balance
(define-read-only (get-user-balance (user principal) (metal uint))
    (if (is-eq metal SILVER)
        (ft-get-balance synthetic-silver user)
        (if (is-eq metal PLATINUM)
            (ft-get-balance synthetic-platinum user)
            (ft-get-balance synthetic-palladium user)
        )
    )
)

;; Get user's collateral for a specific metal
(define-read-only (get-user-collateral (user principal) (metal uint))
    (default-to u0 (map-get? user-collateral { user: user, metal: metal }))
)

;; Get total supply of synthetic tokens for a metal
(define-read-only (get-total-supply (metal uint))
    (if (is-eq metal SILVER)
        (ft-get-supply synthetic-silver)
        (if (is-eq metal PLATINUM)
            (ft-get-supply synthetic-platinum)
            (ft-get-supply synthetic-palladium)
        )
    )
)

;; Get contract owner
(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

;; Get oracle address
(define-read-only (get-oracle-address)
    (var-get oracle-address)
)

;; Get metal name by ID
(define-read-only (get-metal-name (metal uint))
    (if (is-eq metal SILVER)
        "SILVER"
        (if (is-eq metal PLATINUM)
            "PLATINUM"
            "PALLADIUM"
        )
    )
)

;; private functions

;; Initialize contract (called once during deployment)
(define-private (initialize)
    (begin
        ;; Set initial prices and timestamps
        (var-set silver-price-updated block-height)
        (var-set platinum-price-updated block-height)
        (var-set palladium-price-updated block-height)
        true
    )
)

;; Call initialize on deployment
(initialize)
