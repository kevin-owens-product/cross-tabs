module CoolTipTest exposing (coolTipTest)

import CoolTip exposing (Position(..))
import Html
import Html.Attributes as Attrs
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


coolTipTest : Test
coolTipTest =
    describe "CoolTip"
        [ describe "withOffset" <|
            List.map
                (\( position, expectedClass ) ->
                    test expectedClass <|
                        \() ->
                            CoolTip.view
                                { offset = Just 123
                                , position = position
                                , type_ = CoolTip.Normal
                                , wrapperAttributes = []
                                , targetAttributes = []
                                , targetHtml = []
                                , tooltipAttributes = []
                                , tooltipHtml = Html.text "THE TEXT"
                                }
                                |> Query.fromHtml
                                |> Query.has
                                    [ Selector.tag "x-cooltip"
                                    , Selector.text "THE TEXT"
                                    , Selector.class expectedClass
                                    , Selector.attribute (Attrs.attribute "offset" "123")
                                    ]
                )
                [ ( Top, "top" )
                , ( Right, "right" )
                , ( BottomRight, "bottomright" )
                ]
        ]
