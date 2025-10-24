
module Parse ( Module(..)
             , modules
             , printModule
             , idGet
             , printMapModules) where

import System.Process (readProcess)
import PkgManagers
import Data.Char (isSpace)
import Data.List (isPrefixOf)
import System.Console.ANSI
import Text.Printf (printf)
import System.Console.ANSI (Color(..), ColorIntensity(..), setSGR, SGR(..))

data Module = Module
  { name   :: String
  , action :: IO String
  }

modules :: [Module]
modules =
  [ Module { name = "Hostname",    action = hostnameGet }
  , Module { name = "Username",    action = usernameGet }
  , Module { name = "Kernel",      action = kernelGet }
  , Module { name = "CPU",         action = cpuGet }
  , Module { name = "RAM",         action = getRAM }
  , Module { name = "Distro",      action = distroGet }
  , Module { name = "Packages",    action = pkgsNumGet }
  , Module { name = "Shell",       action = shellGet }
  , Module { name = "WM/DE",       action = wmGet }
  , Module { name = "InstallData", action = installDataGet }
  , Module { name = "Uptime",      action = uptimeGet }
  , Module { name = "ID",          action = idGet }
  ]

printModule m color = do
  setSGR [SetColor Foreground Dull color]
  putStr ("[" ++ name m ++ "]: ")
  setSGR [Reset]
  value <- action m
  putStrLn (trim value)

printMapModules :: [Module] -> Color -> IO ()
printMapModules mods color = mapM_ (\m -> printModule m color) mods

hostnameGet :: IO String
hostnameGet = readProcess "hostname" [] ""

usernameGet :: IO String
usernameGet = readProcess "whoami" [] ""

kernelGet :: IO String
kernelGet = readProcess "uname" ["-r"] ""

cpuGet :: IO String
cpuGet = do
  cpuInfo <- readFile "/proc/cpuinfo"
  let modelNameLine = head (filter ("model name" `isPrefixOf`) (lines cpuInfo))
  return $ drop 2 (dropWhile (/= ':') modelNameLine)

getRAM :: IO String
getRAM = do
  output <- readProcess "free" ["-h"] ""
  let rawLine = words $ lines output !! 1
      total = rawLine !! 1
      used  = rawLine !! 2
  return $ used ++ " / " ++ total

distroGet :: IO String
distroGet = do
  name    <- readProcess "sh" ["-c", ". /etc/os-release && echo $NAME"] ""
  version <- readProcess "sh" ["-c", ". /etc/os-release && echo $VERSION"] ""
  code    <- readProcess "sh" ["-c", ". /etc/os-release && echo $VERSION_CODENAME"] ""
  return $ filter (/= '\n') (name ++ " " ++ version ++ " " ++ code)

pkgsNumGet :: IO String
pkgsNumGet = do
  pkgManager <- checkPkgManager
  output <- getListPkg pkgManager
  return $ if output == "-" then "-" else output

getListPkg :: String -> IO String
getListPkg "apt"       = readProcess "dpkg" ["--list"] ""
getListPkg "dnf"       = readProcess "sh" ["-c", "dnf list --installed | wc -l"] ""
getListPkg "pacman"    = readProcess "pacman" ["-Q"] ""
getListPkg "zypper"    = readProcess "zypper" ["se", "-i"] ""
getListPkg "slackpkg"  = readProcess "sh" ["-c", "ls /var/log/packages | wc -l"] ""
getListPkg "emerge"    = readProcess "sh" ["-c", "ls /var/lib/portage/world | wc -l"] ""
getListPkg "base"      = readProcess "base" [""] ""
getListPkg _           = return "-"

shellGet :: IO String
shellGet = readProcess "sh" ["-c", "echo $SHELL"] ""

idGet :: IO String
idGet = readProcess "sh" ["-c", ". /etc/os-release && echo $ID"] ""

colorGet :: String -> (ColorIntensity, Color)
colorGet id = case id of
  "slackware\n" -> (Dull, Blue)
  "nuros\n"     -> (Dull, Blue)
  "buildx\n"    -> (Dull, Cyan)
  "ptu\n"       -> (Dull, Red)
  "arch\n"      -> (Dull, Cyan)
  "fedora\n"    -> (Dull, Blue)
  "void\n"      -> (Dull, Green)
  "gentoo\n"    -> (Dull, Magenta)
  "artix\n"     -> (Dull, Cyan)
  "mint\n"      -> (Dull, Green)
  "debian\n"    -> (Dull, Red)
  "ubuntu\n"    -> (Dull, Yellow)
  _             -> (Dull, White)

installDataGet :: IO String
installDataGet = do
  versionInfo <- readFile "/proc/version"
  let afterPreempt = dropWhile (not . isPrefixOf "PREEMPT_DYNAMIC") (wordsBySpace versionInfo)
      dateWords = drop 1 afterPreempt
  return $ unwords $ take 6 dateWords

uptimeGet :: IO String
uptimeGet = do
  uptimeStr <- readFile "/proc/uptime"
  let uptimeSeconds = read (head (words uptimeStr)) :: Double
      totalSeconds = floor uptimeSeconds :: Int
  return $ formatUptime totalSeconds

wordsBySpace :: String -> [String]
wordsBySpace = words

trim :: String -> String
trim = f . f where f = reverse . dropWhile isSpace

formatUptime :: Int -> String
formatUptime totalSeconds =
  let (days, rem1) = totalSeconds `divMod` (60 * 60 * 24)
      (hours, rem2) = rem1 `divMod` (60 * 60)
      (minutes, _) = rem2 `divMod` 60
  in printf "%d days, %02d hours, %02d minutes" days hours minutes

wmGet :: IO String
wmGet = do
  wm <- readProcess "sh"
        ["-c", "xprop -root _NET_SUPPORTING_WM_CHECK | grep -oE '0x[0-9a-f]+' | \
              \xargs -I{} xprop -id {} _NET_WM_NAME | awk -F'\"' '{print $2}'"] ""
  let result = trim wm
  return $ if null result then "unknown" else result

