import Data.Char
import Parser 
import Combinators      


-- string parser 
pstring :: String -> Parser String 
pstring = sequenceOut . fmap pchar

-- digit parser 
pdigit :: Parser Char
pdigit = satisfy isDigit

pdigits :: Parser [Char]
pdigits = many1 pdigit


-- int parser 
pint :: Parser Int 
pint = fmap (\(a,b) ->  
           case a of 
               Nothing -> read b
               Just '-' -> read $ "-" ++ b
        ) $ optional (pchar '-') ->>- pdigits
             

-- double parser 
pfloat :: Parser Float
pfloat = fmap (\((sign, left), (dot, right)) -> 
            let composed = left ++ [dot] ++ right in
                case sign of 
                    Nothing -> read composed 
                    Just '-' -> read $ "-" ++ composed
        ) fullMatch where 
          fullMatch = (optional (pchar '-') ->>- pdigits) ->>- (pchar '.' ->>- pdigits)



-- whitespace parser 
pws :: Parser Char
pws = satisfy isSpace






