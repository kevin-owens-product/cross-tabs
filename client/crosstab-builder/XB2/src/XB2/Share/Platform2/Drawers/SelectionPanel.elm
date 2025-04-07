module XB2.Share.Platform2.Drawers.SelectionPanel exposing (DefaultConfig, DrawerType(..), LocationsShowingMode(..), Place(..), view)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Extra as Html
import List
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Set.Any exposing (AnySet)
import Time
import WeakCss exposing (ClassName)
import XB2.Share.CoolTip
import XB2.Share.CoolTip.Platform2 as P2CoolTip
import XB2.Share.Data.Id exposing (IdSet)
import XB2.Share.Data.Labels
    exposing
        ( Location
        , LocationCode
        , LocationCodeTag
        , Wave
        )
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Platform2.Bubble as Bubble


{-| As we find more and more differences, we can expand this type :)
-}
type Place
    = NotTVEdit


selectionInfoWavesView : ClassName -> { canEdit : Bool, notShowingNumbers : Bool } -> List Wave -> Html msg
selectionInfoWavesView cls { canEdit, notShowingNumbers } activeWaves =
    let
        names =
            activeWaves
                |> List.sortBy (.startDate >> Time.posixToMillis)
                |> List.map .name

        lockIcon =
            if canEdit then
                Nothing

            else
                P2CoolTip.view
                    { offset = Nothing
                    , type_ = XB2.Share.CoolTip.Normal
                    , position = XB2.Share.CoolTip.Bottom
                    , wrapperAttributes = []
                    , targetAttributes = []
                    , targetHtml =
                        [ Html.span
                            [ WeakCss.nestMany [ "selection-info", "locked" ] cls ]
                            [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.lock ]
                        ]
                    , tooltipAttributes = []
                    , tooltipHtml = Html.text "Waves can’t be changed"
                    }
                    |> Just
    in
    selectionInfoView cls notShowingNumbers names lockIcon <| Just <| List.length names


selectionInfoView : ClassName -> Bool -> List String -> Maybe (Html msg) -> Maybe Int -> Html msg
selectionInfoView cls notShowingNumbers activeItemsNames lockIcon activeItemsCount =
    Html.div
        [ WeakCss.nest "selection-info" cls
        ]
        [ Html.span
            [ WeakCss.nestMany [ "selection-info", "items" ] cls
            ]
            [ activeItemsNames
                |> String.join ", "
                |> Html.text
            ]
        , case lockIcon of
            Just lockIconHtml ->
                lockIconHtml

            Nothing ->
                Html.viewIf (not notShowingNumbers)
                    (activeItemsCount
                        |> Html.viewMaybe
                            (\count ->
                                Bubble.view
                                    (WeakCss.addMany [ "selection-info", "counter" ] cls)
                                    (String.fromInt count)
                            )
                    )
        ]


selectionInfoLocationsView : ClassName -> { canEdit : Bool, notShowingNumbers : Bool, locationsShowingMode : LocationsShowingMode } -> Place -> List Location -> IdSet LocationCodeTag -> Html msg
selectionInfoLocationsView cls { canEdit, notShowingNumbers, locationsShowingMode } _ activeLocations setOfAllLocationCodes =
    let
        newActiveLocations =
            case locationsShowingMode of
                ShowByComparison ->
                    if
                        Set.Any.equal
                            (activeLocations |> List.map .code |> XB2.Share.Data.Id.setFromList)
                            setOfAllLocationCodes
                    then
                        [ "All" ]

                    else
                        List.map .name activeLocations

        lockIcon =
            if canEdit then
                Nothing

            else
                P2CoolTip.view
                    { offset = Nothing
                    , type_ = XB2.Share.CoolTip.Normal
                    , position = XB2.Share.CoolTip.Bottom
                    , wrapperAttributes = []
                    , targetAttributes = []
                    , targetHtml =
                        [ Html.span
                            [ WeakCss.nestMany [ "selection-info", "locked" ] cls ]
                            [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.lock ]
                        ]
                    , tooltipAttributes = []
                    , tooltipHtml = Html.text "Locations can’t be changed"
                    }
                    |> Just
    in
    selectionInfoView cls notShowingNumbers newActiveLocations lockIcon <| Just <| List.length activeLocations


type alias DefaultConfig msg a =
    { a | openDrawer : msg }


type LocationsShowingMode
    = ShowByComparison


type DrawerType msg
    = LocationsDrawer
        (DefaultConfig
            msg
            { activeLocations : List Location
            , allLocations : AnySet String LocationCode
            , canEdit : Bool
            , notShowingNumbers : Bool
            , disabledTooltip : Maybe String
            , locationsShowingMode : LocationsShowingMode
            }
        )
    | WavesDrawer
        (DefaultConfig
            msg
            { activeWaves : List Wave
            , canEdit : Bool
            , notShowingNumbers : Bool
            , disabledTooltip : Maybe String
            }
        )


view : ClassName -> Place -> NonEmpty (DrawerType msg) -> Html msg
view moduleClass place drawers =
    let
        iconView iconData =
            Html.span [ WeakCss.nest "icon" moduleClass ]
                [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] iconData
                ]

        containerView { locked } lockedTooltip openDrawer =
            Html.button
                [ WeakCss.add "container" moduleClass
                    |> WeakCss.withStates
                        [ ( "locked", locked )
                        ]
                , Attrs.attributeIf locked <| Attrs.attributeMaybe (Attrs.attribute "data-title") lockedTooltip
                , Attrs.attributeIf (not locked) <| Events.onClick openDrawer
                , Attrs.disabled locked
                ]
    in
    NonemptyList.toList drawers
        |> List.map
            (\drawer ->
                case drawer of
                    LocationsDrawer { openDrawer, canEdit, notShowingNumbers, disabledTooltip, activeLocations, allLocations, locationsShowingMode } ->
                        containerView { locked = not canEdit }
                            disabledTooltip
                            openDrawer
                            [ iconView P2Icons.locations
                            , Html.span
                                [ WeakCss.nest "label" moduleClass ]
                                [ Html.text "Locations" ]
                            , selectionInfoLocationsView
                                moduleClass
                                { canEdit = canEdit, notShowingNumbers = notShowingNumbers, locationsShowingMode = locationsShowingMode }
                                place
                                activeLocations
                                allLocations
                            ]

                    WavesDrawer { openDrawer, canEdit, notShowingNumbers, disabledTooltip, activeWaves } ->
                        containerView { locked = not canEdit }
                            disabledTooltip
                            openDrawer
                            [ iconView P2Icons.waves
                            , Html.span
                                [ WeakCss.nest "label" moduleClass ]
                                [ Html.text "Waves" ]
                            , selectionInfoWavesView
                                moduleClass
                                { canEdit = canEdit, notShowingNumbers = notShowingNumbers }
                                activeWaves
                            ]
            )
        |> Html.div [ WeakCss.toClass moduleClass ]
