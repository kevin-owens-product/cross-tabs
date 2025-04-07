module XB2.Share.Data.Auth exposing (header)

import Http


header : String -> Http.Header
header token =
    Http.header "Authorization" ("Bearer " ++ token)
