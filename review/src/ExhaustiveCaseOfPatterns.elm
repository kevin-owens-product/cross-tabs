module ExhaustiveCaseOfPatterns exposing (rule)

import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Pattern exposing (Pattern(..))
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "ExhaustiveCaseOfPatterns" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.CaseExpression caseBlock ->
            let
                somePatternIsWildcard =
                    List.any
                        (\( patternNode, _ ) ->
                            case Node.value patternNode of
                                AllPattern ->
                                    True

                                _ ->
                                    False
                        )
                        caseBlock.cases
            in
            if somePatternIsWildcard then
                [ Rule.error
                    { message = "This case .. of expression does not exhaust all possible branches."
                    , details =
                        [ "Wildcard pattern is bug-prone, it's best to exhaust all the possible patterns in the case .. of expressions."
                        , "(See: https://github.com/NoRedInk/elm-style-guide?tab=readme-ov-file#casing)."
                        ]
                    }
                    (Node.range node)
                ]

            else
                []

        _ ->
            []
