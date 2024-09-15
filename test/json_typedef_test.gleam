import birdie
import gleam/dynamic
import gleam/json
import gleeunit
import json_typedef.{RootSchema, Type}
import pprint

pub fn main() {
  gleeunit.main()
}

fn test_decode(json: String) -> String {
  let result = json.decode(json, json_typedef.decoder)
  json <> "\n\n" <> pprint.format(result)
}

pub fn decode_empty_test() {
  "{}"
  |> test_decode
  |> birdie.snap("decode_empty_test")
}

pub fn decode_type_boolean_test() {
  "{ \"type\": \"boolean\" }"
  |> test_decode
  |> birdie.snap("decode_type_boolean_test")
}

pub fn decode_type_string_test() {
  "{ \"type\": \"string\" }"
  |> test_decode
  |> birdie.snap("decode_type_string_test")
}

pub fn decode_type_timestamp_test() {
  "{ \"type\": \"timestamp\" }"
  |> test_decode
  |> birdie.snap("decode_type_timestamp_test")
}

pub fn decode_type_float32_test() {
  "{ \"type\": \"float32\" }"
  |> test_decode
  |> birdie.snap("decode_type_float32_test")
}

pub fn decode_type_float64_test() {
  "{ \"type\": \"float64\" }"
  |> test_decode
  |> birdie.snap("decode_type_float64_test")
}

pub fn decode_type_int16_test() {
  "{ \"type\": \"int16\" }"
  |> test_decode
  |> birdie.snap("decode_type_int16_test")
}

pub fn decode_type_int8_test() {
  "{ \"type\": \"int8\" }"
  |> test_decode
  |> birdie.snap("decode_type_int8_test")
}

pub fn decode_type_int32_test() {
  "{ \"type\": \"int32\" }"
  |> test_decode
  |> birdie.snap("decode_type_int32_test")
}

pub fn decode_type_uint16_test() {
  "{ \"type\": \"uint16\" }"
  |> test_decode
  |> birdie.snap("decode_type_uint16_test")
}

pub fn decode_type_uint8_test() {
  "{ \"type\": \"uint8\" }"
  |> test_decode
  |> birdie.snap("decode_type_uint8_test")
}

pub fn decode_type_uint32_test() {
  "{ \"type\": \"uint32\" }"
  |> test_decode
  |> birdie.snap("decode_type_uint32_test")
}

pub fn decode_type_unknown_test() {
  "{ \"type\": \"object\" }"
  |> test_decode
  |> birdie.snap("decode_type_object_test")
}

pub fn decode_type_invalid_test() {
  "{ \"type\": 1 }"
  |> test_decode
  |> birdie.snap("decode_type_invalid_test")
}

pub fn decode_enum_season_test() {
  "{ \"enum\": [\"Spring\", \"Summer\", \"Autumn\", \"Winter\"] }"
  |> test_decode
  |> birdie.snap("decode_enum_season_test")
}

pub fn decode_enum_direction_test() {
  "{ \"enum\": [\"Up\", \"Down\"] }"
  |> test_decode
  |> birdie.snap("decode_enum_direction_test")
}

pub fn decode_ref_direction_test() {
  "{ \"ref\": \"direction\" }"
  |> test_decode
  |> birdie.snap("decode_ref_direction_test")
}

pub fn decode_ref_pokemon_test() {
  "{ \"ref\": \"pokemon\" }"
  |> test_decode
  |> birdie.snap("decode_ref_pokemon_test")
}

pub fn decode_elements_string_test() {
  "{ \"elements\": { \"type\": \"string\" } }"
  |> test_decode
  |> birdie.snap("decode_elements_string_test")
}

pub fn decode_elements_ref_test() {
  "{ \"elements\": { \"ref\": \"pokemon\" } }"
  |> test_decode
  |> birdie.snap("decode_elements_ref_test")
}

pub fn decode_values_string_test() {
  "{ \"values\": { \"type\": \"string\" } }"
  |> test_decode
  |> birdie.snap("decode_values_string_test")
}

pub fn decode_values_ref_test() {
  "{ \"values\": { \"ref\": \"pokemon\" } }"
  |> test_decode
  |> birdie.snap("decode_values_ref_test")
}

pub fn decode_discriminator_event_type_test() {
  "{
    \"discriminator\": \"eventType\",
    \"mapping\": {
        \"USER_CREATED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" }
            }
        },
        \"USER_PAYMENT_PLAN_CHANGED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"plan\": { \"enum\": [\"FREE\", \"PAID\"]}
            }
        },
        \"USER_DELETED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"softDelete\": { \"type\": \"boolean\" }
            }
        }
    }
}"
  |> test_decode
  |> birdie.snap("decode_discriminator_event_type_test")
}

pub fn decode_discriminator_event_type_metadata_test() {
  "{
    \"discriminator\": \"eventType\",
    \"metadata\": { \"name\": \"wibble\" },
    \"mapping\": {
        \"USER_CREATED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" }
            }
        },
        \"USER_PAYMENT_PLAN_CHANGED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"plan\": { \"enum\": [\"FREE\", \"PAID\"]}
            }
        },
        \"USER_DELETED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"softDelete\": { \"type\": \"boolean\" }
            }
        }
    }
}"
  |> test_decode
  |> birdie.snap("decode_discriminator_event_type_metadata_test")
}

pub fn decode_discriminator_event_type_nullable_test() {
  "{
    \"discriminator\": \"eventType\",
    \"nullable\": true,
    \"mapping\": {
        \"USER_CREATED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" }
            }
        },
        \"USER_PAYMENT_PLAN_CHANGED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"plan\": { \"enum\": [\"FREE\", \"PAID\"]}
            }
        },
        \"USER_DELETED\": {
            \"properties\": {
                \"id\": { \"type\": \"string\" },
                \"softDelete\": { \"type\": \"boolean\" }
            }
        }
    }
}"
  |> test_decode
  |> birdie.snap("decode_discriminator_event_type_nullable_test")
}

pub fn decode_properties_test() {
  "{
    \"properties\": {
        \"name\": { \"type\": \"string\" },
        \"isAdmin\": { \"type\": \"boolean\" }
    }
}"
  |> test_decode
  |> birdie.snap("decode_properties_test")
}

pub fn decode_properties_optional_test() {
  "{
    \"properties\": {
        \"name\": { \"type\": \"string\" },
        \"isAdmin\": { \"type\": \"boolean\" }
    },
    \"optionalProperties\": {
        \"middleName\": { \"type\": \"string\" }
    }
}"
  |> test_decode
  |> birdie.snap("decode_properties_optional_test")
}

pub fn decode_properties_additional_test() {
  "{
    \"properties\": {
        \"name\": { \"type\": \"string\" },
        \"isAdmin\": { \"type\": \"boolean\" }
    },
    \"additionalProperties\": true
}"
  |> test_decode
  |> birdie.snap("decode_properties_additional_test")
}

pub fn decode_type_nullable_true_test() {
  "{ \"type\": \"boolean\", \"nullable\": true }"
  |> test_decode
  |> birdie.snap("decode_type_nullable_true_test")
}

pub fn decode_type_nullable_false_test() {
  "{ \"type\": \"boolean\", \"nullable\": false }"
  |> test_decode
  |> birdie.snap("decode_type_nullable_false_test")
}

pub fn to_json_discriminator_test() {
  RootSchema(
    [],
    json_typedef.Discriminator(False, [], "kind", [
      #(
        "up",
        json_typedef.PropertiesSchema(
          [#("amount", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
      #(
        "down",
        json_typedef.PropertiesSchema(
          [#("amount", json_typedef.Type(False, [], json_typedef.Float32))],
          [],
          False,
        ),
      ),
    ]),
  )
  |> json_typedef.to_json
  |> json.to_string
  |> birdie.snap("to_json_discriminator_test")
}

pub fn to_json_discriminator_nullable_test() {
  RootSchema(
    [],
    json_typedef.Discriminator(True, [], "kind", [
      #(
        "up",
        json_typedef.PropertiesSchema(
          [#("amount", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
      #(
        "down",
        json_typedef.PropertiesSchema(
          [#("amount", json_typedef.Type(False, [], json_typedef.Float32))],
          [],
          False,
        ),
      ),
    ]),
  )
  |> json_typedef.to_json
  |> json.to_string
  |> birdie.snap("to_json_discriminator_nullable_test")
}

pub fn to_json_type_nullable_test() {
  RootSchema([], Type(nullable: True, metadata: [], type_: json_typedef.String))
  |> json_typedef.to_json
  |> json.to_string
  |> birdie.snap("to_json_type_nullable_test")
}

pub fn to_json_type_not_nullable_test() {
  RootSchema(
    [],
    Type(nullable: False, metadata: [], type_: json_typedef.String),
  )
  |> json_typedef.to_json
  |> json.to_string
  |> birdie.snap("to_json_type_not_nullable_test")
}

pub fn decode_type_metadata_test() {
  "{ \"type\": \"boolean\", \"metadata\": { \"documentation\": \"waddup\" } }"
  |> test_decode
  |> birdie.snap("decode_type_metadata_test")
}

pub fn to_json_type_metadata_test() {
  RootSchema(
    [],
    Type(
      nullable: False,
      metadata: [#("documentation", dynamic.from("Hello, Joe!"))],
      type_: json_typedef.String,
    ),
  )
  |> json_typedef.to_json
  |> json.to_string
  |> birdie.snap("to_json_type_metadata_test")
}

fn snap_format(
  result: Result(String, json_typedef.CodegenError),
  schema: json_typedef.RootSchema,
) -> String {
  let code = case result {
    Ok(code) -> code
    Error(e) -> "ERROR: " <> pprint.format(e)
  }
  pprint.format(schema)
  <> "\n\n-----------------------------------------------------------\n\n"
  <> code
}

fn to_decoder(schema: json_typedef.RootSchema) -> String {
  json_typedef.codegen()
  |> json_typedef.generate_decoders(True)
  |> json_typedef.generate_encoders(False)
  |> json_typedef.generate(schema)
  |> snap_format(schema)
}

fn to_encoder_and_decoder(schema: json_typedef.RootSchema) -> String {
  json_typedef.codegen()
  |> json_typedef.generate_decoders(True)
  |> json_typedef.generate_encoders(True)
  |> json_typedef.generate(schema)
  |> snap_format(schema)
}

pub fn codegen_decoder_type_empty_test() {
  RootSchema([], json_typedef.Empty)
  |> to_decoder
  |> birdie.snap("codegen_decoder_type_empty")
}

pub fn codegen_type_empty_test() {
  RootSchema([], json_typedef.Empty)
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_empty")
}

pub fn codegen_type_boolean_test() {
  RootSchema([], Type(False, [], json_typedef.Boolean))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_boolean")
}

pub fn codegen_type_string_test() {
  RootSchema([], Type(False, [], json_typedef.String))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_string")
}

pub fn codegen_type_timestamp_test() {
  RootSchema([], Type(False, [], json_typedef.Timestamp))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_timestamp")
}

pub fn codegen_type_float32_test() {
  RootSchema([], Type(False, [], json_typedef.Float32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_float32")
}

pub fn codegen_type_float64_test() {
  RootSchema([], Type(False, [], json_typedef.Float64))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_float64")
}

pub fn codegen_type_int8_test() {
  RootSchema([], Type(False, [], json_typedef.Int8))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_int8")
}

pub fn codegen_type_uint8_test() {
  RootSchema([], Type(False, [], json_typedef.Uint8))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_uint8")
}

pub fn codegen_type_int16_test() {
  RootSchema([], Type(False, [], json_typedef.Int16))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_int16")
}

pub fn codegen_type_uint16_test() {
  RootSchema([], Type(False, [], json_typedef.Uint16))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_uint16")
}

pub fn codegen_type_int32_test() {
  RootSchema([], Type(False, [], json_typedef.Int32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_int32")
}

pub fn codegen_type_uint32_test() {
  RootSchema([], Type(False, [], json_typedef.Uint32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_uint32")
}

pub fn codegen_type_nullable_boolean_test() {
  RootSchema([], Type(True, [], json_typedef.Boolean))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_boolean")
}

pub fn codegen_type_nullable_string_test() {
  RootSchema([], Type(True, [], json_typedef.String))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_string")
}

pub fn codegen_type_nullable_timestamp_test() {
  RootSchema([], Type(True, [], json_typedef.Timestamp))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_timestamp")
}

pub fn codegen_type_nullable_float32_test() {
  RootSchema([], Type(True, [], json_typedef.Float32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_float32")
}

pub fn codegen_type_nullable_float64_test() {
  RootSchema([], Type(True, [], json_typedef.Float64))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_float64")
}

pub fn codegen_type_nullable_int8_test() {
  RootSchema([], Type(True, [], json_typedef.Int8))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_int8")
}

pub fn codegen_type_nullable_uint8_test() {
  RootSchema([], Type(True, [], json_typedef.Uint8))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_uint8")
}

pub fn codegen_type_nullable_int16_test() {
  RootSchema([], Type(True, [], json_typedef.Int16))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_int16")
}

pub fn codegen_type_nullable_uint16_test() {
  RootSchema([], Type(True, [], json_typedef.Uint16))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_uint16")
}

pub fn codegen_type_nullable_int32_test() {
  RootSchema([], Type(True, [], json_typedef.Int32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_int32")
}

pub fn codegen_type_nullable_uint32_test() {
  RootSchema([], Type(True, [], json_typedef.Uint32))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_nullable_uint32")
}

pub fn codegen_type_elements_string_test() {
  RootSchema(
    [],
    json_typedef.Elements(False, [], Type(False, [], json_typedef.String)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_elements_string")
}

pub fn codegen_type_elements_string_nullable_test() {
  RootSchema(
    [],
    json_typedef.Elements(True, [], Type(False, [], json_typedef.String)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_elements_string_nullable")
}

pub fn codegen_type_elements_float_test() {
  RootSchema(
    [],
    json_typedef.Elements(False, [], Type(False, [], json_typedef.Float32)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_elements_float")
}

pub fn codegen_type_elements_float_nullable_test() {
  RootSchema(
    [],
    json_typedef.Elements(True, [], Type(False, [], json_typedef.Float32)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_elements_float_nullable")
}

pub fn codegen_type_values_float_test() {
  RootSchema(
    [],
    json_typedef.Values(False, [], Type(False, [], json_typedef.Float32)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_values_float")
}

pub fn codegen_type_values_float_nullable_test() {
  RootSchema(
    [],
    json_typedef.Values(True, [], Type(False, [], json_typedef.Float32)),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_type_values_float_nullable")
}

pub fn codegen_enum_empty_test() {
  RootSchema([], json_typedef.Enum(False, [], []))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_enum_empty_test")
}

pub fn codegen_enum_directions_test() {
  RootSchema([], json_typedef.Enum(False, [], ["UP", "DOWN", "LEFT", "RIGHT"]))
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_enum_directions_test")
}

pub fn codegen_element_enum_directions_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Enum(False, [], ["UP", "DOWN", "LEFT", "RIGHT"]),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_element_enum_directions_test")
}

pub fn codegen_element_enum_directions_nullable_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Enum(True, [], ["UP", "DOWN", "LEFT", "RIGHT"]),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_element_enum_directions_nullable_test")
}

pub fn codegen_root_name_test() {
  let schema =
    RootSchema(
      [],
      json_typedef.Elements(
        False,
        [],
        json_typedef.Enum(True, [], ["UP", "DOWN", "LEFT", "RIGHT"]),
      ),
    )
  json_typedef.codegen()
  |> json_typedef.generate_decoders(True)
  |> json_typedef.generate_encoders(True)
  |> json_typedef.root_name("Direction")
  |> json_typedef.generate(schema)
  |> snap_format(schema)
  |> birdie.snap("codegen_root_name_test")
}

pub fn codegen_properties_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("amount", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("key", json_typedef.Type(False, [], json_typedef.String)),
        ],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_test")
}

pub fn codegen_properties_optional_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [],
        [
          #("key", json_typedef.Type(False, [], json_typedef.String)),
          #("amount", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_optional_test")
}

pub fn codegen_properties_mixed_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("wup", json_typedef.Type(False, [], json_typedef.String)),
          #("key", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        [
          #("what", json_typedef.Type(False, [], json_typedef.String)),
          #("amount", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_mixed_test")
}

pub fn codegen_properties_nested_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("name", json_typedef.Type(False, [], json_typedef.String)),
          #(
            "values",
            json_typedef.Properties(
              False,
              [],
              json_typedef.PropertiesSchema(
                [
                  #("amount", json_typedef.Type(False, [], json_typedef.Uint8)),
                  #("key", json_typedef.Type(False, [], json_typedef.String)),
                ],
                [],
                False,
              ),
            ),
          ),
        ],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_nested_test")
}

pub fn codegen_properties_nullable_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      True,
      [],
      json_typedef.PropertiesSchema(
        [
          #("amount", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("key", json_typedef.Type(False, [], json_typedef.String)),
        ],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_nullable_test")
}

pub fn codegen_properties_wrong_case_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [#("wibbleWobble", json_typedef.Type(False, [], json_typedef.Uint8))],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_wrong_case_test")
}

pub fn codegen_properties_in_elements_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Properties(
        False,
        [],
        json_typedef.PropertiesSchema(
          [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_in_elements_test")
}

pub fn codegen_properties_nullable_in_elements_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Properties(
        True,
        [],
        json_typedef.PropertiesSchema(
          [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_properties_nullable_in_elements_test")
}

pub fn codegen_discriminator_test() {
  RootSchema(
    [],
    json_typedef.Discriminator(False, [], "kind", [
      #(
        "up",
        json_typedef.PropertiesSchema(
          [#("height", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
      #(
        "down",
        json_typedef.PropertiesSchema(
          [
            #("depth", json_typedef.Type(False, [], json_typedef.Float32)),
            #("note", json_typedef.Type(True, [], json_typedef.String)),
          ],
          [],
          False,
        ),
      ),
    ]),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_discriminator_test")
}

pub fn codegen_discriminator_nullable_test() {
  RootSchema(
    [],
    json_typedef.Discriminator(True, [], "kind", [
      #(
        "up",
        json_typedef.PropertiesSchema(
          [#("height", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
      #(
        "down",
        json_typedef.PropertiesSchema(
          [
            #("depth", json_typedef.Type(False, [], json_typedef.Float32)),
            #("note", json_typedef.Type(True, [], json_typedef.String)),
          ],
          [],
          False,
        ),
      ),
    ]),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_discriminator_nullable_test")
}

pub fn codegen_discriminator_as_elements_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Discriminator(False, [], "kind", [
        #(
          "up",
          json_typedef.PropertiesSchema(
            [#("height", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
        #(
          "down",
          json_typedef.PropertiesSchema(
            [
              #("depth", json_typedef.Type(False, [], json_typedef.Float32)),
              #("note", json_typedef.Type(True, [], json_typedef.String)),
            ],
            [],
            False,
          ),
        ),
      ]),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_discriminator_as_elements_test")
}

pub fn codegen_discriminator_nullable_as_elements_test() {
  RootSchema(
    [],
    json_typedef.Elements(
      False,
      [],
      json_typedef.Discriminator(True, [], "kind", [
        #(
          "up",
          json_typedef.PropertiesSchema(
            [#("height", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
        #(
          "down",
          json_typedef.PropertiesSchema(
            [
              #("depth", json_typedef.Type(False, [], json_typedef.Float32)),
              #("note", json_typedef.Type(True, [], json_typedef.String)),
            ],
            [],
            False,
          ),
        ),
      ]),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_discriminator_nullable_as_elements_test")
}

pub fn codegen_ref_test() {
  RootSchema(
    [#("wibble", Type(False, [], json_typedef.Boolean))],
    json_typedef.Ref(False, [], "wibble"),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_test")
}

pub fn codegen_ref_nullable_test() {
  RootSchema(
    [#("wobble", Type(False, [], json_typedef.Boolean))],
    json_typedef.Ref(True, [], "wobble"),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_nullable_test")
}

pub fn codegen_ref_as_elements_test() {
  RootSchema(
    [#("thing", Type(False, [], json_typedef.Boolean))],
    json_typedef.Elements(False, [], json_typedef.Ref(False, [], "thing")),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_as_elements_test")
}

pub fn codegen_ref_as_elements_nullable_test() {
  RootSchema(
    [#("bibble", Type(False, [], json_typedef.Boolean))],
    json_typedef.Elements(False, [], json_typedef.Ref(True, [], "bibble")),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_as_elements_nullable_test")
}

pub fn codegen_ref_wrong_case_test() {
  RootSchema(
    [#("YeeHaw", Type(False, [], json_typedef.Boolean))],
    json_typedef.Ref(False, [], "YeeHaw"),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_wrong_case_test")
}

pub fn codegen_ref_properties_test() {
  RootSchema(
    [
      #(
        "wibble",
        json_typedef.Properties(
          False,
          [],
          json_typedef.PropertiesSchema(
            [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
      ),
    ],
    json_typedef.Ref(False, [], "wibble"),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_properties_test")
}

pub fn codegen_ref_properties_properties_test() {
  RootSchema(
    [
      #(
        "wibble",
        json_typedef.Properties(
          False,
          [],
          json_typedef.PropertiesSchema(
            [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
      ),
    ],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [#("inner", json_typedef.Ref(False, [], "wibble"))],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_properties_properties_test")
}

pub fn codegen_ref_properties_nullable_test() {
  RootSchema(
    [
      #(
        "wibble",
        json_typedef.Properties(
          False,
          [],
          json_typedef.PropertiesSchema(
            [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
      ),
    ],
    json_typedef.Ref(True, [], "wibble"),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_properties_nullable_test")
}

pub fn codegen_ref_properties_properties_nullable_test() {
  RootSchema(
    [
      #(
        "wibble",
        json_typedef.Properties(
          False,
          [],
          json_typedef.PropertiesSchema(
            [#("count", json_typedef.Type(False, [], json_typedef.Uint8))],
            [],
            False,
          ),
        ),
      ),
    ],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [#("inner", json_typedef.Ref(False, [], "wibble"))],
        [],
        True,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_ref_properties_properties_nullable_test")
}

pub fn codegen_duplicate_properties_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("a", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("b", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("a", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        [],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_duplicate_properties_test")
}

pub fn codegen_duplicate_optional_properties_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [],
        [
          #("b", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("c", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("c", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_duplicate_optional_properties_test")
}

pub fn codegen_duplicate_mixed_properties_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("b", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("c", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        [#("c", json_typedef.Type(False, [], json_typedef.Uint8))],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_duplicate_mixed_properties_test")
}

pub fn codegen_duplicate_mixed_properties_case_test() {
  RootSchema(
    [],
    json_typedef.Properties(
      False,
      [],
      json_typedef.PropertiesSchema(
        [
          #("b", json_typedef.Type(False, [], json_typedef.Uint8)),
          #("C", json_typedef.Type(False, [], json_typedef.Uint8)),
        ],
        [#("c", json_typedef.Type(False, [], json_typedef.Uint8))],
        False,
      ),
    ),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_duplicate_mixed_properties_case_test")
}

pub fn codegen_duplicate_discriminator_properties_case_test() {
  RootSchema(
    [],
    json_typedef.Discriminator(False, [], "ID", [
      #(
        "a",
        json_typedef.PropertiesSchema(
          [#("b", json_typedef.Type(False, [], json_typedef.Uint8))],
          [],
          False,
        ),
      ),
      #(
        "b",
        json_typedef.PropertiesSchema(
          [
            #("b", json_typedef.Type(False, [], json_typedef.Uint8)),
            #("id", json_typedef.Type(False, [], json_typedef.Uint8)),
          ],
          [],
          False,
        ),
      ),
    ]),
  )
  |> to_encoder_and_decoder
  |> birdie.snap("codegen_duplicate_discriminator_properties_case_test")
}
