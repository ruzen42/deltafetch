{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module Lib (
  moduleOS, 
  moduleCPU, 
  moduleKernel, 
  getLogo, 
  ) where

import Module (Module(..), Logo(..))
import System.Posix.Unistd (getSystemID, systemName, release)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Control.Exception (catch, IOException)
import Data.Text (Text)
import Foreign.C.String

-- Modules 
moduleOS :: IO Module
moduleOS = do
  distro <- getDistroName 
  pure $ Module{name="os    ", out=distro}

moduleKernel :: IO Module
moduleKernel = do
  info <- getSystemID 
  pure $ Module{name="kernel", out=(T.pack $ (systemName info) ++ " " ++ (release info))}

moduleCPU :: Logo -> IO Module 
moduleCPU logo = do 
  info <- case logo of
            FreeBSD -> getCPUFreeBSD
            Linux   -> getCPULinux
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

getCPULinux :: IO T.Text
getCPULinux = do
    cpuinfo <- TIO.readFile "/proc/cpuinfo"
    pure $ case T.breakOn "model name" cpuinfo of
        (_, rest)
            | T.null rest -> "Unknown"
            | otherwise ->
                T.strip $
                T.takeWhile (/= '\n') $
                T.drop 1 $
                T.dropWhile (/= ':') rest

foreign import ccall "get_cpu_model"
    c_get_cpu_model :: IO CString

getCPUFreeBSD :: IO Text
getCPUFreeBSD = do
    ptr <- c_get_cpu_model
    str <- peekCString ptr
    pure $ T.pack str 
