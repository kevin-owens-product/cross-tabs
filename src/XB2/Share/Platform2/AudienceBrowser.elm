module XB2.Share.Platform2.AudienceBrowser exposing
    ( Config
    , clickedDisabledAudienceText
    , view
    )

import Dict.Any
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Set.Any
import XB2.Data.Namespace as Namespace
import XB2.Share.Config exposing (Flags)
import XB2.Share.Config.Main exposing (Uri)
import XB2.Share.Data.Id exposing (IdDict)
import XB2.Share.Data.Platform2
    exposing
        ( Audience
        , AudienceFolder
        , AudienceFolderIdTag
        , AudienceId
        , Dataset
        )
import XB2.Share.Data.User


type alias Config msg =
    -- msgs
    { toggleAudience : Audience -> msg
    , showDisabledWarning : msg
    , createAudience : msg
    , editAudience : AudienceId -> msg

    -- data
    , preexistingAudiences : List Audience
    , stagedAudiences : List Audience
    , isBase : Bool
    , setDecodingError : String -> msg
    , allDatasets : List Dataset
    , compatibleNamespaces : List Namespace.Code
    , appName : String
    , hideMyAudiencesTab : Bool
    }


view :
    Flags
    -> Config msg
    -> IdDict AudienceFolderIdTag AudienceFolder
    -> Html msg
view flags config audienceFolders =
    let
        uri : Uri
        uri =
            XB2.Share.Config.Main.get flags.env
                |> .uri

        apiEncoded =
            Encode.object
                [ ( "AUDIENCES_CORE_HOST", Encode.string uri.audiencesCore )
                , ( "SERVICE_LAYER_HOST", Encode.string uri.serviceLayer )
                , ( "ANALYTICS_HOST", Encode.string uri.analytics )
                , ( "API_ROOT_HOST", Encode.string uri.api )
                , ( "COLLECTIONS_HOST", Encode.string (uri.collections ++ "/") )
                ]

        userEncoded =
            Encode.object
                [ ( "token", Encode.string flags.token )
                , ( "email", Encode.string flags.user.email )
                , ( "customer_features", Set.Any.encode XB2.Share.Data.User.encodeFeature flags.user.customerFeatures )
                ]

        encodedConfig =
            Encode.object
                [ ( "appName", Encode.string config.appName )
                , ( "environment", Encode.string <| XB2.Share.Config.Main.stageToString flags.env )
                , ( "api", apiEncoded )
                , ( "user", userEncoded )
                ]
                |> Encode.encode 0

        toggleDecoder =
            Decode.at [ "detail", "payload" ] XB2.Share.Data.Platform2.audienceDecoder

        editDecoder =
            Decode.at [ "detail", "audienceId" ] XB2.Share.Data.Id.decode

        encodedStagedAudiences =
            config.stagedAudiences
                |> Encode.list (.id >> XB2.Share.Data.Id.encode)
                |> Encode.encode 0

        encodedSelectedAudiences =
            config.preexistingAudiences
                |> Encode.list (.id >> XB2.Share.Data.Id.encode)
                |> Encode.encode 0

        encodedModalType =
            (if config.isBase then
                "base"

             else
                "regular"
            )
                |> Encode.string
                |> Encode.encode 0

        encodedFolders =
            audienceFolders
                |> Dict.Any.values
                |> Encode.list XB2.Share.Data.Platform2.encodeAudienceFolder
                |> Encode.encode 0

        encodedAllDatasets =
            config.allDatasets
                |> Encode.list
                    (\dataset ->
                        Encode.list identity
                            [ XB2.Share.Data.Id.encode dataset.code
                            , XB2.Share.Data.Platform2.encodeDatasetForWebcomponent dataset
                            ]
                    )
                |> Encode.encode 0

        encodedCompatibleNamespaces =
            config.compatibleNamespaces
                |> Encode.list Namespace.encodeCode
                |> Encode.encode 0

        encodedHideMyAudiencesTab =
            config.hideMyAudiencesTab
                |> Encode.bool
                |> Encode.encode 0

        event eventName =
            config.appName ++ "-" ++ eventName
    in
    Html.node "x-et-audience-browser"
        [ Attrs.attribute "x-env-values" encodedConfig
        , Attrs.attribute "modal-type" encodedModalType
        , Attrs.attribute "staged-audiences" encodedStagedAudiences
        , Attrs.attribute "selected-audiences" encodedSelectedAudiences
        , Attrs.attribute "folders" encodedFolders
        , Attrs.attribute "all-datasets" encodedAllDatasets
        , Attrs.attribute "compatible-namespaces" encodedCompatibleNamespaces
        , Attrs.attribute "hide-my-audiences-tab" encodedHideMyAudiencesTab
        , Events.on (event "audienceBrowserLeftAudienceBuilderEditClicked")
            (Decode.value
                |> Decode.map
                    (\event_ ->
                        case Decode.decodeValue editDecoder event_ of
                            Ok decodedAudienceId ->
                                config.editAudience decodedAudienceId

                            Err err ->
                                config.setDecodingError <| Decode.errorToString err
                    )
            )
        , Events.on (event "audienceBrowserLeftToggledEvent")
            (Decode.value
                |> Decode.map
                    (\event_ ->
                        case Decode.decodeValue toggleDecoder event_ of
                            Ok decodedAudience ->
                                config.toggleAudience decodedAudience

                            Err err ->
                                config.setDecodingError <| Decode.errorToString err
                    )
            )
        , Events.on (event "audienceBrowserLeftDisabledAudienceClicked")
            (Decode.succeed config.showDisabledWarning)
        , Events.on (event "audienceBrowserLeftAudienceBuilderCreateClicked")
            (Decode.succeed config.createAudience)
        ]
        []


clickedDisabledAudienceText : String -> Html msg
clickedDisabledAudienceText entity =
    Html.text <| "Audience is not compatible with the data\u{00A0}set you have already selected in your " ++ entity
