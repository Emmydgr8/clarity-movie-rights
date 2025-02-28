;; Movie Rights Management Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-movie-exists (err u101))
(define-constant err-movie-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rights (err u104))
(define-constant err-invalid-duration (err u105))

;; License duration constraints
(define-constant min-license-duration u30) ;; 30 blocks minimum
(define-constant max-license-duration u52560) ;; ~365 days in blocks

;; Data Variables
(define-map movies
    { movie-id: uint }
    {
        title: (string-ascii 100),
        owner: principal,
        rights-holder: principal,
        license-expiry: uint,
        is-transferable: bool
    }
)

(define-map rights-holders
    principal
    {
        total-movies: uint,
        active-licenses: uint
    }
)

;; Events
(define-data-var last-movie-id uint u0)

;; Helper functions
(define-private (increment-rights-holder-stats (rights-holder principal))
    (let (
        (current-stats (default-to {total-movies: u0, active-licenses: u0} 
            (map-get? rights-holders rights-holder)))
    )
    (map-set rights-holders
        rights-holder
        {
            total-movies: (+ (get total-movies current-stats) u1),
            active-licenses: (+ (get active-licenses current-stats) u1)
        }
    ))
)

;; Register new movie
(define-public (register-movie (movie-id uint) (title (string-ascii 100)) (rights-holder principal) (license-duration uint) (transferable bool))
    (let (
        (movie-exists (get title (map-get? movies {movie-id: movie-id})))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none movie-exists) err-movie-exists)
    (asserts! (and (>= license-duration min-license-duration) (<= license-duration max-license-duration)) err-invalid-duration)
    
    (begin
        (map-set movies 
            {movie-id: movie-id}
            {
                title: title,
                owner: contract-owner,
                rights-holder: rights-holder,
                license-expiry: (+ block-height license-duration),
                is-transferable: transferable
            }
        )
        (increment-rights-holder-stats rights-holder)
        (print {event: "movie-registered", movie-id: movie-id, rights-holder: rights-holder})
        (ok true)
    ))
)

;; Transfer movie rights
(define-public (transfer-rights (movie-id uint) (new-rights-holder principal))
    (let (
        (movie-data (unwrap! (map-get? movies {movie-id: movie-id}) err-movie-not-found))
    )
    (asserts! (and
        (is-eq tx-sender (get rights-holder movie-data))
        (get is-transferable movie-data)
    ) err-unauthorized)
    
    (begin
        (map-set movies
            {movie-id: movie-id}
            (merge movie-data {rights-holder: new-rights-holder})
        )
        (print {event: "rights-transferred", movie-id: movie-id, from: tx-sender, to: new-rights-holder})
        (ok true)
    ))
)

;; Get rights holder's portfolio
(define-read-only (get-rights-holder-stats (holder principal))
    (ok (default-to 
        {total-movies: u0, active-licenses: u0}
        (map-get? rights-holders holder)
    ))
)

;; Check rights status
(define-read-only (get-movie-rights (movie-id uint))
    (let (
        (movie-data (map-get? movies {movie-id: movie-id}))
    )
    (if (is-none movie-data)
        err-movie-not-found
        (ok (unwrap-panic movie-data))
    ))
)

;; Check if rights are active
(define-read-only (are-rights-active (movie-id uint))
    (let (
        (movie-data (unwrap! (map-get? movies {movie-id: movie-id}) err-movie-not-found))
    )
    (ok (>= (get license-expiry movie-data) block-height))
    )
)

;; Extend license duration
(define-public (extend-license (movie-id uint) (extension-period uint))
    (let (
        (movie-data (unwrap! (map-get? movies {movie-id: movie-id}) err-movie-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= extension-period max-license-duration) err-invalid-duration)
    
    (begin
        (map-set movies
            {movie-id: movie-id}
            (merge movie-data {
                license-expiry: (+ (get license-expiry movie-data) extension-period)
            })
        )
        (print {event: "license-extended", movie-id: movie-id, extension: extension-period})
        (ok true)
    ))
)
