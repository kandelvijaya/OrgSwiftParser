module Combinators(andThen
                    , (->>-)
                    , keepLeft
                    , (->>)
                    , keepRight
                    , (>>-)
                    , orElse
                    , (<|>)
                    , optional
                    , many
                    , many1
                    , choice
                    , sequenceOut
                    ) where 

import Parser
import Result

-- combinators 

-- andThen
andThen :: Parser a -> Parser b -> Parser (a,b)
andThen leftp rightp = leftp >>= \l -> rightp >>= \r -> return (l,r)
                
-- typealias to operator 
(->>-) = andThen



-- orElse 
orElse :: Parser a -> Parser a -> Parser a
orElse lp rp = Parser $ \input -> 
  case run lp input of 
    Success x -> Success x
    Failure e -> run rp input
   
-- typealias for orElse
(<|>) = orElse


--keepLeft--
keepLeft :: Parser a -> Parser b -> Parser a
keepLeft pl pr = pl >>= \l -> pr >>= \_ -> return l

(->>) = keepLeft

--keepRight
keepRight :: Parser a -> Parser b -> Parser b
keepRight pl pr = pl >>= \_ -> pr >>= \r -> return r

(>>-) = keepRight


-- sequenceOut 
sequenceOut :: [Parser a] -> Parser [a]
sequenceOut [] = return []
sequenceOut (x:[]) = fmap (\i-> [i]) x
sequenceOut (x: xs) = 
  fmap (\(a,b) -> a ++ b) added where 
    added = (fmap (\i -> [i]) x) ->>- (sequenceOut xs)
  

-- optional 
-- consumes the string only if there is a match 
optional :: Parser a -> Parser (Maybe a)
optional p = Parser $ \input -> 
  case run p input of
    Failure _ -> Success (Nothing, input)
    Success (c, rem) -> Success (Just c, rem)


--many
many :: Parser a -> Parser [a]
many parser = Parser $ \input -> 
  case run parser input of 
    Failure _ -> Success([], input)
    Success (c, rem) -> case run (many parser) rem of 
      Failure _ -> Success ([c], rem)
      Success (c2, rem2) -> Success ([c] ++ c2, rem2)


-- many1
-- Has to have at least 1 match 
many1 :: Parser a -> Parser [a]
many1 parser = Parser $ \input -> 
    case run (many parser) input of 
        Failure e -> Failure e 
        Success ([], rem) -> Failure "couldn't match any of the given parser"
        Success (xs, rem) -> Success (xs, rem)
        

-- choice 
choice :: [Parser a] -> Parser a
choice [] = Parser $ \_ -> Failure "Can't make a choice on empty parsers"
choice (a:[]) = a
choice ps = foldl (\ a b -> a <|> b) (ps!!0) ps
