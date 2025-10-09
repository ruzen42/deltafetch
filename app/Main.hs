import System.Console.ANSI
import Parse
import Logos

putStrColor :: String -> ColorIntensity -> Color -> IO ()
putStrColor string intensity color = do
  setSGR [SetColor Foreground intensity color]
  putStr string 
  setSGR [SetColor Foreground Dull White]

main :: IO ()
main = do
    idStr <- idGet 

    let (intensity, color) = colorGet idStr 
    let ver = "0.0.1.0"

    printLogo
    putStrLn ""

    distro <- distroGet
    putStrColor "OS: " intensity color
    putStr distro 

    cpu <- cpuGet 
    putStrColor "CPU: " intensity color
    putStrLn cpu

    ram <- getRAM
    putStrColor "RAM: " intensity color
    putStrLn ram
    
    uptime <- uptimeGet 
    putStrColor "UPTIME: " intensity color
    putStrLn uptime
    
    wm <- wmGet 
    putStrColor "WM: " intensity color
    putStrLn wm

    pkgs <- pkgsNumGet 
    putStrColor "PKGS: " intensity color
    putStr pkgs

    installDate <- installDataGet 
    putStrColor "Install data: " intensity color
    putStrLn installDate

    kernel <- kernelGet 
    putStrColor "Kernel: " intensity color
    putStr kernel

    shell <- shellGet 
    putStrColor "Shell: " intensity color
    putStr shell

    putStrColor "DeltaFetch: " intensity color
    putStrLn ver
