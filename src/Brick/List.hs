module Brick.List
  ( List(listElements)
  , list
  , drawList
  , listInsert
  )
where

import Control.Applicative ((<$>), (<|>))
import Graphics.Vty (Event(..), Key(..))

import Brick.Core (HandleEvent(..), SetSize(..), Name(..))
import Brick.Prim (Prim(..), Priority(..), (<<=))
import Brick.Scroll (VScroll(..), vScroll, vScrollToView)
import Brick.Util (clamp, for)

data List e a =
    List { listElements :: ![e]
         , listElementDraw :: Bool -> e -> Prim a
         , listSelected :: !(Maybe Int)
         , listScroll :: !VScroll
         , listName :: !Name
         }

instance HandleEvent (List e a) where
    handleEvent e theList = f theList
        where
            f = case e of
                  EvKey KUp [] -> moveUp
                  EvKey KDown [] -> moveDown
                  _ -> id

instance SetSize (List e a) where
    setSize sz l =
        let updatedScroll = setSize sz $ listScroll l
            Just scrollTo = listSelected l <|> Just 0
        in l { listScroll = vScrollToView scrollTo updatedScroll
             }

list :: Name -> (Bool -> e -> Prim a) -> [e] -> List e a
list name draw es =
    let selIndex = if null es then Nothing else Just 0
    in List es draw selIndex (VScroll 0 0) name

drawList :: List e a -> Prim a
drawList l =
    let es = listElements l
        drawn = for (zip [0..] es) $ \(i, e) ->
                  let isSelected = Just i == listSelected l
                  in (listElementDraw l isSelected e, High)
    in GetSize (listName l) $
       vScroll (listScroll l) $
       VBox drawn <<= VPad ' '

listInsert :: Int -> e -> List e a -> List e a
listInsert pos e l =
    let safePos = clamp 0 (length es) pos
        es = listElements l
        newSel = case listSelected l of
          Nothing -> 0
          Just s -> if safePos < s
                    then s + 1
                    else s
        (front, back) = splitAt safePos es
    in l { listSelected = Just newSel
         , listElements = front ++ (e : back)
         , listScroll = vScrollToView newSel (listScroll l)
         }

moveUp :: List e a -> List e a
moveUp = moveBy (-1)

moveDown :: List e a -> List e a
moveDown = moveBy 1

moveBy :: Int -> List e a -> List e a
moveBy amt l =
    let newSel = clamp 0 (length (listElements l) - 1) <$> (amt +) <$> listSelected l
        Just scrollTo = newSel <|> Just 0
    in l { listSelected = newSel
         , listScroll = vScrollToView scrollTo (listScroll l)
         }