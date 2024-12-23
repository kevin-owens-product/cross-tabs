module XB2.Share.Factory.Flags exposing (withFeature)

import XB2.Share.Config exposing (Flags)
import XB2.Share.Config.Main
import XB2.Share.Data.User
import XB2.Share.Factory.User


withFeature : Maybe String -> Flags
withFeature feature =
    { token = ""
    , user = XB2.Share.Factory.User.withPlan XB2.Share.Data.User.Free
    , env = XB2.Share.Config.Main.Testing
    , feature = Maybe.map ((++) "feature/") feature
    , pathPrefix = Nothing
    , can = always False
    , helpMode = False
    , supportChatVisible = False
    , revision = Nothing
    , referrer = XB2.Share.Config.OtherReferrer
    , platform2Url = ""
    }
