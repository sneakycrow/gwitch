import dotenv
import gleam/erlang/os
import gleam/io
import gleam/result
import glitch

// TODO: Create bot client
// TODO: Create an auth provider
// TODO: Create a new client
// TODO: Subscribe to incoming chat messages
// TODO: Add example to repository?
pub fn main() {
  // Load the environment variables
  dotenv.config()
  io.println("Hello from twitchbot!")
}

// Function that sets up the instance
pub fn setup() -> Config {
  let mode = get_mode()
}

fn get_mode() -> Mode {
  // Check if we're in development mode, otherwise presume production
  // Mostly just to ensure sensitive information isn't leaked unintentionally
  case os.get_env("BOT_MODE") {
    Ok(mode) -> {
      case mode {
        "development" -> Config(Mode.Development)
        _ -> {
          io.println("Invalid mode, defaulting to production")
          Config(Mode.Production)
        }
      }
    }
    Err(_) -> Config(Mode.Production)
  }
}

type Mode {
  Production
  Development
}

type Config {
  Config(mode: Mode)
}
