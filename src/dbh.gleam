import dbh/model
import dbh/query
import gleam/io
import gleam/option

const user = model.Model(
  table: "users",
  fields: [
    #(
      "pk",
      model.BigInt(index: model.PrimaryKey, null: False, default: option.None),
    ),
    #(
      "email",
      model.Text(index: model.Unique, null: False, default: option.None),
    ),
    #(
      "created_on",
      model.TimestampTz(
        index: model.Index,
        null: False,
        default: option.Some("now()"),
      ),
    ),
  ],
)

pub fn main() {
  io.println("-- create")
  user
  |> model.serialize
  |> io.println
  io.println("-- query")
  let #(query, params) =
    user
    |> query.get(query.Any([
      query.Where("pk", query.Lt, query.Int(3)),
      query.All([
        query.Where("pk", query.Gte, query.Int(4)),
        query.Where("email", query.Eq, query.String("user@example.com")),
      ]),
    ]))
    |> query.serialize
  io.println(query)
  io.debug(params)
}
