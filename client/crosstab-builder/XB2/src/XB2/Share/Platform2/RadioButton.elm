module XB2.Share.Platform2.RadioButton exposing (State(..), view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events.Extra as Events
import Html.Extra as Html
import Json.Encode
import WeakCss exposing (ClassName)


type State
    = Checked
    | Unchecked


view :
    { className : ClassName
    , groupName : String
    , value : String
    , label : String
    , msg : String -> msg
    , state : State
    , getInfo : Maybe String
    }
    -> Html msg
view { className, groupName, value, label, msg, state, getInfo } =
    let
        checkedOrDisabled : Attribute msg
        checkedOrDisabled =
            case state of
                Checked ->
                    Attrs.property "checked" <| Json.Encode.bool True

                Unchecked ->
                    Attrs.empty

        id =
            groupName ++ "_" ++ value
    in
    Html.span
        [ WeakCss.toClass className
        ]
        [ Html.input
            [ Attrs.id id
            , Attrs.name groupName
            , Attrs.type_ "radio"
            , Attrs.value value
            , checkedOrDisabled
            , Events.onChange msg
            ]
            []
        , Html.label
            [ Attrs.for id ]
            [ Html.span
                [ WeakCss.nest "label-text" className
                , Attrs.attribute "data-text" label
                ]
                [ Html.text label ]
            ]
        , getInfo
            |> Html.viewMaybe
                (Html.div [ WeakCss.nestMany [ "label-text", "info" ] className ]
                    << List.singleton
                    << Html.text
                )
        ]
