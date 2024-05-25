import gleam/erlang/process.{type Subject}
import gleam/http/request
import stratus
import websockets.{type Msg, Message}

const twitch_server = "http://irc-ws.chat.twitch.tv"

// A function for building the initial Twitch connection
pub fn get_twitch_subj() -> Subject(stratus.InternalMessage(Msg)) {
  // Establish a connection to the Twitch server
  let assert Ok(req) = request.to(twitch_server)
  // Build the WebSocket process
  let builder = websockets.create_websockets_builder(req)
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
  creds: LoginCredentials,
) {
  // Send the login message to the WebSocket process
  stratus.send_message(subj, Message("NICK " <> creds.username))
  stratus.send_message(subj, Message("PASS " <> creds.password))
}

// A utility function for logging in anonymously
pub fn login_anon(subj: Subject(stratus.InternalMessage(websockets.Msg))) {
  login(subj, Static("justinfan123", ""))
}
