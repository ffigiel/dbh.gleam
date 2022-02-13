import gleam/option
import gleam/string
import gleam/list
import gleam/int

pub type Model {
  Model(table: String, fields: List(Field))
}

pub type Field {
  BigInt(col: String, index: Index, null: Bool, default: option.Option(Int))
  Text(col: String, index: Index, null: Bool, default: option.Option(String))
  TimestampTz(
    col: String,
    index: Index,
    null: Bool,
    default: option.Option(String),
  )
  Bool(col: String, index: Index, null: Bool, default: option.Option(Bool))
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

fn serialize_fields(fs: List(Field)) -> String {
  list.map(fs, serialize_field)
  |> string.join("\n  , ")
}

// FIELDS
fn serialize_field(f: Field) -> String {
  let parts = [
    serialize_field_col(f),
    case f {
      BigInt(_, _, _, _) -> serialize_big_int_field(f)
      Text(_, _, _, _) -> serialize_text_field(f)
      TimestampTz(_, _, _, _) -> serialize_timestamp_tz_field(f)
      Bool(_, _, _, _) -> serialize_bool_field(f)
    },
  ]
  parts
  |> string.join(" ")
}

fn serialize_field_col(f: Field) -> String {
  case f {
    BigInt(_, _, _, col: col) -> col
    Text(_, _, _, col: col) -> col
    TimestampTz(_, _, _, col: col) -> col
    Bool(_, _, _, col: col) -> col
  }
}

fn serialize_big_int_field(f: Field) -> String {
  assert BigInt(_, index, null, default) = f
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
  assert Text(_, index, null, default) = f
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
  assert TimestampTz(_, index, null, default) = f
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

fn serialize_bool_field(f: Field) -> String {
  assert Bool(_, index, null, default) = f
  let parts = [
    "bool",
    serialize_index(index),
    serialize_null(null),
    serialize_default_bool(default),
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

fn serialize_default_bool(default: option.Option(Bool)) -> String {
  case default {
    option.Some(True) -> "default true"
    option.Some(False) -> "default false"
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

fn serialize_field_index(table: String, f: Field) -> String {
  let col = serialize_field_col(f)
  let has_index = case f {
    BigInt(_, _, _, index: index) -> index == Index
    Text(_, _, _, index: index) -> index == Index
    TimestampTz(_, _, _, index: index) -> index == Index
    Bool(_, _, _, index: index) -> index == Index
  }
  case has_index {
    False -> ""
    True -> string.concat(["create index on ", table, " (", col, ");"])
  }
}
