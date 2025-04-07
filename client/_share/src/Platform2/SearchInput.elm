module Platform2.SearchInput exposing
    ( Config
    , Model
    , Msg
    , initialModel
    , update
    , view
    )

import Browser.Dom
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Icons
import Icons.Platform2 as P2Icons
import Task
import WeakCss exposing (ClassName)


type alias Config msg =
    { baseClass : ClassName
    , placeholder : String
    , searchInputId : String
    , msg : Msg -> msg
    }


type alias Model =
    { searchTerm : String
    }


initialModel : Model
initialModel =
    { searchTerm = ""
    }


type Msg
    = UpdateSearchField String
    | Focus String
    | NoOp


view : Config msg -> Model -> Html msg
view config model =
    let
        searchClass =
            WeakCss.add "search" config.baseClass

        input =
            Html.input
                [ WeakCss.nest "input" searchClass
                , Attrs.placeholder config.placeholder
                , Attrs.value model.searchTerm
                , Attrs.id config.searchInputId
                , Attrs.autocomplete False
                , Events.onClick (config.msg (Focus config.searchInputId))
                , Events.onInput (config.msg << UpdateSearchField)
                ]
                []

        searchIcon =
            Html.div
                [ WeakCss.nest "search-icon" searchClass ]
                [ Icons.icon [] P2Icons.search
                ]

        isEmpty =
            String.length model.searchTerm == 0

        searchContent =
            if String.isEmpty model.searchTerm then
                [ searchIcon
                , input
                ]

            else
                let
                    crossIcon =
                        Html.div
                            [ WeakCss.nest "cross-icon" searchClass
                            , Events.onClick (config.msg resetSearchField)
                            ]
                            [ Icons.icon [] P2Icons.cross
                            ]
                in
                [ searchIcon
                , input
                , crossIcon
                ]
    in
    Html.div
        [ searchClass |> WeakCss.withStates [ ( "is-nonempty", not isEmpty ) ]
        ]
        searchContent


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateSearchField newSearchTerm ->
            ( { model | searchTerm = newSearchTerm }, Cmd.none )

        Focus elementId ->
            ( model, Browser.Dom.focus elementId |> Task.attempt (always NoOp) )


resetSearchField : Msg
resetSearchField =
    UpdateSearchField ""
