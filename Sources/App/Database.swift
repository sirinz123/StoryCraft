import Foundation
import SQLite

extension Connection: @unchecked @retroactive Sendable {}

struct Database {
    // TABLES
    static let utilisateurs = Table("utilisateurs")
    static let sessions = Table("sessions")
    static let histoires = Table("histoires")
    static let chapitres = Table("chapitres")
    static let notesChapitres = Table("notes_chapitres")
    static let commentairesHistoires = Table("commentaires_histoires")

    // UTILISATEURS
    static let utilisateurId = Expression<Int64>("id")
    static let pseudo = Expression<String>("pseudo")
    static let email = Expression<String>("email")
    static let motDePasseHash = Expression<String>("mot_de_passe_hash")
    static let motDePasseSalt = Expression<String>("mot_de_passe_salt")
    static let bio = Expression<String>("bio")
    static let avatarURL = Expression<String>("avatar_url")
    static let utilisateurDateCreation = Expression<String>("date_creation")

    // SESSIONS
    static let sessionId = Expression<Int64>("id")
    static let sessionUtilisateurId = Expression<Int64>("utilisateur_id")
    static let sessionToken = Expression<String>("token")
    static let sessionDateCreation = Expression<String>("date_creation")
    static let sessionDateExpiration = Expression<String>("date_expiration")

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

    // NOTES
    static let noteId = Expression<Int64>("id")
    static let noteUtilisateurId = Expression<Int64>("utilisateur_id")
    static let noteChapitreId = Expression<Int64>("chapitre_id")
    static let noteValeur = Expression<Int>("note")
    static let noteDateCreation = Expression<String>("date_creation")

    // COMMENTAIRES
    static let commentaireId = Expression<Int64>("id")
    static let commentaireHistoireId = Expression<Int64>("histoire_id")
    static let commentaireUtilisateurId = Expression<Int64>("utilisateur_id")
    static let commentaireContenu = Expression<String>("contenu")
    static let commentaireDateCreation = Expression<String>("date_creation")

    static func setup() throws -> Connection {
        let db = try Connection("db.sqlite3")
        try db.run("PRAGMA foreign_keys = ON")

        try db.run(
            utilisateurs.create(ifNotExists: true) { t in
                t.column(utilisateurId, primaryKey: .autoincrement)
                t.column(pseudo, unique: true)
                t.column(email, unique: true)
                t.column(motDePasseHash)
                t.column(motDePasseSalt)
                t.column(bio, defaultValue: "")
                t.column(avatarURL, defaultValue: "")
                t.column(utilisateurDateCreation)
            })

        try db.run(
            sessions.create(ifNotExists: true) { t in
                t.column(sessionId, primaryKey: .autoincrement)
                t.column(sessionUtilisateurId)
                t.column(sessionToken, unique: true)
                t.column(sessionDateCreation)
                t.column(sessionDateExpiration)
            })

        try db.run(
            histoires.create(ifNotExists: true) { t in
                t.column(histoireId, primaryKey: .autoincrement)
                t.column(auteurId)
                t.column(titre)
                t.column(genre)
                t.column(resume)
                t.column(couverture, defaultValue: "")
                t.column(statut)
                t.column(histoireDateCreation)
                t.column(histoireDateModification)
            })

        try db.run(
            chapitres.create(ifNotExists: true) { t in
                t.column(chapitreId, primaryKey: .autoincrement)
                t.column(chapitreHistoireId)
                t.column(numero)
                t.column(chapitreTitre)
                t.column(contenu)
                t.column(chapitreDateCreation)
                t.column(chapitreDateModification)
            })

        try db.run(
            notesChapitres.create(ifNotExists: true) { t in
                t.column(noteId, primaryKey: .autoincrement)
                t.column(noteUtilisateurId)
                t.column(noteChapitreId)
                t.column(noteValeur)
                t.column(noteDateCreation)
                t.unique(noteUtilisateurId, noteChapitreId)
            })

        try db.run(
            commentairesHistoires.create(ifNotExists: true) { t in
                t.column(commentaireId, primaryKey: .autoincrement)
                t.column(commentaireHistoireId)
                t.column(commentaireUtilisateurId)
                t.column(commentaireContenu)
                t.column(commentaireDateCreation)
            })

        return db
    }

    // MARK: - UTILS

    static func dateActuelle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    static func dateDans7Jours() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date().addingTimeInterval(7 * 24 * 60 * 60))
    }

    // MARK: - UTILISATEURS

    static func ajouterUtilisateur(
        db: Connection,
        pseudo: String,
        email: String,
        motDePasse: String
    ) throws {
        let now = dateActuelle()
        let salt = Security.genererSalt()
        let hash = Security.hasherMotDePasse(motDePasse, salt: salt)

        try db.run(
            utilisateurs.insert(
                self.pseudo <- pseudo,
                self.email <- email.lowercased(),
                self.motDePasseHash <- hash,
                self.motDePasseSalt <- salt,
                self.bio <- "",
                self.avatarURL <- "",
                self.utilisateurDateCreation <- now
            ))
    }

    static func recupererUtilisateurParEmail(
        db: Connection,
        emailRecherche: String
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(email == emailRecherche.lowercased())

        guard let row = try db.pluck(query) else { return nil }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[email],
            motDePasseHash: row[motDePasseHash],
            motDePasseSalt: row[motDePasseSalt],
            bio: row[bio],
            avatarURL: row[avatarURL],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    static func recupererUtilisateurParPseudo(
        db: Connection,
        pseudoRecherche: String
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(pseudo == pseudoRecherche)

        guard let row = try db.pluck(query) else { return nil }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[email],
            motDePasseHash: row[motDePasseHash],
            motDePasseSalt: row[motDePasseSalt],
            bio: row[bio],
            avatarURL: row[avatarURL],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    static func recupererUtilisateurParId(
        db: Connection,
        idRecherche: Int64
    ) throws -> Utilisateur? {
        let query = utilisateurs.filter(utilisateurId == idRecherche)

        guard let row = try db.pluck(query) else { return nil }

        return Utilisateur(
            id: row[utilisateurId],
            pseudo: row[pseudo],
            email: row[email],
            motDePasseHash: row[motDePasseHash],
            motDePasseSalt: row[motDePasseSalt],
            bio: row[bio],
            avatarURL: row[avatarURL],
            dateCreation: row[utilisateurDateCreation]
        )
    }

    static func mettreAJourProfil(
        db: Connection,
        utilisateurIdRecherche: Int64,
        pseudoNouveau: String,
        bioNouvelle: String,
        avatarURLNouvelle: String
    ) throws {
        let query = utilisateurs.filter(utilisateurId == utilisateurIdRecherche)

        try db.run(
            query.update(
                pseudo <- pseudoNouveau,
                bio <- bioNouvelle,
                avatarURL <- avatarURLNouvelle
            ))
    }

    static func verifierConnexion(
        db: Connection,
        email: String,
        motDePasse: String
    ) throws -> Utilisateur? {
        guard let utilisateur = try recupererUtilisateurParEmail(db: db, emailRecherche: email)
        else {
            return nil
        }

        let ok = Security.verifierMotDePasse(
            motDePasse,
            hash: utilisateur.motDePasseHash,
            salt: utilisateur.motDePasseSalt
        )

        return ok ? utilisateur : nil
    }

    // MARK: - SESSIONS

    static func creerSession(
        db: Connection,
        utilisateurId: Int64
    ) throws -> String {
        let token = Security.genererToken()

        try db.run(
            sessions.insert(
                sessionUtilisateurId <- utilisateurId,
                sessionToken <- token,
                sessionDateCreation <- dateActuelle(),
                sessionDateExpiration <- dateDans7Jours()
            ))

        return token
    }

    static func recupererUtilisateurDepuisToken(
        db: Connection,
        token: String
    ) throws -> Utilisateur? {
        let query = sessions.filter(sessionToken == token)

        guard let row = try db.pluck(query) else { return nil }

        return try recupererUtilisateurParId(
            db: db,
            idRecherche: row[sessionUtilisateurId]
        )
    }

    static func supprimerSession(
        db: Connection,
        token: String
    ) throws {
        let query = sessions.filter(sessionToken == token)
        try db.run(query.delete())
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

        try db.run(
            histoires.insert(
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
        let query =
            histoires
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

    static func recupererHistoiresPubliees(db: Connection) throws -> [HistoirePublique] {
        let query =
            histoires
            .join(utilisateurs, on: histoires[auteurId] == utilisateurs[utilisateurId])
            .filter(histoires[statut] == "publie")
            .order(histoires[histoireDateModification].desc)

        return try db.prepare(query).map { row in
            HistoirePublique(
                id: row[histoires[histoireId]],
                auteurId: row[histoires[auteurId]],
                pseudoAuteur: row[utilisateurs[pseudo]],
                avatarAuteur: row[utilisateurs[avatarURL]],
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

        guard let row = try db.pluck(query) else { return nil }

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

        try db.run(
            query.update(
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
        try db.run(
            commentairesHistoires.filter(commentaireHistoireId == histoireIdRecherche).delete())

        let chapitresHistoire = try recupererChapitresParHistoire(
            db: db, histoireIdRecherche: histoireIdRecherche)
        for chapitre in chapitresHistoire {
            try db.run(notesChapitres.filter(noteChapitreId == chapitre.id ?? -1).delete())
        }

        try db.run(chapitres.filter(chapitreHistoireId == histoireIdRecherche).delete())
        try db.run(histoires.filter(histoireId == histoireIdRecherche).delete())
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

        try db.run(
            chapitres.insert(
                chapitreHistoireId <- histoireId,
                self.numero <- numero,
                chapitreTitre <- titre,
                self.contenu <- contenu,
                chapitreDateCreation <- now,
                chapitreDateModification <- now
            ))
    }

    static func recupererChapitresParHistoire(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> [Chapitre] {
        let query =
            chapitres
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

        guard let row = try db.pluck(query) else { return nil }

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

        try db.run(
            query.update(
                self.numero <- numero,
                chapitreTitre <- titre,
                self.contenu <- contenu,
                chapitreDateModification <- dateActuelle()
            ))
    }

    static func supprimerChapitre(
        db: Connection,
        chapitreIdRecherche: Int64
    ) throws {
        try db.run(notesChapitres.filter(noteChapitreId == chapitreIdRecherche).delete())
        try db.run(chapitres.filter(chapitreId == chapitreIdRecherche).delete())
    }

    static func prochainNumeroChapitre(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> Int {
        let query =
            chapitres
            .filter(chapitreHistoireId == histoireIdRecherche)
            .order(numero.desc)

        if let row = try db.pluck(query) {
            return row[numero] + 1
        }

        return 1
    }

    // MARK: - NOTES

    static func noterChapitre(
        db: Connection,
        utilisateurId: Int64,
        chapitreId: Int64,
        note: Int
    ) throws {
        let query = notesChapitres.filter(
            noteUtilisateurId == utilisateurId && noteChapitreId == chapitreId
        )

        if try db.pluck(query) != nil {
            try db.run(
                query.update(
                    noteValeur <- note,
                    noteDateCreation <- dateActuelle()
                ))
        } else {
            try db.run(
                notesChapitres.insert(
                    noteUtilisateurId <- utilisateurId,
                    noteChapitreId <- chapitreId,
                    noteValeur <- note,
                    noteDateCreation <- dateActuelle()
                ))
        }
    }

    static func statistiquesChapitre(
        db: Connection,
        chapitreIdRecherche: Int64,
        utilisateurIdConnecte: Int64?
    ) throws -> (Double, Int, Int?) {
        let query = notesChapitres.filter(noteChapitreId == chapitreIdRecherche)
        let rows = Array(try db.prepare(query))

        let nombre = rows.count
        let somme = rows.reduce(0) { $0 + $1[noteValeur] }
        let moyenne = nombre == 0 ? 0.0 : Double(somme) / Double(nombre)

        var maNote: Int? = nil
        if let utilisateurIdConnecte {
            let maQuery = notesChapitres.filter(
                noteChapitreId == chapitreIdRecherche && noteUtilisateurId == utilisateurIdConnecte
            )
            if let row = try db.pluck(maQuery) {
                maNote = row[noteValeur]
            }
        }

        return (moyenne, nombre, maNote)
    }

    // MARK: - COMMENTAIRES

    static func ajouterCommentaireHistoire(
        db: Connection,
        histoireId: Int64,
        utilisateurId: Int64,
        contenu: String
    ) throws {
        try db.run(
            commentairesHistoires.insert(
                commentaireHistoireId <- histoireId,
                commentaireUtilisateurId <- utilisateurId,
                commentaireContenu <- contenu,
                commentaireDateCreation <- dateActuelle()
            ))
    }

    static func recupererCommentairesHistoire(
        db: Connection,
        histoireIdRecherche: Int64
    ) throws -> [CommentaireAffichage] {
        let query =
            commentairesHistoires
            .join(
                utilisateurs,
                on: commentairesHistoires[commentaireUtilisateurId] == utilisateurs[utilisateurId]
            )
            .filter(commentairesHistoires[commentaireHistoireId] == histoireIdRecherche)
            .order(commentairesHistoires[commentaireDateCreation].desc)

        return try db.prepare(query).map { row in
            CommentaireAffichage(
                id: row[commentairesHistoires[commentaireId]],
                histoireId: row[commentairesHistoires[commentaireHistoireId]],
                utilisateurId: row[commentairesHistoires[commentaireUtilisateurId]],
                pseudoUtilisateur: row[utilisateurs[pseudo]],
                avatarUtilisateur: row[utilisateurs[avatarURL]],
                contenu: row[commentairesHistoires[commentaireContenu]],
                dateCreation: row[commentairesHistoires[commentaireDateCreation]]
            )
        }
    }
}
