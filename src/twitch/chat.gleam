import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/option.{type Option, None, Some}
import stratus
import websockets.{type Msg, Message}

const twitch_server = "http://irc-ws.chat.twitch.tv"

// A function for connecting to a twitch channel. Returns a subject for sending and receiving messages
pub fn connect(
  channel: String,
  creds: Option(LoginCredentials),
) -> Subject(stratus.InternalMessage(Msg)) {
  // Get the subject for the Twitch connection
  let twitch_subj = get_twitch_subj()
  // Log into the Twitch connection
  login(twitch_subj, creds)
  // Join the target channel
  join_channel(twitch_subj, channel)
  // Return the subject
  twitch_subj
}

// A function for building the initial Twitch connection
pub fn get_twitch_subj() -> Subject(stratus.InternalMessage(Msg)) {
  // Establish a connection to the Twitch server
  let assert Ok(req) = request.to(twitch_server)
  // Create an initialization function for when the WebSocket process is built
  let initializer = fn() { #(Nil, None) }
  // Build the WebSocket process
  let builder = websockets.create_websockets_builder(req, initializer)
  // Create a subject from the builder we can send and receive messages to/from
  let assert Ok(subj) = stratus.initialize(builder)
  // Return the subject
  subj
}

pub type LoginCredentials {
  Static(username: String, password: String)
}

// A function for logging into Twitch
pub fn login(
  subj: Subject(stratus.InternalMessage(websockets.Msg)),
  creds: Option(LoginCredentials),
) {
  let #(username, password) = case creds {
    Some(creds) -> #(creds.username, creds.password)
    None -> #("justinfan123", "gibberish")
  }
  // Send the login message to the WebSocket process
  stratus.send_message(subj, Message("NICK " <> username))
  stratus.send_message(subj, Message("PASS " <> password))
}

// A function for joining a Twitch channel
pub fn join_channel(
  subj: Subject(stratus.InternalMessage(websockets.Msg)),
  channel: String,
) {
  // Send the join message to the WebSocket process
  stratus.send_message(subj, Message("JOIN #" <> channel))
}
