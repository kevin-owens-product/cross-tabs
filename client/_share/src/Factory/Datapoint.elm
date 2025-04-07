module Factory.Datapoint exposing
    ( accessible
    , inaccessible
    , mock
    , withCode
    , withName
    )

import Data.Id
import Data.Labels
    exposing
        ( Datapoint
        , QuestionAndDatapointCode
        )


mock : Datapoint
mock =
    { code = Data.Id.fromString ""
    , name = ""
    , accessible = True
    , midpoint = Nothing
    , order = 1
    }


withCode : QuestionAndDatapointCode -> Datapoint -> Datapoint
withCode code datapoint =
    { datapoint | code = code }


withName : String -> Datapoint -> Datapoint
withName name datapoint =
    { datapoint | name = name }


accessible : Datapoint -> Datapoint
accessible datapoint =
    { datapoint | accessible = True }


inaccessible : Datapoint -> Datapoint
inaccessible datapoint =
    { datapoint | accessible = False }
