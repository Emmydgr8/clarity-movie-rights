;; Movie Rights Management Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-movie-exists (err u101))
(define-constant err-movie-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rights (err u104))
(define-constant err-invalid-duration (err u105))
(define-constant err-contract-paused (err u106))

;; License duration constraints
(define-constant min-license-duration u30) ;; 30 blocks minimum
(define-constant max-license-duration u52560) ;; ~365 days in blocks
(define-constant grace-period u1440) ;; ~10 days in blocks

;; Contract State
(define-data-var contract-paused bool false)
(define-data-var last-movie-id uint u0)

;; Enhanced Data Structures
(define-map movies
    { movie-id: uint }
    {
        title: (string-ascii 100),
        owner: principal,
        rights-holder: principal,
        license-expiry: uint,
        is-transferable: bool,
        genre: (string-ascii 50),
        release-year: uint,
        creation-height: uint
    }
)

(define-map rights-holders
    principal
    {
        total-movies: uint,
        active-licenses: uint,
        reputation-score: uint
    }
)

(define-map rights-history
    { movie-id: uint, transfer-id: uint }
    {
        from: principal,
        to: principal,
        timestamp: uint
    }
)

;; Administrative Functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused paused)
        (ok true)
    )
)

;; Helper Functions
(define-private (increment-rights-holder-stats (rights-holder principal))
    (let (
        (current-stats (default-to 
            {total-movies: u0, active-licenses: u0, reputation-score: u100} 
            (map-get? rights-holders rights-holder)))
    )
    (map-set rights-holders
        rights-holder
        {
            total-movies: (+ (get total-movies current-stats) u1),
            active-licenses: (+ (get active-licenses current-stats) u1),
            reputation-score: (get reputation-score current-stats)
        }
    ))
)

;; Register new movie
(define-public (register-movie 
    (movie-id uint) 
    (title (string-ascii 100)) 
    (rights-holder principal) 
    (license-duration uint) 
    (transferable bool)
    (genre (string-ascii 50))
    (release-year uint))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? movies {movie-id: movie-id})) err-movie-exists)
        (asserts! (and (>= license-duration min-license-duration) (<= license-duration max-license-duration)) err-invalid-duration)
        
        (map-set movies 
            {movie-id: movie-id}
            {
                title: title,
                owner: contract-owner,
                rights-holder: rights-holder,
                license-expiry: (+ block-height license-duration),
                is-transferable: transferable,
                genre: genre,
                release-year: release-year,
                creation-height: block-height
            }
        )
        (increment-rights-holder-stats rights-holder)
        (print {event: "movie-registered", movie-id: movie-id, rights-holder: rights-holder})
        (ok true)
    )
)

;; Batch register movies
(define-public (batch-register-movies (movie-data (list 10 {
    movie-id: uint,
    title: (string-ascii 100),
    rights-holder: principal,
    license-duration: uint,
    transferable: bool,
    genre: (string-ascii 50),
    release-year: uint
})))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map register-movie-internal movie-data))
    )
)

;; [Previous functions remain with added pause check]
;; [Rest of the contract implementation...]
