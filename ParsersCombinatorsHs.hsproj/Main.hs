import Data.Char

-- Result type
data Result t = Success t | Failure String deriving Show

-- Parser 

data Parser a = Parser (String -> Result (a, String))

-- auxilarry function
run :: Parser a -> String -> Result (a, String)
run (Parser p) input = p input


-- fundamental parser
pchar :: Char -> Parser Char
pchar ch = Parser (\input -> 
  if head input == ch 
    then Success (ch, tail input)
    else Failure $ "Expecting " ++ [ch] ++ " but got " ++ [(head input)]
  )



-- Parser has to be a functor
instance Functor Result where 
  fmap tranform res = case res of 
    Failure e -> Failure e 
    Success v -> Success $ tranform v
    

instance Monad Result where 
  res >>= a2Res = case res of 
    Failure e -> Failure e
    Success v -> a2Res v
 
instance Functor Parser where 
  fmap by p = Parser (\input -> 
       case run p input of 
         Failure e -> Failure e
         Success (v, reminder) -> Success (by v, reminder)
    )
    

bind :: Parser a -> (a -> Parser b) -> Parser b
bind pl a2p2 = join (fmap a2p2 pl) where 
        join ppa = Parser $ \input -> 
          case run ppa input of 
            Success (p, rem) -> run p rem
            Failure e -> Failure e 

lift :: a -> Parser a 
lift x = Parser $ \input -> Success (x, input)


instance Monad Parser where 
  return a = Parser $ \input -> Success(a, input)
  (>>=) = bind
      


        

-- combinator 

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
optional :: Parser a -> Parser Bool
optional p = Parser $ \input -> 
  case run p input of
    Failure _ -> Success (False, input)
    Success (c, rem) -> Success (True, rem)


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













-- satisfy 
satisfy :: (Char -> Bool) -> Parser Char
satisfy condition = Parser $ \input -> 
    case input of 
        [] -> Failure "Input stream is empty"
        (x:xs) -> if condition x then Success (x, xs)
            else Failure ("Unexpected " ++ show x)
                
            

-- string parser 
pstring :: String -> Parser String 
pstring = sequenceOut . fmap pchar

-- digit parser 
pdigit :: Parser Char
pdigit = satisfy isDigit

pdigits :: Parser Int 
pdigits = fmap (\a -> read a) $ many1 pdigit


-- int parser 
pint :: Parser Int 
pint = let match = optional (pchar '-') ->>- pdigits in
        fmap (\(a,b) ->  if a then -1 * b else b) match
             
        












