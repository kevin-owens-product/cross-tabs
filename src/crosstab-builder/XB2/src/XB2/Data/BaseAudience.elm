module XB2.Data.BaseAudience exposing
    ( BaseAudience
    , default
    , fromAudienceItem
    , fromSavedProject
    , getCaption
    , getExpression
    , getId
    , getIdString
    , isDefault
    , namespaceCodes
    , setCaption
    , setExpression
    , setId
    , toBaseAudienceData
    , updateCaption
    )

import Random
import XB2.Data
    exposing
        ( AudienceDefinition(..)
        , BaseAudienceData
        )
import XB2.Data.Audience as Audience
import XB2.Data.Audience.Expression as Expression exposing (Expression)
import XB2.Data.AudienceItem as AudienceItem exposing (AudienceItem)
import XB2.Data.AudienceItemId as AudienceItemId exposing (AudienceItemId)
import XB2.Data.Caption as Caption exposing (Caption)
import XB2.Data.Namespace as Namespace


type BaseAudience
    = BaseAudience
        { id : AudienceItemId
        , caption : Caption
        , expression : Expression
        }


fromSavedProject : Random.Seed -> BaseAudienceData -> ( BaseAudience, Random.Seed )
fromSavedProject seed { id, name, subtitle, expression } =
    AudienceItemId.generateFromString id seed
        |> Tuple.mapFirst
            (\itemId ->
                BaseAudience
                    { id = itemId
                    , caption =
                        Caption.fromAudience
                            { audience = name
                            , parent =
                                if String.isEmpty subtitle then
                                    Nothing

                                else
                                    Just subtitle
                            }
                    , expression = expression
                    }
            )


setCaption : Caption -> BaseAudience -> BaseAudience
setCaption caption (BaseAudience data) =
    BaseAudience { data | caption = caption }


updateCaption : (Caption -> Caption) -> BaseAudience -> BaseAudience
updateCaption fn (BaseAudience data) =
    BaseAudience { data | caption = fn data.caption }


getExpression : BaseAudience -> Expression
getExpression (BaseAudience { expression }) =
    expression


setExpression : Expression -> BaseAudience -> BaseAudience
setExpression expression (BaseAudience data) =
    BaseAudience { data | expression = expression }


getId : BaseAudience -> AudienceItemId
getId (BaseAudience { id }) =
    id


getIdString : BaseAudience -> String
getIdString baseAudience =
    AudienceItemId.toString (getId baseAudience)


setId : BaseAudience -> AudienceItemId -> BaseAudience
setId (BaseAudience data) id =
    BaseAudience { data | id = id }


getCaption : BaseAudience -> Caption
getCaption (BaseAudience { caption }) =
    caption


default : BaseAudience
default =
    fromSavedProject
        (Random.initialSeed 0)
        { id = AudienceItemId.totalString
        , name = Audience.defaultName
        , fullName = Audience.defaultName
        , subtitle = "Audience Size"
        , expression = Expression.sizeExpression
        }
        |> Tuple.first


isDefault : BaseAudience -> Bool
isDefault baseAudience =
    (getExpression baseAudience == getExpression default)
        && (getCaption baseAudience == getCaption default)


fromAudienceItem : AudienceItem -> Maybe BaseAudience
fromAudienceItem item =
    case AudienceItem.getDefinition item of
        Expression expr ->
            Just <|
                BaseAudience
                    { id = AudienceItem.getId item
                    , caption = AudienceItem.getCaption item
                    , expression = expr
                    }

        Average _ ->
            Nothing

        DeviceBasedUsage _ ->
            Nothing


toBaseAudienceData : BaseAudience -> BaseAudienceData
toBaseAudienceData (BaseAudience data) =
    { id = AudienceItemId.toString data.id
    , name = Caption.getName data.caption
    , fullName = Caption.getFullName data.caption
    , subtitle = Maybe.withDefault "" <| Caption.getSubtitle data.caption
    , expression = data.expression
    }


namespaceCodes : BaseAudience -> List Namespace.Code
namespaceCodes (BaseAudience { expression }) =
    if expression == Expression.AllRespondents then
        [ Namespace.coreCode ]

    else
        Expression.getNamespaceCodes expression
