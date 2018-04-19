module JSONParserTests where 
    
import JSONParser
import Parser
import Result
import Test.HUnit

firstHSTest = TestCase (assertEqual "1 is equal to 1" 1 1 )


canParseNull = TestCase (assertEqual 
                        "can Parser null string"
                        (run jnull "null")
                        (Success (JNull, ""))
                        )
                        
canParseTrue = TestCase (assertEqual 
                        "jbool can parser quoted true"
                        (run jbool "\"true\"")
                        (Success (JBool True, ""))
                        )
                        
canParseFalse = TestCase (assertEqual 
                        "jbool can parser quoted false"
                        (run jbool "\"false\"")
                        (Success (JBool False, ""))
                        )
                        
wontParseRawFalse = TestCase (assertEqual 
                        "jbool wont parse unquoted boolean values"
                        (run jbool "false")
                        (Failure "fix this")
                        )

wontParseCapsTrue = TestCase (assertEqual 
                        "jbool wont parse unquoted boolean values"
                        (run jbool "\"TRUE\"")
                        (Failure "fix this")
                        )
                        

tests = TestList [TestLabel "can parse null" canParseNull,
                    TestLabel "can parse true" canParseTrue,
                    TestLabel "can parse false" canParseFalse,
                    TestLabel "wont parse raw false" wontParseRawFalse,
                    TestLabel "wont parse caps true" wontParseCapsTrue
                    ]