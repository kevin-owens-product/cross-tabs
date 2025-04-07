module XB2.Data.Range exposing
    ( Range
    , combine
    , contains
    , extendWith
    , fromList
    , fromNumber
    , init
    , interpolate
    )


type alias Range =
    { min : Float
    , max : Float
    }


{-| `init.min` is guaranteed to be GTE any value you put in,
`init.max` is guaranteed to be LTE any value you put in.

It's the monoid zero, if you are into that sort of stuff ;)

-}
init : Range
init =
    { min = 1 / 0
    , max = -1 / 0
    }


combine : Range -> Range -> Range
combine a b =
    { min = min a.min b.min
    , max = max a.max b.max
    }


{-| Defaults to `init` on empty list.
-}
fromList : List Float -> Range
fromList list =
    { min = List.foldl min init.min list
    , max = List.foldl max init.max list
    }


fromNumber : Float -> Range
fromNumber n =
    { min = n
    , max = n
    }


extendWith : Float -> Range -> Range
extendWith n range =
    -- careful: this will invalidate Html.Lazy down the line
    { min = min n range.min
    , max = max n range.max
    }


{-| Convert the number to the 0..1 scale based on the given range (but only if
the number is in the range!)

    interpolate { min = 100, max = 300 } 100 --> 0.0

    interpolate { min = 100, max = 300 } 300 --> 1.0

    interpolate { min = 100, max = 300 } 200 --> 0.5

If you give it a number outside of the range, all bets are off:

    interpolate { min = 100, max = 300 } 0 --> -0.5

    interpolate { min = 100, max = 300 } 50 --> -0.25

The special case of min == max == n returns `0`:

    interpolate { min = 5, max = 5 } 5 --> 0

-}
interpolate : Range -> Float -> Float
interpolate { min, max } n =
    if min == max && min == n then
        0

    else
        (n - min) / (max - min)


{-| Unused in code, used in tests
-}
contains : Float -> Range -> Bool
contains float range =
    float >= range.min && float <= range.max
