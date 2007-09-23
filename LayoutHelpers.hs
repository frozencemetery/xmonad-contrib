-----------------------------------------------------------------------------
-- |
-- Module       : XMonadContrib.LayoutHelpers
-- Copyright    : (c) David Roundy <droundy@darcs.net>
-- License      : BSD
--
-- Maintainer   : David Roundy <droundy@darcs.net>
-- Stability    : unstable
-- Portability  : portable
--
-- A module for writing easy Layouts
-----------------------------------------------------------------------------

module XMonadContrib.LayoutHelpers (
    -- * Usage
    -- $usage
    LayoutModifier(..), ModifiedLayout(..)
    ) where

import Graphics.X11.Xlib ( Rectangle )
import XMonad
import StackSet ( Stack )
import Operations ( UnDoLayout(UnDoLayout) )

-- $usage
-- Use LayoutHelpers to help write easy Layouts.

class (Show (m a), Read (m a)) => LayoutModifier m a where
    modifyModify :: m a -> SomeMessage -> X (Maybe (m l))
    modifyModify m mess | Just UnDoLayout <- fromMessage mess = do unhook m; return Nothing
                        | otherwise = return Nothing
    redoLayout :: m a -> Rectangle -> Stack a -> [(a, Rectangle)]
               -> X ([(a, Rectangle)], Maybe (m l))
    redoLayout m _ _ wrs = do hook m; return (wrs, Nothing)
    hook :: m a -> X ()
    hook _ = return ()
    unhook :: m a -> X ()
    unhook _ = return ()

instance (LayoutModifier m a, Layout l a) => Layout (ModifiedLayout m l) a where
    doLayout (ModifiedLayout m l) r s =
        do (ws, ml') <- doLayout l r s
           (ws', mm') <- redoLayout m r s ws
           let ml'' = case mm' of
                      Just m' -> Just $ (ModifiedLayout m') $ maybe l id ml'
                      Nothing -> ModifiedLayout m `fmap` ml'
           return (ws', ml'')
    modifyLayout (ModifiedLayout m l) mess =
        do ml' <- modifyLayout l mess
           mm' <- modifyModify m mess
           return $ case mm' of
                    Just m' -> Just $ (ModifiedLayout m') $ maybe l id ml'
                    Nothing -> (ModifiedLayout m) `fmap` ml'

data ModifiedLayout m l a = ModifiedLayout (m a) (l a) deriving ( Read, Show )
