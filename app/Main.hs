{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Options.Applicative
import Parse (defaultModules, trim, idGet, colorGet, printMapModules, name)
import Logos (printLogo)
import System.Console.ANSI
import Data.Char (toLower)
import Control.Monad (when)

data Options = Options
  { optColor   :: String
  , optModules :: Maybe String
  } 

optionsParser :: Parser Options
optionsParser = Options
  <$> strOption
      ( long "color"
     <> short 'c'
     <> metavar "COLOR"
     <> help "Output color (Red, Blue, Cyan, Green, Yellow, Magenta, etc.)"
     <> value "White"
     <> showDefault )
  <*> optional (strOption
      ( long "defaultModules"
     <> short 'm'
     <> metavar "LIST"
     <> help "Comma-separated module list (e.g. CPU,Kernel,RAM)" ))

parseColor :: String -> Color
parseColor s = case map toLower s of
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
  distroId <- fmap trim idGet

  let userColor = map toLower (optColor opts)
      baseColor = if userColor == "auto"
                    then colorGet distroId
                    else parseColor userColor

      selectedModules = case optModules opts of
        Nothing -> defaultModules
        Just listStr ->
          let names = map trim $ splitByComma listStr
          in filter (\m -> name m `elem` names) defaultModules

  printLogo distroId 
  putStrLn ""
  printMapModules selectedModules baseColor

optsInfo :: ParserInfo Options
optsInfo = info (optionsParser <**> helper)
  ( fullDesc
 <> progDesc "deltafetch — minimal system info CLI tool"
 <> header "deltafetch" )

splitByComma :: String -> [String]
splitByComma [] = []
splitByComma s  = case break (== ',') s of
  (x, ',':rest) -> x : splitByComma rest
  (x, "")       -> [x]
