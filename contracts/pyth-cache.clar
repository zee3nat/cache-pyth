;; pyth-cache
;; A decentralized caching mechanism for Pyth Network price feeds on the Stacks blockchain
;; This contract manages price feed caching, validation, and retrieval for 
;; financial data with efficient storage and retrieval mechanisms.
;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LISTING-NOT-FOUND (err u101))
(define-constant ERR-LISTING-EXPIRED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-ALREADY-PURCHASED (err u104))
(define-constant ERR-INVALID-PRICE (err u105))
(define-constant ERR-INVALID-ROYALTY (err u106))
(define-constant ERR-INVALID-REVIEW (err u107))
(define-constant ERR-NOT-PURCHASED (err u108))
(define-constant ERR-ALREADY-REVIEWED (err u109))
(define-constant ERR-PLATFORM-FEE-TRANSFER-FAILED (err u110))
(define-constant ERR-ROYALTY-TRANSFER-FAILED (err u111))
(define-constant ERR-SELLER-PAYMENT-FAILED (err u112))
;; Platform Configuration
(define-constant CONTRACT-OWNER tx-sender)
(define-constant PLATFORM-FEE-PERCENT u5) ;; 5% platform fee
(define-constant MAX-ROYALTY-PERCENT u15) ;; Max 15% royalty
(define-constant MAX-REVIEW-SCORE u5) ;; Review score out of 5
;; Data Maps and Variables
;; Listings storage
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    price: uint,
    category: (string-ascii 50),
    preview-url: (string-utf8 200),
    full-asset-url: (string-utf8 200),
    royalty-percent: uint,
    created-at: uint,
    is-active: bool,
  }
)
;; Track listing ownership history
(define-map ownership-history
  {
    listing-id: uint,
    owner-index: uint,
  }
  {
    owner: principal,
    acquired-at: uint,
    purchase-price: uint,
  }
)
;; Purchases tracking
(define-map purchases
  {
    listing-id: uint,
    buyer: principal,
  }
  {
    purchased-at: uint,
    purchase-price: uint,
    reviewed: bool,
  }
)
;; Reviews for assets
(define-map reviews
  {
    listing-id: uint,
    reviewer: principal,
  }
  {
    score: uint,
    comment: (string-utf8 300),
    review-date: uint,
  }
)
;; Trend tracking - counts purchases by category
(define-map category-trends
  {
    category: (string-ascii 50),
    month-year: (string-ascii 7),
  }
  { purchase-count: uint }
)
;; Counter for listing IDs
(define-data-var last-listing-id uint u0)
;; Counter for tracking ownership indices
(define-map ownership-indices
  { listing-id: uint }
  { current-index: uint }
)
;; Private Functions
;; Increment and get the next listing ID
(define-private (get-next-listing-id)
  (let ((next-id (+ (var-get last-listing-id) u1)))
    (var-set last-listing-id next-id)
    next-id
  )
)

;; Get current block time as timestamp
(define-private (get-current-time)
  block-height
)

;; Calculate platform fee amount
(define-private (calculate-platform-fee (price uint))
  (/ (* price PLATFORM-FEE-PERCENT) u100)
)

;; Calculate royalty amount
(define-private (calculate-royalty
    (price uint)
    (royalty-percent uint)
  )
  (/ (* price royalty-percent) u100)
)

;; Placeholder for int-to-ascii conversion
(define-private (int-to-ascii (n uint))
  ;; TODO: This is a placeholder. A proper implementation converting uint to
  ;; a string-ascii (e.g., "123") is needed for correct functionality.
  ;; This current version returns a fixed string to resolve the compile error.
  "?"
)

;; Format month-year string for trend tracking (e.g., "2023-05")
(define-private (get-current-month-year)
  ;; In a real implementation, you'd parse the block time to extract month-year
  ;; For simplicity, we'll just use the block height divided by 144 * 30 as a rough approximation
  (concat (int-to-ascii (/ block-height u4320))
    (concat "-" (int-to-ascii (/ (mod block-height u4320) u360)))
  )
)

;; Update trend data for a category
(define-private (update-trend-data (category (string-ascii 50)))
  (let (
      (month-year (get-current-month-year))
      (current-data (default-to { purchase-count: u0 }
        (map-get? category-trends {
          category: category,
          month-year: month-year,
        })
      ))
    )
    (map-set category-trends {
      category: category,
      month-year: month-year,
    } { purchase-count: (+ u1 (get purchase-count current-data)) }
    )
  )
)

;; Get the current ownership index for a listing
(define-private (get-ownership-index (listing-id uint))
  (default-to { current-index: u0 }
    (map-get? ownership-indices { listing-id: listing-id })
  )
)

;; Update ownership history for a listing
(define-private (record-ownership
    (listing-id uint)
    (new-owner principal)
    (price uint)
  )
  (let (
      (index-data (get-ownership-index listing-id))
      (current-index (get current-index index-data))
      (next-index (+ current-index u1))
    )
    ;; Record the new ownership entry
    (map-set ownership-history {
      listing-id: listing-id,
      owner-index: next-index,
    } {
      owner: new-owner,
      acquired-at: (get-current-time),
      purchase-price: price,
    })
    ;; Update the index counter
    (map-set ownership-indices { listing-id: listing-id } { current-index: next-index })
  )
)

;; Public Functions
;; Create a new listing
(define-public (create-listing
    (title (string-ascii 100))
    (description (string-utf8 500))
    (price uint)
    (category (string-ascii 50))
    (preview-url (string-utf8 200))
    (full-asset-url (string-utf8 200))
    (royalty-percent uint)
  )
  (let ((listing-id (get-next-listing-id)))
    ;; Validate inputs
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (<= royalty-percent MAX-ROYALTY-PERCENT) ERR-INVALID-ROYALTY)
    ;; Create the listing
    (map-set listings { listing-id: listing-id } {
      seller: tx-sender,
      title: title,
      description: description,
      price: price,
      category: category,
      preview-url: preview-url,
      full-asset-url: full-asset-url,
      royalty-percent: royalty-percent,
      created-at: (get-current-time),
      is-active: true,
    })
    ;; Initialize ownership history
    (map-set ownership-history {
      listing-id: listing-id,
      owner-index: u0,
    } {
      owner: tx-sender,
      acquired-at: (get-current-time),
      purchase-price: u0,
    })
    ;; Initialize ownership index
    (map-set ownership-indices { listing-id: listing-id } { current-index: u0 })
    (ok listing-id)
  )
)

;; Update an existing listing
(define-public (update-listing
    (listing-id uint)
    (title (string-ascii 100))
    (description (string-utf8 500))
    (price uint)
    (category (string-ascii 50))
    (preview-url (string-utf8 200))
    (full-asset-url (string-utf8 200))
    (is-active bool)
  )
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
    ;; Check authorization
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-PRICE)
    ;; Update listing
    (map-set listings { listing-id: listing-id }
      (merge listing {
        title: title,
        description: description,
        price: price,
        category: category,
        preview-url: preview-url,
        full-asset-url: full-asset-url,
        is-active: is-active,
      })
    )
    (ok true)
  )
)

;; Remove a listing
(define-public (remove-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
    ;; Check authorization
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
    ;; Update listing to inactive
    (map-set listings { listing-id: listing-id }
      (merge listing { is-active: false })
    )
    (ok true)
  )
)

;; Purchase an asset
(define-public (purchase-asset (listing-id uint))
  (let (
      (listing (unwrap! (map-get? listings { listing-id: listing-id })
        ERR-LISTING-NOT-FOUND
      ))
      (buyer tx-sender)
      (seller (get seller listing))
      (price (get price listing))
      (category (get category listing))
      (royalty-percent (get royalty-percent listing))
      (platform-fee (calculate-platform-fee price))
      (seller-amount (- price platform-fee))
    )
    ;; Validate purchase conditions
    (asserts! (get is-active listing) ERR-LISTING-EXPIRED)
    (asserts! (not (is-eq buyer seller)) ERR-NOT-AUTHORIZED)
    (asserts!
      (is-none (map-get? purchases {
        listing-id: listing-id,
        buyer: buyer,
      }))
      ERR-ALREADY-PURCHASED
    )
    ;; Transfer platform fee to contract owner
    (unwrap! (stx-transfer? platform-fee buyer CONTRACT-OWNER)
      ERR-PLATFORM-FEE-TRANSFER-FAILED
    )
    ;; Transfer payment to seller
    (unwrap! (stx-transfer? seller-amount buyer seller) ERR-SELLER-PAYMENT-FAILED)
    ;; Record the purchase
    (map-set purchases {
      listing-id: listing-id,
      buyer: buyer,
    } {
      purchased-at: (get-current-time),
      purchase-price: price,
      reviewed: false,
    })
    ;; Record ownership transfer
    (record-ownership listing-id buyer price)
    ;; Update trend data
    (update-trend-data category)
    (ok true)
  )
)

;; Submit a review for a purchased asset
(define-public (submit-review
    (listing-id uint)
    (score uint)
    (comment (string-utf8 300))
  )
  (let (
      (listing (unwrap! (map-get? listings { listing-id: listing-id })
        ERR-LISTING-NOT-FOUND
      ))
      (purchase (unwrap!
        (map-get? purchases {
          listing-id: listing-id,
          buyer: tx-sender,
        })
        ERR-NOT-PURCHASED
      ))
    )
    ;; Validate review
    (asserts! (not (get reviewed purchase)) ERR-ALREADY-REVIEWED)
    (asserts! (<= score MAX-REVIEW-SCORE) ERR-INVALID-REVIEW)
    ;; Record the review
    (map-set reviews {
      listing-id: listing-id,
      reviewer: tx-sender,
    } {
      score: score,
      comment: comment,
      review-date: (get-current-time),
    })
    ;; Update the purchase record to mark as reviewed
    (map-set purchases {
      listing-id: listing-id,
      buyer: tx-sender,
    }
      (merge purchase { reviewed: true })
    )
    (ok true)
  )
)

;; Resell a previously purchased asset
(define-public (resell-asset
    (listing-id uint)
    (new-price uint)
  )
  (let (
      (listing (unwrap! (map-get? listings { listing-id: listing-id })
        ERR-LISTING-NOT-FOUND
      ))
      (purchase (unwrap!
        (map-get? purchases {
          listing-id: listing-id,
          buyer: tx-sender,
        })
        ERR-NOT-PURCHASED
      ))
      (original-seller (get seller listing))
      (royalty-percent (get royalty-percent listing))
    )
    ;; Validate resale
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    ;; Update the listing with new seller and price
    (map-set listings { listing-id: listing-id }
      (merge listing {
        seller: tx-sender,
        price: new-price,
        is-active: true,
      })
    )
    (ok true)
  )
)

;; Read-Only Functions
;; Get listing details
(define-read-only (get-listing (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

;; Check if user has purchased an asset
(define-read-only (has-purchased
    (listing-id uint)
    (user principal)
  )
  (is-some (map-get? purchases {
    listing-id: listing-id,
    buyer: user,
  }))
)

;; Get review for a listing by a specific reviewer
(define-read-only (get-review
    (listing-id uint)
    (reviewer principal)
  )
  (map-get? reviews {
    listing-id: listing-id,
    reviewer: reviewer,
  })
)

;; Get trend data for a category in a specific month
(define-read-only (get-category-trend
    (category (string-ascii 50))
    (month-year (string-ascii 7))
  )
  (default-to { purchase-count: u0 }
    (map-get? category-trends {
      category: category,
      month-year: month-year,
    })
  )
)

;; Get ownership history for a listing
(define-read-only (get-ownership-history
    (listing-id uint)
    (index uint)
  )
  (map-get? ownership-history {
    listing-id: listing-id,
    owner-index: index,
  })
)

;; Get the total number of listings
(define-read-only (get-listing-count)
  (var-get last-listing-id)
)
