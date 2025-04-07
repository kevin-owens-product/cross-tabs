module NoDecodeAtWithSingleField exposing (rule)

import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoDecodeAtWithSingleField" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.Application listNodeExpr ->
            case listNodeExpr of
                functionNode :: argNode :: _ ->
                    case ( Node.value functionNode, Node.value argNode ) of
                        ( FunctionOrValue moduleName functionName, ListExpr [ _ ] ) ->
                            {- Relying on import aliases being consistent - should be enforced by ConsistentImports rule -}
                            if List.member "Decode" moduleName && functionName == "at" then
                                [ Rule.error
                                    { message = "Json.Decode.at used with list with one element"
                                    , details = [ "Use Json.Decode.field \"field\" instead of Json.Decode.at [\"field\"]" ]
                                    }
                                    (Node.range node)
                                ]

                            else
                                []

                        _ ->
                            []

                _ ->
                    []

        _ ->
            []
