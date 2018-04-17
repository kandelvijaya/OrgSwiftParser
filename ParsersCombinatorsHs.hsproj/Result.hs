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
