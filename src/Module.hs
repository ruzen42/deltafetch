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
      FreeBSD -> """______            ______  ___________ 
|  ___|           | ___ \\/  ___|  _  \\
| |_ _ __ ___  ___| |_/ /\\ `--.| | | |
|  _| '__/ _ \\/ _ \\ ___ \\ `--. \\ | | |
| | | | |  __/  __/ |_/ //\\__/ / |/ / 
\\_| |_|  \\___|\\___\\____/ \\____/|___/"""
      Linux   -> """.__  .__            ____  ___
|  | |__| ____  __ _\\   \\/  /
|  | |  |/    \\|  |  \\     / 
|  |_|  |   |  \\  |  /     \\ 
|____/__|___|  /____/___/\\  \\
             \\/           \\_/"""

instance TextShow Module where
  showt m = (name m) <> " :: " <> (out m)
