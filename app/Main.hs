{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Options.Applicative
import System.Console.ANSI
import Data.Char (toLower)
import Control.Monad (when)
import qualified Data.Text as T
import Data.Text.IO as T (putStrLn)

data Options = Options
  { optColor   :: T.Text
  , optLogo    :: Maybe T.Text
  , optModules :: Maybe T.Text
  } deriving Show

optionsParser :: Parser Options
optionsParser = Options
  <$> strOption
      ( long "color"
     <> short 'c'
     <> metavar "COLOR"
     <> help "Output color (Red, Blue, Cyan, Green, Yellow, Magenta, etc.)"
     <> value "auto"
     <> showDefault )
  <*> optional (strOption
      ( long "logo"
     <> short 'l'
     <> metavar "LOGO"
     <> help "Set fetch logo" ))
  <*> optional (strOption
      ( long "defaultModules"
     <> short 'm'
     <> metavar "LIST"
     <> help "Comma-separated module list (e.g. CPU,Kernel,RAM)" ))

parseColor :: T.Text -> Color
parseColor s = case T.toLower s of
  "black"   -> Black
  "red"     -> Red
  "green"   -> Green
  "yellow"  -> Yellow
  "blue"    -> Blue
  "magenta" -> Magenta
  "cyan"    -> Cyan
  "white"   -> White
  _         -> White

main :: IO ()
main = do
  opts <- execParser optsInfo
  print opts

optsInfo :: ParserInfo Options
optsInfo = info (optionsParser <**> helper)
  ( fullDesc
 <> progDesc "deltafetch — fastfetch on Haskell"
 <> header "deltafetch" )
