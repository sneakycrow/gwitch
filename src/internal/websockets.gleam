import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import stratus

pub type Msg {
  Close
  Message(String)
}

pub type Message =
  stratus.InternalMessage(Msg)

pub type ReceiveTwitchMessageFn =
  fn(TwitchMessage) -> Nil

pub fn create_websockets_builder(
  req: Request(String),
  receive_message: Option(ReceiveTwitchMessageFn),
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
                // Parse out metadata from irc message
                let twitch_message = to_twitch_message(msg)
                func(twitch_message)
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

pub type MessageTypeEnum {
  PrivMsg
  Join
  TwitchSystem
  Ping
  Unknown
}

pub type TwitchMessage {
  TwitchMessage(
    user: User,
    message: String,
    channel: String,
    message_type: MessageTypeEnum,
  )
}

pub type User {
  User(username: String)
}

// A function for converting a generic IRC message to a Twitch message
// This parses the metadata out of the string within the IRC message
pub fn to_twitch_message(irc_message: String) -> TwitchMessage {
  // A cleaned version for debugging purposes
  let assert Ok(cleaned_message) = clean_message(irc_message)
  // Split the message into parts
  let parts = string.split(irc_message, " ")
  // Certain messages have different part structures, but this should catch everything we care about
  case parts {
    [_, "JOIN", _] -> {
      TwitchMessage(User("twitch"), cleaned_message, "system", Join)
    }
    // This line should catch most messages
    [user_repeated, "PRIVMSG", channel, ..message] -> {
      // Parse the user out of user repeated
      let user_name = clean_username(user_repeated)
      let assert Ok(user_msg) = clean_message(string.join(message, " "))
      TwitchMessage(User(user_name), user_msg, channel, PrivMsg)
    }
    ["PING", ..message] -> {
      // Strip the initial : from the message
      TwitchMessage(User("twitch"), string.join(message, " "), "system", Ping)
    }
    _ -> {
      TwitchMessage(User("unknown"), cleaned_message, "system", Unknown)
    }
  }
}

pub fn to_pretty_string(msg: TwitchMessage) -> String {
  message_type_to_string(msg.message_type)
  <> " "
  <> msg.channel
  <> "/"
  <> msg.user.username
  <> ": "
  <> msg.message
}

fn message_type_to_string(msg: MessageTypeEnum) -> String {
  case msg {
    PrivMsg -> "PRIVMSG"
    Join -> "JOIN"
    TwitchSystem -> "TwitchSystem"
    Ping -> "PING"
    Unknown -> "Unknown"
  }
}

fn clean_message(raw_msg: String) -> Result(String, Nil) {
  use msg <- result.try(
    // Remove the newline character
    string.replace(raw_msg, "\r\n", "")
    // Remove the initial :
    |> string.split_once(":"),
  )

  Ok(msg.1)
}

fn clean_username(raw_username: String) -> String {
  case string.split(raw_username, "!") {
    [username, _] -> {
      // Remove the initial : from the username
      string.slice(username, 1, string.length(username))
    }
    _ -> panic as "Invalid username!"
  }
}
