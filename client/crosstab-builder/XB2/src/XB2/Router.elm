module XB2.Router exposing
    ( Route(..)
    , getPrefix
    , getProjectId
    , parseUrl
    , toUrlString
    )

import Maybe.Extra as Maybe
import Url exposing (Url)
import Url.Builder as Url
import Url.Parser exposing ((</>), Parser, map, oneOf, s, string, top)
import XB2.Data exposing (XBProjectId)
import XB2.Share.Config exposing (Flags)
import XB2.Share.Data.Id


type Route
    = ProjectList
    | Project (Maybe XBProjectId)
    | ExternalUrl String


route : Parser (Route -> a) a
route =
    oneOf
        [ map (Project Nothing) <| s "new"
        , map (Project << Just << XB2.Share.Data.Id.fromString) string
        , map ProjectList top
        ]


getPrefix : Flags -> Maybe String
getPrefix { feature, pathPrefix } =
    case String.join "/" <| Maybe.values [ feature, pathPrefix ] of
        "" ->
            Nothing

        prefix ->
            Just prefix


toUrlString : Maybe String -> Route -> List Url.QueryParameter -> String
toUrlString prefix route_ =
    case route_ of
        ProjectList ->
            Url.absolute (Maybe.values [ prefix ])

        Project maybeId ->
            Url.absolute
                (Maybe.values [ prefix, Just <| Maybe.withDefault "new" <| Maybe.map XB2.Share.Data.Id.unwrap maybeId ])

        ExternalUrl url ->
            always url


parseUrl : Flags -> Url -> Maybe Route
parseUrl flags url =
    let
        namespaceRouter : String -> Parser b c -> Parser b c
        namespaceRouter str =
            String.split "/" str
                |> List.map ((</>) << s)
                |> List.foldl (>>) identity
    in
    Maybe.unwrap identity namespaceRouter (XB2.Share.Config.combinePrefixAndFeature flags)
        |> (\f -> Url.Parser.parse (f route) url)


getProjectId : Route -> Maybe XBProjectId
getProjectId route_ =
    case route_ of
        ProjectList ->
            Nothing

        Project id ->
            id

        ExternalUrl _ ->
            Nothing
