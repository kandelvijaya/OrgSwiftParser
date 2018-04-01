import Foundation
import ParserCombinator


func consoleOut(_ msg: Any) {
    print(msg)
}

// MARK:-  Test site

let inputJSONString = "{\n\t\"created_at\": \"Thu Jun 22 21:00:00 +0000 2017\",\n\t\"id\": 877994604561387500,\n\t\"id_str\": \"877994604561387520\",\n\t\"text\": \"Creating a Grocery List Manager Using Angular, Part 1: Addamp; Display Items https://t.co/xFox78juL1 #Angular\",\n\t\"truncated\": false,\n\t\"entities\": {\n\t\t\"hashtags\": [{\n\t\t\t\"text\": \"Angular\",\n\t\t\t\"indices\": [103, 111]\n\t\t}],\n\t\t\"symbols\": [12],\n\t\t\"user_mentions\": [],\n\t\t\"urls\": [{\n\t\t\t\"url\": \"https://t.co/xFox78juL1\",\n\t\t\t\"expanded_url\": \"http://buff.ly/2sr60pf\",\n\t\t\t\"display_url\": \"buff.ly/2sr60pf\",\n\t\t\t\"indices\": [79, 102]\n\t\t}]\n\t},\n\t\"source\": \"<a href=\\\"http://bufferapp.com\\\" rel=\\\"nofollow\\\">Buffer</a>\",\n\t\"user\": {\n\t\t\"id\": 772682964,\n\t\t\"id_str\": \"772682964\",\n\t\t\"name\": \"SitePoint JavaScript\",\n\t\t\"screen_name\": \"SitePointJS\",\n\t\t\"location\": \"Melbourne, Australia\",\n\t\t\"description\": \"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.\",\n\t\t\"url\": \"http://t.co/cCH13gqeUK\",\n\t\t\"entities\": {\n\t\t\t\"url\": {\n\t\t\t\t\"urls\": [{\n\t\t\t\t\t\"url\": \"http://t.co/cCH13gqeUK\",\n\t\t\t\t\t\"expanded_url\": \"http://sitepoint.com/javascript\",\n\t\t\t\t\t\"display_url\": \"sitepoint.com/javascript\",\n\t\t\t\t\t\"indices\": [0, 22]\n\t\t\t\t}]\n\t\t\t},\n\t\t\t\"description\": {\n\t\t\t\t\"urls\": []\n\t\t\t}\n\t\t},\n\t\t\"protected\": false,\n\t\t\"followers_count\": 2145,\n\t\t\"friends_count\": 18,\n\t\t\"listed_count\": 328,\n\t\t\"created_at\": \"Wed Aug 22 02:06:33 +0000 2012\",\n\t\t\"favourites_count\": 57,\n\t\t\"utc_offset\": 43200,\n\t\t\"time_zone\": \"Wellington\"\n\t}\n}"

import JSONParser

pjson() |> run(inputJSONString) |> consoleOut





