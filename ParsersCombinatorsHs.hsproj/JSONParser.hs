module JSONParser where 
    
import Parser
import Result 
import Combinators
import StandardLib

import qualified Data.Map as Map

type Dict k v = Map.Map k v


data JSONValue =    JNull 
                   | JBool Bool 
                   | JNumber Float 
                   | JString String
                   | JObject (Dict String JSONValue) 
                   | JArray ([JSONValue])
                   deriving Show 



-- parser specifics for json

--jquote 
jq :: Parser Char 
jq = satisfy (\x -> x == '\"')

--jnull
jnull :: Parser JSONValue
jnull = let match = jq >>- pstring "null" ->> jq in
        (\str -> JNull) <$> match 
        
--jbool
jbool :: Parser JSONValue
jbool = let ptrue = (\_ -> True) <$> jq >>- pstring "true" ->> jq in
    let pfalse = (\_ -> False) <$> jq >>- pstring "false" ->> jq in
    (\b -> JBool b) <$> ptrue <|> pfalse
        

specialChars = "{}[]\\"

--jstring 
jstring :: Parser JSONValue
jstring = let notSC = satisfy (\c -> not (elem c specialChars)) in 
    let jmatch = many notSC in
    let match = jq >>- jmatch ->> jq in
        (\x -> JString x) <$> match

