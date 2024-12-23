module XB2.Share.Platform2.AutocompleteInput exposing (Config, Model, Msg, init, update, view)

import Browser.Dom as Dom
import Cmd.Extra as Cmd
import Debouncer.Basic as Debouncer exposing (Debouncer)
import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Json.Decode as Decode exposing (Decoder)
import List.Extra as List
import Maybe.Extra as Maybe
import Process
import Task
import WeakCss exposing (ClassName)
import XB2.Share.Gwi.Browser.Dom as Dom
import XB2.Share.Gwi.Html.Events as Events
import XB2.Share.Gwi.Http exposing (Error, HttpCmd)
import XB2.Share.Icons exposing (IconData)
import XB2.Share.Icons.Platform2 as P2Icons


type alias Config msg item =
    -- @toLabel will be used to display information in the selected items
    { toLabel : item -> String

    -- @toOption will be used to display the suggestions inside the autocomplete options
    , toOption : item -> Int -> Html (Msg item)
    , msg : Msg item -> msg
    , moduleClass : ClassName
    , uniqueElementId : String
    , placeholder : String
    , icon : IconData
    , attributes : List (String -> Attribute msg)
    , disabled : Bool
    }


type alias Model item =
    { inputDebouncer : Debouncer (Msg item) (Msg item)
    , searchTerm : String
    , selectedItems : List item
    , suggestions : Maybe (List item)
    , selectionIndex : Int
    }


type Msg item
    = NoOp
    | OnInput { elementId : String } String
    | OnEnter { elementId : String }
    | FetchSuggestions { applyIfMatch : Bool } { elementId : String } String
    | SuggestionsLoaded { applyIfMatch : Bool } { elementId : String } String (Result (Error Never) (List item))
    | InputDebouncerMsg (Debouncer.Msg (Msg item))
    | SelectSuggestion String item
    | RemoveItemFromSelected String item
    | FocusInput String
    | CloseSuggestions
    | InputBlur String
    | ChangedIndex Int


init :
    { debounceSeconds : Float
    , selectedItems : List item
    }
    -> Model item
init config =
    { inputDebouncer = Debouncer.toDebouncer <| Debouncer.debounce <| Debouncer.fromSeconds config.debounceSeconds
    , searchTerm = ""
    , selectedItems = config.selectedItems
    , suggestions = Nothing
    , selectionIndex = 0
    }


processSuggestionResult : Result (Error Never) (List item) -> Model item -> Model item
processSuggestionResult result model =
    case result of
        Ok items ->
            { model | suggestions = Just items }

        Err _ ->
            model


update :
    { fetchSuggestions : String -> HttpCmd Never (List item)
    , toName : item -> String
    , validate : String -> HttpCmd Never (Maybe item)
    }
    -> Msg item
    -> Model item
    -> ( Model item, Cmd (Msg item) )
update config msg model =
    let
        getSuggestionsMatch : String -> Maybe (List item) -> Maybe item
        getSuggestionsMatch requestedString suggestions =
            suggestions
                |> Maybe.withDefault []
                |> List.find (config.toName >> (==) requestedString)
    in
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OnInput elementId string ->
            if model.searchTerm /= string then
                { model | searchTerm = string }
                    |> Cmd.withTrigger (InputDebouncerMsg <| Debouncer.provideInput <| FetchSuggestions { applyIfMatch = False } elementId string)

            else if String.isEmpty string then
                Cmd.pure { model | searchTerm = string, suggestions = Nothing }

            else
                Cmd.pure model

        OnEnter elementId ->
            case getSuggestionsMatch model.searchTerm model.suggestions of
                Just item ->
                    Cmd.withTrigger (SelectSuggestion elementId.elementId item) model

                Nothing ->
                    model
                        |> Cmd.with
                            (config.validate model.searchTerm
                                |> Cmd.map
                                    (Result.map (List.singleton >> Maybe.values)
                                        >> SuggestionsLoaded { applyIfMatch = True } elementId model.searchTerm
                                    )
                            )

        FetchSuggestions applyIfMatch elementId string ->
            let
                isInputValid : Bool
                isInputValid =
                    String.length string >= 3
            in
            if isInputValid then
                model
                    |> Cmd.with (config.fetchSuggestions string |> Cmd.map (SuggestionsLoaded applyIfMatch elementId string))

            else
                ( model, Cmd.none )

        SuggestionsLoaded { applyIfMatch } { elementId } requestedString result ->
            let
                selectItemIfMatch : Model item -> ( Model item, Cmd (Msg item) )
                selectItemIfMatch m =
                    if applyIfMatch then
                        getSuggestionsMatch requestedString m.suggestions
                            |> Maybe.unwrap (Cmd.pure m)
                                (\item ->
                                    m
                                        |> Cmd.withTrigger (SelectSuggestion elementId item)
                                )

                    else
                        Cmd.pure m
            in
            processSuggestionResult result model
                |> selectItemIfMatch

        InputDebouncerMsg subMsg ->
            let
                ( newDebouncer, debouncerCmd, emittedMsg ) =
                    Debouncer.update subMsg model.inputDebouncer

                command =
                    Cmd.map InputDebouncerMsg debouncerCmd

                newModel =
                    { model | inputDebouncer = newDebouncer }
            in
            case emittedMsg of
                Just emitted ->
                    update config emitted newModel |> Cmd.add command

                Nothing ->
                    ( newModel, command )

        SelectSuggestion elementId suggestion ->
            ( { model
                | selectedItems = model.selectedItems ++ [ suggestion ] |> List.unique
                , suggestions = Nothing
                , searchTerm = ""
              }
            , Task.attempt (always NoOp) <| Dom.focus elementId
            )

        RemoveItemFromSelected elementId item ->
            ( { model | selectedItems = List.filter ((/=) item) model.selectedItems }
            , Task.attempt (always NoOp) <| Dom.focus elementId
            )

        FocusInput elementId ->
            ( model, Task.attempt (always NoOp) <| Dom.focus elementId )

        InputBlur elementId ->
            ( model
            , Cmd.batch
                [ Process.sleep 500 |> Task.perform (always CloseSuggestions)
                , config.validate model.searchTerm
                    |> Cmd.map
                        (Result.map (List.singleton >> Maybe.values)
                            >> SuggestionsLoaded { applyIfMatch = True } { elementId = elementId } model.searchTerm
                        )
                ]
            )

        CloseSuggestions ->
            Cmd.pure
                { model
                    | suggestions = Nothing
                    , selectionIndex = 0
                    , inputDebouncer = Debouncer.cancel model.inputDebouncer
                }

        ChangedIndex newIndex ->
            ( { model | selectionIndex = newIndex }
            , Dom.scrollToIfNotVisible
                { scrollParentId = suggestionsElementId
                , elementId = getSuggestionItemElementId newIndex
                }
                |> Task.attempt (always NoOp)
            )


inputElementId : String
inputElementId =
    "autocomplete-input-module-input-element-id"


suggestionsElementId : String
suggestionsElementId =
    "autocomplete-input-suggestions"


getSuggestionItemElementId : Int -> String
getSuggestionItemElementId id =
    inputElementId ++ "-" ++ String.fromInt id


view : Config msg item -> Model item -> Html msg
view { msg, attributes, toLabel, toOption, moduleClass, uniqueElementId, placeholder, icon, disabled } model =
    let
        uniqueInputElementId =
            uniqueElementId ++ inputElementId

        suggestionsView suggestions =
            if List.isEmpty suggestions then
                Html.div
                    [ WeakCss.nestMany [ "container", "suggestions" ] moduleClass ]
                    [ Html.div [ WeakCss.nestMany [ "container", "suggestions", "no-results" ] moduleClass ]
                        [ Html.text "No results found" ]
                    ]

            else
                suggestions
                    |> List.indexedMap
                        (\index suggestion ->
                            Html.div
                                [ Events.onClickStopPropagation <| msg <| SelectSuggestion uniqueInputElementId suggestion
                                , WeakCss.addMany [ "container", "suggestions", "item" ] moduleClass
                                    |> WeakCss.withStates [ ( "selected", index == model.selectionIndex ) ]
                                , Attrs.id <| getSuggestionItemElementId index
                                ]
                                [ toOption suggestion index |> Html.map msg ]
                        )
                    |> Html.div
                        [ WeakCss.nestMany [ "container", "suggestions" ] moduleClass
                        , Attrs.id suggestionsElementId
                        ]

        isEmpty : Bool
        isEmpty =
            List.isEmpty model.selectedItems

        msgs : { changedIndex : Int -> msg, changedSelection : item -> msg }
        msgs =
            { changedIndex = ChangedIndex >> msg
            , changedSelection = \item -> SelectSuggestion (toLabel item) item |> msg
            }

        enterDcoder : m -> Decoder m
        enterDcoder m =
            Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        case key of
                            "Enter" ->
                                Decode.succeed m

                            _ ->
                                Decode.fail "Not the key we're interested in"
                    )

        selectedAndInputView =
            ((model.selectedItems
                |> List.map
                    (\item ->
                        Html.div [ WeakCss.nestMany [ "container", "selected-items", "item" ] moduleClass ]
                            [ Html.text <| toLabel item
                            , Html.button
                                [ WeakCss.nestMany [ "container", "selected-items", "item", "remove" ] moduleClass
                                , Attrs.disabled disabled
                                , Events.onClickStopPropagation <| RemoveItemFromSelected uniqueInputElementId item
                                ]
                                [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 29 ] P2Icons.cross
                                ]
                            ]
                            |> Html.map msg
                    )
             )
                ++ [ Html.input
                        ([ WeakCss.nestMany [ "container", "input" ] moduleClass
                         , Attrs.disabled disabled
                         , Attrs.attribute "autocomplete" "off"
                         , Events.onInput (msg << OnInput { elementId = uniqueInputElementId })
                         , Attrs.attributeIf (String.isEmpty model.searchTerm)
                            (List.last model.selectedItems
                                |> Attrs.attributeMaybe
                                    (Events.onBackspace << msg << RemoveItemFromSelected uniqueInputElementId)
                            )
                         , Events.onBlur <| msg <| InputBlur uniqueInputElementId
                         , Attrs.id uniqueInputElementId
                         , Attrs.value model.searchTerm
                         , Attrs.attributeIf isEmpty <| Attrs.placeholder placeholder
                         , Events.on "keyup" (enterDcoder <| msg <| OnEnter { elementId = uniqueInputElementId })
                         , onKeyDown msgs model.selectionIndex (Maybe.withDefault [] model.suggestions)
                         ]
                            ++ List.map ((|>) uniqueInputElementId) attributes
                        )
                        []
                   ]
            )
                |> Html.div [ WeakCss.nestMany [ "container", "selected-items" ] moduleClass ]
    in
    Html.div [ WeakCss.nest "container" moduleClass ]
        [ Html.div
            [ WeakCss.nestMany [ "container", "input-cont" ] moduleClass
            , Events.onClick <| msg <| FocusInput uniqueInputElementId
            ]
            [ Html.span
                [ WeakCss.nest "search-icon" moduleClass ]
                [ XB2.Share.Icons.icon [] icon ]
            , selectedAndInputView
            ]
        , Html.viewMaybe suggestionsView model.suggestions
        ]


onKeyDown :
    { r | changedIndex : Int -> msg, changedSelection : item -> msg }
    -> Int
    -> List item
    -> Attribute msg
onKeyDown msgs selectionIndex options =
    let
        newIndex operator =
            modBy (List.length options) (operator selectionIndex 1)
                |> msgs.changedIndex
                |> Decode.succeed

        isArrowKey keyName =
            case keyName of
                "ArrowDown" ->
                    newIndex (+)

                "ArrowUp" ->
                    newIndex (-)

                "Enter" ->
                    options
                        |> List.drop selectionIndex
                        |> List.head
                        |> Maybe.map (msgs.changedSelection >> Decode.succeed)
                        |> Maybe.withDefault (Decode.fail "invalid index")

                _ ->
                    Decode.fail "key not handled"
    in
    Decode.field "key" Decode.string
        |> Decode.andThen isArrowKey
        |> Events.on "keydown"
