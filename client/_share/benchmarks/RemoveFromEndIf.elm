module RemoveFromEndIf exposing (main)

import Benchmark exposing (Benchmark, benchmark, describe)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Gwi.List as List


list : List Int
list =
    List.repeat 100 420
        ++ [ 69 ]
        ++ List.repeat 100 420


twoReversalsBased : List Int -> List Int
twoReversalsBased xs =
    xs
        |> List.reverse
        |> List.removeIf ((==) 69)
        |> List.reverse


foldrBased : List Int -> List Int
foldrBased xs =
    xs
        |> List.removeFromEndIf ((==) 69)


suite : Benchmark
suite =
    describe "removeFromEndIf"
        [ benchmark "two reversals" <| \() -> twoReversalsBased list
        , benchmark "foldr" <| \() -> foldrBased list
        ]


main : BenchmarkProgram
main =
    program suite
