import Foundation

struct Utilisateur: Codable, Sendable {
    let id: Int64?
    var pseudo: String
    var email: String
    var motDePasse: String
    var dateCreation: String
}

struct Histoire: Codable, Sendable {
    let id: Int64?
    var auteurId: Int64
    var titre: String
    var genre: String
    var resume: String
    var couverture: String
    var statut: String
    var dateCreation: String
    var dateModification: String
}

struct Chapitre: Codable, Sendable {
    let id: Int64?
    var histoireId: Int64
    var numero: Int
    var titre: String
    var contenu: String
    var dateCreation: String
    var dateModification: String
}

struct HistoirePublique: Codable, Sendable {
    let id: Int64
    var auteurId: Int64
    var pseudoAuteur: String
    var titre: String
    var genre: String
    var resume: String
    var couverture: String
    var statut: String
    var dateCreation: String
    var dateModification: String
}
