{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Environment (getArgs)
import System.Exit (die)
import Data.Aeson (FromJSON, decode)
import GHC.Generics (Generic)
import qualified Data.ByteString.Lazy as B
import Emitter (generateManifests, TopologyIR(..), Intersection(..))

-- | Define the Haskell data types that mirror the Agda JSON IR
data VerifiedBounds = VerifiedBounds
  { cpuLimit    :: String
  , memoryLimit :: String
  } deriving (Show, Generic)

instance FromJSON VerifiedBounds

data DeploymentStrategy = DeploymentStrategy
  { maxSurge       :: Int
  , maxUnavailable :: Int
  } deriving (Show, Generic)

instance FromJSON DeploymentStrategy

-- | The core topology record
data AgdaIR = AgdaIR
  { topologyId         :: String
  , verifiedBounds     :: VerifiedBounds
  , deploymentStrategy :: DeploymentStrategy
  , intersections      :: [Intersection]
  } deriving (Show, Generic)

instance FromJSON AgdaIR

-- | The Ken-n Lowering Functor (L)
main :: IO ()
main = do
    putStrLn "[Ken-n Compiler] Initializing lowering functor (L)..."
    args <- getArgs
    
    -- Default to the mocked output if no arguments are passed
    let inputFile = if null args 
                    then "agda-output/checkout-verified.json" 
                    else head args

    putStrLn $ "[Ken-n Compiler] Reading verified invariants from: " ++ inputFile
    
    -- Read and parse the JSON file
    jsonData <- B.readFile inputFile
    let parsedData = decode jsonData :: Maybe AgdaIR

    case parsedData of
        Nothing -> die "[Ken-n Compiler] ERROR: Failed to parse Agda JSON AST. Invalid univalence bounds."
        Just ir -> do
            putStrLn $ "[Ken-n Compiler] Mathematical bounds successfully parsed for: " ++ topologyId ir
            
            -- Map the parsed Agda AST into the Emitter's expected format
            let topoIR = TopologyIR 
                    { topoName = topologyId ir
                    , topoSurge = maxSurge (deploymentStrategy ir)
                    , topoDependencies = intersections ir
                    }
            
            -- Pass the strictly typed data to the Kubernetes emitter
            generateManifests topoIR
            putStrLn "[Ken-n Compiler] Discrete Kubernetes manifests successfully generated."
