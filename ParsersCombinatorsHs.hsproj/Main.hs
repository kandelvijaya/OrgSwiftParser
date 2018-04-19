import Data.Char
import Parser 
import Combinators  
import System.IO
import JSONParser


main = do 
    handle <- openFile "./exampleBig.json" ReadMode
    stringStream <- hGetContents handle
    putStr $ show (run jsonParser stringStream)
        







