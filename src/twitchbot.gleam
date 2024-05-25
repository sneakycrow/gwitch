import gleam/erlang/process
import gleam/function
import gleam/io
import gleam/option.{None, Some}
import logging
import twitch/chat

pub fn main() {
  // Configure the logger
  logging.configure()
  set_logger_level(Level, Debug)
  // Connect to the Twitch channel
  let subj = chat.connect("thesneakycrow", None)
  // Create a process that will manage the WebSocket connection and stop when the WebSocket process goes down
  let done =
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

  case done {
    _ -> io.print("exiting...later skater!")
  }
}

pub type LogLevel {
  Debug
}

pub type Log {
  Level
}

@external(erlang, "logger", "set_primary_config")
fn set_logger_level(log: Log, level: LogLevel) -> Nil
