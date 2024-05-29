import auth.{login}
import config.{type Config, default_config}
import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/option.{Some}
import internal/websockets.{type Message, type ReceiveTwitchMessageFn, Message}
import stratus

/// A function for connecting to a twitch channel. Returns a subject for sending and receiving messages
pub fn connect(channel: String, config: Config) -> Subject(Message) {
  // Get the subject for the Twitch connection
  let twitch_subj = get_twitch_subj(config.on_receive)
  // Log into the Twitch connection
  login(twitch_subj, config.creds)
  // Join the target channel
  join_channel(twitch_subj, channel)
  // Return the subject
  twitch_subj
}

const twitch_server = "http://irc-ws.chat.twitch.tv"

/// A function for building the initial Twitch connection
pub fn get_twitch_subj(
  receive_msg_fn: ReceiveTwitchMessageFn,
) -> Subject(Message) {
  // Establish a connection to the Twitch server
  let assert Ok(req) = request.to(twitch_server)
  // Build the WebSocket process and get the subject
  let assert Ok(subj) =
    websockets.create_websockets_builder(req, Some(receive_msg_fn))
  // Return the subject
  subj
}

/// A function for configuring the Twitch connection
pub fn create_config() -> Config {
  // TODO: Add a way to add custom handler
  default_config()
}

/// A function for joining a Twitch channel
pub fn join_channel(subj: Subject(Message), channel: String) {
  // Send the join message to the WebSocket process
  send_message(subj, "JOIN #" <> channel)
}

/// A function for sending a message to a Twitch channel
pub fn send_message(subj: Subject(Message), msg: String) {
  stratus.send_message(subj, Message(msg))
}
