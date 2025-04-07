module XB2.Share.Factory.Question exposing (mock)

import List.NonEmpty as NonemptyList
import XB2.Data.Namespace as Namespace
import XB2.Share.Data.Id
import XB2.Share.Data.Labels exposing (Question)


mock : Question
mock =
    { code = XB2.Share.Data.Id.fromString ""
    , namespaceCode = Namespace.coreCode
    , name = ""
    , fullName = ""
    , categoryIds = []
    , datapoints =
        NonemptyList.singleton
            { code = XB2.Share.Data.Id.fromString ""
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
