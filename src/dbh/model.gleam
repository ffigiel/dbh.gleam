import gleam/option
import gleam/string
import gleam/list
import gleam/int

pub type Model {
  Model(table: String, fields: List(#(String, Field)))
}

pub type Field {
  BigIntField(BigIntFieldSpec)
  TextField(TextFieldSpec)
  TimestampTzField(TimestampTzFieldSpec)
}

pub type BigIntFieldSpec {
  BigIntFieldSpec(index: Index, null: Bool, default: option.Option(Int))
}

pub type TextFieldSpec {
  TextFieldSpec(index: Index, null: Bool, default: option.Option(String))
}

pub type TimestampTzFieldSpec {
  TimestampTzFieldSpec(index: Index, null: Bool, default: option.Option(String))
}

pub type Index {
  NoIndex
  Index
  Unique
  PrimaryKey
}

pub fn serialize(m: Model) -> String {
  let parts = [
    "create table ",
    m.table,
    "\n  ( ",
    serialize_fields(m.fields),
    "\n  );",
  ]
  parts
  |> string.join("")
}

fn serialize_fields(fs: List(#(String, Field))) -> String {
  list.map(fs, serialize_field)
  |> string.join("\n  , ")
}

fn serialize_field(ff: #(String, Field)) -> String {
  let #(name, f) = ff
  let parts = [
    name,
    case f {
      BigIntField(bif) -> serialize_big_int_field(bif)
      TextField(tf) -> serialize_text_field(tf)
      TimestampTzField(ttf) -> serialize_timestamp_tz_field(ttf)
    },
  ]
  parts
  |> string.join(" ")
}

fn serialize_big_int_field(f: BigIntFieldSpec) -> String {
  let parts = [
    case f.index {
      PrimaryKey -> "bigserial primary key"
      Unique -> "bigint unique"
      _ -> "bigint"
    },
    case f.null {
      True -> ""
      False -> "not null"
    },
    case f.default {
      option.Some(d) -> string.concat(["default ", int.to_string(d)])
      option.None -> ""
    },
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

fn serialize_text_field(f: TextFieldSpec) -> String {
  let parts = [
    "text",
    case f.index {
      PrimaryKey -> "primary key"
      Unique -> "unique"
      _ -> ""
    },
    case f.null {
      True -> ""
      False -> "not null"
    },
    case f.default {
      option.Some(d) -> string.concat(["default ", d])
      option.None -> ""
    },
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

fn serialize_timestamp_tz_field(f: TimestampTzFieldSpec) -> String {
  let parts = [
    "timestamp with time zone",
    case f.index {
      PrimaryKey -> "primary key"
      Unique -> "unique"
      _ -> ""
    },
    case f.null {
      True -> ""
      False -> "not null"
    },
    case f.default {
      option.Some(d) -> string.concat(["default ", d])
      option.None -> ""
    },
  ]
  parts
  |> list.filter(string_not_empty)
  |> string.join(" ")
}

fn string_not_empty(s: String) -> Bool {
  s != ""
}
