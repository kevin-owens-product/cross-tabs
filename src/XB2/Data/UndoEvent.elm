module XB2.Data.UndoEvent exposing
    ( UndoEvent(..)
    , label
    )


type UndoEvent
    = DeleteAudienceItems Int
    | DeleteAverageItem
    | AppendToAudienceItems Int
    | CreateAudienceItems Int
    | MergeAudienceItems
    | SwapAxes
    | MoveAudienceItem
    | ApplyBaseAudience
    | RemoveBaseAudience
    | ApplyLocationsSelection
    | ApplyWavesSelection
    | SetGroupTitle
    | SaveAsAudience
    | RemoveSelectedBaseAudiences
    | ResetDefaultBaseAudience
    | ResetSort
    | Sort
    | ResizeTableHeader
    | ReorderBaseAudiences


label : UndoEvent -> String
label event =
    case event of
        DeleteAudienceItems 1 ->
            "Delete single row/column"

        DeleteAverageItem ->
            "Delete average row/column"

        DeleteAudienceItems _ ->
            "Delete multiple rows/columns"

        AppendToAudienceItems 1 ->
            "Append to single row/column"

        AppendToAudienceItems _ ->
            "Append to multiple rows/columns"

        CreateAudienceItems 1 ->
            "Create single row/column"

        CreateAudienceItems _ ->
            "Create multiple rows/columns"

        SwapAxes ->
            "Swap axes"

        MoveAudienceItem ->
            "Move single row/column"

        MergeAudienceItems ->
            "Row/Column Merged"

        ApplyBaseAudience ->
            "Apply base"

        RemoveBaseAudience ->
            "Remove base"

        ApplyLocationsSelection ->
            "Apply location"

        ApplyWavesSelection ->
            "Apply waves"

        SetGroupTitle ->
            "Rename group"

        SaveAsAudience ->
            "Save in My Audience"

        RemoveSelectedBaseAudiences ->
            "Remove Selected Base Audiences"

        ResetDefaultBaseAudience ->
            "Reset Default Base Audience"

        ResetSort ->
            "Reset Sort"

        Sort ->
            "Sort"

        ResizeTableHeader ->
            "Resize Table Header"

        ReorderBaseAudiences ->
            "Reorder Base Audiences"
