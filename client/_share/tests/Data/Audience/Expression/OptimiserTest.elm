module Data.Audience.Expression.OptimiserTest exposing (optimiseTest)

-- Core

import Data.Audience.Expression
    exposing
        ( AudienceExpression(..)
        , AudienceInclusion(..)
        , LogicOperator(..)
        )
import Data.Audience.Expression.Optimiser as Optimiser
import Data.Id
import Expect
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Test exposing (..)


simpleNotOptimisedExpr : AudienceExpression
simpleNotOptimisedExpr =
    NonemptyList.singleton
        (Leaf
            { inclusion = Include
            , minCount = 1
            , questionCode = Data.Id.fromString "q2"
            , datapointCodes = [ Data.Id.fromString "q2_1" ]
            , suffixCodes = []
            }
        )
        |> NonemptyList.cons
            (Node Or <|
                NonemptyList.singleton
                    (Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    )
            )
        |> Node And


simpleOptimisedExpr : AudienceExpression
simpleOptimisedExpr =
    NonemptyList.singleton
        (Leaf
            { inclusion = Include
            , minCount = 1
            , questionCode = Data.Id.fromString "q2"
            , datapointCodes = [ Data.Id.fromString "q2_1" ]
            , suffixCodes = []
            }
        )
        |> NonemptyList.cons
            (Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "q3"
                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                , suffixCodes = []
                }
            )
        |> Node And


fromList : List AudienceExpression -> NonEmpty AudienceExpression
fromList =
    NonemptyList.fromList
        >> Maybe.withDefault (NonemptyList.singleton AllRespondents)


complexNotOptimisedExpr : AudienceExpression
complexNotOptimisedExpr =
    Node And <|
        fromList
            [ Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "q2"
                , datapointCodes = [ Data.Id.fromString "q2_1" ]
                , suffixCodes = []
                }
            , Node Or <|
                fromList
                    [ Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    ]
            , Node And <|
                fromList
                    [ Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    , Node Or <|
                        fromList
                            [ Node And <|
                                fromList
                                    [ Leaf
                                        { inclusion = Include
                                        , minCount = 1
                                        , questionCode = Data.Id.fromString "q3"
                                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                        , suffixCodes = []
                                        }
                                    , Leaf
                                        { inclusion = Include
                                        , minCount = 1
                                        , questionCode = Data.Id.fromString "q3"
                                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                        , suffixCodes = []
                                        }
                                    ]
                            ]
                    ]
            , Node And <|
                fromList
                    [ Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    , Node Or <|
                        fromList
                            [ Node And <|
                                fromList
                                    [ Leaf
                                        { inclusion = Include
                                        , minCount = 1
                                        , questionCode = Data.Id.fromString "q3"
                                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                        , suffixCodes = []
                                        }
                                    , Node And <|
                                        fromList
                                            [ Leaf
                                                { inclusion = Include
                                                , minCount = 1
                                                , questionCode = Data.Id.fromString "q3"
                                                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                                , suffixCodes = []
                                                }
                                            ]
                                    ]
                            ]
                    ]
            ]


complexOptimisedExpr : AudienceExpression
complexOptimisedExpr =
    Node And <|
        fromList
            [ Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "q2"
                , datapointCodes = [ Data.Id.fromString "q2_1" ]
                , suffixCodes = []
                }
            , Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "q3"
                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                , suffixCodes = []
                }
            , Node And <|
                fromList
                    [ Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    , Node And <|
                        fromList
                            [ Leaf
                                { inclusion = Include
                                , minCount = 1
                                , questionCode = Data.Id.fromString "q3"
                                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                , suffixCodes = []
                                }
                            , Leaf
                                { inclusion = Include
                                , minCount = 1
                                , questionCode = Data.Id.fromString "q3"
                                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                , suffixCodes = []
                                }
                            ]
                    ]
            , Node And <|
                fromList
                    [ Leaf
                        { inclusion = Include
                        , minCount = 1
                        , questionCode = Data.Id.fromString "q3"
                        , datapointCodes = [ Data.Id.fromString "q3_1" ]
                        , suffixCodes = []
                        }
                    , Node And <|
                        fromList
                            [ Leaf
                                { inclusion = Include
                                , minCount = 1
                                , questionCode = Data.Id.fromString "q3"
                                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                , suffixCodes = []
                                }
                            , Leaf
                                { inclusion = Include
                                , minCount = 1
                                , questionCode = Data.Id.fromString "q3"
                                , datapointCodes = [ Data.Id.fromString "q3_1" ]
                                , suffixCodes = []
                                }
                            ]
                    ]
            ]


leafNotOptimisedExpr : AudienceExpression
leafNotOptimisedExpr =
    Node And <|
        fromList
            [ Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "q2"
                , datapointCodes = [ Data.Id.fromString "q2_1" ]
                , suffixCodes = []
                }
            ]


leafOptimisedExpr : AudienceExpression
leafOptimisedExpr =
    Leaf
        { inclusion = Include
        , minCount = 1
        , questionCode = Data.Id.fromString "q2"
        , datapointCodes = [ Data.Id.fromString "q2_1" ]
        , suffixCodes = []
        }


optimiseTest : Test
optimiseTest =
    describe "Data.Audience.Expression.Optimiser.optimise"
        [ test "remove nesting when node contains only single child" <|
            \() ->
                Optimiser.optimise simpleNotOptimisedExpr
                    |> Expect.equal simpleOptimisedExpr
        , test "remove nesting when node contains only single child more nesting" <|
            \() ->
                Optimiser.optimise complexNotOptimisedExpr
                    |> Expect.equal complexOptimisedExpr
        , test "minimal expression example for optimise" <|
            \() ->
                Optimiser.optimise leafNotOptimisedExpr
                    |> Expect.equal leafOptimisedExpr
        ]
