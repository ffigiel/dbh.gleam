import dbh/model
import gleam/io
import gleam/option

const user = model.Model(
  table: "user",
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
  user
  |> io.debug
  |> model.serialize
  |> io.print
}
