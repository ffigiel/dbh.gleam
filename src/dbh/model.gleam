import gleam/option
import gleam/string
import gleam/list
import gleam/int

pub type Model {
  Model(table: String, fields: List(#(String, Field)))
}

pub type Field {
  BigInt(index: Index, null: Bool, default: option.Option(Int))
  Text(index: Index, null: Bool, default: option.Option(String))
  TimestampTz(index: Index, null: Bool, default: option.Option(String))
}

pub type Index {
  NoIndex
  Index
  Unique
  PrimaryKey
}

// CREATE TABLE
pub fn serialize(m: Model) -> String {
  let parts = [
    "create table ",
    m.table,
    "\n  ( ",
    serialize_fields(m.fields),
    "\n  );",
    "\n",
    serialize_fields_indexes(m),
  ]
  parts
  |> string.join("")
}

fn serialize_fields(fs: List(#(String, Field))) -> String {
  list.map(fs, serialize_field)
  |> string.join("\n  , ")
}

// FIELDS
fn serialize_field(ff: #(String, Field)) -> String {
  let #(name, f) = ff
  let parts = [
    name,
    case f {
      BigInt(_, _, _) -> serialize_big_int_field(f)
      Text(_, _, _) -> serialize_text_field(f)
      TimestampTz(_, _, _) -> serialize_timestamp_tz_field(f)
    },
  ]
  parts
  |> string.join(" ")
}

fn serialize_big_int_field(f: Field) -> String {
  assert BigInt(index, null, default) = f
  let parts = [
    case index {
      PrimaryKey -> "bigserial"
      _ -> "bigint"
    },
    serialize_index(index),
    serialize_null(null),
    serialize_default_int(default),
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

fn serialize_text_field(f: Field) -> String {
  assert Text(index, null, default) = f
  let parts = [
    "text",
    serialize_index(index),
    serialize_null(null),
    serialize_default_string(default),
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

fn serialize_timestamp_tz_field(f: Field) -> String {
  assert TimestampTz(index, null, default) = f
  let parts = [
    "timestamp with time zone",
    serialize_index(index),
    serialize_null(null),
    serialize_default_string(default),
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

// FIELD TAGS
fn serialize_index(index: Index) -> String {
  case index {
    PrimaryKey -> "primary key"
    Unique -> "unique"
    _ -> ""
  }
}

fn serialize_null(null: Bool) -> String {
  case null {
    True -> ""
    False -> "not null"
  }
}

fn serialize_default_int(default: option.Option(Int)) -> String {
  case default {
    option.Some(d) -> string.concat(["default ", int.to_string(d)])
    option.None -> ""
  }
}

fn serialize_default_string(default: option.Option(String)) -> String {
  case default {
    option.Some(d) -> string.concat(["default ", d])
    option.None -> ""
  }
}

fn string_not_empty(s: String) -> Bool {
  s != ""
}

// CREATE INDEX
fn serialize_fields_indexes(m: Model) -> String {
  list.map(m.fields, serialize_field_index(m.table, _))
  |> list.filter(string_not_empty)
  |> string.join("\n")
}

fn serialize_field_index(table: String, ff: #(String, Field)) -> String {
  let #(name, f) = ff
  let has_index = case f {
    BigInt(_, _, index: index) -> index == Index
    Text(_, _, index: index) -> index == Index
    TimestampTz(_, _, index: index) -> index == Index
  }
  case has_index {
    False -> ""
    True -> string.concat(["create index on ", table, " (", name, ");"])
  }
}
