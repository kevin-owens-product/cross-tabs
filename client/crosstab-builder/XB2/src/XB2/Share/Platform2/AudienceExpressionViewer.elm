module XB2.Share.Platform2.AudienceExpressionViewer exposing (view)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Keyed
import Json.Encode as Encode
import WeakCss exposing (ClassName)
import XB2.Data.Audience.Expression as Expression exposing (Expression)
import XB2.Share.Config exposing (Flags)
import XB2.Share.Config.Main exposing (Uri)


view : Flags -> ClassName -> Expression -> Html msg
view flags moduleClass expression =
    let
        uri : Uri
        uri =
            XB2.Share.Config.Main.get flags.env
                |> .uri

        apiEncoded =
            Encode.object
                [ ( "SERVICE_LAYER_HOST", Encode.string uri.serviceLayer ) ]

        userEncoded =
            Encode.object
                [ ( "token", Encode.string flags.token )
                , ( "email", Encode.string flags.user.email )
                ]

        encodedConfig =
            Encode.object
                [ ( "environment", Encode.string <| XB2.Share.Config.Main.stageToString flags.env )
                , ( "api", apiEncoded )
                , ( "user", userEncoded )
                ]
                |> Encode.encode 0

        encodedExpression =
            Expression.encode expression
                |> Encode.encode 0
    in
    Html.Keyed.node "x-et-audience-expression-viewer"
        [ Attrs.attribute "x-env-values" encodedConfig
        , Attrs.attribute "expression" encodedExpression
        , WeakCss.nest "expression-viewer" moduleClass
        ]
        []
