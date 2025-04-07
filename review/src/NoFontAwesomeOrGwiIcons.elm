module NoFontAwesomeOrGwiIcons exposing (rule)

{-| Make sure we no longer use any FontAwesome or GWI icons in Platform2.

To be used with <https://package.elm-lang.org/packages/jfmengels/elm-review/latest/>


# Rule

@docs rule

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoFontAwesomeOrGwiIcons" OutsidePlatform2
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withImportVisitor importVisitor
        |> Rule.fromModuleRuleSchema


type Context
    = InsidePlatform2
    | OutsidePlatform2


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor node _ =
    if [ "XB2", "TV2", "Dashboards2", "Platform2" ] |> List.any (\m -> List.member m (Node.value node |> Module.moduleName)) then
        ( [], InsidePlatform2 )

    else
        ( [], OutsidePlatform2 )


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor importNode context =
    case context of
        OutsidePlatform2 ->
            ( [], context )

        InsidePlatform2 ->
            case importNode |> Node.value |> .moduleName |> Node.value of
                [ "Icons", "FontAwesome" ] ->
                    ( [ Rule.error
                            { message = "Icons.FontAwesome should not be used inside Platform2."
                            , details =
                                [ "Please use Icons.Platform2 instead."
                                ]
                            }
                            (Node.range importNode)
                      ]
                    , context
                    )

                [ "Icons", "Gwi" ] ->
                    ( [ Rule.error
                            { message = "Icons.Gwi should not be used inside Platform2."
                            , details =
                                [ "Please use Icons.Platform2 instead."
                                ]
                            }
                            (Node.range importNode)
                      ]
                    , context
                    )

                _ ->
                    ( [], context )
