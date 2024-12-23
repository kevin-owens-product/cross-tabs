module XB2.List.SortTest exposing (allTests)

import Expect
import Test exposing (..)
import Time
import XB2.List.Sort as Sort exposing (ProjectOwner(..), SortBy(..))


item name updatedAt createdAt =
    { name = name
    , updatedAt = Time.millisToPosix updatedAt
    , createdAt = Time.millisToPosix createdAt
    }


convertForSort ( i, parent ) =
    { item = i
    , getUpdatedAt = .updatedAt
    , getCreatedAt = .createdAt
    , getName = .name
    , parent = parent
    , owner = Me
    }


testCases =
    [ { items =
            [ ( item "BB somewhere in the middle" 1 1, Nothing )
            , ( item "Z the last one" 1 1, Nothing )
            , ( item "A first one" 1 1, Nothing )
            , ( item "B second one" 2 1, Nothing )
            ]
      , sortBy = NameDesc
      , expected =
            [ item "A first one" 1 1
            , item "B second one" 2 1
            , item "BB somewhere in the middle" 1 1
            , item "Z the last one" 1 1
            ]
      }
    , { items =
            [ ( item "BB somewhere in the middle" 69 1, Nothing )
            , ( item "Z the last one" 1 0, Nothing )
            , ( item "A first one" 1 0, Nothing )
            , ( item "B second one" 2 0, Nothing )
            ]
      , sortBy = NameAsc
      , expected =
            [ item "Z the last one" 1 0
            , item "BB somewhere in the middle" 69 1
            , item "B second one" 2 0
            , item "A first one" 1 0
            ]
      }
    , { items =
            [ ( item "BB somewhere in the middle" 69 1, Nothing )
            , ( item "Z the last one" 1 1, Nothing )
            , ( item "A first one" 1 1, Nothing )
            , ( item "B second one" 2 1, Nothing )
            ]
      , sortBy = LastModifiedAsc
      , expected =
            [ item "Z the last one" 1 1
            , item "A first one" 1 1
            , item "B second one" 2 1
            , item "BB somewhere in the middle" 69 1
            ]
      }
    , { items =
            [ ( item "BB somewhere in the middle" 69 1, Nothing )
            , ( item "Z the last one" 1 1, Nothing )
            , ( item "A first one" 1 1, Nothing )
            , ( item "B second one" 2 1, Nothing )
            ]
      , sortBy = LastModifiedDesc
      , expected =
            [ item "BB somewhere in the middle" 69 1
            , item "B second one" 2 1
            , item "A first one" 1 1
            , item "Z the last one" 1 1
            ]
      }
    , { items =
            [ ( item "BB somewhere in the middle" 69 69, Nothing )
            , ( item "Z the last one" 1 1, Nothing )
            , ( item "A first one" 1 2, Nothing )
            , ( item "B second one" 2 1, Nothing )
            ]
      , sortBy = CreatedAsc
      , expected =
            [ item "Z the last one" 1 1
            , item "B second one" 2 1
            , item "A first one" 1 2
            , item "BB somewhere in the middle" 69 69
            ]
      }
    , { items =
            [ ( item "BB somewhere in the middle" 69 69, Nothing )
            , ( item "Z the last one" 1 1, Nothing )
            , ( item "A first one" 1 2, Nothing )
            , ( item "B second one" 2 1, Nothing )
            ]
      , sortBy = CreatedDesc
      , expected =
            [ item "BB somewhere in the middle" 69 69
            , item "A first one" 1 2
            , item "B second one" 2 1
            , item "Z the last one" 1 1
            ]
      }
    ]


sortByToString sb =
    case sb of
        NameAsc ->
            "NameAsc"

        NameDesc ->
            "NameDesc"

        LastModifiedAsc ->
            "LastModifiedAsc"

        LastModifiedDesc ->
            "LastModifiedDesc"

        OwnedByAsc ->
            "OwnedByAsc"

        OwnedByDesc ->
            "OwnedByDesc"

        CreatedAsc ->
            "CreatedAsc"

        CreatedDesc ->
            "CreatedDesc"


allTests : Test
allTests =
    describe "Different sorting options" <|
        List.indexedMap
            (\index { items, sortBy, expected } ->
                test ("[" ++ String.fromInt index ++ "] Sort by " ++ sortByToString sortBy) <|
                    \() ->
                        Sort.sort sortBy (List.map convertForSort items)
                            |> Expect.equal expected
            )
            testCases
