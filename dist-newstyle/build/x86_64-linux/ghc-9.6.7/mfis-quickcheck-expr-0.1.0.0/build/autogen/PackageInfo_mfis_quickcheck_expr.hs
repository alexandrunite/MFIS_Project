{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_mfis_quickcheck_expr (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "mfis_quickcheck_expr"
version :: Version
version = Version [0,1,0,0] []

synopsis :: String
synopsis = "Proiect MFIS despre QuickCheck pe un mini-limbaj aritmetic"
copyright :: String
copyright = ""
homepage :: String
homepage = ""
