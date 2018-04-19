module JSONParserTests2 where 
    
import JSONParser
import Parser
import Result 
import Test.HUnit

sample1 = "{\n      \"_id\": \"5ad9014f274b99c3923f5662\",\n      \"index\": 0,\n      \"guid\": \"9c225b7f-efcc-4d0e-8f93-e0760bcc22f1\",\n      \"isActive\": false,\n      \"balance\": \"$3,141.75\",\n      \"picture\": \"http://placehold.it/32x32\",\n      \"age\": 23,\n      \"eyeColor\": \"green\",\n      \"name\": \"Vonda Cross\",\n      \"gender\": \"female\",\n      \"company\": \"SIGNIDYNE\",\n      \"email\": \"vondacross@signidyne.com\",\n      \"phone\": \"+1 (994) 515-2320\",\n      \"address\": \"803 Irving Street, Munjor, California, 9228\",\n      \"about\": \"Mollit enim laborum culpa mollit aliquip. Laborum id aute quis minim enim ullamco consectetur tempor tempor sit. Consectetur quis aliquip mollit duis velit magna magna.\\r\\n\",\n      \"registered\": \"2016-05-14T12:18:58 -02:00\",\n      \"latitude\": -33.757841,\n      \"longitude\": 81.078737,\n      \"tags\": [\n        \"duis\",\n        \"aliquip\",\n        \"voluptate\",\n        \"deserunt\",\n        \"ad\",\n        \"laborum\",\n        \"ut\"\n      ],\n      \"friends\": [\n        {\n          \"id\": 0,\n          \"name\": \"Myrtle Sampson\"\n        },\n        {\n          \"id\": 1,\n          \"name\": \"Carmella Leach\"\n        },\n        {\n          \"id\": 2,\n          \"name\": \"Rollins Caldwell\"\n        }\n      ],\n      \"greeting\": \"Hello, Vonda Cross! You have 7 unread messages.\",\n      \"favoriteFruit\": \"strawberry\"\n    }"


sampleJsonParser =  case run jsonParser sample1 of 
    Failure _ -> False
    Success _ -> True 

testSample1 = TestCase (assertBool "can parse sample json file" sampleJsonParser)






