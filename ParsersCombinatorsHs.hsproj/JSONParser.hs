module JSONParser (jnull,
                   jbool,
                   jnumber,
                   jstring,
                   jarray,
                   jobject,
                   JSONValue(JNull,
                             JString,
                             JNumber,
                             JObject,
                             JArray,
                             JBool
                             ),
                   jsonParser,
                   ) where 
    
import Parser
import Result 
import Combinators
import StandardLib
import Data.Char

import qualified Data.Map as Map

type Dict k v = Map.Map k v


data JSONValue =    JNull 
                   | JBool Bool 
                   | JNumber Float 
                   | JString String
                   | JObject (Dict String JSONValue) 
                   | JArray ([JSONValue])
                   deriving Show 


-- equality of JSONValue 
instance Eq JSONValue where 
    JNull == JNull = True 
    JBool a == JBool b = a == b
    JNumber a == JNumber b = a == b
    JString a == JString b = a == b
    JArray [] == JArray [] = True 
    JArray (x:xs) == JArray (y:ys) = x == y && xs == ys
    JObject x == JObject y = x == y


--jquote 
jq :: Parser Char 
jq = satisfy (\x -> x == '\"')

--jnull
jnull :: Parser JSONValue
jnull = let match = pstring "null" in
        (\str -> JNull) <$> match 
        
--jbool
jbool :: Parser JSONValue
jbool = let ptrue = (\_ -> True) <$> pstring "true" in
    let pfalse = (\_ -> False) <$> pstring "false" in
    (\b -> JBool b) <$> ptrue <|> pfalse
        

specialChars = ['{', '}', '[', ']', '\"']




--jstring 
-- actual implementation of using proper unicode and escaping are left at this moment
escapedChars = [("\\\"", '\"'),
                ("\\\\", '\\'),
                ("\\/", '/'),
                ("\\n", '\n'),
                ("\\r", '\n'),
                ("\\t", '\t')]
                
jEscapedChar :: Parser Char
jEscapedChar = choice $ (\(s,c) -> fmap (\_ -> c) (pstring s)) <$> escapedChars


jUnescapedChars :: Parser Char 
jUnescapedChars = satisfy (\c -> c /= '\\' && c /= '\"')


jstring :: Parser JSONValue
jstring = let strMatch = many $ choice [jEscapedChar, jUnescapedChars] in
    let match = (jq >>- strMatch) ->> jq in 
        (\x -> JString x) <$> match




--jnumber 
jnumber :: Parser JSONValue 
jnumber = (\x -> JNumber x) <$> (pfloat <|> pfint) where 
    pfint = fmap (fromIntegral) pint


wss = many $ satisfy isSpace
value = wss >>- jsonParser ->> wss
comma = wss >>- pchar ',' >>- wss
openArr = wss ->>- pchar '[' ->>- wss
closeArr = wss ->>- pchar ']' ->> wss
valueComma = value ->> comma
listValue = many valueComma ->>- optional value


--jArray
jarray :: Parser JSONValue 
jarray =  (\(xs,maybex) -> case maybex of 
                Nothing -> JArray xs
                Just x -> JArray $ xs ++ [x]
           )  <$> openArr >>- listValue ->> closeArr


openObj = wss >>- pchar '{' ->> wss
closeObj = wss >>- pchar '}' ->> wss 
colon = wss >>- pchar ':' ->> wss
key = (\x -> case x of
             JString a -> a
       ) <$> wss >>- jstring ->> wss
keyValue = (key ->> colon) ->>- value
keyValueComma = keyValue ->> comma
keyValuePairs = many keyValueComma ->>- optional keyValue

--jObject 
jobject :: Parser JSONValue 
jobject = (\(kvs, kvmaybe) -> case kvmaybe of 
                Nothing -> JObject $ Map.fromList kvs 
                Just a -> JObject $ Map.fromList (kvs ++ [a])
           ) <$> openObj >>- keyValuePairs ->> closeObj

--jsonP
jsonParser :: Parser JSONValue 
jsonParser = choice [jnull, jbool, jnumber, jstring, jarray, jobject]
