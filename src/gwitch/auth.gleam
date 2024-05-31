import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gwitch/messages.{type ReceiveMessageFn, type TwitchMessage}
import gwitch/websockets.{type Message, Message}
import logging
import stratus

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

/// Configuration for the connection to Twitch, as well as a callback for when messages are received
pub type Config {
  Config(creds: Option(LoginCredentials), on_receive: ReceiveMessageFn)
}

/// A function for creating a new Config
pub fn create_config(
  creds: Option(LoginCredentials),
  on_receive: ReceiveMessageFn,
) -> Config {
  Config(creds, on_receive)
}

/// A basic function that will log all messages
pub fn default_config() -> Config {
  let on_receive = fn(msg: TwitchMessage) {
    logging.log(logging.Info, messages.to_string(msg))
    msg
  }
  Config(None, on_receive)
}
