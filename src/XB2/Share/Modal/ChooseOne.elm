module XB2.Share.Modal.ChooseOne exposing (Config, Model, Msg, init, update, view)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Extra as Html
import WeakCss exposing (ClassName)
import XB2.Detail.Heatmap as Heatmap exposing (Color(..))
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Platform2.RadioButton as P2RadioButton


type alias Model item =
    { items : List item
    , selectedItem : Maybe item
    , edited : Bool
    }


type alias Config item msg =
    { title : String
    , confirmButton : String
    , cancelButton : String
    , resetButtonTitle : String
    , helpLink : Maybe String
    , msg : Msg item -> msg
    , close : msg
    , openUrl : String -> msg
    , confirm : Maybe item -> msg
    , getName : item -> String
    , getInfo : item -> Maybe String
    }


type Msg item
    = ToggleItem item
    | ResetSelection


init : List item -> Maybe item -> Model item
init items selectedItem =
    { items = items
    , selectedItem = selectedItem
    , edited = False
    }


setEdited : Bool -> Model item -> Model item
setEdited edited model =
    { model | edited = edited }


update : Msg item -> Model item -> ( Model item, Cmd (Msg item) )
update msg model =
    case msg of
        ToggleItem item ->
            let
                checkedModel =
                    if List.member item model.items then
                        let
                            toggledModel =
                                if model.selectedItem == Just item then
                                    { model | selectedItem = Nothing }

                                else
                                    { model | selectedItem = Just item }
                        in
                        setEdited True toggledModel

                    else
                        model
            in
            ( checkedModel
            , Cmd.none
            )

        ResetSelection ->
            ( { model | selectedItem = Nothing, edited = True }
            , Cmd.none
            )


className : ClassName
className =
    WeakCss.namespace "share-modal-choose-one"


itemView : Config item msg -> Bool -> item -> Html msg
itemView config isSelected item =
    P2RadioButton.view
        { groupName = "heatmap-options"
        , value = config.getName item
        , className = WeakCss.addMany [ "radio-button-cont", "radio-button" ] className
        , msg = always <| config.msg <| ToggleItem item
        , label = config.getName item
        , getInfo = config.getInfo item
        , state =
            if isSelected then
                P2RadioButton.Checked

            else
                P2RadioButton.Unchecked
        }


isItemSelected : Maybe item -> item -> Bool
isItemSelected maybeSelected item =
    maybeSelected == Just item


view : Config item msg -> Model item -> Html msg
view ({ title, confirmButton, cancelButton, resetButtonTitle, helpLink } as config) { items, edited, selectedItem } =
    Html.div
        [ WeakCss.nest "container" className
        ]
        [ Html.div
            [ WeakCss.nest "overlay" className
            , Events.onClick config.close
            ]
            []
        , Html.div [ WeakCss.nest "modal" className ]
            [ Html.div []
                [ Html.header [ WeakCss.nestMany [ "modal", "header" ] className ]
                    [ Html.h2 [ WeakCss.nestMany [ "modal", "title" ] className ] [ Html.text title ]
                    , Html.button
                        [ WeakCss.addMany [ "modal", "batch-action" ] className
                            |> WeakCss.withStates [ ( "disabled", selectedItem == Nothing ) ]
                        , Attrs.attributeIf (selectedItem /= Nothing) <| Events.onClick <| config.msg ResetSelection
                        , Attrs.id "modal-heatmap-reset-all-button"
                        ]
                        [ Html.text resetButtonTitle
                        ]
                    ]
                ]
            , Html.div [ WeakCss.nestMany [ "modal", "legend" ] className ]
                [ Html.div [ WeakCss.nestMany [ "modal", "legend", "colors" ] className ]
                    ([ Red500
                     , Red400
                     , Red300
                     , Red200
                     , Red100
                     , NoColor
                     , Green100
                     , Green200
                     , Green300
                     , Green400
                     , Green500
                     ]
                        |> List.map
                            (\color ->
                                Html.div
                                    [ WeakCss.nestMany [ "modal", "legend", "colors", "color" ] className
                                    , Attrs.style "background-color" (Heatmap.colorToHex color)
                                    ]
                                    []
                            )
                    )
                , Html.div [ WeakCss.nestMany [ "modal", "legend", "labels" ] className ]
                    [ Html.span [] [ Html.text "Low value" ]
                    , Html.span [] [ Html.text "High value" ]
                    ]
                ]
            , items
                |> List.map (\item -> itemView config (isItemSelected selectedItem item) item)
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
                            |> WeakCss.withStates [ ( "disabled", not edited ) ]
                        , Attrs.attributeIf edited <| Events.onClick <| config.confirm selectedItem
                        ]
                        [ Html.text confirmButton ]
                    ]
                ]
            ]
        ]
