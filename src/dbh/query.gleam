import dbh/model
import gleam/string
import gleam/list
import gleam/int

pub type Query {
  Query(model: model.Model, condition: Condition)
}

pub type Condition {
  Where(field: String, cmp: Cmp, param: Param)
  All(qq: List(Condition))
  Any(qq: List(Condition))
}

pub type Cmp {
  Lt
  Lte
  Gt
  Gte
  Eq
}

pub type Param {
  Int(i: Int)
  String(s: String)
}

pub fn get(model: model.Model, condition: Condition) -> Query {
  Query(model, condition)
}

pub fn serialize(query: Query) -> #(String, List(Param)) {
  let #(filters, params) = serialize_condition(query.condition)
  let parts = [
    "select\n",
    "  *\n",
    "from\n",
    "  ",
    query.model.table,
    "\n",
    "where\n",
    "  ",
    filters,
  ]
  #(
    parts
    |> string.join(""),
    params,
  )
}

fn serialize_condition(condition: Condition) -> #(String, List(Param)) {
  case condition {
    Where(field, cmp, param) -> serialize_condition_where(field, cmp, param)
    All(cc) -> serialize_conditions(cc, "and")
    Any(cc) -> serialize_conditions(cc, "or")
  }
}

fn serialize_condition_where(
  field: String,
  cmp: Cmp,
  param: Param,
) -> #(String, List(Param)) {
  let parts = [field, serialize_cmp(cmp), "?"]
  #(string.join(parts, " "), [param])
}

fn serialize_conditions(
  cc: List(Condition),
  operator: String,
) -> #(String, List(Param)) {
  let #(filters, params) =
    list.map(cc, serialize_condition)
    |> list.unzip
  #(
    filters
    |> string.join(add_spaces(operator))
    |> add_parens,
    list.flatten(params),
  )
}

fn add_parens(s: String) -> String {
  string.concat(["(", s, ")"])
}

fn add_spaces(s: String) -> String {
  string.concat([" ", s, " "])
}

fn serialize_cmp(cmp: Cmp) -> String {
  case cmp {
    Lt -> "<"
    Lte -> "<="
    Eq -> "="
    Gt -> ">"
    Gte -> ">="
  }
}