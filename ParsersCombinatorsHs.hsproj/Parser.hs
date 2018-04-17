module Parser (Parser(Parser), run, satisfy, pchar) where 
import Result
    
-- Parser 
data Parser a = Parser (String -> Result (a, String))

-- auxilarry function
run :: Parser a -> String -> Result (a, String)
run (Parser p) input = p input


instance Functor Parser where 
  fmap by p = Parser (\input -> 
       case run p input of 
         Failure e -> Failure e
         Success (v, reminder) -> Success (by v, reminder)
    )
    
instance Applicative Parser where 
    pure a = lift a 
    wF <*> p = Parser $ \input -> 
        case run wF input of
            Failure e -> Failure e 
            Success (func, rem) -> case run p rem of 
                Failure e -> Failure e 
                Success (c, rem2) -> Success (func c, rem2)
                

instance Monad Parser where 
  return a = lift a 
  (>>=) = bind
      
bind :: Parser a -> (a -> Parser b) -> Parser b
bind pl a2p2 = join (fmap a2p2 pl) where 
        join ppa = Parser $ \input -> 
          case run ppa input of 
            Success (p, rem) -> run p rem
            Failure e -> Failure e 

lift :: a -> Parser a 
lift a = Parser $ \input -> Success(a, input)


-- fundamental 
-- satisfy 
satisfy :: (Char -> Bool) -> Parser Char
satisfy condition = Parser $ \input -> 
    case input of 
        [] -> Failure "Input stream is empty"
        (x:xs) -> if condition x then Success (x, xs)
            else Failure ("Unexpected " ++ show x)

-- fundamental parser
pchar :: Char -> Parser Char
pchar ch = satisfy (\a -> a == ch)

     