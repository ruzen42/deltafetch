{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultilineStrings #-}

module Module (Module(..), Logo(..), printObj) where

import Data.Text (Text)
import qualified Data.Text.IO as TIO 
import TextShow 

data Module = Module 
  { name :: Text 
  , out  :: Text
  }

data Logo 
  = Linux 
  | FreeBSD

printObj :: TextShow a => a -> IO ()
printObj = TIO.putStrLn . showt

instance TextShow Logo where
  showt logo = 
    case logo of 
      FreeBSD -> """[0;91;40m██[0;91;41m▀[0;31;40m▀██[0;37;40m [0;91;40m▀▀[0;31;40m▀▀██[0;37;40m [0;91;40m██[0;91;41m▀[0;31;40m▀██[0;37;40m [0;91;40m██[0;91;41m▀[0;31;40m▀██[0;37;40m [0;91;40m▀▀▀▀[0;31;40m██[0;37;40m [0;91;40m█[0;91;41m█▀[0;31;40m▀▀▀[0;37;40m [0;91;40m▀▀▀▀[0;31;40m██[0m
[0;91;41m█▀[0;31;40m█▀  [0;37;40m [0;91;40m█[0;91;41m▀ [0;31;40m▄█▀[0;37;40m [0;91;41m█▀[0;31;40m█▀ ▄[0;37;40m [0;91;41m█▀[0;31;40m█▀ ▄[0;37;40m [0;91;40m██[0;91;41m▀[0;31;40m▀█▄[0;37;40m [0;91;40m▀[0;31;40m▀▀▀██[0;37;40m [0;91;40m██[0;91;41m▀[0;31;40m ██[0m
[0;91;40m▀[0;31;40m▀▀   [0;7;40m [0;91;40m▀[0;31;40m▀▀ ▀▀[0;37;40m [0;91;40m▀[0;31;40m▀▀▀▀▀[0;37;40m [0;91;40m▀[0;31;40m▀▀▀▀▀[0;37;40m [0;91;40m▀[0;31;40m▀▀▀▀▀[0;37;40m [0;91;40m▀[0;31;40m▀▀▀▀▀[0;37;40m [0;91;40m▀[0;31;40m▀▀▀▀▀[0m"""
      Linux   -> """.__  .__            ____  ___
|  | |__| ____  __ _\\   \\/  /
|  | |  |/    \\|  |  \\     / 
|  |_|  |   |  \\  |  /     \\ 
|____/__|___|  /____/___/\\  \\
             \\/           \\_/"""

instance TextShow Module where
  showt m = (name m) <> " :: " <> (out m)
