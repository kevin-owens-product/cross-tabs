module Data.Labels.Fulltext exposing (markdownOptions)

import Markdown


markdownOptions : Markdown.Options
markdownOptions =
    Markdown.defaultOptions
        |> (\o -> { o | sanitize = False })
