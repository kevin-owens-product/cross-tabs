module FormattedTextTest exposing (suite)

import Expect
import FormattedText exposing (Part(..), Protocol(..))
import Test exposing (..)


suite : Test
suite =
    describe "parsing"
        [ test "parse regular string" <|
            \() ->
                FormattedText.parse "foo bar baz."
                    |> Expect.equal [ Text "foo bar baz." ]
        , test "parse url with http" <|
            \() ->
                FormattedText.parse "http://foo.com"
                    |> Expect.equal [ Link Http "foo.com" ]
        , test "parse url with https" <|
            \() ->
                FormattedText.parse "https://foo.com"
                    |> Expect.equal [ Link Https "foo.com" ]
        , test "parse text with url" <|
            \() ->
                FormattedText.parse "foo https://bar.com"
                    |> Expect.equal
                        [ Text "foo "
                        , Link Https "bar.com"
                        ]
        , test "parse text starting with url" <|
            \() ->
                FormattedText.parse "https://foo.com bar"
                    |> Expect.equal
                        [ Link Https "foo.com"
                        , Text " bar"
                        ]
        , test "parse url surrounded by text" <|
            \() ->
                FormattedText.parse "foo https://bar.com baz."
                    |> Expect.equal
                        [ Text "foo "
                        , Link Https "bar.com"
                        , Text " baz."
                        ]
        , test "parse http url surrounded by text" <|
            \() ->
                FormattedText.parse "foo http://bar.com baz."
                    |> Expect.equal
                        [ Text "foo "
                        , Link Http "bar.com"
                        , Text " baz."
                        ]
        , test "don't freak out from `http` word" <|
            \() ->
                FormattedText.parse "foo http baz."
                    |> Expect.equal [ Text "foo http baz." ]
        , test "complicated content" <|
            \() ->
                "Lorem ipsum links http://google.com\nand thus http or https like https://www.seznam.cz"
                    |> FormattedText.parse
                    |> Expect.equal
                        [ Text "Lorem ipsum links "
                        , Link Http "google.com"
                        , Text "\nand thus http or https like "
                        , Link Https "www.seznam.cz"
                        ]
        , test "empty link" <|
            \() ->
                FormattedText.parse "https:// foo"
                    |> Expect.equal
                        [ Text "https:// foo"
                        ]
        , test "IP address" <|
            \() ->
                FormattedText.parse "http://127.0.0.1 localhost"
                    |> Expect.equal
                        [ Link Http "127.0.0.1"
                        , Text " localhost"
                        ]
        ]
