module DragAndDrop.Reorder exposing
    ( DropIndex, System, create, Msg
    , Config, config
    , freeMovement, horizontalMovement, verticalMovement
    , listenOnDrag, listenOnDrop
    , hookItemsBeforeListUpdate, hookCommandsOnReorderFinished
    , Info
    , Model
    , BeforeSort, DragElementId, DragIndex, DropElementId, moveItem
    )

{-|

@docs DropIndex, System, create, Msg

@docs Config, config

@docs freeMovement, horizontalMovement, verticalMovement
@docs listenOnDrag, listenOnDrop
@docs hookItemsBeforeListUpdate, hookCommandsOnReorderFinished

@docs Info
@docs Model

-}

import Browser.Dom
import Browser.Events
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Task



-- GENERAL


type alias DragIndex =
    Int


type alias DropIndex =
    Int


type alias DragElementId =
    String


type alias DropElementId =
    String


type alias Position =
    { x : Float
    , y : Float
    }



-- MODEL


type Model
    = Model (Maybe State)


type alias State =
    { dragIndex : DragIndex
    , dropIndex : DropIndex
    , dragElementId : DragElementId
    , dropElementId : DropElementId
    , dragElement : Maybe Browser.Dom.Element
    , dropElement : Maybe Browser.Dom.Element
    , startPosition : Position
    , currentPosition : Position
    , translateVector : Position
    , moveCounter : Int
    }



-- SYSTEM


type alias System msg item =
    { model : Model
    , subscriptions : Model -> Sub msg
    , update : Msg -> List item -> Model -> ( List item, Model, Cmd msg )
    , dragEvents : DragIndex -> DragElementId -> List (Html.Attribute msg)
    , dropEvents : DropIndex -> DropElementId -> List (Html.Attribute msg)
    , ghostStyles : Model -> List (Html.Attribute msg)
    , info : Model -> Maybe Info
    }


create : (Msg -> msg) -> Config msg item -> System msg item
create toMsg configuration =
    { model = Model Nothing
    , subscriptions = subscriptions toMsg
    , update = update configuration toMsg
    , dragEvents = dragEvents toMsg
    , dropEvents = dropEvents toMsg
    , ghostStyles = ghostStyles configuration
    , info = info
    }



-- CONFIG


type alias BeforeSort item =
    DragIndex -> DropIndex -> List item -> List item


type Movement
    = Free
    | Horizontal
    | Vertical


type Listen
    = OnDrag
    | OnDrop


type alias Options msg item =
    { movement : Movement
    , listen : Listen
    , hookItemsBeforeListUpdate : BeforeSort item
    , hookCommandsOnReorderFinished : Maybe (List item -> DropIndex -> msg)
    }


defaultOptions : Options msg item
defaultOptions =
    { movement = Free
    , listen = OnDrag
    , hookItemsBeforeListUpdate = \_ _ list -> list
    , hookCommandsOnReorderFinished = Nothing
    }


type Config msg item
    = Config (Options msg item)


config : Config msg item
config =
    Config defaultOptions



-- Movements


freeMovement : Config msg item -> Config msg item
freeMovement (Config options) =
    Config { options | movement = Free }


horizontalMovement : Config msg item -> Config msg item
horizontalMovement (Config options) =
    Config { options | movement = Horizontal }


verticalMovement : Config msg item -> Config msg item
verticalMovement (Config options) =
    Config { options | movement = Vertical }



-- Listen


listenOnDrag : Config msg item -> Config msg item
listenOnDrag (Config options) =
    Config { options | listen = OnDrag }


listenOnDrop : Config msg item -> Config msg item
listenOnDrop (Config options) =
    Config { options | listen = OnDrop }



-- Hooks


hookItemsBeforeListUpdate : BeforeSort item -> Config msg item -> Config msg item
hookItemsBeforeListUpdate handler (Config options) =
    Config { options | hookItemsBeforeListUpdate = handler }


hookCommandsOnReorderFinished : (List item -> DropIndex -> msg) -> Config msg item -> Config msg item
hookCommandsOnReorderFinished handler (Config options) =
    Config { options | hookCommandsOnReorderFinished = Just handler }



-- INFO


type alias Info =
    { dragIndex : DragIndex
    , dropIndex : DropIndex
    , dragElementId : DragElementId
    , dropElementId : DropElementId
    , dragElement : Browser.Dom.Element
    , dropElement : Browser.Dom.Element
    }


info : Model -> Maybe Info
info (Model model) =
    Maybe.andThen
        (\state ->
            Maybe.map2
                (\dragElement dropElement ->
                    { dragIndex = state.dragIndex
                    , dropIndex = state.dropIndex
                    , dragElementId = state.dragElementId
                    , dropElementId = state.dropElementId
                    , dragElement = dragElement
                    , dropElement = dropElement
                    }
                )
                state.dragElement
                state.dropElement
        )
        model



-- DECODERS


checkedPagePosition : Decode.Decoder Position
checkedPagePosition =
    checkMainMouseButtonPressed pagePosition


pagePosition : Decoder Position
pagePosition =
    Decode.map2 Position
        (Decode.field "pageX" Decode.float)
        (Decode.field "pageY" Decode.float)


checkMainMouseButtonPressed : Decoder a -> Decoder a
checkMainMouseButtonPressed decoder =
    Decode.field "button" Decode.int
        |> Decode.andThen
            (\button ->
                case button of
                    0 ->
                        decoder

                    _ ->
                        Decode.fail "Event is only relevant when the main mouse button was pressed."
            )



-- UPDATE


type StateMsg
    = MoveBrowser Position
    | OverDropItem DropIndex DropElementId
    | EnterDropItem
    | LeaveDropItem
    | GotDragItem (Result Browser.Dom.Error Browser.Dom.Element)
    | GotDropItem (Result Browser.Dom.Error Browser.Dom.Element)
    | Tick


type Msg
    = DownDragItem DragIndex DragElementId Position
    | StateMsg StateMsg
    | UpBrowser


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions toMsg (Model model) =
    case model of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Browser.Events.onMouseMove
                    (Decode.map (MoveBrowser >> StateMsg >> toMsg) pagePosition)
                , Browser.Events.onMouseUp
                    (Decode.succeed (UpBrowser |> toMsg))
                , Browser.Events.onAnimationFrameDelta (always Tick >> StateMsg >> toMsg)
                ]


{-| rotateLeft [1,2,3,4]
--> [2,3,4,1]
-}
rotateLeft : List item -> List item
rotateLeft list =
    case list of
        x :: xs ->
            xs ++ [ x ]

        [] ->
            []


rotate : Int -> Int -> List item -> List item
rotate i j list =
    let
        beginning : List item
        beginning =
            List.take i list

        middle : List item
        middle =
            list |> List.drop i |> List.take (j - i + 1)

        end : List item
        end =
            List.drop (j + 1) list
    in
    beginning ++ rotateLeft middle ++ end


moveItem : DragIndex -> DropIndex -> List item -> List item
moveItem dragIndex dropIndex list =
    if dragIndex < dropIndex then
        rotate dragIndex dropIndex list

    else if dragIndex > dropIndex then
        let
            n : Int
            n =
                List.length list - 1
        in
        List.reverse (rotate (n - dragIndex) (n - dropIndex) (List.reverse list))

    else
        list


updateState : Options msg item -> StateMsg -> List item -> State -> ( List item, State, Cmd Msg )
updateState options msg list state =
    case msg of
        MoveBrowser coordinates ->
            ( list
            , { state | currentPosition = coordinates, moveCounter = state.moveCounter + 1 }
            , case state.dragElement of
                Nothing ->
                    Task.attempt (GotDragItem >> StateMsg) (Browser.Dom.getElement state.dragElementId)

                _ ->
                    Cmd.none
            )

        OverDropItem dropIndex dropElementId ->
            ( list
            , { state | dropIndex = dropIndex, dropElementId = dropElementId }
            , Task.attempt (GotDropItem >> StateMsg) (Browser.Dom.getElement dropElementId)
            )

        EnterDropItem ->
            if state.moveCounter > 1 && state.dragIndex /= state.dropIndex then
                case options.listen of
                    OnDrag ->
                        ( list
                            |> options.hookItemsBeforeListUpdate state.dragIndex state.dropIndex
                            |> moveItem state.dragIndex state.dropIndex
                        , { state | dragIndex = state.dropIndex, moveCounter = 0 }
                        , Cmd.none
                        )

                    OnDrop ->
                        ( list, { state | moveCounter = 0 }, Cmd.none )

            else
                ( list, state, Cmd.none )

        LeaveDropItem ->
            ( list
            , { state | dropIndex = state.dragIndex }
            , Cmd.none
            )

        GotDragItem (Err _) ->
            ( list, state, Cmd.none )

        GotDragItem (Ok dragElement) ->
            ( list
            , { state | dragElement = Just dragElement, dropElement = Just dragElement }
            , Cmd.none
            )

        GotDropItem (Err _) ->
            ( list, state, Cmd.none )

        GotDropItem (Ok dropElement) ->
            ( list
            , { state | dropElement = Just dropElement }
            , Cmd.none
            )

        Tick ->
            ( list
            , { state
                | translateVector =
                    Position
                        (state.currentPosition.x - state.startPosition.x)
                        (state.currentPosition.y - state.startPosition.y)
              }
            , Cmd.none
            )


update : Config msg item -> (Msg -> msg) -> Msg -> List item -> Model -> ( List item, Model, Cmd msg )
update (Config options) toMsg msg list (Model model) =
    case ( msg, model ) of
        ( DownDragItem dragIndex dragElementId coordinates, _ ) ->
            ( list
            , Model <|
                Just
                    { dragIndex = dragIndex
                    , dropIndex = dragIndex
                    , dragElementId = dragElementId
                    , dropElementId = dragElementId
                    , dragElement = Nothing
                    , dropElement = Nothing
                    , startPosition = coordinates
                    , currentPosition = coordinates
                    , translateVector = Position 0 0
                    , moveCounter = 0
                    }
            , Cmd.none
            )

        ( StateMsg stateMsg, Just state ) ->
            let
                ( newList, newModel, cmds ) =
                    updateState options stateMsg list state
            in
            ( newList, Model (Just newModel), Cmd.map toMsg cmds )

        ( UpBrowser, Just state ) ->
            if state.dragIndex /= state.dropIndex && state.dragElementId /= state.dropElementId then
                case options.listen of
                    OnDrag ->
                        ( list, Model Nothing, Cmd.none )

                    OnDrop ->
                        let
                            newList : List item
                            newList =
                                list
                                    |> options.hookItemsBeforeListUpdate state.dragIndex state.dropIndex
                                    |> moveItem state.dragIndex state.dropIndex
                        in
                        ( newList
                        , Model Nothing
                        , options.hookCommandsOnReorderFinished
                            |> Maybe.map (\f -> Task.perform (f newList) (Task.succeed state.dropIndex))
                            |> Maybe.withDefault Cmd.none
                        )

            else
                ( list
                , Model Nothing
                , options.hookCommandsOnReorderFinished
                    |> Maybe.map (\f -> Task.perform (f list) (Task.succeed state.dropIndex))
                    |> Maybe.withDefault Cmd.none
                )

        ( _, Nothing ) ->
            ( list, Model model, Cmd.none )



-- EVENTS


dragEvents : (Msg -> msg) -> DragIndex -> DragElementId -> List (Html.Attribute msg)
dragEvents toMsg dragIndex dragElementId =
    [ Html.Events.preventDefaultOn "mousedown"
        (checkedPagePosition
            |> Decode.map (DownDragItem dragIndex dragElementId >> toMsg)
            |> Decode.map (\msg -> ( msg, True ))
        )
    ]


dropEvents : (Msg -> msg) -> DropIndex -> DropElementId -> List (Html.Attribute msg)
dropEvents toMsg dropIndex dropElementId =
    [ Html.Events.onMouseOver (OverDropItem dropIndex dropElementId |> StateMsg |> toMsg)
    , Html.Events.onMouseEnter (EnterDropItem |> StateMsg |> toMsg)
    , Html.Events.onMouseLeave (LeaveDropItem |> StateMsg |> toMsg)
    ]



-- STYLES


px : Int -> String
px n =
    String.fromInt n ++ "px"


translate : Int -> Int -> String
translate x y =
    "translate3d(" ++ px x ++ ", " ++ px y ++ ", 0)"


free : Position -> Browser.Dom.Element -> Html.Attribute msg
free { x, y } { element } =
    Html.Attributes.style "transform" <|
        translate
            (round (x + element.x))
            (round (y + element.y))


horizontal : Position -> Browser.Dom.Element -> Html.Attribute msg
horizontal { x } { element } =
    Html.Attributes.style "transform" <|
        translate
            (round (x + element.x))
            (round element.y)


vertical : Position -> Browser.Dom.Element -> Html.Attribute msg
vertical { y } { element } =
    Html.Attributes.style "transform" <|
        translate
            (round element.x)
            (round (y + element.y))


baseStyles : List (Html.Attribute msg)
baseStyles =
    [ Html.Attributes.style "pointer-events" "none"
    , Html.Attributes.style "position" "fixed"
    , Html.Attributes.style "left" "0"
    , Html.Attributes.style "top" "0"
    ]


ghostStyles : Config msg item -> Model -> List (Html.Attribute msg)
ghostStyles (Config options) (Model model) =
    Maybe.withDefault []
        (Maybe.andThen
            (\state ->
                Maybe.map
                    (\element ->
                        case options.movement of
                            Free ->
                                free state.translateVector element :: baseStyles

                            Horizontal ->
                                horizontal state.translateVector element :: baseStyles

                            Vertical ->
                                vertical state.translateVector element :: baseStyles
                    )
                    state.dragElement
            )
            model
        )
