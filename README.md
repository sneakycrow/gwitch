# gwitch

A library for reading and writing messages to Twitch IRC

[![Package Version](https://img.shields.io/hexpm/v/gwitch)](https://hex.pm/packages/gwitch)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gwitch/)

## Features
- [x] Read Messages from Twitch Chat
- [ ] Parses Twitch metadata out of IRC Message
- [ ] Send Messages to Twitch Chat

## Usage
```sh
gleam add gwitch
```
```gleam
import gleam/erlang/process
import gwitch

pub fn main() {
  // Connect to the Twitch channel "criken" with an anonymous user, returning a subject to receive messages
  let subj = gwitch.connect("criken", None)
  // Start a process that will monitor the connection
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
}
```

Further documentation can be found at <https://hexdocs.pm/gwitch>.
