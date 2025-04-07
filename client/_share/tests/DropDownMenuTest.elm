module DropDownMenuTest exposing (dropDownMenuTest)

import DropDownMenu exposing (ArrowPosition(..), Model(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import WeakCss


dropDownMenuTest : Test
dropDownMenuTest =
    describe "DropDownMenu"
        [ describe "view" <|
            List.map
                (\( arrowPosition, expectedClass ) ->
                    let
                        config =
                            { id = ""
                            , className = WeakCss.namespace "test-dropdown"
                            , arrow = arrowPosition
                            , content = []
                            }
                    in
                    test ("view " ++ expectedClass) <|
                        \() ->
                            DropDownMenu.view config (Open config)
                                |> Query.fromHtml
                                |> Query.has
                                    [ Selector.class "test-dropdown"
                                    , Selector.class expectedClass
                                    ]
                )
                [ ( Nowhere, "no-arrow" )
                , ( TopLeft, "top-left" )
                ]
        ]
