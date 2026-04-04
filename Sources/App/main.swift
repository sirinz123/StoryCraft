import Foundation
import Hummingbird
@preconcurrency import SQLite

let db = try Database.setup()
let router = Router()

func lireFormulaire(_ request: Request) async throws -> [String: String] {
    let buffer = try await request.body.collect(upTo: 1024 * 64)
    let bodyString = String(buffer: buffer).replacingOccurrences(of: "+", with: "%20")

    var components = URLComponents()
    components.percentEncodedQuery = bodyString

    var data: [String: String] = [:]
    components.queryItems?.forEach { item in
        data[item.name] = item.value ?? ""
    }

    return data
}

func recupererOuCreerUtilisateurParDefaut() throws -> Utilisateur {
    if let utilisateur = try Database.recupererUtilisateurParEmail(
        db: db,
        emailRecherche: "demo@storycraft.fr"
    ) {
        return utilisateur
    }

    try Database.ajouterUtilisateur(
        db: db,
        pseudo: "demo",
        email: "demo@storycraft.fr",
        motDePasse: "demo"
    )

    return try Database.recupererUtilisateurParEmail(
        db: db,
        emailRecherche: "demo@storycraft.fr"
    )!
}

// LANDING PAGE PUBLIQUE
router.get("/") { _, _ -> HTML in
    let histoiresPubliees = try Database.recupererHistoiresPubliees(db: db)
    return Views.pageLanding(histoiresPubliees: histoiresPubliees)
}

// DASHBOARD
router.get("/dashboard") { _, _ -> HTML in
    let utilisateur = try recupererOuCreerUtilisateurParDefaut()

    let histoires = try Database.recupererHistoiresParAuteur(
        db: db,
        auteurIdRecherche: utilisateur.id!
    )

    let brouillons = histoires.filter { $0.statut == "brouillon" }
    let publiees = histoires.filter { $0.statut == "publie" }

    return Views.pageTableauDeBord(
        pseudoUtilisateur: utilisateur.pseudo,
        brouillons: brouillons,
        publiees: publiees
    )
}

// LISTE PUBLIQUE DES HISTOIRES PUBLIEES
router.get("/histoires/publiees") { _, _ -> HTML in
    let histoires = try Database.recupererHistoiresPubliees(db: db)
    return Views.pageHistoiresPubliees(histoires: histoires)
}

// DETAIL D'UNE HISTOIRE
router.get("/histoires/:id") { _, context -> HTML in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id),
          let auteur = try Database.recupererUtilisateurParId(db: db, idRecherche: histoire.auteurId)
    else {
        return Views.pageErreur()
    }

    let chapitres = try Database.recupererChapitresParHistoire(
        db: db,
        histoireIdRecherche: id
    )

    return Views.pageDetailHistoire(
        histoire: histoire,
        auteur: auteur,
        chapitres: chapitres
    )
}

// CREATION D'HISTOIRE
router.post("/histoires/ajouter") { request, _ -> Response in
    let utilisateur = try recupererOuCreerUtilisateurParDefaut()
    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let genre = form["genre"] ?? ""
    let resume = form["resume"] ?? ""
    let couverture = form["couverture"] ?? ""
    let statut = form["statut"] ?? "brouillon"

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.ajouterHistoire(
        db: db,
        auteurId: utilisateur.id!,
        titre: titre,
        genre: genre,
        resume: resume,
        couverture: couverture,
        statut: statut
    )

    return Response(status: .seeOther, headers: [.location: "/dashboard"])
}

// MODIFICATION D'HISTOIRE - PAGE
router.get("/histoires/:id/modifier") { _, context -> HTML in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id)
    else {
        return Views.pageErreur()
    }

    return Views.pageModificationHistoire(histoire: histoire)
}

// MODIFICATION D'HISTOIRE - ACTION
router.post("/histoires/:id/update") { request, context -> Response in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let genre = form["genre"] ?? ""
    let resume = form["resume"] ?? ""
    let couverture = form["couverture"] ?? ""
    let statut = form["statut"] ?? "brouillon"

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.modifierHistoire(
        db: db,
        histoireIdRecherche: id,
        titre: titre,
        genre: genre,
        resume: resume,
        couverture: couverture,
        statut: statut
    )

    return Response(status: .seeOther, headers: [.location: "/dashboard"])
}

// SUPPRESSION D'HISTOIRE
router.post("/histoires/:id/supprimer") { _, context -> Response in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString)
    else {
        return Response(status: .badRequest)
    }

    try Database.supprimerHistoire(db: db, histoireIdRecherche: id)
    return Response(status: .seeOther, headers: [.location: "/dashboard"])
}

// PAGE CHAPITRES (gestion)
router.get("/histoires/:id/chapitres") { _, context -> HTML in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id)
    else {
        return Views.pageErreur()
    }

    let chapitres = try Database.recupererChapitresParHistoire(
        db: db,
        histoireIdRecherche: id
    )

    return Views.pageGestionChapitres(histoire: histoire, chapitres: chapitres)
}

// AJOUT CHAPITRE
router.post("/histoires/:id/chapitres/ajouter") { request, context -> Response in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let contenu = form["contenu"] ?? ""

    guard !titre.isEmpty, !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    let numero = try Database.prochainNumeroChapitre(
        db: db,
        histoireIdRecherche: id
    )

    try Database.ajouterChapitre(
        db: db,
        histoireId: id,
        numero: numero,
        titre: titre,
        contenu: contenu
    )

    return Response(status: .seeOther, headers: [.location: "/histoires/\(id)/chapitres"])
}

// PAGE MODIFICATION CHAPITRE
router.get("/chapitres/:id/modifier") { _, context -> HTML in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id)
    else {
        return Views.pageErreur()
    }

    return Views.pageModificationChapitre(chapitre: chapitre)
}

// ACTION MODIFICATION CHAPITRE
router.post("/chapitres/:id/update") { request, context -> Response in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let chapitreExistant = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id)
    else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let contenu = form["contenu"] ?? ""
    let numeroString = form["numero"] ?? ""
    let numero = Int(numeroString) ?? chapitreExistant.numero

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

    return Response(
        status: .seeOther,
        headers: [.location: "/histoires/\(chapitreExistant.histoireId)/chapitres"]
    )
}

// SUPPRESSION CHAPITRE
router.post("/chapitres/:id/supprimer") { _, context -> Response in
    guard let idString = context.parameters.get("id"),
          let id = Int64(idString),
          let chapitre = try Database.recupererChapitreParId(db: db, chapitreIdRecherche: id)
    else {
        return Response(status: .badRequest)
    }

    try Database.supprimerChapitre(db: db, chapitreIdRecherche: id)

    return Response(
        status: .seeOther,
        headers: [.location: "/histoires/\(chapitre.histoireId)/chapitres"]
    )
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print("Serveur lancé sur http://localhost:8080")
try await app.runService()