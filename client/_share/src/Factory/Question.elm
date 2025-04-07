module Factory.Question exposing (mock)

import Data.Id
import Data.Labels exposing (Question)
import List.NonEmpty as NonemptyList


mock : Question
mock =
    { code = Data.Id.fromString ""
    , namespaceCode = Data.Id.fromString ""
    , name = ""
    , fullName = ""
    , categoryIds = []
    , datapoints =
        NonemptyList.singleton
            { code = Data.Id.fromString ""
            , name = ""
            , accessible = True
            , midpoint = Nothing
            , order = 1
            }
    , suffixes = Nothing
    , message = Nothing
    , locationCodes = []
    , accessible = True
    , notice = Nothing
    , averagesUnit = Nothing
    , warning = Nothing
    , knowledgeBase = Nothing
    }
