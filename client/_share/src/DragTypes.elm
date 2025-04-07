module DragTypes exposing (Dragging(..), DropPlace(..))

import Data.Core exposing (Audience, AudienceFolderId, AudienceId)


type DropPlace
    = InvalidDropPlace
    | GroupAudiencesDropPlace AudienceId
    | AddToFolderDropPlace AudienceFolderId
    | UngroupAudienceDropPLace
    | BaseAudienceDropPlace


type Dragging
    = Dragging Audience DropPlace
