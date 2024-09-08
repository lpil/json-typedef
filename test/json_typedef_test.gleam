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

fn to_decoder(schema: json_typedef.RootSchema) -> String {
  let code = json_typedef.to_gleam_decoder_source_code(schema)
  pprint.format(schema)
  <> "\n\n-----------------------------------------------------------\n\n"
  <> code
}

pub fn decoder_type_boolean_test() {
  RootSchema([], Type(False, [], json_typedef.Boolean))
  |> to_decoder
  |> birdie.snap("decoder_type_boolean")
}

pub fn decoder_type_string_test() {
  RootSchema([], Type(False, [], json_typedef.String))
  |> to_decoder
  |> birdie.snap("decoder_type_string")
}

pub fn decoder_type_timestamp_test() {
  RootSchema([], Type(False, [], json_typedef.Timestamp))
  |> to_decoder
  |> birdie.snap("decoder_type_timestamp")
}

pub fn decoder_type_float32_test() {
  RootSchema([], Type(False, [], json_typedef.Float32))
  |> to_decoder
  |> birdie.snap("decoder_type_float32")
}

pub fn decoder_type_float64_test() {
  RootSchema([], Type(False, [], json_typedef.Float64))
  |> to_decoder
  |> birdie.snap("decoder_type_float64")
}

pub fn decoder_type_int8_test() {
  RootSchema([], Type(False, [], json_typedef.Int8))
  |> to_decoder
  |> birdie.snap("decoder_type_int8")
}

pub fn decoder_type_uint8_test() {
  RootSchema([], Type(False, [], json_typedef.Uint8))
  |> to_decoder
  |> birdie.snap("decoder_type_uint8")
}

pub fn decoder_type_int16_test() {
  RootSchema([], Type(False, [], json_typedef.Int16))
  |> to_decoder
  |> birdie.snap("decoder_type_int16")
}

pub fn decoder_type_uint16_test() {
  RootSchema([], Type(False, [], json_typedef.Uint16))
  |> to_decoder
  |> birdie.snap("decoder_type_uint16")
}

pub fn decoder_type_int32_test() {
  RootSchema([], Type(False, [], json_typedef.Int32))
  |> to_decoder
  |> birdie.snap("decoder_type_int32")
}

pub fn decoder_type_uint32_test() {
  RootSchema([], Type(False, [], json_typedef.Uint32))
  |> to_decoder
  |> birdie.snap("decoder_type_uint32")
}
