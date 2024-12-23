module XB2.Share.Factory.User exposing (withPlan)

import Time.Extra as Time
import XB2.Share.Data.User exposing (Plan, User, toFeatureSet)


withPlan : Plan -> User
withPlan plan =
    { id = "test"
    , email = "test@globalwebindex.net"
    , firstName = "John"
    , lastName = "Evil"
    , organisationId = Nothing
    , organisationName = Nothing
    , country = Nothing
    , city = Nothing
    , jobTitle = Nothing
    , planHandle = plan
    , customerFeatures = toFeatureSet []
    , industry = Nothing
    , sawOnboarding = True
    , lastPlatformUsed = XB2.Share.Data.User.Platform1
    , accessStart = Time.epoch
    }
