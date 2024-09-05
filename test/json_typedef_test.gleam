import birdie
import gleam/json
import gleeunit
import json_typedef
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
