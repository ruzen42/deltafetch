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

    putStrColor "OS: " intensity color

    putStrColor "CPU: " intensity color

    putStrColor "RAM: " intensity color
    
    putStrColor "UPTIME: " intensity color
    
    putStrColor "WM: " intensity color

    putStrColor "PKGS: " intensity color

    putStrColor "Install data: " intensity color

    putStrColor "Kernel: " intensity color

    putStrColor "Shell: " intensity color

    putStrColor "DeltaFetch: " intensity color
    putStrLn ver
