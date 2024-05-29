import auth.{type LoginCredentials}
import gleam/option.{type Option, None}
import internal/websockets.{
  type ReceiveTwitchMessageFn, type TwitchMessage, to_pretty_string,
}
import logging

pub type Config {
  Config(creds: Option(LoginCredentials), on_receive: ReceiveTwitchMessageFn)
}

pub fn default_config() -> Config {
  let receive_fn = fn(msg: TwitchMessage) {
    case msg.message_type {
      websockets.PrivMsg -> {
        logging.log(logging.Info, to_pretty_string(msg))
      }
      websockets.Join -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      websockets.TwitchSystem -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      websockets.Ping -> {
        logging.log(logging.Debug, to_pretty_string(msg))
      }
      websockets.Unknown -> {
        logging.log(logging.Error, to_pretty_string(msg))
      }
    }
  }
  Config(None, receive_fn)
}
