module Factory.Wave exposing (mock, withStartDate)

import Data.Id
import Data.Labels exposing (Wave, WaveKind(..), WaveQuarter(..))
import Time exposing (Month)
import Time.Extra as Time


mock : Wave
mock =
    { code = Data.Id.fromString ""
    , name = ""
    , accessible = False
    , kind = Quarter Q1
    , startDate = Time.millisToPosix 0
    , endDate = Time.millisToPosix 0
    }


withStartDate : ( Int, Month, Int ) -> Wave -> Wave
withStartDate startDate wave =
    { wave | startDate = Time.fromDateTuple Time.utc startDate }
