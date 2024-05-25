import auth.{type LoginCredentials}
import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/option.{type Option, Some}
import internal/websockets.{type Message, new_priv_msg, send_message}
import stratus

const twitch_server = "http://irc-ws.chat.twitch.tv"

/// A function for connecting to a twitch channel. Returns a subject for sending and receiving messages
pub fn connect(
  channel: String,
  creds: Option(LoginCredentials),
) -> Subject(Message) {
  // Get the subject for the Twitch connection
  let twitch_subj = get_twitch_subj()
  // Log into the Twitch connection
  auth.login(twitch_subj, creds)
  // Join the target channel
  join_channel(twitch_subj, channel)
  // Return the subject
  twitch_subj
}

/// A function for building the initial Twitch connection
pub fn get_twitch_subj() -> Subject(Message) {
  // Establish a connection to the Twitch server
  let assert Ok(req) = request.to(twitch_server)
  // Create an initialization function for when the WebSocket process is built
  let receive_msg_fn = fn(_msg) { Nil }
  // Build the WebSocket process and get the subject
  let assert Ok(subj) =
    websockets.create_websockets_builder(req, Some(receive_msg_fn))
  // Return the subject
  subj
}

/// A function for joining a Twitch channel
pub fn join_channel(
  subj: Subject(stratus.InternalMessage(websockets.Msg)),
  channel: String,
) {
  // Send the join message to the WebSocket process
  send_message(subj, new_priv_msg("JOIN #" <> channel))
}
