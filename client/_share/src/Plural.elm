module Plural exposing (fromFloat, fromInt)

import PluralRules exposing (Cardinal(..), Rules)
import PluralRules.En


rules : Rules
rules =
    PluralRules.fromList
        [ ( "Query"
          , [ ( One, "Query" )
            , ( Other, "Queries" )
            ]
          )
        , ( "this"
          , [ ( One, "this" )
            , ( Other, "these" )
            ]
          )
        , ( "be"
          , [ ( One, "is" )
            , ( Other, "are" )
            ]
          )
        , ( "have"
          , [ ( One, "has" )
            , ( Other, "have" )
            ]
          )
        , ( "person"
          , [ ( One, "person" )
            , ( Other, "people" )
            ]
          )
        ]


fromInt : Int -> String -> String
fromInt n word =
    PluralRules.En.pluralize rules n word


fromFloat : Float -> String -> String
fromFloat n word =
    PluralRules.En.pluralizeFloat rules n word
