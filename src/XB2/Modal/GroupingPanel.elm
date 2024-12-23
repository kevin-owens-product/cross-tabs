module XB2.Modal.GroupingPanel exposing
    ( Config
    , ElementToFocus
    , ItemsForGrouping
    , itemsElementId
    , view
    )

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Json.Decode as Decode
import List.Extra as List
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import WeakCss exposing (ClassName)
import XB2.Data exposing (XBUserSettings)
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Platform2.Grouping as Grouping exposing (Grouping)
import XB2.Share.Platform2.GroupingPanel exposing (Format(..), Item, ItemType(..))


type alias ElementToFocus =
    Maybe String


type alias ItemsForGrouping item =
    { item : item, nextItem : item }


type alias GroupingState msg =
    { isSelected : Bool, isActive : Bool, action : msg, canGrouping : Bool }


type alias Config item msg =
    { config : XB2.Share.Platform2.GroupingPanel.Config item msg
    , noOp : msg
    , getDndForItem :
        Int
        -> Item item
        ->
            { dragEvents : List (Html.Attribute msg)
            , dropEvents : List (Html.Attribute msg)
            , dndStates : List ( String, Bool )
            , isDragged : Bool
            , htmlId : String
            }
    , renameItem : item -> ElementToFocus -> Maybe String -> msg
    , itemsBeingRenamed : List (Item item)
    , getItemChildren : item -> Maybe { children : NonEmpty (XB2.Share.Platform2.GroupingPanel.Item item), grouping : Grouping }
    , isAffixing : Bool
    , singleItemGroupings :
        List
            (ItemsForGrouping item
             ->
                { grouping : Grouping
                , disabled : Bool
                , onClick : msg
                }
            )
    , insideGroupGroupings :
        List
            (item
             ->
                { grouping : Grouping
                , disabled : Bool
                , onClick : msg
                }
            )
    , getItemDropdown : ClassName -> item -> Html msg
    , groupingWithState : item -> Maybe (GroupingState msg)
    , updateUserSettings : XBUserSettings -> msg
    , clearAttributeBrowser : msg
    , closeDropdown : msg
    }


itemsElementId : String
itemsElementId =
    "complex-grouping-panel--items-scroll-element-id"


buttonView :
    ClassName
    ->
        { label : String
        , onClick : msg
        , disabled : Bool
        }
    -> Html msg
buttonView moduleClass { label, onClick, disabled } =
    Html.button
        [ WeakCss.nest "button" moduleClass
        , Attrs.attributeIf (not disabled) <| Events.onClick onClick
        , Attrs.disabled disabled
        ]
        [ Html.text label ]


warningView : ClassName -> Html msg -> Html msg
warningView moduleClass warning =
    Html.div [ WeakCss.nest "warning" moduleClass ]
        [ Html.span [ WeakCss.nestMany [ "warning", "icon" ] moduleClass ]
            [ XB2.Share.Icons.icon [] P2Icons.warningTriangleIcon ]
        , warning
        ]


groupingView :
    ClassName
    -> { isActive : Grouping -> Bool }
    -> Config item msg
    -> XB2.Share.Platform2.GroupingPanel.GroupingControl msg
    -> Html msg
groupingView moduleClass { isActive } { config } { grouping, disabled, onClick } =
    let
        containsAverage =
            config.items |> List.any (.type_ >> (==) Average)
    in
    Html.button
        [ WeakCss.add "grouping" moduleClass
            |> WeakCss.withStates
                [ ( "active", isActive grouping )
                ]
        , Attrs.disabled disabled
        , Events.onClick onClick
        , Attrs.attributeIf (containsAverage && disabled) <| Attrs.attribute "tooltip-content" "Averages and attributes cannot be combined"
        ]
        [ Html.text <| Grouping.toString grouping ]


itemView :
    ClassName
    -> Config item msg
    -> Int
    -> Item item
    -> Html msg
itemView moduleClass config index ({ item, title, subtitle, type_ } as itm) =
    let
        { items } =
            config.config

        iconForGroupingState : { a | isSelected : Bool, isActive : Bool } -> XB2.Share.Icons.IconData
        iconForGroupingState { isSelected, isActive } =
            if isActive then
                P2Icons.group

            else if isSelected then
                P2Icons.checkboxFilled

            else
                P2Icons.checkboxUnfilled

        topLevelGroupingsView : () -> Html msg
        topLevelGroupingsView () =
            case List.getAt (index + 1) items of
                Just nextItem ->
                    Html.div
                        [ WeakCss.nest "item-operator" moduleClass ]
                        [ Html.div
                            [ WeakCss.addMany [ "item-operator", "groupings" ] moduleClass
                                |> WeakCss.withStates [ ( "is-affixing", config.isAffixing ) ]
                            ]
                            (List.map
                                (\itemGrouping ->
                                    groupingView (WeakCss.add "item-operator" moduleClass)
                                        { isActive = (==) config.config.activeGrouping }
                                        config
                                        (itemGrouping { item = item, nextItem = nextItem.item })
                                )
                                config.singleItemGroupings
                            )
                        ]

                Nothing ->
                    Html.nothing

        groupingsView : { isActive : Grouping -> Bool } -> ClassName -> Int -> item -> List (Item item) -> Html msg
        groupingsView isActive className index_ group items_ =
            case List.getAt (index_ + 1) items_ of
                Just _ ->
                    Html.div
                        [ WeakCss.nest "item-operator" className ]
                        [ Html.div
                            [ WeakCss.nestMany [ "item-operator", "groupings" ] className ]
                            (List.map
                                (\itemGrouping ->
                                    groupingView (WeakCss.add "item-operator" className)
                                        isActive
                                        config
                                        (itemGrouping group)
                                )
                                config.insideGroupGroupings
                            )
                        ]

                Nothing ->
                    Html.nothing

        itemStates : Maybe (GroupingState msg) -> List ( String, Bool )
        itemStates groupWithState =
            [ ( "active", Maybe.unwrap False .isActive groupWithState )
            , ( "selected", Maybe.unwrap False .isSelected groupWithState )
            , ( "clickable", Maybe.unwrap False (.isActive >> not) groupWithState )
            , ( "with-icon", Maybe.isJust groupWithState )
            ]

        itemsGroupView : Grouping -> item -> NonEmpty (Item item) -> { isParentActive : Bool, isParentDragged : Bool } -> Int -> Int -> Item item -> Html msg
        itemsGroupView grouping_ group items_ { isParentActive, isParentDragged } depth index_ item_ =
            let
                groupWithState : Maybe (GroupingState msg)
                groupWithState =
                    config.groupingWithState item_.item

                isThisGroupActive : Bool
                isThisGroupActive =
                    Maybe.unwrap False .isActive groupWithState || isParentActive

                ({ dragEvents, isDragged } as dndInfo) =
                    config.getDndForItem index_ item_

                ( dndStates, dropEvents ) =
                    if isParentDragged then
                        ( [ ( "parent-dragged", True ) ], [] )

                    else
                        ( dndInfo.dndStates, dndInfo.dropEvents )
            in
            case config.getItemChildren item_.item of
                Just { children, grouping } ->
                    let
                        firstLevel =
                            depth == 0
                    in
                    Html.div
                        [ WeakCss.nest "item-group-cont" moduleClass ]
                        [ Html.div
                            ([ WeakCss.add "item-group" moduleClass
                                |> WeakCss.withStates (( "active", isThisGroupActive ) :: dndStates)
                             , Attrs.id dndInfo.htmlId
                             ]
                                ++ dragEvents
                                ++ dropEvents
                            )
                            [ Html.viewIf firstLevel <|
                                case List.find ((==) item_) config.itemsBeingRenamed of
                                    Just it ->
                                        Html.input
                                            [ WeakCss.nestMany [ "item-group", "name", "input" ] moduleClass
                                            , Attrs.value it.title
                                            , Attrs.id <| dndInfo.htmlId ++ item_.title
                                            , Events.onInput (config.renameItem item_.item Nothing << Just)
                                            , Events.onBlur (config.renameItem item_.item Nothing Nothing)
                                            , Events.onEnter (config.renameItem item_.item Nothing Nothing)
                                            ]
                                            []

                                    Nothing ->
                                        Html.div [ WeakCss.nestMany [ "item-group", "name" ] moduleClass ]
                                            [ Html.div
                                                [ WeakCss.nestMany [ "item-group", "name", "icon" ] moduleClass
                                                , Events.onClick <| config.renameItem item_.item (Just <| dndInfo.htmlId ++ item_.title) <| Just item_.title
                                                ]
                                                [ XB2.Share.Icons.icon [] P2Icons.rename ]
                                            , Html.div
                                                [ WeakCss.nestMany [ "item-group", "name", "text" ] moduleClass ]
                                                [ Html.text item_.title ]
                                            ]
                            , Html.div [ WeakCss.nestMany [ "item-group", "children", "wrapper" ] moduleClass ]
                                [ Html.div [ WeakCss.nestMany [ "item-group", "children" ] moduleClass ]
                                    (NonemptyList.toList children
                                        |> List.indexedMap
                                            (itemsGroupView grouping
                                                item_.item
                                                children
                                                { isParentActive = isThisGroupActive, isParentDragged = isParentDragged || isDragged }
                                                (depth + 1)
                                            )
                                    )
                                ]
                            , Html.div [ WeakCss.nestMany [ "item-group", "dropdown" ] moduleClass ]
                                [ config.getItemDropdown (WeakCss.addMany [ "item-group", "item-row", "item" ] moduleClass) item_.item
                                ]
                            ]
                        , if item_ /= itm then
                            groupingsView { isActive = (==) grouping_ }
                                (WeakCss.addMany [ "item-group", "item-row" ] moduleClass)
                                index_
                                group
                                (NonemptyList.toList items_)

                          else
                            topLevelGroupingsView ()
                        ]

                Nothing ->
                    let
                        itemStates_ : List ( String, Bool )
                        itemStates_ =
                            if isThisGroupActive then
                                [ ( "active", isThisGroupActive ), ( "with-icon", True ) ]

                            else
                                itemStates groupWithState
                    in
                    Html.div [ WeakCss.nestMany [ "item-group", "item-row" ] moduleClass ]
                        [ Html.div
                            ([ WeakCss.addMany [ "item-group", "item-row", "item" ] moduleClass
                                |> WeakCss.withStates (itemStates_ ++ dndStates)
                             , Attrs.attributeIf (not isThisGroupActive) <|
                                Attrs.attributeMaybe (.action >> Events.onClick) (config.groupingWithState item_.item)
                             , Attrs.id dndInfo.htmlId
                             ]
                                ++ dragEvents
                                ++ dropEvents
                            )
                            [ Html.viewMaybe
                                (\state ->
                                    Html.div
                                        [ WeakCss.nestMany [ "item-group", "item-row", "item-icon" ] moduleClass ]
                                        [ XB2.Share.Icons.icon [] (iconForGroupingState { state | isActive = state.isActive || isThisGroupActive }) ]
                                )
                                groupWithState
                            , Html.div [ WeakCss.nestMany [ "item-group", "item-row", "item", "name" ] moduleClass ]
                                [ Html.text item_.title
                                ]
                            , config.getItemDropdown (WeakCss.addMany [ "item-group", "item-row", "item" ] moduleClass) item_.item
                            ]
                        , groupingsView { isActive = (==) grouping_ }
                            (WeakCss.addMany [ "item-group", "item-row" ] moduleClass)
                            index_
                            group
                            (NonemptyList.toList items_)
                        ]
    in
    case config.getItemChildren item of
        Just { children, grouping } ->
            itemsGroupView grouping item children { isParentActive = False, isParentDragged = False } 0 0 itm

        Nothing ->
            let
                groupWithState =
                    config.groupingWithState item

                { dndStates, dragEvents, dropEvents, htmlId } =
                    config.getDndForItem index itm
            in
            Html.div [ WeakCss.nest "item-row" moduleClass ]
                [ Html.div
                    ([ WeakCss.add "item" moduleClass
                        |> WeakCss.withStates
                            (itemStates groupWithState ++ dndStates)
                     , Attrs.attributeMaybe (.action >> Events.onClick) groupWithState
                     , Attrs.id htmlId
                     ]
                        ++ dragEvents
                        ++ dropEvents
                    )
                    [ Html.div
                        [ WeakCss.nest "item-icon" moduleClass ]
                        [ XB2.Share.Icons.icon [] <|
                            case groupWithState of
                                Just state ->
                                    if state.canGrouping then
                                        iconForGroupingState state

                                    else
                                        P2Icons.lock

                                Nothing ->
                                    case type_ of
                                        Attribute ->
                                            P2Icons.attribute

                                        AudienceMy ->
                                            P2Icons.audiences

                                        AudienceDefault ->
                                            P2Icons.audienceDefault

                                        Average ->
                                            P2Icons.average

                                        Group ->
                                            P2Icons.attribute
                        ]
                    , Html.div [ WeakCss.nest "names" moduleClass ]
                        [ subtitle
                            |> Html.viewMaybe
                                (\subt ->
                                    Html.div
                                        [ WeakCss.nestMany [ "names", "subtitle" ] moduleClass ]
                                        [ Html.text subt ]
                                )
                        , Html.div
                            [ WeakCss.addMany [ "names", "title" ] moduleClass
                                |> WeakCss.withStates [ ( "subtitle-only", subtitle == Nothing ) ]
                            ]
                            [ Html.text title ]
                        ]
                    , config.getItemDropdown (WeakCss.add "item-row" moduleClass) item
                    ]
                , topLevelGroupingsView ()
                ]


placeholderMessageView : ClassName -> List ( Format, String ) -> Html msg
placeholderMessageView moduleClass content =
    Html.div
        [ WeakCss.nest "placeholder-message" moduleClass ]
        (content
            |> List.map
                (\( format, string ) ->
                    Html.span
                        [ WeakCss.add "placeholder-text" moduleClass
                            |> WeakCss.withStates
                                [ ( "bold", format == Bold )
                                ]
                        ]
                        [ Html.text string ]
                )
        )


view : Config item msg -> ClassName -> Html msg
view ({ config } as cnf) moduleClass =
    let
        itemsCount : Int
        itemsCount =
            List.length config.items

        maybePlaceholder : Maybe (List ( Format, String ))
        maybePlaceholder =
            config.placeholder itemsCount

        placeholderView : Html msg
        placeholderView =
            case maybePlaceholder of
                Just placeholders ->
                    Html.div
                        [ WeakCss.nest "placeholder" moduleClass ]
                        [ Html.div
                            [ WeakCss.nest "placeholder-icon" moduleClass ]
                            [ XB2.Share.Icons.icon [] config.placeholderIcon
                            ]
                        , placeholderMessageView moduleClass placeholders
                        ]

                Nothing ->
                    Html.div [] []

        loadingStateView : () -> Html msg
        loadingStateView _ =
            Html.div []
                [ Html.i [ WeakCss.nest "loading-bar" moduleClass ] []
                , Html.div
                    [ WeakCss.nest "loading-state" moduleClass ]
                    [ XB2.Share.Icons.icon [] P2Icons.attribute
                    , Html.text "Attributes loading…"
                    ]
                ]

        itemsView : Html msg
        itemsView =
            Html.div
                [ WeakCss.nest "items" moduleClass
                , Events.on "scroll" (Decode.succeed cnf.closeDropdown)
                , Attrs.id itemsElementId
                ]
                (List.indexedMap (itemView moduleClass cnf) config.items)
    in
    Html.div
        [ WeakCss.toClass moduleClass ]
        [ Html.div
            [ WeakCss.nest "header" moduleClass ]
            [ Html.div
                [ WeakCss.nest "title" moduleClass ]
                [ Html.text config.title ]
            , Html.viewIf config.isClearable <|
                Html.button
                    [ WeakCss.nest "clear-all-btn" moduleClass
                    , Events.onClick config.clearAll
                    , Attrs.disabled (itemsCount <= 0)
                    ]
                    [ Html.text "Clear all" ]
            ]
        , Html.div
            [ WeakCss.nest "groupings-container" moduleClass ]
            [ Html.div [ WeakCss.nestMany [ "groupings-container", "info-icon", "wrapper" ] moduleClass ]
                [ Html.div
                    [ WeakCss.nestMany [ "groupings-container", "info-icon" ] moduleClass
                    , Attrs.attribute "tooltip-content" "Bulk set will apply the connection to everything below"
                    ]
                    [ XB2.Share.Icons.icon [] P2Icons.info ]
                ]
            , Html.text "Bulk set to:"
            , Html.div
                [ WeakCss.nest "groupings" moduleClass ]
                (List.map (groupingView moduleClass { isActive = (==) config.activeGrouping } cnf) config.groupings)
            ]
        , Html.viewIf (itemsCount > 0) itemsView
        , Html.viewIf (itemsCount == 0) placeholderView
        , Html.viewIfLazy config.isLoading loadingStateView
        , Html.viewMaybe (warningView moduleClass) config.warning
        , Html.div
            [ WeakCss.nest "buttons" moduleClass ]
            (List.map
                (buttonView moduleClass)
                config.buttons
            )
        ]
