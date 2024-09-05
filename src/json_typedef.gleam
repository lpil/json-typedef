//// <https://jsontypedef.com/>
////
//// <https://datatracker.ietf.org/doc/html/rfc8927>

// TODO: nullable
// TODO: metadata
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/result

pub type RootSchema {
  RootSchema(definitions: List(#(String, Schema)), schema: Schema)
}

pub type Type {
  /// `true` or `false`
  Boolean
  /// JSON strings
  String
  /// JSON strings containing an RFC3339 timestamp
  Timestamp
  /// JSON numbers
  Float32
  /// JSON numbers
  Float64
  /// Whole JSON numbers that fit in a signed 8-bit integer
  Int8
  /// Whole JSON numbers that fit in an unsigned 8-bit integer
  UInt8
  /// Whole JSON numbers that fit in a signed 16-bit integer
  Int16
  /// Whole JSON numbers that fit in an unsigned 16-bit integer
  UInt16
  /// Whole JSON numbers that fit in a signed 32-bit integer
  Int32
  /// Whole JSON numbers that fit in an unsigned 32-bit integer
  UInt32
}

pub type Schema {
  /// Any value. The empty form is like a Java Object or TypeScript any.
  Empty
  /// A simple built-in type. The type form is like a Java or TypeScript
  /// primitive type.
  Type(Type)
  /// One of a fixed set of strings. The enum form is like a Java or TypeScript
  /// enum.
  Enum(List(String))
  // The properties form is like a Java class or TypeScript interface.
  Properties(PropertiesSchema)
  /// A sequence of some other form. The elements form is like a Java `List<T>`
  /// or TypeScript `T[]`.
  Elements(Schema)
  /// A dictionary with string keys and some form values. The values form is
  /// like a Java `Map<String, T>` or TypeScript `{ [key: string]: T}`.
  Values(Schema)
  /// The discriminator form is like a tagged union.
  Discriminator(tag: String, mapping: List(#(String, PropertiesSchema)))
  /// The ref form is for re-using schemas, usually so you can avoid repeating
  /// yourself.
  Ref(String)
}

pub type PropertiesSchema {
  PropertiesSchema(
    properties: List(#(String, Schema)),
    optional_properties: List(#(String, Schema)),
    additional_properties: Bool,
  )
}

pub fn to_json(schema: RootSchema) -> Json {
  let properties = schema_to_json(schema.schema)
  let properties = case schema.definitions {
    [] -> properties
    definitions -> {
      let definitions =
        list.map(definitions, fn(definition) {
          #(definition.0, json.object(schema_to_json(definition.1)))
        })
      [#("definitions", json.object(definitions)), ..properties]
    }
  }

  json.object(properties)
}

fn properties_schema_to_json(schema: PropertiesSchema) -> List(#(String, Json)) {
  let props_json = fn(props: List(#(String, Schema))) {
    json.object(
      list.map(props, fn(property) {
        #(property.0, json.object(schema_to_json(property.1)))
      }),
    )
  }

  let PropertiesSchema(
    properties:,
    optional_properties:,
    additional_properties:,
  ) = schema

  let data = []

  let data = case additional_properties {
    False -> data
    _ -> [#("additionalProperties", json.bool(True)), ..data]
  }

  let data = case optional_properties {
    [] -> data
    p -> [#("optionalProperties", props_json(p)), ..data]
  }

  let data = case properties {
    [] -> data
    p -> [#("properties", props_json(p)), ..data]
  }

  data
}

fn schema_to_json(schema: Schema) -> List(#(String, Json)) {
  case schema {
    Empty -> []
    Ref(name) -> [#("values", json.string(name))]
    Type(t) -> type_to_json(t)
    Enum(variants) -> [#("enum", json.array(variants, json.string))]
    Values(schema) -> [#("values", json.object(schema_to_json(schema)))]
    Elements(schema) -> [#("elements", json.object(schema_to_json(schema)))]
    Properties(schema) -> properties_schema_to_json(schema)
    Discriminator(tag:, mapping:) -> discriminator_to_json(tag, mapping)
  }
}

fn type_to_json(t: Type) -> List(#(String, Json)) {
  let t = case t {
    Boolean -> "boolean"
    Float32 -> "float32"
    Float64 -> "float64"
    Int16 -> "int16"
    Int32 -> "int32"
    Int8 -> "int8"
    String -> "string"
    Timestamp -> "timestamp"
    UInt16 -> "uint16"
    UInt32 -> "uint32"
    UInt8 -> "uint8"
  }
  [#("type", json.string(t))]
}

fn discriminator_to_json(
  tag: String,
  mapping: List(#(String, PropertiesSchema)),
) -> List(#(String, Json)) {
  let mapping =
    list.map(mapping, fn(variant) {
      #(variant.0, json.object(properties_schema_to_json(variant.1)))
    })
  [#("discriminator", json.string(tag)), #("mapping", json.object(mapping))]
}

pub fn decoder(data: Dynamic) -> Result(RootSchema, List(dynamic.DecodeError)) {
  dynamic.decode2(RootSchema, fn(_) { Ok([]) }, decode_schema)(data)
}

fn decode_schema(data: Dynamic) -> Result(Schema, List(dynamic.DecodeError)) {
  use data <- result.try(dynamic.dict(dynamic.string, dynamic.dynamic)(data))
  // TODO: metadata
  // TODO: nullable
  let decoder =
    key_decoder(data, "type", decode_type)
    |> result.lazy_or(fn() { key_decoder(data, "enum", decode_enum) })
    |> result.lazy_or(fn() { key_decoder(data, "ref", decode_ref) })
    |> result.lazy_or(fn() { key_decoder(data, "values", decode_values) })
    |> result.lazy_or(fn() { key_decoder(data, "elements", decode_elements) })
    |> result.lazy_or(fn() {
      key_decoder(data, "discriminator", decode_discriminator)
    })
    |> result.lazy_or(fn() {
      key_decoder(data, "properties", decode_properties)
    })
    |> result.lazy_or(fn() {
      key_decoder(data, "extraProperties", decode_properties)
    })
    |> result.lazy_or(fn() {
      key_decoder(data, "additionalProperties", decode_properties)
    })
    |> result.unwrap(fn() { decode_empty(data) })

  decoder()
}

fn key_decoder(
  dict: Dict(String, Dynamic),
  key: String,
  constructor: fn(Dynamic, Dict(String, Dynamic)) ->
    Result(t, List(dynamic.DecodeError)),
) -> Result(fn() -> Result(t, List(dynamic.DecodeError)), Nil) {
  case dict.get(dict, key) {
    Ok(value) -> Ok(fn() { constructor(value, dict) })
    Error(e) -> Error(e)
  }
}

fn decode_discriminator(
  tag: Dynamic,
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use tag <- result.try(dynamic.string(tag) |> push_path("discriminator"))
  use mapping <- result.try(case dict.get(data, "mapping") {
    Ok(mapping) -> Ok(mapping)
    Error(_) -> Error([dynamic.DecodeError("field", "nothing", ["mapping"])])
  })
  use properties <- result.try(
    decode_object_as_list(mapping, decode_properties_schema)
    |> push_path("mapping"),
  )
  Ok(Discriminator(tag:, mapping: properties))
}

fn decode_object_as_list(
  data: Dynamic,
  inner: dynamic.Decoder(t),
) -> Result(List(#(String, t)), List(dynamic.DecodeError)) {
  dynamic.dict(dynamic.string, inner)(data)
  |> result.map(dict.to_list)
}

fn decode_properties(
  _tag: Dynamic,
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  dynamic.from(data)
  |> decode_properties_schema
  |> result.map(Properties)
}

fn decode_properties_schema(
  data: Dynamic,
) -> Result(PropertiesSchema, List(dynamic.DecodeError)) {
  let field = fn(name, data) {
    case dynamic.field(name, dynamic.dynamic)(data) {
      Ok(d) -> decode_object_as_list(d, decode_schema) |> push_path(name)
      Error(_) -> Ok([])
    }
  }
  dynamic.decode3(
    PropertiesSchema,
    field("properties", _),
    field("optionalProperties", _),
    fn(d) {
      case dynamic.field("additionalProperties", dynamic.dynamic)(d) {
        Ok(d) -> dynamic.bool(d) |> push_path("additionalProperties")
        Error(_) -> Ok(False)
      }
    },
  )(data)
}

fn decode_type(
  type_: Dynamic,
  _data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use type_ <- result.try(dynamic.string(type_) |> push_path("type"))

  case type_ {
    "boolean" -> Ok(Type(Boolean))
    "float32" -> Ok(Type(Float32))
    "float64" -> Ok(Type(Float64))
    "int16" -> Ok(Type(Int16))
    "int32" -> Ok(Type(Int32))
    "int8" -> Ok(Type(Int8))
    "string" -> Ok(Type(String))
    "timestamp" -> Ok(Type(Timestamp))
    "uint16" -> Ok(Type(UInt16))
    "uint32" -> Ok(Type(UInt32))
    "uint8" -> Ok(Type(UInt8))
    _ -> Error([dynamic.DecodeError("Type", "String", ["type"])])
  }
}

fn decode_enum(
  type_: Dynamic,
  _data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  dynamic.list(dynamic.string)(type_)
  |> push_path("enum")
  |> result.map(Enum)
}

fn decode_ref(
  type_: Dynamic,
  _data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  dynamic.string(type_)
  |> push_path("ref")
  |> result.map(Ref)
}

fn decode_empty(
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  case dict.size(data) {
    0 -> Ok(Empty)
    _ -> Error([dynamic.DecodeError("Schema", "Dict", [])])
  }
}

fn decode_values(
  values: Dynamic,
  _data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  decode_schema(values)
  |> push_path("values")
  |> result.map(Values)
}

fn decode_elements(
  elements: Dynamic,
  _data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  decode_schema(elements)
  |> push_path("elements")
  |> result.map(Elements)
}

fn push_path(
  result: Result(t, List(dynamic.DecodeError)),
  segment: String,
) -> Result(t, List(dynamic.DecodeError)) {
  result.map_error(result, list.map(_, fn(e) {
    dynamic.DecodeError(..e, path: [segment, ..e.path])
  }))
}
