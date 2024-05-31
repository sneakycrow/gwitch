import gleam/result
import gleam/string
import logging

/// The different types of messages that can be received from Twitch
pub type TwitchMessage {
  PrivMsg(user: User, channel: String, message: String)
  Join(user: User, channel: String)
  TwitchSystem(message: String)
  Ping(message: String)
  Unknown(message: String)
}

/// A function for receiving a message from Twitch
pub type ReceiveMessageFn =
  fn(TwitchMessage) -> TwitchMessage

/// The relevant user to a message
pub type User {
  User(username: String)
}

/// A function for making the raw IRC message human-readable
pub fn clean_message(raw_msg: String) -> Result(String, Nil) {
  use msg <- result.try(
    // Remove the newline character
    string.replace(raw_msg, "\r\n", "")
    // Remove the initial :
    |> string.split_once(":"),
  )

  Ok(msg.1)
}

/// A function for cleaning the channel out of the raw IRC message
pub fn clean_channel(raw_channel: String) -> String {
  // Expected input #channel_name\r\n
  // Remove the initial # from the channel
  // Remove the newline character
  string.replace(
    string.slice(raw_channel, 1, string.length(raw_channel)),
    "\r\n",
    "",
  )
}

/// A function for cleaning the username out of the raw IRC message
pub fn clean_username(raw_username: String) -> String {
  case string.split(raw_username, "!") {
    [username, _] -> {
      // Remove the initial : from the username
      string.slice(username, 1, string.length(username))
    }
    _ -> panic as "Invalid username!"
  }
}

// A function for converting a generic IRC message to a Twitch message
// This parses the metadata out of the string within the IRC message
pub fn to_twitch_message(irc_message: String) -> TwitchMessage {
  // Split the message into parts
  let parts = string.split(irc_message, " ")
  // Certain messages have different part structures, but this should catch everything we care about
  case parts {
    // Join message for our user
    [user_repeated, "JOIN", channel] -> {
      let channel = clean_channel(channel)
      let user = clean_username(user_repeated)
      // TODO: Parse user
      Join(User(user), channel)
    }
    // Another Join?
    [user_repeated, "JOIN", channel, ..message] -> {
      let channel = clean_channel(channel)
      let user = clean_username(user_repeated)
      let assert Ok(clean_msg) = clean_message(string.join(message, " "))
      logging.log(logging.Debug, clean_msg)
      Join(User(user), channel)
    }
    // User sent messages
    [user_repeated, "PRIVMSG", channel, ..message] -> {
      // Parse the user out of user repeated
      let user_name = clean_username(user_repeated)
      let assert Ok(user_msg) = clean_message(string.join(message, " "))
      PrivMsg(User(user_name), channel, user_msg)
    }
    // Ping message
    ["PING", ..message] -> {
      let assert Ok(clean_msg) = clean_message(string.join(message, ""))
      Ping(clean_msg)
    }
    // Permissions message
    [_user_repeated, "353", ..rest] -> {
      let assert Ok(message) = clean_message(string.join(rest, " "))
      TwitchSystem(message)
    }
    // Startup message
    [":tmi.twitch.tv", "001", ..rest] -> {
      let assert Ok(message) = clean_message(string.join(rest, " "))
      TwitchSystem("Startup" <> message)
    }
    _ -> {
      Unknown(irc_message)
    }
  }
}

/// A function for converting a Twitch message to a string
pub fn to_string(msg: TwitchMessage) -> String {
  case msg {
    PrivMsg(user, channel, message) ->
      "PRIVMSG " <> channel <> "/" <> user.username <> ": " <> message
    Join(user, channel) -> "JOIN #" <> channel <> " as " <> user.username
    TwitchSystem(message) -> "TWITCH_SYSTEM " <> message
    Ping(message) -> "PING " <> message
    Unknown(message) -> "Unknown " <> message
  }
}
