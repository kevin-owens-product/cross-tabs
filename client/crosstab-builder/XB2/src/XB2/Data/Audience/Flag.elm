module XB2.Data.Audience.Flag exposing
    ( Flag(..)
    , StringifiedFlag
    , decoder
    , toString
    )

import Json.Decode as Decode


type Flag
    = -- Means that GWI shared the entity to others.
      CuratedAudience
      -- Means that the User owns the entity.
    | AuthoredAudience
      -- This flag indicates that the audience was created by P2 App.
    | IsP2Audience
      {- We use this constructor for forward compatibility with new flags. There's no
         `"unknown"` flag, this just wraps anything that does not fall into the previous
         three values. This way we can still convert them to `String` and encode in case
         backend does some tests.
      -}
    | UnknownFlag String


type alias StringifiedFlag =
    String


toString : Flag -> StringifiedFlag
toString flag =
    case flag of
        CuratedAudience ->
            "curated"

        AuthoredAudience ->
            "authored"

        IsP2Audience ->
            "isP2"

        UnknownFlag anotherFlag ->
            anotherFlag


fromString : String -> Flag
fromString string =
    case string of
        "curated" ->
            CuratedAudience

        "authored" ->
            AuthoredAudience

        "isP2" ->
            IsP2Audience

        anotherFlag ->
            UnknownFlag anotherFlag


decoder : Decode.Decoder Flag
decoder =
    Decode.map fromString Decode.string
