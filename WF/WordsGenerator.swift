//
//  WordsGenerator.swift
//  WF
//
//  Created by Bo Ni on 6/20/18.
//  Copyright © 2018 Bo Ni. All rights reserved.
//

import Foundation

class WordsGenerator
{
    let resource = Resource()
    ///theme: Hiphop, Basketball, Random, English
    func getWord(theme: String) -> String{
        switch theme{
        case "Hiphop":
            var list = resource.HiphopWordList
            let randomNumber = list.count.arc4random
            return list.remove(at: randomNumber)
        case "Basketball":
            var list = resource.BasketballWordList
            let randomNumber = list.count.arc4random
            return list.remove(at: randomNumber)
        case "Random":
            var list = resource.BasketballWordList + resource.HiphopWordList + resource.ChineseWordList
            let randomNumber = list.count.arc4random
            return list.remove(at: randomNumber)
        case "English":
            var list = resource.EnglishWordsList
            let randomNumber = list.count.arc4random
            return list.remove(at: randomNumber)
        default:
            var list = resource.BasketballWordList + resource.HiphopWordList + resource.ChineseWordList
            let randomNumber = list.count.arc4random
            return list.remove(at: randomNumber)
        }
    }
}

extension Int{
    var arc4random: Int{
        return Int(arc4random_uniform(UInt32(self)))
    }
}

