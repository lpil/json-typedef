//// <https://jsontypedef.com/>
////
//// <https://datatracker.ietf.org/doc/html/rfc8927>

// TODO: ensure field names are snake case
// TODO: ensure the tag field isn't used in any of the variants

import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import justin

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
  Uint8
  /// Whole JSON numbers that fit in a signed 16-bit integer
  Int16
  /// Whole JSON numbers that fit in an unsigned 16-bit integer
  Uint16
  /// Whole JSON numbers that fit in a signed 32-bit integer
  Int32
  /// Whole JSON numbers that fit in an unsigned 32-bit integer
  Uint32
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
  Discriminator(
    nullable: Bool,
    metadata: List(#(String, Dynamic)),
    tag: String,
    mapping: List(#(String, PropertiesSchema)),
  )
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
    Discriminator(nullable:, tag:, mapping:, metadata: _) ->
      discriminator_to_json(tag, mapping)
      |> add_nullable(nullable)
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
    Uint16 -> "uint16"
    Uint32 -> "uint32"
    Uint8 -> "uint8"
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
  use nullable <- result.try(get_nullable(data))
  use metadata <- result.try(get_metadata(data))
  use tag <- result.try(dynamic.string(tag) |> push_path("discriminator"))
  use mapping <- result.try(case dict.get(data, "mapping") {
    Ok(mapping) -> Ok(mapping)
    Error(_) -> Error([dynamic.DecodeError("field", "nothing", ["mapping"])])
  })
  use properties <- result.try(
    decode_object_as_list(mapping, decode_properties_schema)
    |> push_path("mapping"),
  )
  Ok(Discriminator(nullable:, tag:, mapping: properties, metadata:))
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
    "uint16" -> Ok(Type(nullable, metadata, Uint16))
    "uint32" -> Ok(Type(nullable, metadata, Uint32))
    "uint8" -> Ok(Type(nullable, metadata, Uint8))
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

pub opaque type Generator {
  Generator(
    generate_decoders: Bool,
    generate_encoders: Bool,
    dynamic_used: Bool,
    option_used: Bool,
    dict_used: Bool,
    optional_properties_used: Bool,
    types: Dict(String, String),
    functions: Dict(String, String),
    root_name: String,
  )
}

pub fn codegen() -> Generator {
  Generator(
    dynamic_used: False,
    option_used: False,
    dict_used: False,
    optional_properties_used: False,
    generate_decoders: False,
    generate_encoders: False,
    types: dict.new(),
    functions: dict.new(),
    root_name: "Data",
  )
}

pub fn root_name(gen: Generator, root_name: String) -> Generator {
  Generator(..gen, root_name:)
}

pub fn generate_encoders(gen: Generator, x: Bool) -> Generator {
  Generator(..gen, generate_encoders: x)
}

pub fn generate_decoders(gen: Generator, x: Bool) -> Generator {
  Generator(..gen, generate_decoders: x)
}

type Out {
  Out(src: String, type_name: String)
}

pub type CodegenError {
  CannotConvertEmptyToJsonError
  EmptyEnumError
}

pub fn generate(
  gen: Generator,
  schema: RootSchema,
) -> Result(String, CodegenError) {
  let name = justin.pascal_case(gen.root_name)
  use gen <- result.try(gen_register(gen, name, schema.schema))
  use gen <- result.try(case gen.generate_decoders {
    True -> gen_add_decoder(gen, name, schema.schema)
    False -> Ok(gen)
  })
  use gen <- result.map(case gen.generate_encoders {
    True -> gen_add_encoder(gen, name, schema.schema)
    False -> Ok(gen)
  })
  gen_to_string(gen)
}

fn gen_register(
  gen: Generator,
  name: String,
  schema: Schema,
) -> Result(Generator, CodegenError) {
  case schema {
    Empty -> Ok(Generator(..gen, dynamic_used: True))
    Ref(nullable:, ..) -> Ok(gen_register_nullable(gen, nullable))
    Type(nullable:, ..) -> Ok(gen_register_nullable(gen, nullable))

    Enum(nullable:, variants:, ..) -> {
      let gen = gen_register_nullable(gen, nullable)
      gen_enum_type(gen, name, variants)
    }

    Properties(schema:, nullable:, ..) -> {
      let gen = gen_register_nullable(gen, nullable)
      gen_register_properties(gen, name, schema)
    }

    Elements(nullable:, schema:, ..) -> {
      let gen = gen_register_nullable(gen, nullable)
      gen_register(gen, name <> "Element", schema)
    }

    Values(nullable:, schema:, ..) -> {
      let gen = gen_register_nullable(gen, nullable)
      let gen = Generator(..gen, dict_used: True)
      gen_register(gen, name <> "Value", schema)
    }

    Discriminator(nullable:, metadata: _, tag: _, mapping:) -> {
      let gen = gen_register_nullable(gen, nullable)
      gen_register_discriminator(gen, name, mapping)
    }
  }
}

fn type_name(schema: Schema, name: String) -> String {
  case schema {
    Enum(..) | Properties(..) | Discriminator(..) -> name

    Ref(name:, ..) -> name

    Values(schema:, ..) -> "dict.Dict(" <> type_name(schema, name) <> ")"
    Elements(schema:, ..) -> "List(" <> type_name(schema, name) <> ")"
    Empty -> "dynamic.Dynamic"

    Type(type_:, ..) ->
      case type_ {
        Boolean -> "Bool"
        Float32 | Float64 -> "Float"
        Int16 | Int32 | Int8 | Uint16 | Uint32 | Uint8 -> "Int"
        String | Timestamp -> "String"
      }
  }
}

fn gen_register_discriminator(
  gen: Generator,
  name: String,
  mapping: List(#(String, PropertiesSchema)),
) -> Result(Generator, CodegenError) {
  use #(gen, src) <- result.try(
    list.try_fold(mapping, #(gen, []), fn(pair, mapping) {
      let name = name <> justin.pascal_case(mapping.0)
      let result = type_variant(pair.0, name, mapping.1)
      use #(gen, src) <- result.map(result)
      #(gen, [src, ..pair.1])
    }),
  )

  let src = "pub type " <> name <> " {
" <> string.join(src, "\n") <> "
}"
  let type_name = name
  gen_add_type(gen, type_name, src)
}

fn gen_register_properties(
  gen: Generator,
  name: String,
  schema: PropertiesSchema,
) -> Result(Generator, CodegenError) {
  use #(gen, src) <- result.try(type_variant(gen, name, schema))

  let src = "pub type " <> name <> " {
" <> src <> "
}"
  let type_name = name
  gen_add_type(gen, type_name, src)
}

fn type_variant(
  gen: Generator,
  name: String,
  schema: PropertiesSchema,
) -> Result(#(Generator, String), CodegenError) {
  let gen = case schema.optional_properties {
    [] -> gen
    _ -> Generator(..gen, optional_properties_used: True)
  }

  // TODO: check that all names are unique
  let PropertiesSchema(
    properties:,
    optional_properties:,
    additional_properties: _,
  ) = schema

  use gen <- result.try(
    list.try_fold(properties, gen, fn(gen, prop) {
      gen_register(gen, name <> prop.0, prop.1)
    }),
  )

  use gen <- result.try(
    list.try_fold(optional_properties, gen, fn(gen, prop) {
      let gen = Generator(..gen, option_used: True)
      gen_register(gen, name <> prop.0, prop.1)
    }),
  )

  // TODO: forbid duplicate names
  let properties =
    list.append(
      list.map(properties, fn(p) { #(p.0, p.1, False) }),
      list.map(optional_properties, fn(p) { #(p.0, p.1, True) }),
    )
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(p) {
      let n = justin.snake_case(p.0)
      "    " <> n <> ": " <> type_name(p.1, name <> justin.pascal_case(p.0))
    })
    |> string.join(",\n")

  // TODO: ensure constructor name isn't taken
  let src = "  " <> name <> "(
" <> properties <> ",
  )"

  Ok(#(gen, src))
}

fn gen_enum_type(
  gen: Generator,
  name: String,
  variants: List(String),
) -> Result(Generator, CodegenError) {
  use <- bool.guard(when: variants == [], return: Error(EmptyEnumError))
  let variants =
    variants
    |> list.map(fn(v) { "  " <> justin.pascal_case(v) <> "\n" })
    |> string.join("")
  let src = "pub type " <> name <> " {\n" <> variants <> "}"
  gen_add_type(gen, name, src)
}

fn gen_register_nullable(gen: Generator, nullable: Bool) -> Generator {
  case nullable {
    False -> gen
    True -> Generator(..gen, option_used: True)
  }
}

fn gen_add_encoder(
  gen: Generator,
  name: String,
  schema: Schema,
) -> Result(Generator, CodegenError) {
  use out <- result.try(en_schema(schema, Some("data"), name))
  let name = justin.snake_case(name) <> "_to_json"
  let src = "pub fn " <> name <> "(data: " <> out.type_name <> ") -> json.Json {
  " <> out.src <> "
}"

  gen_add_function(gen, name, src)
}

fn gen_add_decoder(
  gen: Generator,
  name: String,
  schema: Schema,
) -> Result(Generator, CodegenError) {
  use out <- result.try(de_schema(schema, name))
  let fn_name = justin.snake_case(name) <> "_decoder"
  let src =
    "pub fn " <> fn_name <> "() -> decode.Decoder(" <> out.type_name <> ") {
  " <> out.src <> "
}"

  gen_add_function(gen, name, src)
}

fn gen_add_function(
  gen: Generator,
  name: String,
  body: String,
) -> Result(Generator, CodegenError) {
  // TODO: ensure function does not already exist
  let functions = dict.insert(gen.functions, name, body)
  Ok(Generator(..gen, functions:))
}

fn gen_add_type(
  gen: Generator,
  name: String,
  body: String,
) -> Result(Generator, CodegenError) {
  // TODO: ensure type does not already exist
  let types = dict.insert(gen.types, name, body)
  Ok(Generator(..gen, types:))
}

fn gen_to_string(gen: Generator) -> String {
  let imp = fn(used, module) {
    case used {
      True -> ["import " <> module]
      False -> []
    }
  }

  let imports =
    [
      imp(gen.generate_decoders, "decode"),
      imp(gen.dict_used, "gleam/dict"),
      imp(gen.dynamic_used, "gleam/dynamic"),
      imp(gen.generate_encoders, "gleam/json"),
      imp(gen.option_used, "gleam/option"),
    ]
    |> list.flatten
    |> string.join("\n")

  let defs = fn(items) {
    items
    |> dict.to_list
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(a) { a.1 })
    |> string.join("\n\n")
  }

  let block = fn(s) {
    case s {
      "" -> []
      _ -> [s]
    }
  }

  let helper__optional_property = case
    gen.generate_encoders && gen.optional_properties_used
  {
    False -> []
    True -> [
      "fn helper__optional_property(
  object: List(#(String, json.Json)),
  key: String,
  value: option.Option(a),
  to_json: fn(a) -> json.Json,
) -> List(#(String, json.Json)), {
  case value {
    option.Some(value) -> [#(key, to_json(value)), ..object]
    option.None -> object
  }
}",
    ]
  }

  let helper__dict_to_json = case gen.generate_encoders && gen.dict_used {
    False -> []
    True -> [
      "fn helper__dict_to_json(
  data: dict.Dict(String, t),
  to_json: fn(t) -> json.Json,
) -> json.Json {
  data
  |> dict.to_list
  |> list.map(fn(pair) { #(pair.0, to_json(pair.1)) })
  |> json.object
}",
    ]
  }

  [
    block(imports),
    block(defs(gen.types)),
    block(defs(gen.functions)),
    helper__dict_to_json,
    helper__optional_property,
  ]
  |> list.flatten
  |> string.join("\n\n")
}

fn en_schema(
  schema: Schema,
  data: Option(String),
  name: String,
) -> Result(Out, CodegenError) {
  case schema {
    Discriminator(nullable:, metadata: _, mapping:, tag:) ->
      en_discriminator(mapping, tag, nullable, data, name)
    Elements(schema:, nullable:, metadata: _) ->
      en_elements(schema, nullable, data, name)
    Empty -> Error(CannotConvertEmptyToJsonError)
    Enum(nullable:, variants:, metadata: _) ->
      en_enum(variants, nullable, data, name)
    Properties(nullable:, schema:, metadata: _) ->
      en_properties_schema(schema, nullable, pro_data_name(data), name, None)
    Ref(nullable:, metadata: _, name:) -> en_ref(name, data, nullable)
    Type(type_:, nullable:, metadata: _) -> Ok(en_type(type_, nullable, data))
    Values(schema:, nullable:, metadata: _) ->
      en_values(schema, nullable, data, name)
  }
}

fn en_ref(
  name: String,
  data: Option(String),
  nullable: Bool,
) -> Result(Out, CodegenError) {
  let src = justin.snake_case(name) <> "_to_json"
  let src = case data, nullable {
    None, False -> src
    None, True -> "json.nullable(_, " <> src <> ")"
    Some(data), False -> src <> "(" <> data <> ")"
    Some(data), True -> "json.nullable(" <> data <> ", " <> src <> ")"
  }

  let type_name = justin.pascal_case(name)
  let type_name = case nullable {
    False -> type_name
    True -> "option.Option(" <> type_name <> ")"
  }

  Ok(Out(src:, type_name:))
}

fn de_ref(name: String, nullable: Bool) -> Result(Out, CodegenError) {
  let src = justin.snake_case(name) <> "_decoder()"
  let src = case nullable {
    False -> src
    True -> "decode.optional(" <> src <> ")"
  }

  let type_name = justin.pascal_case(name)
  let type_name = case nullable {
    False -> type_name
    True -> "option.Option(" <> type_name <> ")"
  }

  Ok(Out(src:, type_name:))
}

fn pro_data_name(name: Option(String)) -> PropertyDataName {
  case name {
    None -> PropertyDataNone
    Some(n) -> PropertyDataAccess(n)
  }
}

fn de_schema(schema: Schema, name: String) -> Result(Out, CodegenError) {
  case schema {
    Discriminator(nullable:, metadata: _, mapping:, tag:) ->
      de_discriminator(mapping, tag, nullable, name)
    Elements(schema:, nullable:, metadata: _) ->
      de_elements(schema, nullable, name)
    Empty -> Ok(Out("decode.dynamic", "dynamic.Dynamic"))
    Enum(nullable:, variants:, metadata: _) -> de_enum(variants, nullable, name)
    Properties(nullable:, schema:, metadata: _) ->
      de_properties_schema(schema, nullable, name)
    Ref(nullable:, metadata: _, name:) -> de_ref(name, nullable)
    Type(type_:, nullable:, metadata: _) -> Ok(de_type(type_, nullable))
    Values(schema:, nullable:, metadata: _) -> de_values(schema, nullable, name)
  }
}

fn de_discriminator(
  mapping: List(#(String, PropertiesSchema)),
  tag: String,
  nullable: Bool,
  name: String,
) -> Result(Out, CodegenError) {
  use mapping <- result.try(
    list.try_map(mapping, fn(pair) {
      let result =
        de_properties_schema(pair.1, False, name <> justin.pascal_case(pair.0))
      use out <- result.map(result)
      #(pair.0, out.src)
    }),
  )

  let clauses =
    list.map(mapping, fn(pair) { "    \"" <> pair.0 <> "\" -> " <> pair.1 })

  let src = "decode.at([\"" <> tag <> "\"], decode.string)
  |> decode.then(fn(tag) {
    case tag {
" <> string.join(clauses, "\n") <> "
      _ -> decode.fail(\"" <> name <> "\")
    }
  })"

  let type_name = case nullable {
    False -> name
    True -> "option.Option(" <> name <> ")"
  }

  Ok(Out(src:, type_name:))
}

type PropertyDataName {
  PropertyDataNone
  PropertyDataDirect
  PropertyDataAccess(String)
}

fn en_discriminator(
  mapping: List(#(String, PropertiesSchema)),
  tag: String,
  nullable: Bool,
  data: Option(String),
  name: String,
) -> Result(Out, CodegenError) {
  use properties <- result.try(
    list.try_map(mapping, fn(pair) {
      let name = name <> justin.pascal_case(name)
      let result =
        en_properties_schema(
          pair.1,
          False,
          PropertyDataDirect,
          name,
          Some(#(tag, pair.0)),
        )
      let props =
        list.append(
          list.map({ pair.1 }.properties, fn(p) { p.0 }),
          list.map({ pair.1 }.optional_properties, fn(p) { p.0 }),
        )
      use Out(src:, ..) <- result.map(result)
      #(pair.0, src, list.sort(props, string.compare))
    }),
  )

  let clauses =
    list.map(properties, fn(pair) {
      let name = justin.pascal_case(pair.0)
      let args = case pair.2 {
        [] -> ""
        a -> "(" <> string.join(a, ":, ") <> ":)"
      }
      "    " <> name <> args <> " -> " <> pair.1
    })

  let src =
    "case "
    <> option.unwrap(data, "data")
    <> " {\n"
    <> string.join(clauses, "\n")
    <> "\n  }"

  let out = case nullable {
    True -> {
      let type_name = "option.Option(" <> name <> ")"
      let data = option.unwrap(data, "data")
      let src = "case " <> data <> " {
    option.Some(data) -> " <> src <> "
    option.None -> json.null()
  }"
      Out(src:, type_name:)
    }
    False -> Out(src:, type_name: name)
  }

  case data {
    None -> Ok(Out(..out, src: "fn(data) { " <> out.src <> " }"))
    Some(_) -> Ok(out)
  }
}

fn en_properties_schema(
  schema: PropertiesSchema,
  nullable: Bool,
  data: PropertyDataName,
  name: String,
  extra: Option(#(String, String)),
) -> Result(Out, CodegenError) {
  let PropertiesSchema(
    properties:,
    optional_properties:,
    additional_properties: _,
  ) = schema
  let property_data = fn(field_name) {
    let field_name = justin.snake_case(field_name)
    case data {
      PropertyDataDirect -> field_name
      PropertyDataAccess(name) if !nullable -> name <> "." <> field_name
      _ -> "data." <> field_name
    }
  }

  use properties <- result.try(
    list.try_map(properties, fn(p) {
      let name = name <> justin.pascal_case(p.0)
      let data = property_data(p.0)
      use out <- result.map(en_schema(p.1, Some(data), name))
      #(p.0, out.src)
    }),
  )

  let properties =
    case extra {
      None -> properties
      Some(#(k, v)) -> [#(k, "json.string(\"" <> v <> "\")"), ..properties]
    }
    |> list.map(fn(p) { "\n    #(\"" <> p.0 <> "\", " <> p.1 <> ")," })

  use optionals <- result.map(
    list.try_map(optional_properties, fn(p) {
      let n = name <> justin.pascal_case(p.0)
      let d = property_data(p.0)
      use Out(src: s, ..) <- result.map(en_schema(p.1, None, name))
      "  |> helper__optional_property(" <> d <> ", \"" <> n <> "\"" <> s <> ")"
    }),
  )

  let src = case properties {
    [] -> "[]"
    p -> "[" <> string.concat(p) <> "\n  ]"
  }

  let src = case optional_properties {
    [] -> "json.object(" <> src <> ")"
    _ -> {
      src <> "\n" <> string.join(optionals, "\n") <> "\n  |> json.object"
    }
  }

  let src = case nullable {
    True -> {
      let data = case data {
        PropertyDataAccess(name) -> name
        PropertyDataDirect | PropertyDataNone -> "data"
      }
      "case " <> data <> " {
    option.Some(data) -> " <> src <> "
    option.None -> json.null()
  }"
    }
    False -> src
  }

  let src = case data {
    PropertyDataNone -> "fn(data) { " <> src <> " }"
    _ -> src
  }

  let type_name = case nullable {
    True -> "option.Option(" <> name <> ")"
    False -> name
  }

  Out(src:, type_name:)
}

fn en_values(
  schema: Schema,
  nullable: Bool,
  data: Option(String),
  position_name: String,
) -> Result(Out, CodegenError) {
  use Out(src:, type_name:) <- result.map(en_schema(schema, None, position_name))
  let type_name = "dict.Dict(String, " <> type_name <> ")"
  let data = option.unwrap(data, "_")
  case nullable {
    False -> {
      let src = "helper__dict_to_json(" <> data <> ", " <> src <> ")"
      Out(src:, type_name:)
    }
    True -> {
      let type_name = "option.Option(" <> type_name <> ")"
      let src = "helper__dict_to_json(_, " <> src <> ")"
      let src = "json.nullable(" <> data <> ", " <> src <> ")"
      Out(src:, type_name:)
    }
  }
}

fn en_enum(
  variants: List(String),
  nullable: Bool,
  data: Option(String),
  position_name: String,
) -> Result(Out, CodegenError) {
  let type_name = position_name
  let src = "json.string(case " <> option.unwrap(data, "data") <> " {\n"
  let variants =
    variants
    |> list.map(fn(v) {
      "    " <> justin.pascal_case(v) <> " -> \"" <> v <> "\"\n"
    })
    |> string.concat
  let src = src <> variants <> "  })"

  let src = case nullable || data == None {
    True -> "fn(data) { " <> src <> " }"
    False -> src
  }

  let out = case nullable {
    True -> {
      let type_name = "option.Option(" <> type_name <> ")"
      let src = case data {
        Some(data) -> "json.nullable(" <> data <> ", " <> src <> ")"
        None -> "json.nullable(_, " <> src <> ")"
      }
      Out(src:, type_name:)
    }
    False -> Out(src:, type_name:)
  }
  Ok(out)
}

fn de_properties_schema(
  schema: PropertiesSchema,
  nullable: Bool,
  name: String,
) -> Result(Out, CodegenError) {
  let PropertiesSchema(
    properties:,
    optional_properties:,
    additional_properties: _,
  ) = schema

  let properties =
    list.append(
      list.map(properties, fn(p) { #(p.0, p.1, False) }),
      list.map(optional_properties, fn(p) { #(p.0, p.1, True) }),
    )
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })

  use properties <- result.try(
    list.try_map(properties, fn(prop) {
      use s <- result.map(de_schema(prop.1, name <> justin.pascal_case(prop.0)))
      #(prop.0, s, prop.2)
    }),
  )

  let params =
    properties
    |> list.map(fn(n) {
      let name = justin.snake_case(n.0)
      "    use " <> name <> " <- decode.parameter"
    })
    |> string.join("\n")

  let fields =
    properties
    |> list.map(fn(p) {
      let field = case p.2 {
        True -> "  |> decode.optional_field(\""
        False -> "  |> decode.field(\""
      }
      field <> p.0 <> "\", " <> { p.1 }.src <> ")"
    })
    |> string.join("\n")

  let keys =
    properties
    |> list.map(fn(n) { justin.snake_case(n.0) <> ":" })
    |> string.join(", ")

  let src = "deocode.into({
" <> params <> "
    " <> name <> "(" <> keys <> ")
  })
" <> fields

  Ok(de_nullable(src, name, nullable))
}

fn en_elements(
  schema: Schema,
  nullable: Bool,
  data: Option(String),
  position_name: String,
) -> Result(Out, CodegenError) {
  use Out(src:, type_name:) <- result.map(en_schema(schema, None, position_name))
  let type_name = "List(" <> type_name <> ")"
  let data = option.unwrap(data, "_")
  case nullable {
    False -> {
      let src = "json.array(" <> data <> ", " <> src <> ")"
      Out(src:, type_name:)
    }
    True -> {
      let type_name = "option.Option(" <> type_name <> ")"
      let src = "json.array(_, " <> src <> ")"
      let src = "json.nullable(" <> data <> ", " <> src <> ")"
      Out(src:, type_name:)
    }
  }
}

fn de_enum(
  variants: List(String),
  nullable: Bool,
  position_name: String,
) -> Result(Out, CodegenError) {
  let type_name = position_name
  let src =
    "decode.then(decode.string, fn(s) {
    case s {\n"
  let variants =
    list.map(variants, fn(v) {
      "      \"" <> v <> "\" -> decode.into(" <> justin.pascal_case(v) <> ")\n"
    })
  let src = src <> string.concat(variants)
  let src = src <> "      _ -> decode.fail(" <> type_name <> ")\n"
  let src = src <> "    }\n  })"
  Ok(de_nullable(src, type_name, nullable))
}

fn de_values(
  schema: Schema,
  nullable: Bool,
  position_name: String,
) -> Result(Out, CodegenError) {
  use Out(src:, type_name:) <- result.map(de_schema(schema, position_name))
  let type_name = "dict.Dict(String, " <> type_name <> ")"
  let src = "decode.dict(decode.string, " <> src <> ")"
  de_nullable(src, type_name, nullable)
}

fn de_elements(
  schema: Schema,
  nullable: Bool,
  position_name: String,
) -> Result(Out, CodegenError) {
  use Out(src:, type_name:) <- result.map(de_schema(schema, position_name))
  let type_name = "List(" <> type_name <> ")"
  let src = "decode.list(" <> src <> ")"
  de_nullable(src, type_name, nullable)
}

fn de_type(t: Type, nullable: Bool) -> Out {
  let #(src, type_name) = case t {
    Boolean -> #("decode.bool", "Bool")
    Float32 | Float64 -> #("decode.float", "Float")
    String | Timestamp -> #("decode.string", "String")
    Int16 | Int32 | Int8 | Uint16 | Uint32 | Uint8 -> #("decode.int", "Int")
  }
  de_nullable(src, type_name, nullable)
}

fn en_type(t: Type, nullable: Bool, data: Option(String)) -> Out {
  let #(src, type_name) = case t {
    Boolean -> #("json.bool", "Bool")
    Float32 | Float64 -> #("json.float", "Float")
    String | Timestamp -> #("json.string", "String")
    Int16 | Int32 | Int8 | Uint16 | Uint32 | Uint8 -> #("json.int", "Int")
  }
  en_nullable(src, type_name, nullable, data)
}

fn en_nullable(
  src: String,
  type_name: String,
  nullable: Bool,
  data: Option(String),
) -> Out {
  case nullable {
    True -> {
      let type_name = "option.Option(" <> type_name <> ")"
      let src = case data {
        Some(data) -> "json.nullable(" <> data <> ", " <> src <> ")"
        None -> "json.nullable(_, " <> src <> ")"
      }
      Out(src:, type_name:)
    }
    False -> {
      let src = case data {
        Some(data) -> src <> "(" <> data <> ")"
        None -> src
      }
      Out(src:, type_name:)
    }
  }
}

fn de_nullable(src: String, type_name: String, nullable: Bool) -> Out {
  case nullable {
    True -> {
      let type_name = "option.Option(" <> type_name <> ")"
      let src = "decode.nullable(" <> src <> ")"
      Out(src:, type_name:)
    }
    False -> Out(src:, type_name:)
  }
}
