module Result (Result(Failure, Success)) where 

-- Result type
data Result t = Success t | Failure String deriving Show

-- Parser has to be a functor
instance Functor Result where 
  fmap tranform res = case res of 
    Failure e -> Failure e 
    Success v -> Success $ tranform v
    

instance Monad Result where 
  return a = Success a
  res >>= a2Res = case res of 
    Failure e -> Failure e
    Success v -> a2Res v
  
instance Applicative Result where 
    pure = Success
    f <*> b = case f of 
        Failure e -> Failure e 
        Success vf -> case b of 
            Failure e2 -> Failure e2
            Success v2 -> Success $ vf v2


-- equality 
instance (Eq a) => Eq (Result a) where 
    res1 == res2 = case res1 of 
        Failure e1 -> case res2 of 
            Failure e2 -> e1 == e2
            _ -> False 
        Success v1 -> case res2 of 
            Success v2 -> v1 == v2
            _ -> False 