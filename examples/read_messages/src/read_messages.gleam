import gleam/erlang/process
import gleam/function
import gwitch.{connect}
import gwitch/auth.{default_config}
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
  logging.configure()
  // NOTE:  This isn't strictly necessary at all (including the associated
  // stuff above). It's included just to show the debug logging.
  set_logger_level(Level, Debug)
  let subj =
    default_config()
    |> connect("criken")
  // Start a process that will monitor the connection
  let _done =
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
