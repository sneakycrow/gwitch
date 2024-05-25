import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/io
import gleam/option.{None}
import gleam/otp/actor
import stratus

pub type Msg {
  Close
  Message(String)
}

// TODO: Add parser to parse out metadata from irc message
// TODO: Add ability to pass closure to handle messages
pub fn create_websockets_builder(req: Request(String)) {
  stratus.websocket(
    request: req,
    init: fn() { #(Nil, None) },
    loop: fn(msg, state, conn) {
      case msg {
        stratus.Text(msg) -> {
          io.println("Received msg " <> msg)
          let assert Ok(_resp) =
            stratus.send_text_message(conn, "hello, world!")
          actor.continue(state)
        }
        stratus.User(Message(msg)) -> {
          io.debug(#("Received message", msg))
          let assert Ok(_resp) = stratus.send_text_message(conn, msg)
          actor.continue(state)
        }
        stratus.Binary(_msg) -> {
          io.println("Received binary message")
          actor.continue(state)
        }
        stratus.User(Close) -> {
          let assert Ok(_) = stratus.close(conn)
          actor.Stop(process.Normal)
        }
      }
    },
  )
  |> stratus.on_close(fn(_state) { io.println("oh noooo") })
}
