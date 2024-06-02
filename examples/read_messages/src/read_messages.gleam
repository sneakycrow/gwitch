import gleam/erlang/process
import gleam/function
import gleam/io
import gwitch.{connect}
import gwitch/auth.{create_config, create_credentials}
import gwitch/messages.{type TwitchMessage}
import logging

pub type LogLevel {
  Debug
}

pub type Log {
  Level
}

@external(erlang, "logger", "set_primary_config")
fn set_logger_level(log: Log, level: LogLevel) -> Nil

pub fn main() {
  // Configure the logger to monitor the WebSocket connection
  logging.configure()
  set_logger_level(Level, Debug)
  // Create a selector that will receive messages from the WebSocket process
  process.new_selector()
  // Monitor for the WebSocket process to go down
  |> process.selecting_process_down(
    // Start the WebSocket monitoring process
    process.monitor_process(process.subject_owner(
      // Create credentials, configure the connection, and finally connect to the Twitch server, returning a subject
      create_credentials("justinfan1234", "password")
      |> create_config(log_message)
      |> connect("criken"),
    )),
    function.identity,
  )
  // Continously receive messages from the WebSocket process
  |> process.select_forever
}

// A basic function that simply logs the message and returns it
fn log_message(msg: TwitchMessage) -> TwitchMessage {
  messages.to_string(msg) |> io.debug

  msg
}
