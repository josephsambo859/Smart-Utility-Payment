(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-bill-already-paid (err u106))
(define-constant err-bill-expired (err u107))
(define-constant err-invalid-provider (err u108))
(define-constant err-invalid-participant (err u109))
(define-constant err-total-share-invalid (err u110))
(define-constant err-already-paid-share (err u111))

(define-data-var next-bill-id uint u1)
(define-data-var next-provider-id uint u1)
(define-data-var platform-fee uint u50)
(define-data-var contract-paused bool false)

(define-map providers
    uint
    {
        name: (string-ascii 50),
        address: principal,
        service-type: (string-ascii 20),
        active: bool,
        total-collected: uint,
    }
)

(define-map provider-by-address
    principal
    uint
)

(define-map bills
    uint
    {
        customer: principal,
        provider-id: uint,
        amount: uint,
        due-date: uint,
        description: (string-ascii 100),
        paid: bool,
        paid-at: (optional uint),
        created-at: uint,
    }
)

(define-map customer-bills
    principal
    (list 100 uint)
)

(define-map provider-bills
    uint
    (list 200 uint)
)

(define-map customer-balances
    principal
    uint
)

(define-map payment-history
    uint
    {
        bill-id: uint,
        customer: principal,
        amount: uint,
        fee: uint,
        timestamp: uint,
    }
)

(define-map bill-participants
    uint
    (list
        10
        {
            participant: principal,
            share: uint,
            paid: bool,
            payment-id: (optional uint),
        }
    )
)

(define-map participant-bills
    principal
    (list 100 uint)
)

(define-data-var next-payment-id uint u1)

(define-read-only (get-contract-owner)
    contract-owner
)

(define-read-only (get-platform-fee)
    (var-get platform-fee)
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-provider (provider-id uint))
    (map-get? providers provider-id)
)

(define-read-only (get-provider-by-address (address principal))
    (match (map-get? provider-by-address address)
        provider-id (map-get? providers provider-id)
        none
    )
)

(define-read-only (get-bill (bill-id uint))
    (map-get? bills bill-id)
)

(define-read-only (get-customer-bills (customer principal))
    (default-to (list) (map-get? customer-bills customer))
)

(define-read-only (get-provider-bills (provider-id uint))
    (default-to (list) (map-get? provider-bills provider-id))
)

(define-read-only (get-customer-balance (customer principal))
    (default-to u0 (map-get? customer-balances customer))
)

(define-read-only (get-payment-history (payment-id uint))
    (map-get? payment-history payment-id)
)

(define-read-only (get-bill-participants (bill-id uint))
    (default-to (list) (map-get? bill-participants bill-id))
)

(define-read-only (get-participant-bills (participant principal))
    (default-to (list) (map-get? participant-bills participant))
)

(define-read-only (calculate-payment-fee (amount uint))
    (/ (* amount (var-get platform-fee)) u10000)
)

(define-read-only (get-bill-status (bill-id uint))
    (match (map-get? bills bill-id)
        bill (let ((current-block stacks-block-height))
            {
                exists: true,
                paid: (get paid bill),
                expired: (> current-block (get due-date bill)),
                amount: (get amount bill),
            }
        )
        {
            exists: false,
            paid: false,
            expired: false,
            amount: u0,
        }
    )
)

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u1000) err-invalid-amount)
        (ok (var-set platform-fee new-fee))
    )
)

(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

(define-public (register-provider
        (name (string-ascii 50))
        (service-type (string-ascii 20))
    )
    (let ((provider-id (var-get next-provider-id)))
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (is-none (map-get? provider-by-address tx-sender))
            err-already-exists
        )
        (map-set providers provider-id {
            name: name,
            address: tx-sender,
            service-type: service-type,
            active: true,
            total-collected: u0,
        })
        (map-set provider-by-address tx-sender provider-id)
        (var-set next-provider-id (+ provider-id u1))
        (ok provider-id)
    )
)

(define-public (deactivate-provider (provider-id uint))
    (let ((provider-data (unwrap! (map-get? providers provider-id) err-not-found)))
        (asserts!
            (or
                (is-eq tx-sender contract-owner)
                (is-eq tx-sender (get address provider-data))
            )
            err-unauthorized
        )
        (map-set providers provider-id (merge provider-data { active: false }))
        (ok true)
    )
)

(define-public (create-bill
        (customer principal)
        (amount uint)
        (due-date uint)
        (description (string-ascii 100))
    )
    (let (
            (bill-id (var-get next-bill-id))
            (provider-id-opt (map-get? provider-by-address tx-sender))
        )
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (> due-date stacks-block-height) err-invalid-amount)
        (let (
                (provider-id (unwrap! provider-id-opt err-unauthorized))
                (provider-data (unwrap! (map-get? providers provider-id) err-not-found))
            )
            (asserts! (get active provider-data) err-unauthorized)
            (map-set bills bill-id {
                customer: customer,
                provider-id: provider-id,
                amount: amount,
                due-date: due-date,
                description: description,
                paid: false,
                paid-at: none,
                created-at: stacks-block-height,
            })
            (map-set customer-bills customer
                (unwrap!
                    (as-max-len? (append (get-customer-bills customer) bill-id)
                        u100
                    )
                    err-invalid-amount
                ))
            (map-set provider-bills provider-id
                (unwrap!
                    (as-max-len?
                        (append (get-provider-bills provider-id) bill-id)
                        u200
                    )
                    err-invalid-amount
                ))
            (var-set next-bill-id (+ bill-id u1))
            (ok bill-id)
        )
    )
)

(define-public (deposit-funds (amount uint))
    (let ((current-balance (get-customer-balance tx-sender)))
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set customer-balances tx-sender (+ current-balance amount))
        (ok true)
    )
)

(define-public (withdraw-funds (amount uint))
    (let ((current-balance (get-customer-balance tx-sender)))
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (>= current-balance amount) err-insufficient-funds)
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-set customer-balances tx-sender (- current-balance amount))
        (ok true)
    )
)

(define-public (pay-bill (bill-id uint))
    (let (
            (bill-data (unwrap! (map-get? bills bill-id) err-not-found))
            (customer-balance (get-customer-balance tx-sender))
            (payment-fee (calculate-payment-fee (get amount bill-data)))
            (total-cost (+ (get amount bill-data) payment-fee))
            (payment-id (var-get next-payment-id))
        )
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (is-eq tx-sender (get customer bill-data)) err-unauthorized)
        (asserts! (not (get paid bill-data)) err-bill-already-paid)
        (asserts! (<= stacks-block-height (get due-date bill-data))
            err-bill-expired
        )
        (asserts! (>= customer-balance total-cost) err-insufficient-funds)

        (let ((provider-data (unwrap! (map-get? providers (get provider-id bill-data))
                err-invalid-provider
            )))
            (map-set customer-balances tx-sender (- customer-balance total-cost))
            (try! (as-contract (stx-transfer? (get amount bill-data) tx-sender
                (get address provider-data)
            )))
            (if (> payment-fee u0)
                (try! (as-contract (stx-transfer? payment-fee tx-sender contract-owner)))
                true
            )

            (map-set bills bill-id
                (merge bill-data {
                    paid: true,
                    paid-at: (some stacks-block-height),
                })
            )

            (map-set providers (get provider-id bill-data)
                (merge provider-data { total-collected: (+ (get total-collected provider-data) (get amount bill-data)) })
            )

            (map-set payment-history payment-id {
                bill-id: bill-id,
                customer: tx-sender,
                amount: (get amount bill-data),
                fee: payment-fee,
                timestamp: stacks-block-height,
            })
            (var-set next-payment-id (+ payment-id u1))
            (ok payment-id)
        )
    )
)

(define-public (create-split-bill
        (co-payer principal)
        (amount uint)
        (due-date uint)
        (description (string-ascii 100))
    )
    (let (
            (bill-id (var-get next-bill-id))
            (provider-id-opt (map-get? provider-by-address tx-sender))
        )
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (> due-date stacks-block-height) err-invalid-amount)

        (let (
                (provider-id (unwrap! provider-id-opt err-unauthorized))
                (provider-data (unwrap! (map-get? providers provider-id) err-not-found))
                (split-participants (list
                    {
                        participant: tx-sender,
                        share: u5000,
                        paid: false,
                        payment-id: none,
                    }
                    {
                        participant: co-payer,
                        share: u5000,
                        paid: false,
                        payment-id: none,
                    }
                ))
            )
            (asserts! (get active provider-data) err-unauthorized)

            (map-set bills bill-id {
                customer: tx-sender,
                provider-id: provider-id,
                amount: amount,
                due-date: due-date,
                description: description,
                paid: false,
                paid-at: none,
                created-at: stacks-block-height,
            })

            (map-set bill-participants bill-id split-participants)

            (map-set provider-bills provider-id
                (unwrap!
                    (as-max-len?
                        (append (get-provider-bills provider-id) bill-id)
                        u200
                    )
                    err-invalid-amount
                ))

            (map-set participant-bills tx-sender
                (unwrap!
                    (as-max-len?
                        (append (get-participant-bills tx-sender) bill-id)
                        u100
                    )
                    err-invalid-amount
                ))

            (map-set participant-bills co-payer
                (unwrap!
                    (as-max-len?
                        (append (get-participant-bills co-payer) bill-id)
                        u100
                    )
                    err-invalid-amount
                ))

            (var-set next-bill-id (+ bill-id u1))
            (ok bill-id)
        )
    )
)

(define-public (pay-split-share (bill-id uint))
    (let (
            (bill-data (unwrap! (map-get? bills bill-id) err-not-found))
            (participants-list (get-bill-participants bill-id))
            (customer-balance (get-customer-balance tx-sender))
        )
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (not (get paid bill-data)) err-bill-already-paid)
        (asserts! (<= stacks-block-height (get due-date bill-data))
            err-bill-expired
        )

        (if (is-eq (len participants-list) u0)
            (pay-bill bill-id)
            (let (
                    (share-amount (/ (get amount bill-data) u2))
                    (payment-fee (calculate-payment-fee share-amount))
                    (total-cost (+ share-amount payment-fee))
                    (payment-id (var-get next-payment-id))
                    (provider-data (unwrap! (map-get? providers (get provider-id bill-data))
                        err-invalid-provider
                    ))
                )
                (asserts! (>= customer-balance total-cost) err-insufficient-funds)

                (map-set customer-balances tx-sender
                    (- customer-balance total-cost)
                )
                (try! (as-contract (stx-transfer? share-amount tx-sender (get address provider-data))))
                (if (> payment-fee u0)
                    (try! (as-contract (stx-transfer? payment-fee tx-sender contract-owner)))
                    true
                )

                (map-set payment-history payment-id {
                    bill-id: bill-id,
                    customer: tx-sender,
                    amount: share-amount,
                    fee: payment-fee,
                    timestamp: stacks-block-height,
                })
                (var-set next-payment-id (+ payment-id u1))

                (ok payment-id)
            )
        )
    )
)

(define-public (emergency-withdraw)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender contract-owner)))
        (ok true)
    )
)

;; ========================================
;; Bill Scheduling & Auto-Payment Feature
;; Clarity v3 - Independent functionality
;; ========================================

;; New error constants for scheduling (continuing from existing u111)
(define-constant err-invalid-interval (err u112))
(define-constant err-invalid-start (err u113))
(define-constant err-not-due (err u114))
(define-constant err-inactive (err u115))
(define-constant err-insufficient-escrow (err u116))

;; Storage for scheduling feature
(define-data-var next-schedule-id uint u1)

(define-map schedules
    uint
    {
        payer: principal,
        payee: principal,
        amount: uint,
        interval: uint,
        next-height: uint,
        total-cycles: (optional uint),
        executed: uint,
        auto-pay: bool,
        active: bool
    }
)

(define-map autopay-prefs
    principal
    bool
)

(define-map schedule-escrow
    principal
    uint
)

;; Read-only functions for scheduling
(define-read-only (get-next-schedule-id)
    (var-get next-schedule-id)
)

(define-read-only (get-schedule (id uint))
    (map-get? schedules id)
)

(define-read-only (get-schedule-escrow (owner principal))
    (default-to u0 (map-get? schedule-escrow owner))
)

(define-read-only (get-autopay-pref (owner principal))
    (default-to false (map-get? autopay-prefs owner))
)

(define-read-only (is-schedule-due (id uint))
    (match (map-get? schedules id)
        sched
            (and (get active sched) (>= stacks-block-height (get next-height sched)))
        false
    )
)

;; Public functions for scheduling
(define-public (set-autopay-pref (enabled bool))
    (begin
        (map-set autopay-prefs tx-sender enabled)
        (ok enabled)
    )
)

(define-private (update-schedule-after-payment (id uint))
    (match (map-get? schedules id)
        curr
            (let (
                    (executed (+ u1 (get executed curr)))
                    (total (get total-cycles curr))
                    (interval (get interval curr))
                    (next (+ (get next-height curr) interval))
                )
                (if (is-some total)
                    (let ((totalv (unwrap-panic total)))
                        (if (>= executed totalv)
                            (begin
                                (map-set schedules id (merge curr { executed: executed, active: false }))
                                true
                            )
                            (begin
                                (map-set schedules id (merge curr { executed: executed, next-height: next }))
                                true
                            )
                        )
                    )
                    (begin
                        (map-set schedules id (merge curr { executed: executed, next-height: next }))
                        true
                    )
                )
            )
        false
    )
)

(define-public (create-schedule
        (payee principal)
        (amount uint)
        (start-height uint)
        (interval uint)
        (total-cycles (optional uint))
        (auto-pay bool)
    )
    (begin
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (> interval u0) err-invalid-interval)
        (asserts! (>= start-height stacks-block-height) err-invalid-start)
        (asserts! (not (is-eq payee tx-sender)) err-unauthorized)

        (let ((id (var-get next-schedule-id)))
            (map-set schedules id {
                payer: tx-sender,
                payee: payee,
                amount: amount,
                interval: interval,
                next-height: start-height,
                total-cycles: total-cycles,
                executed: u0,
                auto-pay: auto-pay,
                active: true
            })
            (var-set next-schedule-id (+ id u1))
            (ok id)
        )
    )
)

(define-public (cancel-schedule (id uint))
    (match (map-get? schedules id)
        sched
            (if (is-eq (get payer sched) tx-sender)
                (begin
                    (map-set schedules id (merge sched { active: false }))
                    (ok true)
                )
                err-unauthorized
            )
        err-not-found
    )
)

(define-public (deposit-to-escrow (amount uint))
    (begin
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (let ((prev (default-to u0 (map-get? schedule-escrow tx-sender))))
            (map-set schedule-escrow tx-sender (+ prev amount))
            (ok (+ prev amount))
        )
    )
)

(define-public (withdraw-from-escrow (amount uint))
    (let (
            (caller tx-sender)
            (bal (default-to u0 (map-get? schedule-escrow tx-sender)))
        )
        (begin
            (asserts! (not (var-get contract-paused)) err-unauthorized)
            (asserts! (> amount u0) err-invalid-amount)
            (asserts! (>= bal amount) err-insufficient-escrow)
            (map-set schedule-escrow caller (- bal amount))
            (try! (as-contract (stx-transfer? amount tx-sender caller)))
            (ok (- bal amount))
        )
    )
)

(define-public (pay-schedule-now (id uint))
    (if (var-get contract-paused)
        err-unauthorized
        (match (map-get? schedules id)
            sched
                (if (and
                        (get active sched)
                        (is-eq (get payer sched) tx-sender)
                        (>= stacks-block-height (get next-height sched))
                    )
                    (match (stx-transfer? (get amount sched) tx-sender (get payee sched))
                        success
                            (let ((updated (update-schedule-after-payment id)))
                                (ok updated)
                            )
                        error (err error)
                    )
                    (if (not (get active sched))
                        err-inactive
                        (if (not (is-eq (get payer sched) tx-sender))
                            err-unauthorized
                            err-not-due
                        )
                    )
                )
            err-not-found
        )
    )
)

(define-public (run-autopay (id uint))
    (if (var-get contract-paused)
        err-unauthorized
        (match (map-get? schedules id)
            sched
                (let (
                        (payer (get payer sched))
                        (payee (get payee sched))
                        (amt (get amount sched))
                        (due? (and (get active sched) (>= stacks-block-height (get next-height sched))))
                        (pref (default-to false (map-get? autopay-prefs (get payer sched))))
                        (bal (default-to u0 (map-get? schedule-escrow (get payer sched))))
                    )
                    (if (and due? (get auto-pay sched) pref (>= bal amt))
                        (begin
                            (map-set schedule-escrow payer (- bal amt))
                            (match (as-contract (stx-transfer? amt tx-sender payee))
                                success
                                    (let ((updated (update-schedule-after-payment id)))
                                        (ok updated)
                                    )
                                error (err error)
                            )
                        )
                        (if (not due?)
                            err-not-due
                            (if (not (and (get auto-pay sched) pref))
                                err-unauthorized
                                err-insufficient-escrow
                            )
                        )
                    )
                )
            err-not-found
        )
    )
)
