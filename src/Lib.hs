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
  getLogo, 
  ) where

import Module (Module(..), Logo(..))
import System.Posix.Unistd (getSystemID, systemName, release)
import qualified Data.Text as T
import qualified Data.Text.Read as TR
import qualified Data.Text.IO as TIO
import Control.Exception (catch, IOException)
import Data.Text (Text)
import Foreign.C.String
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

moduleRAM :: IO Module
moduleRAM = do 
  ram <- getRAMLinux 
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
  pure $ Module{name="kernel     ", out=(T.pack $ (systemName info) ++ " " ++ (release info))}

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
checkSBoot = doesFileExist "/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c" 

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

getRAMLinux :: IO Text
getRAMLinux = do
    info <- TIO.readFile "/proc/meminfo"
    pure $ (parse2Human $ getActive info) <> " / " <> (parse2Human $ getTotal info)
    where 
      getTotal :: Text -> Text
      getTotal info = case T.breakOn "MemTotal" info of
        (_, rest)
            | T.null rest -> "0 kB"
            | otherwise ->
                T.strip $
                T.takeWhile (/= 'k') $
                T.drop 1 $
                T.dropWhile (/= ':') rest

      getActive :: Text -> Text
      getActive info = case T.breakOn "Active" info of
        (_, rest)
            | T.null rest -> "0 kB"
            | otherwise ->
                T.strip $
                T.takeWhile (/= 'k') $
                T.drop 1 $
                T.dropWhile (/= ':') rest

      textToFloat :: Text -> Float
      textToFloat txt = case TR.rational txt of
        Left _ -> 0.0
        Right (val, rest)
          | T.null rest -> val
          | otherwise   -> 0.0
     
      formats :: [Text]
      formats = ["KiB", "MiB", "GiB", "TiB"]

      parse2Human :: Text -> Text
      parse2Human ram = 
        let valRaw           = textToFloat ram
            (val, unit) = format valRaw formats 
        in T.pack $ printf "%.2f %s" val (T.unpack unit)

      format :: Float -> [Text] -> (Float, Text)
      format val [fmt] = (val, fmt) 
      format val (fmt:fmts)
        | val >= 1024.0 = format (val / 1024.0) fmts
        | otherwise     = (val, fmt)
      format val []    = (val, "KiB")


                
                
                

