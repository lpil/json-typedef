# json_typedef

Work with JSON using a schema! 

[![Package Version](https://img.shields.io/hexpm/v/json_typedef)](https://hex.pm/packages/json_typedef)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/json_typedef/)

JSON-Typedef is an easy-to-learn, portable, and standardized way to describe the
shape of your JSON data. This library provides encoders and decoders for the
JSON-Typedef schema format, and can generate Gleam encoders and decoders for a
given schema.

- [JSON-Typedef website](https://jsontypedef.com/)
- [RFC8927](https://datatracker.ietf.org/doc/html/rfc8927)

For example, if you have this JSON-Typedef schema:

```json
{
  "properties": {
    "id": { "type": "string" },
    "createdAt": { "type": "timestamp" },
    "karma": { "type": "int32" },
    "isAdmin": { "type": "boolean" }
  }
}
```

Then you can use this package to generate this Gleam source code:

```gleam
import decode
import gleam/json

pub type Data {
  Data(
    created_at: String,
    id: String,
    is_admin: Bool,
    karma: Int,
  )
}

pub fn data_decoder() -> decode.Decoder(Data) {
  decode.into({
    use created_at <- decode.parameter
    use id <- decode.parameter
    use is_admin <- decode.parameter
    use karma <- decode.parameter
    Data(created_at:, id:, is_admin:, karma:)
  })
  |> decode.field("createdAt", decode.string)
  |> decode.field("id", decode.string)
  |> decode.field("isAdmin", decode.bool)
  |> decode.field("karma", decode.int)
}

pub fn data_to_json(data: Data) -> json.Json {
  json.object([
    #("createdAt", json.string(data.created_at)),
    #("id", json.string(data.id)),
    #("isAdmin", json.bool(data.is_admin)),
    #("karma", json.int(data.karma)),
  ])
}
```

## Usage
Everything starts with a string representation of your schema written using the [JSON Type Definition Format](https://jsontypedef.com/docs/jtd-in-5-minutes/)
```gleam
// you can also achieve this by using the gleam/json.{string} function if you receive the data from stdin or a file
let json_schema =
    "{
  \"properties\": {
    \"id\": { \"type\": \"string\" },
    \"createdAt\": { \"type\": \"timestamp\" },
    \"karma\": { \"type\": \"int32\" },
    \"isAdmin\": { \"type\": \"boolean\" }
  }
}"
```
Then you'll need to use the [gleam/json module](https://hexdocs.pm/gleam_json/gleam/json.html)'s [decode function](https://hexdocs.pm/gleam_json/gleam/json.html#decode) to convert your string representation into a usable [RootSchema](https://hexdocs.pm/json_typedef/json_typedef.html#RootSchema) type like this:

```gleam
import gleam/json
import json_typedef

let assert Ok(root_schema) = json.decode(json_schema, json_typedef.decoder)
```

Once you have your `root_schema` you can then generate your encoders and or decoders! That can be achieved like this:
```gleam
json_typedef.codegen()
|> json_typedef.generate_decoders(True) // change to false to EXCLUDE decoders from the output
|> json_typedef.generate_encoders(True) // change to false to EXCLUDE encoders from the output
|> json_typedef.generate(root_schema) // returns type Result(String, CodeGenError)
```

you can then save the `Ok(String)` value to a file and use the generated code to decode and encode any future pieces of json that satisfy your schema.

Further documentation can be found at <https://hexdocs.pm/json_typedef>.
