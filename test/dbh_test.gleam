import gleeunit
import gleam/pgo
import gleam/dynamic
import gleam/option
import gleam/list
import dbh/model
import dbh/query
import gleeunit/should
import gleam/io
import gleam/pair

pub fn main() {
  let db = get_db()

  // create model tables
  let return_type = fn(_) { Ok(Nil) }
  [user]
  |> list.each(fn(m: model.Model) {
    [model.serialize_table(m), ..model.serialize_indexes(m)]
    |> list.each(fn(sql: String) {
      assert Ok(_) = pgo.execute(sql, db, [], return_type)
    })
  })

  // response.rows
  // |> should.equal([#("Nubi", 3, "black", ["Al", "Cutlass"])])
  gleeunit.main()
}

fn get_db() -> pgo.Connection {
  pgo.connect(pgo.Config(..pgo.default_config(), port: 5932, database: "test"))
}

const user = model.Model(
  table: "users",
  fields: [
    model.BigInt(
      col: "pk",
      index: model.PrimaryKey,
      null: False,
      default: option.None,
    ),
    model.Text(
      col: "email",
      index: model.Unique,
      null: False,
      default: option.None,
    ),
    model.TimestampTz(
      col: "created_on",
      index: model.Index,
      null: False,
      default: option.Some("now()"),
    ),
    model.Bool(
      col: "wants_newsletter",
      index: model.NoIndex,
      null: False,
      default: option.Some(False),
    ),
  ],
)

pub fn insert_select_test() {
  let db = get_db()
  let decode_user = fn(a) {
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic_datetime, dynamic.bool)(
      a,
    )
  }
  let fields = [
    #("email", pgo.text("user1@example.com")),
    #("wants_newsletter", pgo.bool(True)),
  ]
  let sql = query.serialize_insert(user, list.map(fields, pair.first))
  let res = pgo.execute(sql, db, list.map(fields, pair.second), decode_user)
  should.be_ok(res)
  assert Ok(res) = res
  should.equal(res.count, 1)
  assert [user] = res.rows
  let #(pk, email, datetime, wants_newsletter) = user
  should.equal(pk, 1)
  should.equal(email, "user1@example.com")
  let #(#(year, _, _), _) = datetime
  should.be_true(year >= 2022)
  should.be_true(year < 2222)
  should.equal(wants_newsletter, True)
}

fn dynamic_datetime(a) {
  let date = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int)
  let time = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.float)
  dynamic.tuple2(date, time)(a)
}
