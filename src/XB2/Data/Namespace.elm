module XB2.Data.Namespace exposing
    ( Code(..)
    , StringifiedCode
    , codeDecoder
    , codeFromString
    , codeToString
    , coreCode
    , encodeCode
    )

{-| A module to handle everything related to _Namespaces_.

They are a group of questions and datapoints from a single study. This means that
_Locations_, _Waves_ and _Splitters_ are defined on the namespace level.

-}

import Json.Decode as Decode
import Json.Encode as Encode


stringifiedCoreCode : StringifiedCode
stringifiedCoreCode =
    "core"


coreCode : Code
coreCode =
    NamespaceCode stringifiedCoreCode


{-| An identifier for the _Namespace_.
Examples:

  - `"core"`
  - `"gwi-ext"`
  - `"gwi-mys-lno"`

It also common to see _Question_ codes coming with the _Namespace_ code as a prefix like
this:

  - `"q1_2"`
  - `"gwi-ext.q5530"`
  - `"gwi-mys-lno.q12"`

There are some special cases with the _Core_ _Namespace_ so we keep it as a separate to
ensure proper strictness.

-}
type Code
    = NamespaceCode StringifiedCode


type alias StringifiedCode =
    String


encodeCode : Code -> Encode.Value
encodeCode =
    codeToString >> Encode.string


{-| A Decoder for the `Code`.

JSON input example:

```json
"gwi-ext"
```

-}
codeDecoder : Decode.Decoder Code
codeDecoder =
    Decode.map NamespaceCode Decode.string


{-| Unwrap a `Code` into a unsafe `String`.
-}
codeToString : Code -> StringifiedCode
codeToString (NamespaceCode code) =
    code


{-| Covert a `String` into a _Code_. Takes in count the special `"core"` namespace code.

TODO: Little bit unsafe. Use a `Parser` for this. This function trusts the backend
absolutely in every case.

-}
codeFromString : String -> Code
codeFromString =
    NamespaceCode
