{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module Lib (
  moduleOS,
  moduleCPU,
  moduleKernel,
  moduleTPM,
  moduleSBoot,
  moduleRAM,
  getLogo
  ) where

import Module (Module(..), Logo(..))
import System.Posix.Unistd (getSystemID, systemName, release)
import qualified Data.Text as T
import qualified Data.Text.Read as TR
import qualified Data.Text.IO as TIO
import Control.Exception (catch, IOException)
import Foreign.C.String 
import Data.Text (Text)
import Data.Word
import System.Directory (doesFileExist)
import Text.Printf (printf)

--
-- Modules
--

moduleOS :: IO Module
moduleOS = do
  distro <- getDistroName
  pure $ Module{name="os         ", out=distro}

moduleTPM :: IO Module
moduleTPM = do
  tpmState <- checkTPM2
  pure $ Module{name="tpm2       ", out=(check tpmState)}
  where
    check ts =
      case ts of
        True -> "available"
        _    -> "not available"

moduleRAM :: Logo -> IO Module
moduleRAM logo = do
  ram <- getRAM logo
  pure $ Module{name="ram        ", out=ram}

moduleSBoot :: IO Module
moduleSBoot = do
  sboot <- checkSBoot
  pure $ Module{name="secure boot", out=(check sboot)}
  where
    check sb =
      case sb of
        True -> "enabled"
        _    -> "disabled"

moduleKernel :: IO Module
moduleKernel = do
  info <- getSystemID
  pure $
    Module
      { name = "kernel     "
      , out = T.pack $ (systemName info) ++ " " ++ (release info)
      }

moduleCPU :: Logo -> IO Module
moduleCPU logo = do
  info <- case logo of
            FreeBSD -> getCPUFreeBSD
            Linux   -> getCPULinux
  pure $ Module{name="cpu        ", out=info}

--
-- Helpers
--

checkTPM2 :: IO Bool
checkTPM2 = doesFileExist "/dev/tpm0"

checkSBoot :: IO Bool
checkSBoot =
  doesFileExist "/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c"

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

--
-- CPU
--

getCPULinux :: IO Text
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

--
-- RAM
--

getRAM :: Logo -> IO Text
getRAM Linux   = getRAMLinux
getRAM FreeBSD = getRAMFreeBSD

formats :: [Text]
formats = ["KiB", "MiB", "GiB", "TiB"]

formatRAM :: Float -> [Text] -> (Float, Text)
formatRAM val [fmt] = (val, fmt)
formatRAM val (fmt:fmts)
  | val >= 1024.0 = formatRAM (val / 1024.0) fmts
  | otherwise     = (val, fmt)
formatRAM val [] = (val, "KiB")

toHuman :: Float -> Text
toHuman kib =
  let (val, unit) = formatRAM kib formats
  in T.pack $ printf "%.2f %s" val (T.unpack unit)

--
-- Linux RAM
--

getRAMLinux :: IO Text
getRAMLinux = do
  info <- TIO.readFile "/proc/meminfo"

  let total = findValue "MemTotal:" info
      active = findValue "Active:" info

  pure $ toHuman active <> " / " <> toHuman total

  where
    findValue :: Text -> Text -> Float
    findValue key content =
      case filter (key `T.isPrefixOf`) (T.lines content) of
        (line:_) ->
          case T.words line of
            (_:valStr:_) -> textToFloat valStr
            _            -> 0.0
        _ -> 0.0

    textToFloat :: Text -> Float
    textToFloat txt =
      case TR.rational txt of
        Right (val, rest)
          | T.null rest -> val
        _ -> 0.0

foreign import ccall "get_total_ram_kib"
  c_get_total_ram_kib :: IO Word64

foreign import ccall "get_active_ram_kib"
  c_get_active_ram_kib :: IO Word64

getRAMFreeBSD :: IO Text
getRAMFreeBSD = do
  total <- c_get_total_ram_kib
  active <- c_get_active_ram_kib

  pure $
    toHuman (fromIntegral active) <>
    " / " <>
    toHuman (fromIntegral total)
