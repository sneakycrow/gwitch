import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import stratus

pub opaque type Msg {
  Close
  PrivMsg(String)
}

pub fn new_priv_msg(msg: String) -> Msg {
  PrivMsg(msg)
}

pub type Message =
  stratus.InternalMessage(Msg)

pub type ReceiveMessageFn =
  fn(String) -> Nil

// TODO: Add parser to parse out metadata from irc message
pub fn create_websockets_builder(
  req: Request(String),
  receive_message: Option(ReceiveMessageFn),
) -> Result(process.Subject(Message), actor.StartError) {
  let builder =
    stratus.websocket(
      request: req,
      init: fn() { #(Nil, None) },
      loop: fn(msg, state, conn) {
        case msg {
          stratus.Text(msg) -> {
            io.debug("Receiving message: " <> msg)
            // TODO: Parse out metadata from irc message
            case receive_message {
              None -> Nil
              Some(func) -> func(msg)
            }
            actor.continue(state)
          }
          stratus.User(PrivMsg(msg)) -> {
            io.debug(#("Sending message: ", msg))
            let assert Ok(_resp) = stratus.send_text_message(conn, msg)
            actor.continue(state)
          }
          stratus.Binary(_msg) -> {
            io.debug("Receiving binary message")
            actor.continue(state)
          }
          stratus.User(Close) -> {
            io.debug("Sending close message")
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
