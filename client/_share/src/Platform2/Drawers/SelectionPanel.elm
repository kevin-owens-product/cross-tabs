module Platform2.Drawers.SelectionPanel exposing (DefaultConfig, DrawerType(..), LocationsShowingMode(..), Place(..), view)

import CoolTip
import CoolTip.Platform2 as P2CoolTip
import Data.Id exposing (IdDict, IdSet)
import Data.Labels
    exposing
        ( Location
        , LocationCode
        , LocationCodeTag
        , Wave
        )
import Data.Platform2
    exposing
        ( TVChannel
        , TargetTimezone
        , Timezone
        , TimezoneCodeTag
        )
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Extra as Html
import Icons
import Icons.Platform2 as P2Icons
import List
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Platform2.Bubble as Bubble
import RemoteData exposing (WebData)
import Set.Any exposing (AnySet)
import Time
import WeakCss exposing (ClassName)


{-| As we find more and more differences, we can expand this type :)
-}
type Place
    = TVEdit
    | NotTVEdit


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
                    , type_ = CoolTip.Normal
                    , position = CoolTip.Bottom
                    , wrapperAttributes = []
                    , targetAttributes = []
                    , targetHtml =
                        [ Html.span
                            [ WeakCss.nestMany [ "selection-info", "locked" ] cls ]
                            [ Icons.icon [ Icons.width 32 ] P2Icons.lock ]
                        ]
                    , tooltipAttributes = []
                    , tooltipHtml = Html.text "Waves can’t be changed"
                    }
                    |> Just
    in
    selectionInfoView cls notShowingNumbers names lockIcon <| Just <| List.length names


selectionInfoTVChannelsView : ClassName -> Place -> List TVChannel -> Html msg
selectionInfoTVChannelsView cls place activeChannels =
    let
        names =
            if place == TVEdit && List.isEmpty activeChannels then
                [ "Please select your channel(s)" ]

            else
                activeChannels
                    |> List.sortBy .name
                    |> List.map .name
    in
    selectionInfoView cls False names Nothing <| Just <| List.length activeChannels


selectionInfoTimezoneView :
    ClassName
    -> WebData (IdDict TimezoneCodeTag Timezone)
    -> TargetTimezone
    -> Html msg
selectionInfoTimezoneView cls allTimezones activeTimezone =
    let
        activeTimezoneName : String
        activeTimezoneName =
            Data.Platform2.targetTimezoneLabel
                { local = "Local time zone"
                , standardized = identity
                }
                allTimezones
                activeTimezone
    in
    selectionInfoView cls False [ activeTimezoneName ] Nothing Nothing


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
selectionInfoLocationsView cls { canEdit, notShowingNumbers, locationsShowingMode } place activeLocations setOfAllLocationCodes =
    let
        newActiveLocations =
            if place == TVEdit && List.isEmpty activeLocations then
                [ "Please select your location(s)" ]

            else
                case locationsShowingMode of
                    ShowByComparison ->
                        if
                            Set.Any.equal
                                (activeLocations |> List.map .code |> Data.Id.setFromList)
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
                    , type_ = CoolTip.Normal
                    , position = CoolTip.Bottom
                    , wrapperAttributes = []
                    , targetAttributes = []
                    , targetHtml =
                        [ Html.span
                            [ WeakCss.nestMany [ "selection-info", "locked" ] cls ]
                            [ Icons.icon [ Icons.width 32 ] P2Icons.lock ]
                        ]
                    , tooltipAttributes = []
                    , tooltipHtml = Html.text "Locations can’t be changed"
                    }
                    |> Just
    in
    selectionInfoView cls notShowingNumbers newActiveLocations lockIcon <| Just <| List.length activeLocations


selectionInfoMinimumImpressionsView :
    ClassName
    -> { minimumImpressions : Int }
    -> Html msg
selectionInfoMinimumImpressionsView className { minimumImpressions } =
    selectionInfoView className False [ String.fromInt minimumImpressions ] Nothing Nothing


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
    | TVChannelsDrawer (DefaultConfig msg { activeChannels : List TVChannel })
    | TimezonesDrawer
        (DefaultConfig
            msg
            { allTimezones : WebData (IdDict TimezoneCodeTag Timezone)
            , activeTimezone : TargetTimezone
            }
        )
    | MinimumImpressionsDrawer (DefaultConfig msg { minimumImpressions : Int })


view : ClassName -> Place -> NonEmpty (DrawerType msg) -> Html msg
view moduleClass place drawers =
    let
        iconView iconData =
            Html.span [ WeakCss.nest "icon" moduleClass ]
                [ Icons.icon [ Icons.width 32 ] iconData
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

                    TVChannelsDrawer { openDrawer, activeChannels } ->
                        containerView { locked = False }
                            Nothing
                            openDrawer
                            [ iconView P2Icons.tv
                            , Html.span
                                [ WeakCss.nest "label" moduleClass ]
                                [ Html.text "Channels" ]
                            , selectionInfoTVChannelsView
                                moduleClass
                                place
                                activeChannels
                            ]

                    TimezonesDrawer { openDrawer, allTimezones, activeTimezone } ->
                        containerView { locked = False }
                            Nothing
                            openDrawer
                            [ iconView P2Icons.time
                            , Html.span
                                [ WeakCss.nest "label" moduleClass ]
                                [ Html.text "Time zone" ]
                            , selectionInfoTimezoneView
                                moduleClass
                                allTimezones
                                activeTimezone
                            ]

                    MinimumImpressionsDrawer { openDrawer, minimumImpressions } ->
                        containerView { locked = False }
                            Nothing
                            openDrawer
                            [ iconView P2Icons.eyeCircleTick
                            , Html.span
                                [ WeakCss.nest "label" moduleClass ]
                                [ Html.text "Minimum number of views" ]
                            , selectionInfoMinimumImpressionsView
                                moduleClass
                                { minimumImpressions = minimumImpressions }
                            ]
            )
        |> Html.div [ WeakCss.toClass moduleClass ]
