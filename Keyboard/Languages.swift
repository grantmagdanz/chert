//
//  Languages.swift
//  AN-Languages
//
//  Created by Grant Magdanz on 8/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation

open class Languages {
    // file names
    static let Ahtna = "Ahtna"
    static let BehntiKenaga = "Tanana(Lower)"
    static let DegXinag = "DegXinag"
    static let Denaakke = "Koyukon"
    static let Denaki = "Kusko(Upper)"
    static let Denaina = "Dena'ina"
    static let DihthaadXteeniinaandeg = "Tanacross"
    static let DinjiiZhuhKyaa = "Gwichin"
    static let Eyak = "Eyak"
    static let Han = "Han"
    static let Holikachuk = "Holikachuk"
    static let Inupiatun = "Inupiaq"
    static let Lingit = "Tlingit"
    static let Neeaaneegn = "Tanana(Upper)"
    static let Smalgyax = "Smalgyax_Tsimshian"
    static let Sugtstun = "Sugtstun_Sugpiaq_Alutiiq"
    static let UnangamTunuu = "Unangan"
    static let Yugtun = "Yugtun"
    static let XaadKil = "Haida"
    
    open static func getLanguages() -> [String] {
        return [
            Ahtna,
            BehntiKenaga,
            DegXinag,
            Denaakke,
            Denaki,
            Denaina,
            DihthaadXteeniinaandeg,
            DinjiiZhuhKyaa,
            Eyak,
            Han,
            Holikachuk,
            Inupiatun,
            Lingit,
            Neeaaneegn,
            Smalgyax,
            Sugtstun,
            UnangamTunuu,
            Yugtun,
            XaadKil
        ]
    }
    
    // display names
    open static func getNames() -> [String: String] {
        return [
            Ahtna: "Ahtna",
            BehntiKenaga: "Behnti Kenaga'",
            DegXinag: "Deg Xinag",
            Denaakke: "Denaakk'e",
            Denaki: "Denak'i",
            Denaina: "Dena'ina",
            DihthaadXteeniinaandeg: "Dihthâad Xt'een iin aanděg'",
            DinjiiZhuhKyaa: "Dinjii Zhuh K'yaa",
            Eyak: "Eyak",
            Han: "Hän",
            Holikachuk: "Holikachuk",
            Inupiatun: "Iñupiatun",
            Lingit: "Lingít",
            Neeaaneegn: "Née'aaneegn'",
            Smalgyax: "Sm'algya̱x",
            Sugtstun: "Sugt'stun",
            UnangamTunuu: "Unangam Tunuu",
            Yugtun: "Yugtun",
            XaadKil: "X̱aad Kíl"
        ]
    }
    
    open static func getCharSet(_ language: String) -> NSDictionary {
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: language, ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        // Note: Dangerous. If the file isn't found, this will fail.
        return keys!
    }
}
