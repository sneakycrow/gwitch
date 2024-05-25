import gleam/erlang/process
import gleam/function
import logging
import twitch/chat

// TODO: Login to Twitch after connecting to the WebSocket
pub fn main() {
  // Configure the logger
  logging.configure()
  set_logger_level(Level, Debug)
  // Get our Twitch chat subject, which will be used to monitor the WebSocket connection
  let subj = chat.get_twitch_subj()
  // Login so we can stay connected
  chat.login_anon(subj)
  // Create a process that will manage the WebSocket connection and stop when the WebSocket process goes down
  let _process_complete =
    // Create a selector that will receive messages from the WebSocket process
    process.new_selector()
    // Monitor for the WebSocket process to go down
    |> process.selecting_process_down(
      // Start the WebSocket monitoring process
      process.monitor_process(process.subject_owner(subj)),
      function.identity,
    )
    // Continously receive messages from the WebSocket process
    |> process.select_forever
}

pub type LogLevel {
  Debug
}

pub type Log {
  Level
}

@external(erlang, "logger", "set_primary_config")
fn set_logger_level(log: Log, level: LogLevel) -> Nil
