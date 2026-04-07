import Foundation
import HTTPTypes
import Hummingbird
@preconcurrency import SQLite

let db = try Database.setup()
let router = Router()

func lireFormulaire(_ request: Request) async throws -> [String: String] {
    let buffer = try await request.body.collect(upTo: 1024 * 1024 * 8)
    let bodyString = String(decoding: buffer.readableBytesView, as: UTF8.self)
        .replacingOccurrences(of: "+", with: "%20")

    var components = URLComponents()
    components.percentEncodedQuery = bodyString

    var data: [String: String] = [:]
    components.queryItems?.forEach { item in
        data[item.name] = item.value ?? ""
    }

    return data
}

func lireCookie(_ request: Request, nom: String) -> String? {
    guard let cookieHeader = request.headers[HTTPField.Name.cookie] else {
        return nil
    }

    let parties = cookieHeader.split(separator: ";")

    for partie in parties {
        let propre = String(partie).trimmingCharacters(in: .whitespaces)
        let elements = propre.split(separator: "=", maxSplits: 1)

        if elements.count == 2 && String(elements[0]) == nom {
            return String(elements[1])
        }
    }

    return nil
}

func utilisateurConnecte(_ request: Request) throws -> Utilisateur? {
    guard let token = lireCookie(request, nom: "storycraft_session") else {
        return nil
    }

    return try Database.recupererUtilisateurDepuisToken(db: db, token: token)
}

func reponseRedirect(_ path: String, cookie: String? = nil) -> Response {
    var headers: HTTPFields = [.location: path]

    if let cookie {
        headers[.setCookie] = cookie
    }

    return Response(status: .seeOther, headers: headers)
}

func reponseHTML(_ html: HTML, status: HTTPResponse.Status = .ok) -> Response {
    Response(
        status: status,
        headers: [.contentType: "text/html; charset=utf-8"],
        body: .init(byteBuffer: .init(string: html.content))
    )
}

func cookieSession(_ token: String) -> String {
    "storycraft_session=\(token); Path=/; HttpOnly; SameSite=Lax"
}

func cookieSuppressionSession() -> String {
    "storycraft_session=; Path=/; HttpOnly; Max-Age=0; SameSite=Lax"
}

func verifierLongueurMotDePasse(_ motDePasse: String) -> Bool {
    motDePasse.count >= 6
}

func pageErreurAuth() -> HTML {
    Views.pageErreur(message: "Tu dois être connectée pour accéder à cette page.")
}

func verifierAuteur(histoire: Histoire, utilisateur: Utilisateur?) -> Bool {
    guard let utilisateur, let userId = utilisateur.id else {
        return false
    }

    return histoire.auteurId == userId
}

// MARK: - PAGE D'ENTRÉE

router.get("/") { request, _ -> Response in
    if (try utilisateurConnecte(request)) != nil {
        return reponseRedirect("/dashboard")
    }

    return reponseHTML(Views.pageAuthAccueil())
}

// MARK: - REGISTER

router.get("/register") { request, _ -> Response in
    if (try utilisateurConnecte(request)) != nil {
        return reponseRedirect("/dashboard")
    }

    return reponseHTML(Views.pageRegister())
}

router.post("/register") { request, _ -> Response in
    let form = try await lireFormulaire(request)

    let pseudo = (form["pseudo"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let email = (form["email"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let motDePasse = form["motDePasse"] ?? ""

    guard !pseudo.isEmpty, !email.isEmpty, !motDePasse.isEmpty else {
        return Response(status: .badRequest)
    }

    guard verifierLongueurMotDePasse(motDePasse) else {
        return reponseHTML(
            Views.pageRegister(messageErreur: "Le mot de passe doit faire au moins 6 caractères.")
        )
    }

    if try Database.recupererUtilisateurParPseudo(db: db, pseudoRecherche: pseudo) != nil {
        return reponseHTML(
            Views.pageRegister(messageErreur: "Ce pseudo est déjà utilisé.")
        )
    }

    if try Database.recupererUtilisateurParEmail(db: db, emailRecherche: email) != nil {
        return reponseHTML(
            Views.pageRegister(messageErreur: "Cet email est déjà utilisé.")
        )
    }

    try Database.ajouterUtilisateur(
        db: db,
        pseudo: pseudo,
        email: email,
        motDePasse: motDePasse
    )

    guard
        let utilisateur = try Database.recupererUtilisateurParEmail(db: db, emailRecherche: email),
        let utilisateurId = utilisateur.id
    else {
        return Response(status: .internalServerError)
    }

    let token = try Database.creerSession(db: db, utilisateurId: utilisateurId)
    return reponseRedirect("/dashboard", cookie: cookieSession(token))
}

// MARK: - LOGIN

router.get("/login") { request, _ -> Response in
    if (try utilisateurConnecte(request)) != nil {
        return reponseRedirect("/dashboard")
    }

    return reponseHTML(Views.pageAuthAccueil())
}

router.post("/login") { request, _ -> Response in
    let form = try await lireFormulaire(request)

    let email = (form["email"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let motDePasse = form["motDePasse"] ?? ""

    guard
        let utilisateur = try Database.verifierConnexion(
            db: db,
            email: email,
            motDePasse: motDePasse
        ),
        let utilisateurId = utilisateur.id
    else {
        return reponseHTML(
            Views.pageAuthAccueil(messageErreur: "Email ou mot de passe incorrect.")
        )
    }

    let token = try Database.creerSession(db: db, utilisateurId: utilisateurId)
    return reponseRedirect("/dashboard", cookie: cookieSession(token))
}

// MARK: - LOGOUT

router.post("/logout") { request, _ -> Response in
    if let token = lireCookie(request, nom: "storycraft_session") {
        try? Database.supprimerSession(db: db, token: token)
    }

    return reponseRedirect("/", cookie: cookieSuppressionSession())
}

// MARK: - DASHBOARD

router.get("/dashboard") { request, _ -> HTML in
    guard let utilisateur = try utilisateurConnecte(request),
        let utilisateurId = utilisateur.id
    else {
        return pageErreurAuth()
    }

    let histoires = try Database.recupererHistoiresParAuteur(
        db: db,
        auteurIdRecherche: utilisateurId
    )

    let brouillons = histoires.filter { $0.statut == "brouillon" }
    let publiees = histoires.filter { $0.statut == "publie" }

    return Views.pageDashboard(
        utilisateur: utilisateur,
        brouillons: brouillons,
        publiees: publiees
    )
}

// MARK: - PROFIL

router.get("/profil") { request, _ -> HTML in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return pageErreurAuth()
    }

    return Views.pageProfil(utilisateur: utilisateur)
}

router.post("/profil/update") { request, _ -> Response in
    guard let utilisateur = try utilisateurConnecte(request),
        let utilisateurId = utilisateur.id
    else {
        return Response(status: .unauthorized)
    }

    let form = try await lireFormulaire(request)
    let pseudo = (form["pseudo"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let bio = (form["bio"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let avatarURL = (form["avatarURL"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    guard !pseudo.isEmpty else {
        return Response(status: .badRequest)
    }

    if let utilisateurExistant = try Database.recupererUtilisateurParPseudo(
        db: db,
        pseudoRecherche: pseudo
    ), utilisateurExistant.id != utilisateur.id {
        return Response(status: .badRequest)
    }

    try Database.mettreAJourProfil(
        db: db,
        utilisateurIdRecherche: utilisateurId,
        pseudoNouveau: pseudo,
        bioNouvelle: bio,
        avatarURLNouvelle: avatarURL
    )

    return reponseRedirect("/profil")
}

// MARK: - EXPLORER

router.get("/histoires/publiees") { request, _ -> HTML in
    let utilisateur = try utilisateurConnecte(request)
    let histoires = try Database.recupererHistoiresPubliees(db: db)
    return Views.pageHistoiresPubliees(histoires: histoires, utilisateur: utilisateur)
}

// MARK: - DETAIL HISTOIRE

router.get("/histoires/:id") { request, context -> HTML in
    let utilisateur = try utilisateurConnecte(request)

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        let auteur = try Database.recupererUtilisateurParId(db: db, idRecherche: histoire.auteurId)
    else {
        return Views.pageErreur(utilisateur: utilisateur)
    }

    if histoire.statut != "publie" && !verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    {
        return Views.pageErreur(
            message: "Cette histoire n’est pas accessible.",
            utilisateur: utilisateur
        )
    }

    let chapitres = try Database.recupererChapitresParHistoire(db: db, histoireIdRecherche: id)

    let chapitresAvecStats = try chapitres.map { chapitre in
        let stats = try Database.statistiquesChapitre(
            db: db,
            chapitreIdRecherche: chapitre.id ?? -1,
            utilisateurIdConnecte: utilisateur?.id
        )

        return ChapitreAvecStats(
            chapitre: chapitre,
            moyenne: stats.0,
            nombreNotes: stats.1,
            maNote: stats.2
        )
    }

    let commentaires = try Database.recupererCommentairesHistoire(db: db, histoireIdRecherche: id)

    return Views.pageDetailHistoire(
        histoire: histoire,
        auteur: auteur,
        chapitres: chapitresAvecStats,
        commentaires: commentaires,
        utilisateur: utilisateur
    )
}

// MARK: - PAGE LECTURE CHAPITRE

router.get("/chapitres/:id") { request, context -> HTML in
    let utilisateur = try utilisateurConnecte(request)

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id),
        let histoire = try Database.recupererHistoireParId(
            db: db, histoireIdRecherche: chapitre.histoireId),
        let auteur = try Database.recupererUtilisateurParId(db: db, idRecherche: histoire.auteurId)
    else {
        return Views.pageErreur(utilisateur: utilisateur)
    }

    if histoire.statut != "publie" && !verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    {
        return Views.pageErreur(
            message: "Ce chapitre n’est pas accessible.",
            utilisateur: utilisateur
        )
    }

    let chapitrePrecedent = try Database.recupererChapitrePrecedent(
        db: db,
        histoireIdRecherche: chapitre.histoireId,
        numeroActuel: chapitre.numero
    )

    let chapitreSuivant = try Database.recupererChapitreSuivant(
        db: db,
        histoireIdRecherche: chapitre.histoireId,
        numeroActuel: chapitre.numero
    )

    return Views.pageLectureChapitre(
        histoire: histoire,
        auteur: auteur,
        chapitre: chapitre,
        chapitrePrecedent: chapitrePrecedent,
        chapitreSuivant: chapitreSuivant,
        utilisateur: utilisateur
    )
}

// MARK: - AJOUT HISTOIRE

router.post("/histoires/ajouter") { request, _ -> Response in
    guard let utilisateur = try utilisateurConnecte(request),
        let utilisateurId = utilisateur.id
    else {
        return Response(status: .unauthorized)
    }

    let form = try await lireFormulaire(request)
    let titre = (form["titre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let genre = (form["genre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let resume = (form["resume"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let couverture = (form["couverture"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let statut = (form["statut"] ?? "brouillon").trimmingCharacters(in: .whitespacesAndNewlines)

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.ajouterHistoire(
        db: db,
        auteurId: utilisateurId,
        titre: titre,
        genre: genre,
        resume: resume,
        couverture: couverture,
        statut: statut
    )

    return reponseRedirect("/dashboard")
}

// MARK: - PAGE MODIF HISTOIRE

router.get("/histoires/:id/modifier") { request, context -> HTML in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return pageErreurAuth()
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Views.pageErreur(utilisateur: utilisateur)
    }

    return Views.pageModificationHistoire(histoire: histoire, utilisateur: utilisateur)
}

// MARK: - ACTION MODIF HISTOIRE

router.post("/histoires/:id/update") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)
    let titre = (form["titre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let genre = (form["genre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let resume = (form["resume"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let couverture = (form["couverture"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let statut = (form["statut"] ?? "brouillon").trimmingCharacters(in: .whitespacesAndNewlines)

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.modifierHistoire(
        db: db,
        histoireIdRecherche: histoire.id ?? id,
        titre: titre,
        genre: genre,
        resume: resume,
        couverture: couverture,
        statut: statut
    )

    return reponseRedirect("/dashboard")
}

// MARK: - SUPPR HISTOIRE

router.post("/histoires/:id/supprimer") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur),
        let histoireId = histoire.id
    else {
        return Response(status: .badRequest)
    }

    try Database.supprimerHistoire(db: db, histoireIdRecherche: histoireId)
    return reponseRedirect("/dashboard")
}

// MARK: - GESTION CHAPITRES

router.get("/histoires/:id/chapitres") { request, context -> HTML in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return pageErreurAuth()
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Views.pageErreur(utilisateur: utilisateur)
    }

    let chapitres = try Database.recupererChapitresParHistoire(db: db, histoireIdRecherche: id)

    return Views.pageGestionChapitres(
        histoire: histoire,
        chapitres: chapitres,
        utilisateur: utilisateur
    )
}

// MARK: - AJOUT CHAPITRE

router.post("/histoires/:id/chapitres/ajouter") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)
    let titre = (form["titre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let contenu = (form["contenu"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    guard !titre.isEmpty, !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    let numero = try Database.prochainNumeroChapitre(db: db, histoireIdRecherche: id)

    try Database.ajouterChapitre(
        db: db,
        histoireId: id,
        numero: numero,
        titre: titre,
        contenu: contenu
    )

    return reponseRedirect("/histoires/\(id)/chapitres")
}

// MARK: - PAGE MODIF CHAPITRE

router.get("/chapitres/:id/modifier") { request, context -> HTML in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return pageErreurAuth()
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id),
        let histoire = try Database.recupererHistoireParId(
            db: db, histoireIdRecherche: chapitre.histoireId),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Views.pageErreur(utilisateur: utilisateur)
    }

    return Views.pageModificationChapitre(chapitre: chapitre, utilisateur: utilisateur)
}

// MARK: - ACTION MODIF CHAPITRE

router.post("/chapitres/:id/update") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id),
        let histoire = try Database.recupererHistoireParId(
            db: db, histoireIdRecherche: chapitre.histoireId),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)
    let titre = (form["titre"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let contenu = (form["contenu"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let numero = Int(form["numero"] ?? "") ?? chapitre.numero

    guard !titre.isEmpty, !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.modifierChapitre(
        db: db,
        chapitreIdRecherche: id,
        numero: numero,
        titre: titre,
        contenu: contenu
    )

    return reponseRedirect("/histoires/\(chapitre.histoireId)/chapitres")
}

// MARK: - SUPPR CHAPITRE

router.post("/chapitres/:id/supprimer") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request) else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let id = Int64(idString),
        let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id),
        let histoire = try Database.recupererHistoireParId(
            db: db, histoireIdRecherche: chapitre.histoireId),
        verifierAuteur(histoire: histoire, utilisateur: utilisateur)
    else {
        return Response(status: .badRequest)
    }

    try Database.supprimerChapitre(db: db, chapitreIdRecherche: id)
    return reponseRedirect("/histoires/\(chapitre.histoireId)/chapitres")
}

// MARK: - NOTER CHAPITRE

router.post("/chapitres/:id/noter") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request),
        let utilisateurId = utilisateur.id
    else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let chapitreId = Int64(idString)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)
    let note = Int(form["note"] ?? "") ?? 0

    guard (1...5).contains(note) else {
        return Response(status: .badRequest)
    }

    try Database.noterChapitre(
        db: db,
        utilisateurId: utilisateurId,
        chapitreId: chapitreId,
        note: note
    )

    if let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: chapitreId) {
        return reponseRedirect("/histoires/\(chapitre.histoireId)")
    }

    return reponseRedirect("/")
}

// MARK: - COMMENTAIRE HISTOIRE

router.post("/histoires/:id/commentaires/ajouter") { request, context -> Response in
    guard let utilisateur = try utilisateurConnecte(request),
        let utilisateurId = utilisateur.id
    else {
        return Response(status: .unauthorized)
    }

    guard let idString = context.parameters.get("id"),
        let histoireId = Int64(idString)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)
    let contenu = (form["contenu"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    guard !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.ajouterCommentaireHistoire(
        db: db,
        histoireId: histoireId,
        utilisateurId: utilisateurId,
        contenu: contenu
    )

    return reponseRedirect("/histoires/\(histoireId)")
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print("Serveur lancé sur http://localhost:8080")
try await app.runService()
