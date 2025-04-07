module NoWeakCssWithConstantStates exposing (rule)

import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoWeakCssWithConstantStates" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.Application listNodeExpr ->
            case listNodeExpr of
                functionNode :: argNode :: _ ->
                    case ( Node.value functionNode, Node.value argNode ) of
                        ( FunctionOrValue moduleName functionName, ListExpr listElems ) ->
                            if List.member "WeakCss" moduleName && (functionName == "withStates") then
                                if List.isEmpty listElems then
                                    [ Rule.error
                                        { message = "WeakCss.withStates used with empty list of states"
                                        , details = [ "Use WeakCss.toClass / nest / nestMany instead" ]
                                        }
                                        (Node.range node)
                                    ]

                                else if allStatesHaveTrue listElems then
                                    [ Rule.error
                                        { message = "WeakCss.withStates used with always True states"
                                        , details = [ "Simplify WeakCss.withStates [ ( \"mystate\", True ) ] to WeakCss.withActiveStates [ \"mystate\" ]" ]
                                        }
                                        (Node.range node)
                                    ]

                                else
                                    []

                            else
                                []

                        _ ->
                            []

                _ ->
                    []

        _ ->
            []


{-| Return True when all elements in the list have the form ( whatever, True )
-}
allStatesHaveTrue : List (Node Expression) -> Bool
allStatesHaveTrue =
    List.all
        (\node ->
            case Node.value node of
                TupledExpression [ _, perhapsTrue ] ->
                    Node.value perhapsTrue == FunctionOrValue [] "True"

                _ ->
                    False
        )
