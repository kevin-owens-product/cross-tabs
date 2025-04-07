module FormattedText.Benchmark exposing (main)

import Benchmark exposing (Benchmark, benchmark, describe)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import FormattedText
import FormattedText.ParserBased
import FormattedText.StringBased
import Html exposing (Html)


string : String
string =
    """
Social shoppers in the West love to be in the spotlight and want to be intimately connected with brands and new products. These consumers enjoy receiving special attention from brands – they care about their social appearance and believe brands will help improve their image. The youngest of this group, Gen Z, are especially keen on connecting with other like-minded fans of the same brand.
For more information check out the blog post: https://bit.ly/2Vrrlfm
    """


parserBased : String -> Html a
parserBased str =
    FormattedText.ParserBased.parse str
        |> FormattedText.ParserBased.toList Html.text (\_ s -> Html.a [] [ Html.text s ])
        |> Html.p []


stringBased : String -> Html a
stringBased str =
    FormattedText.StringBased.parse str
        |> FormattedText.StringBased.toList Html.text (\_ s -> Html.a [] [ Html.text s ])
        |> Html.p []


{-| The final implementation
-}
regexBased : String -> Html a
regexBased str =
    FormattedText.parse str
        |> FormattedText.toList Html.text (\_ s -> Html.a [] [ Html.text s ])
        |> Html.p []


suite : Benchmark
suite =
    describe "FormattedText"
        [ benchmark "parser based" <| \() -> parserBased string
        , benchmark "string based" <| \() -> stringBased string
        , benchmark "regex based" <| \() -> regexBased string
        ]


main : BenchmarkProgram
main =
    program suite
