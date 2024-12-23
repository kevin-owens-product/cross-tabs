module XB2.Share.Palette exposing
    ( Palette
    , p2AvatarColorFromIndex
    )

import Array exposing (Array)


type alias Palette =
    Array String


cycledColor : Array a -> Int -> Result String a
cycledColor palette index =
    if Array.isEmpty palette then
        Err "Palette is empty"

    else
        let
            index_ =
                modBy (Array.length palette) index
        in
        case Array.get index_ palette of
            Just color_ ->
                Ok color_

            Nothing ->
                -- This shouldn't happen but our type system is not clever enough for that
                Err "Supposedly untriggerable error in Palette.color"


p2AvatarColorFromIndex : Int -> String
p2AvatarColorFromIndex index =
    cycledColor avatarsPalette index |> Result.withDefault "#fff"


avatarsPalette : Palette
avatarsPalette =
    Array.fromList
        [ "#963CBD"
        , "#008851"
        , "#007CB6"
        , "#DE1B76"
        ]
