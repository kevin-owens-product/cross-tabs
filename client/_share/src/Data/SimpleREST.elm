module Data.SimpleREST exposing
    ( Action(..)
    , simpleRoutes
    )


type Action
    = Create
    | Fetch String



-- Constructors


simpleRoutes : String -> String -> Action -> String
simpleRoutes host name action =
    let
        collection name_ =
            host ++ "/" ++ name_

        single name_ id =
            collection name_ ++ "/" ++ id
    in
    case action of
        Create ->
            collection name

        Fetch id ->
            single name id



-- Actions
