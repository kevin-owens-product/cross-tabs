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
      -- Browser
    | BrowserGroupItemWithAnother
    | BrowserGroupItemWithOthers
    | BrowserInclusionOfItemToggled
    | BrowserItemToggled
    | BrowserAttributesAdded
    | BrowserAttributesToggled
    | BrowserClearedAll
    | BrowserToggledAverage
    | BrowserToggledDeviceBasedUsage
    | BrowserGroupingSelected
    | BrowserChangedGroupingForGroup
    | BrowserUngroupedItem
    | BrowserRenamedItems


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

        BrowserGroupItemWithAnother ->
            "Group item with another"

        BrowserGroupItemWithOthers ->
            "Group item with others"

        BrowserInclusionOfItemToggled ->
            "Inclusion of item toggled"

        BrowserItemToggled ->
            "Item toggled"

        BrowserAttributesAdded ->
            "Attributes added"

        BrowserAttributesToggled ->
            "Attributes toggled"

        BrowserClearedAll ->
            "Cleared all"

        BrowserToggledAverage ->
            "Toggled average"

        BrowserToggledDeviceBasedUsage ->
            "Toggled device-based usage"

        BrowserGroupingSelected ->
            "Grouping selected"

        BrowserChangedGroupingForGroup ->
            "Changed grouping for group"

        BrowserUngroupedItem ->
            "Ungrouped item"

        BrowserRenamedItems ->
            "Renamed items"
