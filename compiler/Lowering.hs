{-# LANGUAGE DeriveGeneric #-}

module Emitter (generateManifests, TopologyIR(..), Intersection(..)) where

import Data.Aeson (FromJSON)
import GHC.Generics (Generic)

-- | Data types shared with Main
data Intersection = Intersection
  { target   :: String
  , port     :: Int
  , protocol :: String
  } deriving (Show, Generic)

instance FromJSON Intersection

data TopologyIR = TopologyIR
  { topoName         :: String
  , topoSurge        :: Int
  , topoDependencies :: [Intersection]
  } deriving (Show)

-- | Generates discrete Kubernetes YAML dynamically from the parsed IR
generateManifests :: TopologyIR -> IO ()
generateManifests ir = do
    let deploymentYaml = unlines
            [ "apiVersion: apps/v1"
            , "kind: Deployment"
            , "metadata:"
            , "  name: " ++ topoName ir ++ "-v2"
            , "spec:"
            , "  strategy:"
            , "    type: RollingUpdate"
            , "    rollingUpdate:"
            , "      maxUnavailable: 0"
            , "      maxSurge: " ++ show (topoSurge ir)
            ]
            
    let networkPolicyHeader = unlines
            [ "---"
            , "apiVersion: networking.k8s.io/v1"
            , "kind: NetworkPolicy"
            , "metadata:"
            , "  name: " ++ topoName ir ++ "-strict-isolation"
            , "spec:"
            , "  podSelector:"
            , "    matchLabels:"
            , "      app: " ++ topoName ir
            , "  policyTypes:"
            , "  - Egress"
            , "  egress:"
            ]
            
    -- Dynamically generate egress rules based on verified intersections
    let egressRules = concatMap generateEgressRule (topoDependencies ir)
    
    let fullYaml = deploymentYaml ++ networkPolicyHeader ++ egressRules

    putStrLn "\n--- [Extracted Kubernetes IR] ---"
    putStrLn fullYaml
    putStrLn "---------------------------------"

-- | Helper to build discrete network rules
generateEgressRule :: Intersection -> String
generateEgressRule dep = unlines
    [ "  - to:"
    , "    - podSelector:"
    , "        matchLabels:"
    , "          app: " ++ target dep
    , "    ports:"
    , "    - protocol: " ++ protocol dep
    , "      port: " ++ show (port dep)
    ]
