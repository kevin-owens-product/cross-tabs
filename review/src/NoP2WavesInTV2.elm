module NoP2WavesInTV2 exposing (rule)

{-| Make sure we use store.wavesByNamespace instead of store.waves in TV2.

To be used with <https://package.elm-lang.org/packages/jfmengels/elm-review/latest/>


# Rule

@docs rule

-}

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


{-| Make sure we use store.wavesByNamespace instead of store.waves in TV2.
If you want to use this rule, add it to `config : List Rule` in `review/ReviewConfig.elm`
-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoP2WavesInTV2" OutsideTV2
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type Context
    = InsideTV2
    | OutsideTV2


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor node _ =
    if List.member "TV2" (Node.value node |> Module.moduleName) then
        ( [], InsideTV2 )

    else
        ( [], OutsideTV2 )


expressionVisitor : Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor node context =
    case context of
        OutsideTV2 ->
            ( [], context )

        InsideTV2 ->
            case Node.value node of
                RecordAccess record accessor ->
                    let
                        record_ =
                            Node.value record

                        accessor_ =
                            Node.value accessor

                        err =
                            Rule.error
                                { message = "P2 store waves field accessed in TV2"
                                , details =
                                    [ "This is suspicious: TV2 doesn't use .waves, it instead uses .wavesByNamespace."
                                    , "Inside TV2 the p2Store.waves expression will most likely be NotAsked all the time because we don't ask for it."
                                    ]
                                }
                                (Node.range node)
                    in
                    case ( record_, accessor_ ) of
                        ( FunctionOrValue [] "store", "waves" ) ->
                            ( [ err ], context )

                        ( FunctionOrValue [] "p2Store", "waves" ) ->
                            ( [ err ], context )

                        ( FunctionOrValue [] "platform2Store", "waves" ) ->
                            ( [ err ], context )

                        _ ->
                            ( [], context )

                _ ->
                    ( [], context )
