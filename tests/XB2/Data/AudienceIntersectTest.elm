module XB2.Data.AudienceIntersectTest exposing (invalidErrorDecodingTest)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import XB2.Data.Calc.AudienceIntersect as AIntersect


invalidQueryJson =
    "{\"error\": \"Problem\",\"error_type\": \"invalid_query\",\"code\": 400}"


invalidErrorDecodingTest : Test
invalidErrorDecodingTest =
    describe "AudienceIntersect tests"
        [ describe "Error decoder"
            [ test "Invalid Query decodes with extra error information in it" <|
                \() ->
                    Decode.decodeString AIntersect.xbQueryErrorDecoder invalidQueryJson
                        |> Result.toMaybe
                        |> Maybe.map AIntersect.xbQueryErrorStringWithoutCodeTranslation
                        |> Expect.equal (Just "Invalid query: Problem")
            ]
        ]
