import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/option.{Some}
import gwitch/auth.{type Config, login}
import gwitch/messages.{to_twitch_message}
import gwitch/websockets.{type Message, Message}
import stratus

/// The Twitch server URL
const twitch_server = "http://irc-ws.chat.twitch.tv"

/// A function for connecting to a twitch channel. Returns a subject for sending and receiving messages
pub fn connect(config: Config, channel: String) -> Subject(Message) {
  // Establish a connection to the Twitch server and create the builder
  let assert Ok(req) = request.to(twitch_server)
  // Create a wrapper around the receive handler that translates the string to a message
  let on_receive = fn(msg) { to_twitch_message(msg) |> config.on_receive }
  let assert Ok(subj) =
    websockets.create_websockets_builder(req, Some(on_receive))
  // Log in to the Twitch server and join the channel
  login(subj, config)
  |> join_channel(channel)
}

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
