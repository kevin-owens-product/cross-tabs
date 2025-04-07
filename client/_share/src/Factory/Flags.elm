module Factory.Flags exposing (withFeature)

import Config exposing (Flags)
import Config.Main
import Data.User
import Factory.User


withFeature : Maybe String -> Flags
withFeature feature =
    { token = ""
    , user = Factory.User.withPlan Data.User.Free
    , env = Config.Main.Testing
    , feature = Maybe.map ((++) "feature/") feature
    , pathPrefix = Nothing
    , can = always False
    , helpMode = False
    , supportChatVisible = False
    , revision = Nothing
    , referrer = Config.OtherReferrer
    , platform2Url = ""
    }
