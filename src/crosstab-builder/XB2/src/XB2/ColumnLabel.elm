module XB2.ColumnLabel exposing (fromInt)

{-| Dealing with Excel-like column header labels. They go in this sequence:

    A,B,C,...,Z,AA,AB,...,AZ,BA,BB,...,ZZ,AAA,...

In our implementation, A = 0.

-}


{-| This _isn't_ base conversion between base 10 and 26. Think about "A" (0)
vs "AA" (26):

    n  | base 26 | our wanted result
    ---+---------+------------------
    0  | 0       | A
    26 | 10      | AA

So if we said `0 = A` and used the base 26 result number, we'd get something
like `BA` instead of `AA`.

-}
fromInt : Int -> Maybe String
fromInt n =
    let
        -- Only makes sense for 0..25 = A..Z
        toLetter : Int -> Char
        toLetter n_ =
            -- A = 65
            Char.fromCode (n_ + 65)

        go : Int -> List Char -> String
        go n_ acc =
            if n_ < 0 then
                String.fromList acc

            else
                let
                    ones =
                        n_ |> modBy 26

                    rest =
                        (n_ // 26) - 1
                in
                go rest (toLetter ones :: acc)
    in
    if n < 0 then
        Nothing

    else
        Just <| go n []
