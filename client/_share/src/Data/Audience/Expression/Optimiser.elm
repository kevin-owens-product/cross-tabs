module Data.Audience.Expression.Optimiser exposing (optimise)

import Data.Audience.Expression exposing (AudienceExpression(..))
import List.NonEmpty as NonemptyList


{-| Current optimisations:

  - AND [x] = x
  - OR [x] = x

Possible future optimisation (TODO):

  - all respondents AND x = x
  - all respondents OR x = all respondents
  - AND [] = all respondents
  - OR [] = all respondents

-}
optimise : AudienceExpression -> AudienceExpression
optimise =
    removeNodesWithSingleChild


{-| This optimisation is necessary for properly working expression in AB

  - when expression is created in XB in two steps like
      - Create single dtp expression
      - add one more single item group with OR logic but as AND for whole group

-}
removeNodesWithSingleChild : AudienceExpression -> AudienceExpression
removeNodesWithSingleChild expression =
    case expression of
        AllRespondents ->
            expression

        Leaf _ ->
            expression

        Node operator subnodes ->
            case NonemptyList.toList subnodes of
                [ singleExpr ] ->
                    removeNodesWithSingleChild singleExpr

                _ ->
                    Node operator <| NonemptyList.map removeNodesWithSingleChild subnodes
