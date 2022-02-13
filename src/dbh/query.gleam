import dbh/model
import gleam/string
import gleam/list
import gleam/int

pub type Query {
  Query(model: model.Model, filters: List(Filter))
}

pub type Cond {
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

pub type Filter =
  #(String, Cond, Param)

pub fn get(model: model.Model, filters: List(Filter)) -> Query {
  Query(model, filters)
}

pub fn serialize(query: Query) -> #(String, List(Param)) {
  let #(filters, params) = serialize_filters(query.filters)
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

fn serialize_filters(ff: List(Filter)) -> #(String, List(Param)) {
  let #(filters, params) =
    list.map(ff, serialize_filter)
    |> list.unzip
  #(
    filters
    |> string.join(" and "),
    params,
  )
}

fn serialize_filter(f: Filter) -> #(String, Param) {
  let #(name, cond, param) = f
  let parts = [name, serialize_cond(cond), "?"]
  #(string.join(parts, " "), param)
}

fn serialize_cond(cond: Cond) -> String {
  case cond {
    Lt -> "<"
    Lte -> "<="
    Eq -> "="
    Gt -> ">"
    Gte -> ">="
  }
}
