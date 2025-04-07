module XB2.Share.Data.Platform2.Export exposing (decodeExportsResponse)

-- Modules

import Json.Decode as Decode exposing (Decoder)
import XB2.Share.Config exposing (Flags)
import XB2.Share.Export
    exposing
        ( ExportResponse(..)
        )
import XB2.Share.Permissions exposing (Permission(..))



-- Encoding
-- Decoding


decodeExportsResponse : Flags -> Decoder ExportResponse
decodeExportsResponse flags =
    if flags.can ReceiveEmailExports then
        Decode.field "message" Decode.string
            |> Decode.map (\message -> Mail { message = message })

    else
        Decode.field "download_url" Decode.string
            |> Decode.map (\downloadUrl -> DirectDownload { downloadUrl = downloadUrl })



-- Gathering Data
