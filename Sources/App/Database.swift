import SQLite
import Foundation

extension Connection: @unchecked @retroactive Sendable {}

struct Database {
    static let utilisateurs = Table("utilisateurs")
    static let histoires = Table("histoires")
    static let chapitres = Table("chapitres")

    // UTILISATEURS
    static let utilisateurId = Expression<Int64>("id")
    static let pseudo = Expression<String>("pseudo")
    static let email = Expression<String>("email")
    static let motDePasse = Expression<String>("mot_de_passe")
    static let utilisateurDateCreation = Expression<String>("date_creation")

    // HISTOIRES
    static let histoireId = Expression<Int64>("id")
    static let auteurId = Expression<Int64>("auteur_id")
    static let titre = Expression<String>("titre")
    static let genre = Expression<String>("genre")
    static let resume = Expression<String>("resume")
    static let couverture = Expression<String>("couverture")
    static let statut = Expression<String>("statut")
    static let histoireDateCreation = Expression<String>("date_creation")
    static let histoireDateModification = Expression<String>("date_modification")

    // CHAPITRES
    static let chapitreId = Expression<Int64>("id")
    static let chapitreHistoireId = Expression<Int64>("histoire_id")
    static let numero = Expression<Int>("numero")
    static let chapitreTitre = Expression<String>("titre")
    static let contenu = Expression<String>("contenu")
    static let chapitreDateCreation = Expression<String>("date_creation")
    static let chapitreDateModification = Expression<String>("date_modification")

    static func setup() throws -> Connection {
        let db = try Connection("db.sqlite3")

        try db.run(utilisateurs.create(ifNotExists: true) { t in
            t.column(utilisateurId, primaryKey: .autoincrement)
            t.column(pseudo)
            t.column(email, unique: true)
            t.column(motDePasse)
            t.column(utilisateurDateCreation)
        })

        try db.run(histoires.create(ifNotExists: true) { t in
            t.column(histoireId, primaryKey: .autoincrement)
            t.column(auteurId)
            t.column(titre)
            t.column(genre)
            t.column(resume)
            t.column(couverture)
            t.column(statut)
            t.column(histoireDateCreation)
            t.column(histoireDateModification)
        })

        try db.run(chapitres.create(ifNotExists: true) { t in
            t.column(chapitreId, primaryKey: .autoincrement)
            t.column(chapitreHistoireId)
            t.column(numero)
            t.column(chapitreTitre)
            t.column(contenu)
            t.column(chapitreDateCreation)
            t.column(chapitreDateModification)
        })

        return db
    }

    // MARK: - UTILISATEURS

    static func ajouterUtilisateur(
        db: Connection,
        pseudo: String,
        email: String,
        motDePasse: String
    ) throws {
        let now = dateActuelle()

        try db.run(utilisateurs.insert(
            self.pseudo <- pseudo,
            self.email <- email,
            self.motDePasse <- motDePasse,
            self.utilisateurDateCreation <- now
        ))
    }

    static func recupererUtilisateurParEmail(
        db: Connection,
        emailRecherche: String
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(email == emailRecherche)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[email],
            motDePasse: row[motDePasse],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    static func recupererUtilisateurParId(
        db: Connection,
        idRecherche: Int64
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(utilisateurId == idRecherche)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[email],
            motDePasse: row[motDePasse],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    static func verifierConnexion(
        db: Connection,
        email: String,
        motDePasse: String
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(self.email == email && self.motDePasse == motDePasse)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[self.email],
            motDePasse: row[self.motDePasse],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    // MARK: - HISTOIRES

    static func ajouterHistoire(
        db: Connection,
        auteurId: Int64,
        titre: String,
        genre: String,
        resume: String,
        couverture: String,
        statut: String
    ) throws {
        let now = dateActuelle()

        try db.run(histoires.insert(
            self.auteurId <- auteurId,
            self.titre <- titre,
            self.genre <- genre,
            self.resume <- resume,
            self.couverture <- couverture,
            self.statut <- statut,
            self.histoireDateCreation <- now,
            self.histoireDateModification <- now
        ))
    }

    static func recupererHistoiresParAuteur(
        db: Connection,
        auteurIdRecherche: Int64
    ) throws -> [Histoire] {
        let query = histoires
            .filter(auteurId == auteurIdRecherche)
            .order(histoireDateModification.desc)

        return try db.prepare(query).map { row in
            Histoire(
                id: row[histoireId],
                auteurId: row[auteurId],
                titre: row[titre],
                genre: row[genre],
                resume: row[resume],
                couverture: row[couverture],
                statut: row[statut],
                dateCreation: row[histoireDateCreation],
                dateModification: row[histoireDateModification]
            )
        }
    }

    static func recupererHistoiresPubliees(
        db: Connection
    ) throws -> [HistoirePublique] {
        let query = histoires
            .join(utilisateurs, on: histoires[auteurId] == utilisateurs[utilisateurId])
            .filter(histoires[statut] == "publie")
            .order(histoires[histoireDateModification].desc)

        return try db.prepare(query).map { row in
            HistoirePublique(
                id: row[histoires[histoireId]],
                auteurId: row[histoires[auteurId]],
                pseudoAuteur: row[utilisateurs[pseudo]],
                titre: row[histoires[titre]],
                genre: row[histoires[genre]],
                resume: row[histoires[resume]],
                couverture: row[histoires[couverture]],
                statut: row[histoires[statut]],
                dateCreation: row[histoires[histoireDateCreation]],
                dateModification: row[histoires[histoireDateModification]]
            )
        }
    }

    static func recupererHistoireParId(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> Histoire? {
        let query = histoires.filter(histoireId == histoireIdRecherche)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Histoire(
            id: row[histoireId],
            auteurId: row[auteurId],
            titre: row[titre],
            genre: row[genre],
            resume: row[resume],
            couverture: row[couverture],
            statut: row[statut],
            dateCreation: row[histoireDateCreation],
            dateModification: row[histoireDateModification]
        )
    }

    static func modifierHistoire(
        db: Connection,
        histoireIdRecherche: Int64,
        titre: String,
        genre: String,
        resume: String,
        couverture: String,
        statut: String
    ) throws {
        let query = histoires.filter(histoireId == histoireIdRecherche)

        try db.run(query.update(
            self.titre <- titre,
            self.genre <- genre,
            self.resume <- resume,
            self.couverture <- couverture,
            self.statut <- statut,
            self.histoireDateModification <- dateActuelle()
        ))
    }

    static func supprimerHistoire(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws {
        let queryChapitres = chapitres.filter(chapitreHistoireId == histoireIdRecherche)
        try db.run(queryChapitres.delete())

        let queryHistoire = histoires.filter(histoireId == histoireIdRecherche)
        try db.run(queryHistoire.delete())
    }

    // MARK: - CHAPITRES

    static func ajouterChapitre(
        db: Connection,
        histoireId: Int64,
        numero: Int,
        titre: String,
        contenu: String
    ) throws {
        let now = dateActuelle()

        try db.run(chapitres.insert(
            self.chapitreHistoireId <- histoireId,
            self.numero <- numero,
            self.chapitreTitre <- titre,
            self.contenu <- contenu,
            self.chapitreDateCreation <- now,
            self.chapitreDateModification <- now
        ))
    }

    static func recupererChapitresParHistoire(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> [Chapitre] {
        let query = chapitres
            .filter(chapitreHistoireId == histoireIdRecherche)
            .order(numero.asc)

        return try db.prepare(query).map { row in
            Chapitre(
                id: row[chapitreId],
                histoireId: row[chapitreHistoireId],
                numero: row[numero],
                titre: row[chapitreTitre],
                contenu: row[contenu],
                dateCreation: row[chapitreDateCreation],
                dateModification: row[chapitreDateModification]
            )
        }
    }

    static func recupererChapitreParId(
        db: Connection,
        chapitreIdRecherche: Int64
    ) throws -> Chapitre? {
        let query = chapitres.filter(chapitreId == chapitreIdRecherche)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return Chapitre(
            id: row[chapitreId],
            histoireId: row[chapitreHistoireId],
            numero: row[numero],
            titre: row[chapitreTitre],
            contenu: row[contenu],
            dateCreation: row[chapitreDateCreation],
            dateModification: row[chapitreDateModification]
        )
    }

    static func modifierChapitre(
        db: Connection,
        chapitreIdRecherche: Int64,
        numero: Int,
        titre: String,
        contenu: String
    ) throws {
        let query = chapitres.filter(chapitreId == chapitreIdRecherche)

        try db.run(query.update(
            self.numero <- numero,
            self.chapitreTitre <- titre,
            self.contenu <- contenu,
            self.chapitreDateModification <- dateActuelle()
        ))
    }

    static func supprimerChapitre(
        db: Connection,
        chapitreIdRecherche: Int64
    ) throws {
        let query = chapitres.filter(chapitreId == chapitreIdRecherche)
        try db.run(query.delete())
    }

    static func prochainNumeroChapitre(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> Int {
        let query = chapitres
            .filter(chapitreHistoireId == histoireIdRecherche)
            .order(numero.desc)

        if let row = try db.pluck(query) {
            return row[numero] + 1
        }

        return 1
    }

    static func dateActuelle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}