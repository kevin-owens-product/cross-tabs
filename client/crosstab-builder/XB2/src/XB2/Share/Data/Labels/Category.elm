module XB2.Share.Data.Labels.Category exposing (categoryPath)

import Basics.Extra exposing (flip)
import Dict.Any
import XB2.Share.Data.Id exposing (IdDict)
import XB2.Share.Data.Labels exposing (Category, CategoryIdTag)


categoryPath : Category -> IdDict CategoryIdTag Category -> List Category
categoryPath =
    let
        categoryPathInternal : List Category -> IdDict CategoryIdTag Category -> Category -> List Category
        categoryPathInternal path allCategories category =
            case category.parentId of
                Just parentId ->
                    let
                        currentPath =
                            category :: path
                    in
                    case Dict.Any.get parentId allCategories of
                        Nothing ->
                            currentPath

                        Just parent ->
                            categoryPathInternal currentPath allCategories parent

                Nothing ->
                    category :: path
    in
    flip (categoryPathInternal [])
