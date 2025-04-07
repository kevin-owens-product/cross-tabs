module NoHugeExpressions exposing (defaults, rule)

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


type alias Config =
    { expressionLengthThreshold : Int }


defaults : Config
defaults =
    { expressionLengthThreshold = 500 }


rule : Config -> Rule
rule config =
    Rule.newModuleRuleSchema "NoHugeExpressions" ()
        |> Rule.withSimpleExpressionVisitor (expressionVisitor config)
        |> Rule.fromModuleRuleSchema


expressionVisitor : Config -> Node Expression -> List (Error {})
expressionVisitor config node =
    let
        expressionLength =
            Node.range node
                |> (\{ start, end } -> end.row - start.row + 1)
    in
    if expressionLength > config.expressionLengthThreshold then
        [ Rule.error
            { message = "This expression is too long! Its definition takes up to " ++ String.fromInt expressionLength ++ " lines of code."
            , details = [ "Long definitions are harder to test and maintain, and increase cognitive complexity. Please, try to split the core steps of the definition into small portions." ]
            }
            (let
                { start, end } =
                    Node.range node
             in
             { start = start, end = { column = end.column, row = start.row + 3 } }
            )
        ]

    else
        []
