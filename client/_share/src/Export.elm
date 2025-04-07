module Export exposing (urlDownload)

import File.Download


urlDownload : String -> Cmd msg
urlDownload url =
    File.Download.url url



-- Types
