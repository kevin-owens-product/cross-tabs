module DragAndDrop.Fuzzer exposing (DDL, ddl)

import Fuzz


type alias DDL =
    { dragIndex : Int
    , dropIndex : Int
    , list : List Int
    }


ddl : Fuzz.Fuzzer DDL
ddl =
    Fuzz.intRange 1 30
        |> Fuzz.andThen
            (\n ->
                Fuzz.map3 DDL
                    (Fuzz.intRange 0 (n - 1))
                    (Fuzz.intRange 0 (n - 1))
                    (Fuzz.listOfLength n (Fuzz.intRange 0 5))
            )
