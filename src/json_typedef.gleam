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
import gleam/string

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
  Type(nullable: Bool, metadata: List(#(String, Dynamic)), type_: Type)
  /// One of a fixed set of strings. The enum form is like a Java or TypeScript
  /// enum.
  Enum(
    nullable: Bool,
    metadata: List(#(String, Dynamic)),
    variants: List(String),
  )
  // The properties form is like a Java class or TypeScript interface.
  Properties(
    nullable: Bool,
    metadata: List(#(String, Dynamic)),
    schema: PropertiesSchema,
  )
  /// A sequence of some other form. The elements form is like a Java `List<T>`
  /// or TypeScript `T[]`.
  Elements(nullable: Bool, metadata: List(#(String, Dynamic)), schema: Schema)
  /// A dictionary with string keys and some form values. The values form is
  /// like a Java `Map<String, T>` or TypeScript `{ [key: string]: T}`.
  Values(nullable: Bool, metadata: List(#(String, Dynamic)), schema: Schema)
  /// The discriminator form is like a tagged union.
  Discriminator(tag: String, mapping: List(#(String, PropertiesSchema)))
  /// The ref form is for re-using schemas, usually so you can avoid repeating
  /// yourself.
  Ref(nullable: Bool, metadata: List(#(String, Dynamic)), name: String)
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
    Ref(nullable:, metadata:, name:) ->
      [#("values", json.string(name))]
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Type(nullable:, metadata:, type_:) ->
      [#("type", type_to_json(type_))]
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Enum(nullable:, metadata:, variants:) ->
      [#("enum", json.array(variants, json.string))]
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Values(nullable:, metadata:, schema:) ->
      [#("values", json.object(schema_to_json(schema)))]
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Elements(nullable:, metadata:, schema:) ->
      [#("elements", json.object(schema_to_json(schema)))]
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Properties(nullable:, metadata:, schema:) ->
      properties_schema_to_json(schema)
      |> add_nullable(nullable)
      |> add_metadata(metadata)
    Discriminator(tag:, mapping:) -> discriminator_to_json(tag, mapping)
  }
}

fn type_to_json(t: Type) -> Json {
  json.string(case t {
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
  })
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
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  dynamic.from(data)
  |> decode_properties_schema
  |> result.map(Properties(nullable, metadata, _))
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
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use type_ <- result.try(dynamic.string(type_) |> push_path("type"))
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))

  case type_ {
    "boolean" -> Ok(Type(nullable, metadata, Boolean))
    "float32" -> Ok(Type(nullable, metadata, Float32))
    "float64" -> Ok(Type(nullable, metadata, Float64))
    "int16" -> Ok(Type(nullable, metadata, Int16))
    "int32" -> Ok(Type(nullable, metadata, Int32))
    "int8" -> Ok(Type(nullable, metadata, Int8))
    "string" -> Ok(Type(nullable, metadata, String))
    "timestamp" -> Ok(Type(nullable, metadata, Timestamp))
    "uint16" -> Ok(Type(nullable, metadata, UInt16))
    "uint32" -> Ok(Type(nullable, metadata, UInt32))
    "uint8" -> Ok(Type(nullable, metadata, UInt8))
    _ -> Error([dynamic.DecodeError("Type", "String", ["type"])])
  }
}

fn decode_enum(
  type_: Dynamic,
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  dynamic.list(dynamic.string)(type_)
  |> push_path("enum")
  |> result.map(Enum(nullable, metadata, _))
}

fn decode_ref(
  type_: Dynamic,
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  dynamic.string(type_)
  |> push_path("ref")
  |> result.map(Ref(nullable, metadata, _))
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
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  decode_schema(values)
  |> push_path("values")
  |> result.map(Values(nullable, metadata, _))
}

fn decode_elements(
  elements: Dynamic,
  data: Dict(String, Dynamic),
) -> Result(Schema, List(dynamic.DecodeError)) {
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  decode_schema(elements)
  |> push_path("elements")
  |> result.map(Elements(nullable, metadata, _))
}

fn push_path(
  result: Result(t, List(dynamic.DecodeError)),
  segment: String,
) -> Result(t, List(dynamic.DecodeError)) {
  result.map_error(result, list.map(_, fn(e) {
    dynamic.DecodeError(..e, path: [segment, ..e.path])
  }))
}

fn get_metadata(
  data: Dict(String, Dynamic),
) -> Result(List(#(String, Dynamic)), List(dynamic.DecodeError)) {
  case dict.get(data, "metadata") {
    Ok(data) ->
      dynamic.dict(dynamic.string, dynamic.dynamic)(data)
      |> result.map(dict.to_list)
      |> push_path("metadata")
    Error(_) -> Ok([])
  }
}

fn get_nullable(
  data: Dict(String, Dynamic),
) -> Result(Bool, List(dynamic.DecodeError)) {
  case dict.get(data, "nullable") {
    Ok(data) -> dynamic.bool(data) |> push_path("nullable")
    Error(_) -> Ok(False)
  }
}

fn metadata_value_to_json(data: Dynamic) -> Json {
  let decoder =
    dynamic.any([
      fn(a) { dynamic.string(a) |> result.map(json.string) },
      fn(a) { dynamic.int(a) |> result.map(json.int) },
      fn(a) { dynamic.float(a) |> result.map(json.float) },
    ])
  case decoder(data) {
    Ok(data) -> data
    Error(_) -> json.string(string.inspect(data))
  }
}

fn add_metadata(
  data: List(#(String, Json)),
  metadata: List(#(String, Dynamic)),
) -> List(#(String, Json)) {
  case metadata {
    [] -> data
    _ -> {
      let metadata =
        list.map(metadata, fn(metadata) {
          #(metadata.0, metadata_value_to_json(metadata.1))
        })
      [#("metadata", json.object(metadata)), ..data]
    }
  }
}

fn add_nullable(
  data: List(#(String, Json)),
  nullable: Bool,
) -> List(#(String, Json)) {
  case nullable {
    False -> data
    True -> [#("nullable", json.bool(True)), ..data]
  }
}
