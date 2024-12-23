module XB2.Share.Factory.Wave exposing (mock)

import Time
import XB2.Share.Data.Id
import XB2.Share.Data.Labels exposing (Wave, WaveKind(..), WaveQuarter(..))


mock : Wave
mock =
    { code = XB2.Share.Data.Id.fromString ""
    , name = ""
    , accessible = False
    , kind = Quarter Q1
    , startDate = Time.millisToPosix 0
    , endDate = Time.millisToPosix 0
    }
