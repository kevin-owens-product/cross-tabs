module Factory.User exposing (withPlan)

import Data.User exposing (Plan, User, toFeatureSet)
import Time.Extra as Time


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
    , lastPlatformUsed = Data.User.Platform1
    , accessStart = Time.epoch
    }
