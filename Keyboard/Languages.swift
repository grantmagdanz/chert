//
//  Languages.swift
//  AN-Languages
//
//  Created by Grant Magdanz on 8/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation

public class Languages {
    // file names
    static let Ahtna = "Ahtna"
    static let DegXinag = "DegXinag"
    static let Denaakke = "Koyukon"
    static let Denaina = "Dena'ina"
    static let Eyak = "Eyak"
    static let Gwichin = "Gwichin"
    static let Han = "Han"
    static let Holikachuk = "Holikachuk"
    static let Inupiaq = "Inupiaq"
    static let Lingit = "Tlingit"
    static let LowerTanana = "Tanana(Lower)"
    static let Neeaaneegn = "Tanana(Upper)"
    static let Neeandeg = "Tanacross"
    static let Smalgyax = "Smalgyax_Tsimshian"
    static let Sugtstun = "Sugtstun_Sugpiaq_Alutiiq"
    static let UnangamTunuu = "Unangan"
    static let UpperKusko = "Kusko(Upper)"
    static let XaadKil = "Haida"
    
    public static func getLanguages() -> [String] {
        return [Ahtna, DegXinag, Denaakke, Denaina, Eyak, Gwichin, Han, Holikachuk, Inupiaq, Lingit, LowerTanana, Neeaaneegn, Neeandeg, Smalgyax, Sugtstun, UnangamTunuu, UpperKusko, XaadKil
        ]
    }
    
    public static func getNames() -> [String: String] {
        return [
            Ahtna: "Ahtna",
            DegXinag: "Deg Xinag",
            Denaakke: "Denaakk'e",
            Denaina: "Dena'ina",
            Eyak: "Eyak",
            Gwichin: "Gwich'in",
            Han: "Hän",
            Holikachuk: "Holikachuk",
            Inupiaq: "Iñupiaq",
            Lingit: "Lingít",
            LowerTanana: "Lower Tanana",
            Neeaaneegn: "Nee'aaneegn'",
            Neeandeg: "Nee'anděg'",
            Smalgyax: "Sm'algya̱x",
            Sugtstun: "Sugt'stun",
            UnangamTunuu: "Unangam Tunuu",
            UpperKusko: "Upper Kuskokwim",
            XaadKil: "X̱aad Kíl"
        ]
    }
    
    public static func getCharSet(language: String) -> NSDictionary {
        var keys: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource(language, ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        // Note: Dangerous. If the file isn't found, this will fail.
        return keys!
    }
}