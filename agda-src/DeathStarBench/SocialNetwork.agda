module DeathStarBench.SocialNetwork where

open import Kenn.DSL

-- Define the core microservices for the Social Network
SocialGraph : Mesh
SocialGraph = Manifest "social-graph-v1" ⟨
    Ports := 8080 ,
    Scale := 10
  ⟩

HomeTimeline : Mesh
HomeTimeline = Manifest "home-timeline-v1" ⟨
    Ports := 8081 ,
    Scale := 15
  ⟩

RedisCache : Mesh
RedisCache = Manifest "redis-cluster" ⟨
    Ports := 6379 ,
    Scale := 3
  ⟩

-- Establish the routing morphisms
-- NOTE: This contains the intentional circular dependency discussed in Section 4.2
ValidRoute1 = HomeTimeline ▹ RedisCache
ValidRoute2 = SocialGraph ▹ RedisCache

-- The following mutual recursion violates the finite intersection axiom.
-- Running `agda` on this file will result in a univalent collapse in O(1) time.
CyclicRouteA = HomeTimeline ▹ SocialGraph
CyclicRouteB = SocialGraph ▹ HomeTimeline

SocialNetworkMesh : Mesh
SocialNetworkMesh = ValidRoute1 ⊕ ValidRoute2 ⊕ CyclicRouteA ⊕ CyclicRouteB
