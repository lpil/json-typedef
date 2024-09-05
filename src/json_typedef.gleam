//// <https://jsontypedef.com/>
////
//// <https://datatracker.ietf.org/doc/html/rfc8927>

import gleam/json.{type Json}
import gleam/list

pub type RootSchema {
  Root(definitions: List(#(String, Schema)), schema: PropertiesSchema)
}

pub type Type {
  /// `true` or `false`
  Bool
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
    extra_properties: Bool,
  )
}

pub fn to_json(schema: RootSchema) -> Json {
  let properties = properties_schema_to_json(schema.schema)
  let properties = case schema.definitions {
    [] -> properties
    definitions -> {
      let definitions =
        list.map(definitions, fn(definition) {
          #(definition.0, schema_to_json(definition.1))
        })
      [#("definitions", json.object(definitions)), ..properties]
    }
  }

  json.object(properties)
}

fn properties_schema_to_json(schema: PropertiesSchema) -> List(#(String, Json)) {
  let props_json = fn(props: List(#(String, Schema))) {
    json.object(
      list.map(props, fn(property) { #(property.0, schema_to_json(property.1)) }),
    )
  }

  let PropertiesSchema(properties:, optional_properties:, extra_properties:) =
    schema

  let data = []

  let data = case extra_properties {
    False -> data
    _ -> [#("extraProperties", json.bool(True)), ..data]
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

fn schema_to_json(schema: Schema) -> Json {
  case schema {
    Discriminator(tag:, mapping:) -> discriminator_to_json(tag, mapping)

    Elements(schema) -> json.object([#("elements", schema_to_json(schema))])

    Empty -> json.object([])

    Enum(variants) ->
      json.object([#("enum", json.array(variants, json.string))])

    Properties(schema) -> json.object(properties_schema_to_json(schema))

    Ref(name) -> json.object([#("values", json.string(name))])

    Type(t) -> type_to_json(t)

    Values(schema) -> json.object([#("values", schema_to_json(schema))])
  }
}

fn type_to_json(t: Type) -> Json {
  let t = case t {
    Bool -> "boolean"
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
  json.object([#("type", json.string(t))])
}

fn discriminator_to_json(
  tag: String,
  mapping: List(#(String, PropertiesSchema)),
) -> Json {
  let mapping =
    list.map(mapping, fn(variant) {
      #(variant.0, json.object(properties_schema_to_json(variant.1)))
    })
  json.object([
    #("discriminator", json.string(tag)),
    #("mapping", json.object(mapping)),
  ])
}
