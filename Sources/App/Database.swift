import SQLite
import Foundation

extension Connection: @unchecked @retroactive Sendable {}

struct Database {
    static let histoires = Table("histoires")

    static let id = Expression<Int64>("id")
    static let titre = Expression<String>("titre")
    static let genre = Expression<String>("genre")
    static let resume = Expression<String>("resume")
    static let contenu = Expression<String>("contenu")
    static let statut = Expression<String>("statut")
    static let dateCreation = Expression<String>("date_creation")
    static let dateModification = Expression<String>("date_modification")

    static func setup() throws -> Connection {
        let db = try Connection("db.sqlite3")

        try db.run(histoires.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(titre)
            t.column(genre)
            t.column(resume)
            t.column(contenu)
            t.column(statut)
            t.column(dateCreation)
            t.column(dateModification)
        })

        return db
    }

    static func recupererHistoires(db: Connection) throws -> [Histoire] {
        try db.prepare(histoires.order(dateModification.desc)).map { row in
            Histoire(
                id: row[id],
                titre: row[titre],
                genre: row[genre],
                resume: row[resume],
                contenu: row[contenu],
                statut: row[statut],
                dateCreation: row[dateCreation],
                dateModification: row[dateModification]
            )
        }
    }

    static func recupererHistoireParId(db: Connection, histoireId: Int64) throws -> Histoire? {
        let query = histoires.filter(id == histoireId)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Histoire(
            id: row[id],
            titre: row[titre],
            genre: row[genre],
            resume: row[resume],
            contenu: row[contenu],
            statut: row[statut],
            dateCreation: row[dateCreation],
            dateModification: row[dateModification]
        )
    }

    static func ajouterHistoire(
        db: Connection,
        titre: String,
        genre: String,
        resume: String,
        contenu: String,
        statut: String
    ) throws {
        let now = dateActuelle()

        try db.run(histoires.insert(
            self.titre <- titre,
            self.genre <- genre,
            self.resume <- resume,
            self.contenu <- contenu,
            self.statut <- statut,
            self.dateCreation <- now,
            self.dateModification <- now
        ))
    }

    static func modifierHistoire(
        db: Connection,
        histoireId: Int64,
        titre: String,
        genre: String,
        resume: String,
        contenu: String,
        statut: String
    ) throws {
        let query = histoires.filter(id == histoireId)

        try db.run(query.update(
            self.titre <- titre,
            self.genre <- genre,
            self.resume <- resume,
            self.contenu <- contenu,
            self.statut <- statut,
            self.dateModification <- dateActuelle()
        ))
    }

    static func supprimerHistoire(db: Connection, histoireId: Int64) throws {
        let query = histoires.filter(id == histoireId)
        try db.run(query.delete())
    }

    static func dateActuelle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}