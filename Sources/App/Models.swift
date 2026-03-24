import Foundation

struct Histoire: Codable, Sendable {
    let id: Int64?
    var titre: String
    var genre: String
    var resume: String
    var contenu: String
    var statut: String
    var dateCreation: String
    var dateModification: String
}