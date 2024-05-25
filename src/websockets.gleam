import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/io
import gleam/option.{type Option}
import gleam/otp/actor
import stratus

pub type Msg {
  Close
  Message(String)
}

// TODO: Add parser to parse out metadata from irc message
// TODO: Add ability to pass closure to handle messages
pub fn create_websockets_builder(
  req: Request(String),
  initializer: fn() -> #(a, Option(process.Selector(Msg))),
) {
  stratus.websocket(request: req, init: initializer, loop: fn(msg, state, conn) {
    case msg {
      stratus.Text(msg) -> {
        io.println("Received message " <> msg)
        // let assert Ok(_resp) = stratus.send_text_message(conn, "hello, world!")
        // io.debug(#("Sent message response", resp))
        actor.continue(state)
      }
      stratus.User(Message(msg)) -> {
        io.debug(#("Sent message", msg))
        let assert Ok(_resp) = stratus.send_text_message(conn, msg)
        // io.debug(#("Sent message response", resp))
        actor.continue(state)
      }
      stratus.Binary(_msg) -> {
        io.debug("Received binary message")
        actor.continue(state)
      }
      stratus.User(Close) -> {
        io.debug("Close message sent")
        let assert Ok(_) = stratus.close(conn)
        actor.Stop(process.Normal)
      }
    }
  })
  |> stratus.on_close(fn(_state) { io.println("Closing Connection!") })
}
