{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Lib where

import Module (Module(..), Logo(..))
import System.Posix.Unistd (getSystemID, systemName, release)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Control.Exception (catch, IOException)
import Data.Text (Text)

-- Modules 
moduleOS :: IO Module
moduleOS = do
  distro <- getDistroName 
  pure $ Module{name="os    ", out=distro}

moduleKernel :: IO Module
moduleKernel = do
  info <- getSystemID 
  pure $ Module{name="kernel", out=(T.pack $ systemName info)}

moduleCPU :: IO Module 
moduleCPU = do 
  info <- getCPU 
  pure $ Module{name="cpu   ", out=info}


getDistroName :: IO Text
getDistroName = parseOSRelease `catch` \(_ :: IOException) -> pure "Linux"
  where
    parseOSRelease = do
      content <- TIO.readFile "/etc/os-release"
      pure $ extractName (T.lines content)

    extractName [] = "Linux"
    extractName (line:ls)
      | "PRETTY_NAME=" `T.isPrefixOf` line = cleanValue (T.drop 12 line)
      | "NAME=" `T.isPrefixOf` line        = cleanValue (T.drop 5 line)
      | otherwise                          = extractName ls

    cleanValue val = T.dropAround (== '"') val

getLogo :: IO Logo 
getLogo = do
  info <- getSystemID
  pure $ case systemName info of 
    "FreeBSD" -> FreeBSD
    _         -> Linux

getCPU :: IO T.Text
getCPU = do
    cpuinfo <- TIO.readFile "/proc/cpuinfo"
    pure $ case T.breakOn "model name" cpuinfo of
        (_, rest)
            | T.null rest -> "Unknown"
            | otherwise ->
                T.strip $
                T.takeWhile (/= '\n') $
                T.drop 1 $
                T.dropWhile (/= ':') rest
