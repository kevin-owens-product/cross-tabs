module FewerFunctionArguments exposing
    ( rule
    , defaults
    )

{-| Some functions have too many arguments. This rule reports them based on the threshold
set in the configuration.

To be used with <https://package.elm-lang.org/packages/jfmengels/elm-review/latest/>


# Rule

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Review.Rule as Rule exposing (Rule)


defaults : Int
defaults =
    5


rule : Int -> Rule
rule maximumArgumentsAllowed =
    Rule.newModuleRuleSchema "FewerFunctionArguments" ()
        |> Rule.withSimpleDeclarationVisitor (declarationVisitor maximumArgumentsAllowed)
        |> Rule.fromModuleRuleSchema


errorMessageAndDetails :
    String
    -> Int
    -> Int
    ->
        { message : String
        , details : List String
        }
errorMessageAndDetails functionName numberOfArguments maximumArgumentsAllowed =
    { message =
        "`"
            ++ functionName
            ++ "` has "
            ++ String.fromInt numberOfArguments
            ++ " arguments, but the maximum is "
            ++ String.fromInt maximumArgumentsAllowed
            ++ "."
    , details =
        [ """
          If a function has too many arguments it can lead to confusion, especially if 
          two correlative arguments share the same type. Although it is cool to have the
          possibility of currying, if a function needs a lot of arguments then maybe you 
          should be using a record.
          """
        ]
    }


declarationVisitor : Int -> Node Declaration -> List (Rule.Error {})
declarationVisitor maximumArgumentsAllowed node =
    case Node.value node of
        Declaration.FunctionDeclaration { declaration } ->
            let
                functionImplementation =
                    Node.value declaration
            in
            if List.length functionImplementation.arguments > maximumArgumentsAllowed then
                [ Rule.error
                    (errorMessageAndDetails
                        (Node.value functionImplementation.name)
                        (List.length functionImplementation.arguments)
                        maximumArgumentsAllowed
                    )
                    (Node.range functionImplementation.name)
                ]

            else
                []

        _ ->
            []
