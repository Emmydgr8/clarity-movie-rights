;; Movie Rights Management Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-movie-exists (err u101))
(define-constant err-movie-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rights (err u104))

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

;; Register new movie
(define-public (register-movie (movie-id uint) (title (string-ascii 100)) (rights-holder principal) (license-duration uint) (transferable bool))
    (let (
        (movie-exists (get title (map-get? movies {movie-id: movie-id})))
    )
    (if (and (is-eq tx-sender contract-owner) (is-none movie-exists))
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
            (ok true)
        )
        err-movie-exists
    ))
)

;; Transfer movie rights
(define-public (transfer-rights (movie-id uint) (new-rights-holder principal))
    (let (
        (movie-data (unwrap! (map-get? movies {movie-id: movie-id}) err-movie-not-found))
    )
    (if (and
            (is-eq tx-sender (get rights-holder movie-data))
            (get is-transferable movie-data)
        )
        (begin
            (map-set movies
                {movie-id: movie-id}
                (merge movie-data {rights-holder: new-rights-holder})
            )
            (ok true)
        )
        err-unauthorized
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
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set movies
                {movie-id: movie-id}
                (merge movie-data {
                    license-expiry: (+ (get license-expiry movie-data) extension-period)
                })
            )
            (ok true)
        )
        err-owner-only
    ))
)
