import dbh/model
import gleam/io
import gleam/option

const user = model.Model(
  table: "user",
  fields: [
    #(
      "pk",
      model.BigIntField(
        model.BigIntFieldSpec(
          index: model.PrimaryKey,
          null: False,
          default: option.None,
        ),
      ),
    ),
    #(
      "email",
      model.TextField(
        model.TextFieldSpec(
          index: model.Unique,
          null: False,
          default: option.None,
        ),
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
