import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import stratus

pub type Msg {
  Close
  Message(String)
}

pub type Message =
  stratus.InternalMessage(Msg)

pub fn create_websockets_builder(
  req: Request(String),
  receive_message: Option(fn(String) -> Nil),
) -> Result(process.Subject(Message), actor.StartError) {
  let builder =
    stratus.websocket(
      request: req,
      init: fn() { #(Nil, None) },
      loop: fn(msg, state, conn) {
        case msg {
          stratus.Text(msg) -> {
            case receive_message {
              None -> Nil
              Some(func) -> {
                func(msg)
              }
            }
            actor.continue(state)
          }
          stratus.User(Message(msg)) -> {
            let assert Ok(_resp) = stratus.send_text_message(conn, msg)
            actor.continue(state)
          }
          stratus.Binary(_msg) -> {
            actor.continue(state)
          }
          stratus.User(Close) -> {
            let assert Ok(_) = stratus.close(conn)
            actor.Stop(process.Normal)
          }
        }
      },
    )
    |> stratus.on_close(fn(_state) { io.println("Closing Connection!") })
  // Create a subject from the builder we can send and receive messages to/from
  stratus.initialize(builder)
}
