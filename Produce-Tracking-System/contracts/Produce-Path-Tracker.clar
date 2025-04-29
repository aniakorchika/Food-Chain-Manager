;; Agricultural Supply Chain Tracking Contract
;; This smart contract enables comprehensive agricultural supply chain management
;; with features for product registration, ownership tracking, quality verification,
;; location tracking, and complete transaction history across the supply chain.

;; Constants
(define-constant contract-admin tx-sender)
(define-constant ERR-UNAUTHORIZED-ACCESS (err u1))
(define-constant ERR-PRODUCT-NOT-FOUND (err u2))
(define-constant ERR-INVALID-STATUS-TRANSITION (err u3))
(define-constant ERR-DUPLICATE-RECORD (err u4))
(define-constant ERR-INVALID-INPUT-DATA (err u5))

;; Configuration Variables
(define-data-var minimum-quality-threshold uint u60)

;; Participant Management
(define-map participant-directory
    principal
    {
        participant-role: (string-ascii 20),
        participant-is-active: bool,
        participant-reputation: uint
    }
)

;; Product Inventory
(define-map agricultural-products
    uint  ;; product-identifier
    {
        product-name: (string-ascii 50),
        producer-principal: principal,
        current-custodian: principal,
        supply-chain-stage: (string-ascii 20),
        product-quality-rating: uint,
        registration-timestamp: uint,
        geographic-location: (string-ascii 100),
        market-value: uint,
        quality-certification-status: bool
    }
)

;; Supply Chain History
(define-map supply-chain-events
    {product-identifier: uint, event-identifier: uint}
    {
        event-source: principal,
        event-destination: principal,
        event-type: (string-ascii 20),
        event-timestamp: uint,
        event-description: (string-ascii 200)
    }
)

;; Event Sequence Counter
(define-data-var event-counter uint u0)

;; Query Functions
(define-read-only (get-product-information (product-identifier uint))
    (map-get? agricultural-products product-identifier)
)

(define-read-only (get-participant-details (participant-address principal))
    (map-get? participant-directory participant-address)
)

(define-read-only (get-supply-chain-event (product-identifier uint) (event-identifier uint))
    (map-get? supply-chain-events {product-identifier: product-identifier, event-identifier: event-identifier})
)

;; Helper Functions
(define-private (is-active-participant (participant-address principal))
    (let ((participant-record (unwrap! (map-get? participant-directory participant-address) false)))
        (get participant-is-active participant-record)
    )
)

(define-private (generate-event-identifier)
    (begin
        (var-set event-counter (+ (var-get event-counter) u1))
        (var-get event-counter)
    )
)

;; Validation Functions
(define-private (validate-short-text (input-text (string-ascii 20)))
    (and (>= (len input-text) u1) (<= (len input-text) u20))
)

(define-private (validate-medium-text (input-text (string-ascii 50)))
    (and (>= (len input-text) u1) (<= (len input-text) u50))
)

(define-private (validate-location-text (input-text (string-ascii 100)))
    (and (>= (len input-text) u1) (<= (len input-text) u100))
)

(define-private (validate-description-text (input-text (string-ascii 200)))
    (and (>= (len input-text) u1) (<= (len input-text) u200))
)

(define-private (validate-uint-value (input-value uint))
    (< input-value u340282366920938463463374607431768211455)  ;; Max uint value
)

;; Administrative Functions
(define-public (register-participant (participant-address principal) (participant-role (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-admin) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-none (map-get? participant-directory participant-address)) ERR-DUPLICATE-RECORD)
        (asserts! (validate-short-text participant-role) ERR-INVALID-INPUT-DATA)
        (ok (map-set participant-directory 
            participant-address
            {
                participant-role: participant-role,
                participant-is-active: true,
                participant-reputation: u100
            }
        ))
    )
)

(define-public (update-participant-status (participant-address principal) (active-status bool))
    (begin
        (asserts! (is-eq tx-sender contract-admin) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-some (map-get? participant-directory participant-address)) ERR-UNAUTHORIZED-ACCESS)
        (ok (map-set participant-directory 
            participant-address
            (merge (unwrap-panic (map-get? participant-directory participant-address))
                  {participant-is-active: active-status})
        ))
    )
)

;; Product Operations
(define-public (register-new-product 
    (product-identifier uint)
    (product-name (string-ascii 50))
    (geographic-location (string-ascii 100))
    (initial-price uint))
    (let ((submitting-participant tx-sender))
        (begin
            (asserts! (is-active-participant submitting-participant) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-none (map-get? agricultural-products product-identifier)) ERR-DUPLICATE-RECORD)
            (asserts! (validate-uint-value product-identifier) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-medium-text product-name) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-location-text geographic-location) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-uint-value initial-price) ERR-INVALID-INPUT-DATA)
            (ok (map-set agricultural-products
                product-identifier
                {
                    product-name: product-name,
                    producer-principal: submitting-participant,
                    current-custodian: submitting-participant,
                    supply-chain-stage: "registered",
                    product-quality-rating: u100,
                    registration-timestamp: block-height,
                    geographic-location: geographic-location,
                    market-value: initial-price,
                    quality-certification-status: false
                }
            ))
        )
    )
)

(define-public (update-supply-chain-stage 
    (product-identifier uint)
    (new-stage (string-ascii 20))
    (stage-details (string-ascii 200)))
    (let (
        (authorized-participant tx-sender)
        (product-record (unwrap! (map-get? agricultural-products product-identifier) ERR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-active-participant authorized-participant) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-record) authorized-participant) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (validate-uint-value product-identifier) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-short-text new-stage) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-description-text stage-details) ERR-INVALID-INPUT-DATA)
            (map-set agricultural-products
                product-identifier
                (merge product-record {supply-chain-stage: new-stage})
            )
            (map-set supply-chain-events
                {product-identifier: product-identifier, event-identifier: (generate-event-identifier)}
                {
                    event-source: authorized-participant,
                    event-destination: authorized-participant,
                    event-type: new-stage,
                    event-timestamp: block-height,
                    event-description: stage-details
                }
            )
            (ok true)
        )
    )
)

(define-public (transfer-product-ownership
    (product-identifier uint)
    (new-custodian principal)
    (transfer-notes (string-ascii 200)))
    (let (
        (current-custodian tx-sender)
        (product-record (unwrap! (map-get? agricultural-products product-identifier) ERR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-active-participant current-custodian) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-active-participant new-custodian) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-record) current-custodian) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (validate-uint-value product-identifier) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-description-text transfer-notes) ERR-INVALID-INPUT-DATA)
            (map-set agricultural-products
                product-identifier
                (merge product-record {
                    current-custodian: new-custodian,
                    supply-chain-stage: "transferred"
                })
            )
            (map-set supply-chain-events
                {product-identifier: product-identifier, event-identifier: (generate-event-identifier)}
                {
                    event-source: current-custodian,
                    event-destination: new-custodian,
                    event-type: "transfer",
                    event-timestamp: block-height,
                    event-description: transfer-notes
                }
            )
            (ok true)
        )
    )
)

(define-public (update-quality-assessment
    (product-identifier uint)
    (quality-score uint)
    (assessment-details (string-ascii 200)))
    (let (
        (quality-assessor tx-sender)
        (product-record (unwrap! (map-get? agricultural-products product-identifier) ERR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-active-participant quality-assessor) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (validate-uint-value product-identifier) ERR-INVALID-INPUT-DATA)
            (asserts! (<= quality-score u100) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-description-text assessment-details) ERR-INVALID-INPUT-DATA)
            (map-set agricultural-products
                product-identifier
                (merge product-record {
                    product-quality-rating: quality-score,
                    quality-certification-status: (>= quality-score (var-get minimum-quality-threshold))
                })
            )
            (map-set supply-chain-events
                {product-identifier: product-identifier, event-identifier: (generate-event-identifier)}
                {
                    event-source: quality-assessor,
                    event-destination: quality-assessor,
                    event-type: "quality-assessment",
                    event-timestamp: block-height,
                    event-description: assessment-details
                }
            )
            (ok true)
        )
    )
)

(define-public (update-product-location
    (product-identifier uint)
    (new-location (string-ascii 100))
    (location-details (string-ascii 200)))
    (let (
        (authorized-participant tx-sender)
        (product-record (unwrap! (map-get? agricultural-products product-identifier) ERR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-active-participant authorized-participant) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-record) authorized-participant) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (validate-uint-value product-identifier) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-location-text new-location) ERR-INVALID-INPUT-DATA)
            (asserts! (validate-description-text location-details) ERR-INVALID-INPUT-DATA)
            (map-set agricultural-products
                product-identifier
                (merge product-record {geographic-location: new-location})
            )
            (map-set supply-chain-events
                {product-identifier: product-identifier, event-identifier: (generate-event-identifier)}
                {
                    event-source: authorized-participant,
                    event-destination: authorized-participant,
                    event-type: "location-update",
                    event-timestamp: block-height,
                    event-description: location-details
                }
            )
            (ok true)
        )
    )
)