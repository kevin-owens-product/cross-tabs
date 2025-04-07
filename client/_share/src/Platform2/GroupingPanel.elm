module Platform2.GroupingPanel exposing
    ( Config
    , ConfirmButton
    , Format(..)
    , GroupingControl
    , Item
    , ItemType(..)
    , view
    )

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Extra as Html
import Icons exposing (IconData)
import Icons.Platform2 as P2Icons
import Maybe.Extra as Maybe
import Platform2.Grouping as Grouping exposing (Grouping)
import WeakCss exposing (ClassName)


type Format
    = Plain
    | Bold


type ItemType
    = AudienceMy
    | AudienceDefault


type alias ConfirmButton msg =
    { label : String
    , onClick : msg
    , disabled : Bool
    }


type alias Item item =
    { item : item
    , subtitle : Maybe String
    , title : String
    , type_ : ItemType
    }


type alias GroupingControl msg =
    { grouping : Grouping
    , disabled : Bool
    , onClick : msg
    }


type alias Config item msg =
    { title : String
    , placeholder : Int -> Maybe (List ( Format, String ))
    , placeholderIcon : IconData
    , activeGrouping : Grouping
    , isClearable : Bool
    , isLoading : Bool
    , warning : Maybe (Html msg)
    , groupings : List (GroupingControl msg)
    , items : List (Item item)
    , buttons : List (ConfirmButton msg)
    , clearAll : msg
    , clearItem : item -> msg
    }


view : ClassName -> Config item msg -> Html msg
view moduleClass config =
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
                            [ Icons.icon [] config.placeholderIcon
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
                    [ Icons.icon [] P2Icons.attribute
                    , Html.text "Attributes loading…"
                    ]
                ]

        itemsView : Html msg
        itemsView =
            (if maybePlaceholder == Nothing then
                Html.div [ WeakCss.add "items" moduleClass |> WeakCss.withStates [ ( "full-height", maybePlaceholder == Nothing ) ] ]
                    << List.singleton
                    << Html.div
                        [ WeakCss.nestMany [ "items", "content-scroll" ] moduleClass ]

             else
                Html.div
                    [ WeakCss.add "items" moduleClass
                        |> WeakCss.withActiveStates [ "native-scroll" ]
                    ]
            )
                [ Html.div []
                    (List.indexedMap
                        (itemView
                            moduleClass
                            config.activeGrouping
                            config.clearItem
                            config.isClearable
                        )
                        config.items
                    )
                ]
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
            [ WeakCss.nest "groupings" moduleClass ]
            (List.map (groupingView moduleClass config) config.groupings)
        , Html.viewIf (itemsCount > 0) itemsView
        , placeholderView
        , Html.viewIfLazy config.isLoading loadingStateView
        , Html.viewMaybe (warningView moduleClass) config.warning
        , Html.div
            [ WeakCss.nest "buttons" moduleClass ]
            (List.map
                (buttonView moduleClass)
                config.buttons
            )
        ]


warningView : ClassName -> Html msg -> Html msg
warningView moduleClass warning =
    Html.div [ WeakCss.nest "warning" moduleClass ]
        [ Html.span [ WeakCss.nestMany [ "warning", "icon" ] moduleClass ] [ Icons.icon [] P2Icons.warningTriangleIcon ]
        , warning
        ]


groupingView :
    ClassName
    -> Config item msg
    -> GroupingControl msg
    -> Html msg
groupingView moduleClass config { grouping, disabled, onClick } =
    let
        containsAverage =
            config.items |> List.any (.type_ >> always False)

        isActive =
            config.activeGrouping == grouping
    in
    Html.button
        [ WeakCss.add "grouping" moduleClass
            |> WeakCss.withStates
                [ ( "active", isActive )
                ]
        , Attrs.disabled disabled
        , Events.onClick onClick
        , Attrs.attributeIf (containsAverage && disabled) <| Attrs.attribute "tooltip-content" "Averages and attributes cannot be combined"
        ]
        [ Html.text <| Grouping.toString grouping ]


itemView :
    ClassName
    -> Grouping
    -> (item -> msg)
    -> Bool
    -> Int
    -> Item item
    -> Html msg
itemView moduleClass activeGrouping clearItem isClearable index { item, title, subtitle, type_ } =
    let
        icon =
            case type_ of
                AudienceMy ->
                    P2Icons.audiences

                AudienceDefault ->
                    P2Icons.audienceDefault
    in
    Html.div [ WeakCss.nest "item-row" moduleClass ]
        [ Grouping.groupingPanelItemLabel activeGrouping
            |> Maybe.filter (\_ -> index /= 0)
            |> Html.viewMaybe
                (\groupingLabel ->
                    Html.div
                        [ WeakCss.nest "item-operator" moduleClass ]
                        [ Html.text groupingLabel ]
                )
        , Html.div
            [ WeakCss.nest "item" moduleClass ]
            [ Html.div
                [ WeakCss.nest "item-icon" moduleClass ]
                [ Icons.icon [] icon
                ]
            , Html.div [ WeakCss.nest "names" moduleClass ]
                [ Html.viewIf (subtitle /= Nothing) <|
                    Html.div
                        [ WeakCss.nestMany [ "names", "subtitle" ] moduleClass ]
                        [ Html.text (subtitle |> Maybe.withDefault "") ]
                , Html.div
                    [ WeakCss.addMany [ "names", "title" ] moduleClass
                        |> WeakCss.withStates [ ( "subtitle-only", subtitle == Nothing ) ]
                    ]
                    [ Html.text title ]
                ]
            , Html.viewIf isClearable <|
                Html.div
                    [ WeakCss.nest "item-close-btn" moduleClass
                    , Events.onClick <| clearItem item
                    ]
                    [ Icons.icon
                        [ Icons.width 32, Icons.height 32 ]
                        P2Icons.cross
                    ]
            ]
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
