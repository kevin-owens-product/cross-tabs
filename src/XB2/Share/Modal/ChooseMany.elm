module XB2.Share.Modal.ChooseMany exposing (Config, Model, Msg, init, update, view)

import AssocSet as Set exposing (Set)
import Basics.Extra exposing (uncurry)
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Extra as Html
import WeakCss exposing (ClassName)
import XB2.Share.Gwi.AssocSet as Set
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Modal.CheckboxItemView as ItemView


type alias Model item =
    { items : List item
    , selected : Set item
    , originallySelected : Set item
    }


type alias Config item msg =
    { title : String
    , selectAllTitle : String
    , confirmButton : String
    , cancelButton : String
    , helpLink : Maybe String
    , msg : Msg item -> msg
    , close : msg
    , openUrl : String -> msg
    , confirm : Set item -> msg
    , getName : item -> String
    , getInfo : item -> Maybe String
    }


type Msg item
    = ToggleItem item
    | SelectAll


init : List item -> Set item -> Model item
init items selected =
    { items = items
    , originallySelected = selected
    , selected = selected
    }


update : Msg item -> Model item -> ( Model item, Cmd (Msg item) )
update msg model =
    case msg of
        ToggleItem toggledItem ->
            ( { model | selected = Set.toggle toggledItem model.selected }
            , Cmd.none
            )

        SelectAll ->
            ( { model | selected = Set.fromList model.items }
            , Cmd.none
            )


className : ClassName
className =
    WeakCss.namespace "share-modal-choose-many"


itemView : Config item msg -> ( Bool, item ) -> Html msg
itemView config =
    ItemView.view
        { getInfo = config.getInfo
        , getName = config.getName
        , toggleItem = config.msg << ToggleItem
        }
        className
        |> uncurry


view : Config item msg -> Model item -> Html msg
view ({ title, confirmButton, cancelButton, selectAllTitle, helpLink } as config) model =
    let
        allSelected =
            Set.size model.selected == List.length model.items

        edited =
            model.selected /= model.originallySelected

        confirmEnabled =
            edited && not (Set.isEmpty model.selected)
    in
    Html.div
        [ WeakCss.nest "container" className ]
        [ Html.div [ WeakCss.nest "overlay" className, Events.onClick config.close ] []
        , Html.div [ WeakCss.nest "modal" className ]
            [ Html.div
                [ WeakCss.nestMany [ "modal", "header" ] className ]
                [ Html.h2 [ WeakCss.nestMany [ "modal", "title" ] className ] [ Html.text title ]
                , Html.button
                    [ WeakCss.addMany [ "modal", "batch-action" ] className
                        |> WeakCss.withStates [ ( "disabled", allSelected ) ]
                    , Attrs.attributeIf (not allSelected) <| Events.onClick <| config.msg SelectAll
                    , Attrs.id "modal-metrics-reset-all"
                    ]
                    [ Html.text selectAllTitle
                    ]
                ]
            , model.items
                |> List.map (\item -> itemView config ( Set.member item model.selected, item ))
                |> Html.div [ WeakCss.nest "items" className ]
            , Html.footer [ WeakCss.nestMany [ "modal", "footer" ] className ]
                [ Html.viewMaybe
                    (\link ->
                        Html.a
                            [ WeakCss.nestMany [ "modal", "footer", "help-link" ] className
                            , Events.onClick <| config.openUrl link
                            ]
                            [ XB2.Share.Icons.icon [] P2Icons.help, Html.text "Help" ]
                    )
                    helpLink
                , Html.div [ WeakCss.nestMany [ "modal", "footer", "buttons" ] className ]
                    [ Html.button
                        [ WeakCss.nestMany [ "modal", "footer", "secondary-button" ] className
                        , Events.onClick config.close
                        ]
                        [ Html.text cancelButton ]
                    , Html.button
                        [ WeakCss.addMany [ "modal", "footer", "primary-button" ] className
                            |> WeakCss.withStates [ ( "disabled", not confirmEnabled ) ]
                        , Attrs.attributeIf confirmEnabled <| Events.onClick <| config.confirm model.selected
                        ]
                        [ Html.text confirmButton ]
                    ]
                ]
            ]
        ]
