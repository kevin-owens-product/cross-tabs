module XB2.Data.DeviceBasedUsage exposing
    ( DeviceBasedUsage(..)
    , decoder
    , encode
    , getDatasets
    , getQuestionCode
    )

import BiDict.Assoc exposing (BiDict)
import Dict.Any
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (WebData)
import XB2.Data.Dataset as Dataset
import XB2.Data.Namespace as Namespace
import XB2.Share.Data.Id
import XB2.Share.Data.Labels
    exposing
        ( NamespaceAndQuestionCode
        , NamespaceLineage
        )
import XB2.Share.Data.Platform2


type DeviceBasedUsage
    = DeviceBasedUsage NamespaceAndQuestionCode


encode : DeviceBasedUsage -> Value
encode (DeviceBasedUsage namespaceAndQuestionCode) =
    Encode.object
        [ ( "question", XB2.Share.Data.Id.encode namespaceAndQuestionCode ) ]


decoder : Decoder DeviceBasedUsage
decoder =
    Decode.succeed DeviceBasedUsage
        |> Decode.andMap (Decode.field "question" XB2.Share.Data.Id.decode)


getQuestionCode : DeviceBasedUsage -> NamespaceAndQuestionCode
getQuestionCode (DeviceBasedUsage namespaceAndQuestionCode) =
    namespaceAndQuestionCode


getDatasets :
    BiDict Dataset.Code Namespace.Code
    -> Dict.Any.AnyDict Namespace.StringifiedCode Namespace.Code (WebData NamespaceLineage)
    -> DeviceBasedUsage
    -> WebData (List Dataset.Code)
getDatasets datasetsToNamespaces lineages deviceBasedUsage =
    getQuestionCode deviceBasedUsage
        |> XB2.Share.Data.Labels.parseNamespaceCode
        |> List.singleton
        |> XB2.Share.Data.Platform2.datasetCodesForNamespaceCodes datasetsToNamespaces lineages
