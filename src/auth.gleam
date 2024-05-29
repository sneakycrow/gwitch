import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import internal/websockets.{type Message, Message}
import stratus

/// Credentials for authenticating with Twitch
/// Not required for anonymous connections
pub type LoginCredentials {
  Static(username: String, password: String)
}

/// A function for logging into Twitch
/// Pass `None` for the creds to use the an anonymous account
pub fn login(subj: Subject(Message), creds: Option(LoginCredentials)) {
  let #(username, password) = case creds {
    Some(creds) -> #(creds.username, creds.password)
    None -> #("justinfan123", "gibberish")
  }
  // Send the login message to the WebSocket process
  stratus.send_message(subj, Message("PASS " <> password))
  stratus.send_message(subj, Message("NICK " <> username))
}
