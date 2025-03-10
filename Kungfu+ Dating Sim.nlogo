extensions [table]

turtles-own
[
  partner   ;;  the turtle that is our partner, or "nobody" if we don't have one
  meet-table
]

;;  This procedure will setup 150 turtles, by randomly placing them around the world.
to setup
  clear-all
  create-turtles 100
  [
    ;;  turtles get random coordinates, and they are
    ;;  light gray (to show they don't have partners yet).
    setxy random-xcor random-ycor
    set color gray + 2
    set partner nobody
    set meet-table table:make ;; each turtle is initialized with its own table
  ]
  reset-ticks
end

to update-memory
  let nearby-turtles sort other turtles-here  ;; Convert agentset to a sorted list
  foreach nearby-turtles [ other-turtle ->
    let other-id [who] of other-turtle  ;; Get the ID of the other turtle

    ;; If this turtle hasn't been met before, initialize the count to 0
    if not table:has-key? meet-table other-id [
      table:put meet-table other-id 0
    ]

    ;; Increment the count for this specific turtle
    table:put meet-table other-id (table:get meet-table other-id) + 1
  ]
end




;; have each turtle move until they find a partner at which point they turn red
to find-partners
  ;; Check for periodic breakups (30% chance every 100 ticks)
  if ticks mod 100 = 0 [check-periodic-breakups]
  
  ;; Check for breakups due to meeting other turtles
  check-meeting-breakups

  let singles turtles with [partner = nobody]
  if not any? singles [ stop ]

  ;; Move randomly before checking for partners
  ask singles [
    lt random 40
    rt random 40
    fd 1
    update-memory  ;; Update meeting counts after moving
  ]

  ;; Check if they have met any turtle meet-threshold times and make them partners
  ask singles [
    let potential-partner nobody

    ;; Find the first turtle that meets the criteria
    foreach table:keys meet-table [ other-id ->
      if (potential-partner = nobody and (table:get meet-table other-id) = meet-threshold and member? turtle other-id other turtles-here) [
        let candidate turtle other-id
        if [partner] of candidate = nobody [
          set potential-partner candidate
        ]
      ]
    ]

    ;; If a valid partner is found, assign them as partners
    if potential-partner != nobody [
      set partner potential-partner
      set color red
      ask potential-partner [
        set partner myself
        set color red
      ]
    ]
  ]

  tick
end

;; Check for periodic breakups (30% chance every 100 ticks)
to check-periodic-breakups
  let paired-turtles turtles with [partner != nobody]
  
  ask paired-turtles [
    ;; 30% chance of breaking up
    if random-float 1 < 0.3 [
      ;; Breakup with partner
      let ex-partner partner
      set partner nobody
      set color gray + 2
      
      ask ex-partner [
        set partner nobody
        set color gray + 2
      ]
    ]
  ]
end

;; Check for breakups caused by singles meeting paired turtles
to check-meeting-breakups
  let singles turtles with [partner = nobody]
  
  ask singles [
    ;; Check nearby turtles in a partnership
    let nearby-paired other turtles in-radius 1 with [partner != nobody]
    
    ask nearby-paired [
      ;; 20% chance of breaking up when a single turtle bumps into paired turtle
      if random-float 1 < 0.2 [
        ;; Store current partner before breaking up
        let current-partner partner
        let single-turtle myself
        
        ;; Break up with current partner
        set partner nobody
        
        ask current-partner [
          set partner nobody
          set color gray + 2
        ]
        
        ;; 50% chance to partner with the single turtle that caused breakup
        ifelse random-float 1 < 0.5 [
          set partner single-turtle
          set color red
          
          ask single-turtle [
            set partner myself
            set color red
          ]
        ] [
          ;; No new partnership, return to single status
          set color gray + 2
        ]
      ]
    ]
  ]
end




; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
