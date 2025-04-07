module NoHugeModules exposing (defaults, rule)

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Module as Module exposing (Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


type alias Config =
    { moduleLengthThreshold : Int }


defaults : Config
defaults =
    { moduleLengthThreshold = 5000
    }


type alias Context =
    { linesOfCode : Int, moduleName : String, moduleNode : Maybe (Node ModuleName) }


rule : Config -> Rule
rule config =
    Rule.newModuleRuleSchema "NoHugeModules"
        { linesOfCode = 0
        , moduleName = ""
        , moduleNode = Nothing
        }
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation config)
        |> Rule.fromModuleRuleSchema


moduleDefinitionVisitor : Node Module -> Context -> ( List (Rule.Error {}), Context )
moduleDefinitionVisitor node context =
    ( []
    , { context
        | moduleName =
            Node.value node
                |> Module.moduleName
                |> String.join "."
        , moduleNode =
            Just <|
                case Node.value node of
                    NormalModule x ->
                        x.moduleName

                    PortModule x ->
                        x.moduleName

                    EffectModule x ->
                        x.moduleName
      }
    )


expressionVisitor : Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor node context =
    let
        lastRow =
            Node.range node
                |> (\{ end } -> end.row)
    in
    ( [], { context | linesOfCode = lastRow } )


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation config context =
    if context.linesOfCode > config.moduleLengthThreshold then
        Maybe.map
            (\node ->
                [ Rule.error
                    { message =
                        "Module "
                            ++ context.moduleName
                            ++ " is too big! It has "
                            ++ String.fromInt context.linesOfCode
                            ++ " lines of code! Modules are set to have a maximum of "
                            ++ String.fromInt config.moduleLengthThreshold
                            ++ " LOC."
                    , details =
                        [ "Big modules are harder to test and maintain, and are a good sign that this module has too many responsibilities."
                        , "Please, try to move the data structures & its related functions into their proper domain."
                        , "(See: https://en.wikipedia.org/wiki/Domain-driven_design)"
                        ]
                    }
                    (Node.range node)
                ]
            )
            context.moduleNode
            |> Maybe.withDefault []

    else
        []
