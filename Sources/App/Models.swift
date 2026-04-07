import Foundation

struct Utilisateur: Codable, Sendable {
    let id: Int64?
    var pseudo: String
    var email: String
    var motDePasseHash: String
    var motDePasseSalt: String
    var bio: String
    var avatarURL: String
    var dateCreation: String
}

struct SessionUtilisateur: Codable, Sendable {
    let id: Int64?
    var utilisateurId: Int64
    var token: String
    var dateCreation: String
    var dateExpiration: String
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
    var avatarAuteur: String
    var titre: String
    var genre: String
    var resume: String
    var couverture: String
    var statut: String
    var dateCreation: String
    var dateModification: String
}

struct NoteChapitre: Codable, Sendable {
    let id: Int64?
    var utilisateurId: Int64
    var chapitreId: Int64
    var note: Int
    var dateCreation: String
}

struct CommentaireHistoire: Codable, Sendable {
    let id: Int64?
    var histoireId: Int64
    var utilisateurId: Int64
    var contenu: String
    var dateCreation: String
}

struct CommentaireAffichage: Codable, Sendable {
    let id: Int64
    var histoireId: Int64
    var utilisateurId: Int64
    var pseudoUtilisateur: String
    var avatarUtilisateur: String
    var contenu: String
    var dateCreation: String
}

struct ChapitreAvecStats: Codable, Sendable {
    var chapitre: Chapitre
    var moyenne: Double
    var nombreNotes: Int
    var maNote: Int?
}

struct FichierUpload: Sendable {
    var nomChamp: String
    var nomOriginal: String
    var typeMime: String
    var donnees: Data
}
