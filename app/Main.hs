module Main (main) where

import Lib (moduleOS, moduleKernel, getLogo)
import Module (printObj, Module(..))
import Control.Concurrent.Async (mapConcurrently)

main :: IO ()
main = do 
  logo <- getLogo
  printObj logo

  let moduleActions :: [IO Module]
      moduleActions = 
        [ moduleOS
        , moduleKernel
        ]

  modules <- mapConcurrently id moduleActions

  mapM_ printObj modules

