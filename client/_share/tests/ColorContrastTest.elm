module ColorContrastTest exposing (getContrastTest)

import ColorContrast
import Expect
import Test exposing (..)


getContrastTest : Test
getContrastTest =
    describe "ColorContrast"
        [ describe "get" <|
            List.map
                (\( color1, color2, expected ) ->
                    test ("compare colors: " ++ color1 ++ " vs " ++ color2) <|
                        \() ->
                            ColorContrast.get color1 color2
                                |> Expect.equal expected
                )
                [ ( "#000000", "#FFFFFF", Just { aaLevelSmall = True, aaLevelLarge = True, aaaLevelSmall = True, aaaLevelLarge = True } )
                , ( "#000000", "#fff", Just { aaLevelSmall = True, aaLevelLarge = True, aaaLevelSmall = True, aaaLevelLarge = True } )
                , ( "#000", "#FFF", Just { aaLevelSmall = True, aaLevelLarge = True, aaaLevelSmall = True, aaaLevelLarge = True } )
                , ( "000", "#FFF", Just { aaLevelSmall = True, aaLevelLarge = True, aaaLevelSmall = True, aaaLevelLarge = True } )
                , ( "ěšěš", "#FFF", Nothing )
                , ( "#FFFFFF", "#001199292", Nothing )
                , ( "#053E00", "#FF8EFF", Just { aaLevelSmall = True, aaLevelLarge = True, aaaLevelSmall = False, aaaLevelLarge = True } )
                , ( "#5C4453", "#FD92FA", Just { aaLevelSmall = False, aaLevelLarge = True, aaaLevelSmall = False, aaaLevelLarge = False } )
                , ( "#5CA953", "#FD92AA", Just { aaLevelSmall = False, aaLevelLarge = False, aaaLevelSmall = False, aaaLevelLarge = False } )
                ]
        ]
