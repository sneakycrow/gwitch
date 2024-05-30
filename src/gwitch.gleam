import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import internal/websockets.{type Message, Message}
import logging
import stratus

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

pub type ReceiveMessageFn =
  fn(TwitchMessage) -> Nil

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

/// A function for connecting to a twitch channel. Returns a subject for sending and receiving messages
pub fn connect(config: Config, channel: String) -> Subject(Message) {
  // Establish a connection to the Twitch server and create the builder
  let assert Ok(req) = request.to(twitch_server)
  let assert Ok(subj) =
    websockets.create_websockets_builder(req, Some(config.on_receive))
  // Log in to the Twitch server and join the channel
  login(subj, config)
  |> join_channel(channel)
}

const twitch_server = "http://irc-ws.chat.twitch.tv"

/// A function for joining a Twitch channel
pub fn join_channel(subj: Subject(Message), channel: String) -> Subject(Message) {
  // Send the join message to the WebSocket process
  send_message(subj, "JOIN #" <> channel)
  // Return the subject
  subj
}

/// A function for sending a message to a Twitch channel
pub fn send_message(subj: Subject(Message), msg: String) {
  stratus.send_message(subj, Message(msg))
}

pub opaque type Config {
  Config(creds: Option(LoginCredentials), on_receive: fn(String) -> Nil)
}

/// A function for creating a new Config
pub fn create_config(
  creds: Option(LoginCredentials),
  on_receive: fn(TwitchMessage) -> Nil,
) -> Config {
  // Add a wrapper around the on_receive function to convert the message to a TwitchMessage
  let on_receive = fn(msg: String) { on_receive(to_twitch_message(msg)) }
  Config(creds, on_receive)
}

pub fn default_config() -> Config {
  // By default, we just log the messages
  let receive_fn = fn(msg: TwitchMessage) {
    case msg.message_type {
      PrivMsg -> {
        logging.log(logging.Info, to_pretty_string(msg))
      }
      Join -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      TwitchSystem -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      Ping -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      Unknown -> {
        logging.log(logging.Error, to_pretty_string(msg))
      }
    }
  }
  // Add a wrapper around the on_receive function to convert the message to a TwitchMessage
  let on_receive = fn(msg: String) { receive_fn(to_twitch_message(msg)) }
  Config(None, on_receive)
}

/// Credentials for authenticating with Twitch
/// Not required for anonymous connections
pub type LoginCredentials {
  Static(username: String, password: String)
}

/// A function for logging into Twitch
/// Pass `None` for the creds to use the an anonymous account
pub fn login(subj: Subject(Message), config: Config) -> Subject(Message) {
  let #(username, password) = case config.creds {
    Some(creds) -> #(creds.username, creds.password)
    None -> #("justinfan123", "gibberish")
  }
  // Send the login message to the WebSocket process
  stratus.send_message(subj, Message("PASS " <> password))
  stratus.send_message(subj, Message("NICK " <> username))
  subj
}
