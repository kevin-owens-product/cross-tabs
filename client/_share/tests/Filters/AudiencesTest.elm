module Filters.AudiencesTest exposing (viewTest)

import Data.Audience.Expression as Expression
import Data.Core exposing (Audience, AudienceFolder)
import Data.Id
import Data.User
import Factory.Flags
import Filters.ActiveAudiences
import Filters.Audiences exposing (Msg(..))
import Filters.Features
import Html.Attributes
import RemoteData exposing (RemoteData(..))
import Store.Core
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time


viewTest : Test
viewTest =
    describe "Filters.Audiences.view"
        [ test "Editing folder name makes the new name visible" <|
            \() ->
                let
                    folder : AudienceFolder
                    folder =
                        { curated = False, id = Data.Id.fromString "643", name = "New Folder" }

                    audience : Audience
                    audience =
                        { id = Data.Id.fromString "666"
                        , name = "Hafo"
                        , created = Time.millisToPosix 0
                        , updated = Time.millisToPosix 0
                        , userId = 0
                        , expression = Expression.sizeExpression
                        , folderId = Just <| Data.Id.fromString "643"
                        , authored = True
                        , shared = False
                        , curated = False
                        }

                    flags =
                        Factory.Flags.withFeature Nothing

                    coreStore =
                        Store.Core.init
                in
                Filters.Audiences.init
                    |> Filters.Audiences.update config flags coreStore (EditFolder folder)
                    |> Tuple.first
                    |> Filters.Audiences.update config flags coreStore (ChangeFolderName "New Folderx")
                    |> Tuple.first
                    |> Filters.Audiences.view
                        config
                        Filters.Features.defaultFeatures
                        Data.User.Free
                        (always True)
                        (Success Data.Id.emptyDict)
                        (Success (Data.Id.dictFromList [ ( Data.Id.fromString "666", audience ) ]))
                        (Success (Data.Id.dictFromList [ ( Data.Id.fromString "643", folder ) ]))
                        Filters.ActiveAudiences.empty
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "filter-audiences__folders--folder--edit-name" ]
                    |> Query.has [ Selector.attribute (Html.Attributes.value "New Folderx") ]
        ]


config : Filters.Audiences.Config ()
config =
    { toggleAudience = \_ _ -> ()
    , activateIds = \_ -> ()
    , deactivateIds = \_ -> ()
    , baseAudience = \_ -> ()
    , createAudience = \_ _ -> ()
    , deleteAudiences = \_ -> ()
    , updateAudience = \_ -> ()
    , updateAudienceFolder = \_ -> ()
    , groupAudiences = \_ _ -> ()
    , msg = \_ -> ()
    , navigateToAB = \_ -> ()
    , trackAndNavigateToAB = \_ -> ()
    , upsellAction = \_ -> ()
    , audienceWithUnknownDataClicked = \_ _ -> ()
    , changeDragging = \_ -> ()
    }
