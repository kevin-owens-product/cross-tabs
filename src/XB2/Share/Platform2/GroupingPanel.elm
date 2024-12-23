module XB2.Share.Platform2.GroupingPanel exposing
    ( Config
    , ConfirmButton
    , Format(..)
    , GroupingControl
    , Item
    , ItemType(..)
    )

import Html exposing (Html)
import XB2.Share.Icons exposing (IconData)
import XB2.Share.Platform2.Grouping exposing (Grouping)


type Format
    = Plain
    | Bold


type ItemType
    = Attribute
    | AudienceMy
    | AudienceDefault
    | Average
    | Group


type alias ConfirmButton msg =
    { label : String
    , onClick : msg
    , disabled : Bool
    }


type alias Item item =
    { item : item
    , subtitle : Maybe String
    , title : String
    , type_ : ItemType
    }


type alias GroupingControl msg =
    { grouping : Grouping
    , disabled : Bool
    , onClick : msg
    }


type alias Config item msg =
    { title : String
    , placeholder : Int -> Maybe (List ( Format, String ))
    , placeholderIcon : IconData
    , activeGrouping : Grouping
    , isClearable : Bool
    , isLoading : Bool
    , warning : Maybe (Html msg)
    , groupings : List (GroupingControl msg)
    , items : List (Item item)
    , buttons : List (ConfirmButton msg)
    , clearAll : msg
    , clearItem : item -> msg
    }
