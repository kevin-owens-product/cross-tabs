module Data.Labels.FulltextTest exposing (markdownOptionsTest)

import Data.Labels.Fulltext
import Expect
import Test exposing (..)


markdownOptionsTest : Test
markdownOptionsTest =
    describe "Data.Labels.Fulltext.markdownOptions"
        [ test "convert HTML in string to a real HTML tag" <|
            \() ->
                {- Due to Markdown and VirtualDOM implementation in Elm,
                   the Test.Html.Query still sees the original Markdown string
                   and not the HTML result.

                   So we can't test the resulting HTML for `Query.has [Selector.tag "em"]`,
                   and instead test for the options used.
                -}
                Data.Labels.Fulltext.markdownOptions.sanitize
                    |> Expect.equal False
                    |> Expect.onFail "sanitize should be False"
        ]
