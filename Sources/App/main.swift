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

router.get("/") { _, _ -> HTML in
    let utilisateur = try recupererOuCreerUtilisateurParDefaut()
    let histoires = try Database.recupererHistoiresParAuteur(
        db: db,
        auteurIdRecherche: utilisateur.id!
    )
    return Views.pageAccueil(histoires: histoires, pseudoUtilisateur: utilisateur.pseudo)
}

router.get("/histoires/publiees") { _, _ -> HTML in
    let histoires = try Database.recupererHistoiresPubliees(db: db)
    return Views.pageHistoiresPubliees(histoires: histoires)
}

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

    return Response(status: .seeOther, headers: [.location: "/"])
}

router.get("/histoires/:id/modifier") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr),
          let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id) else {
        return Views.pageErreur()
    }

    return Views.pageModification(histoire: histoire)
}

router.post("/histoires/:id/update") { request, context -> Response in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr) else {
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

    return Response(status: .seeOther, headers: [.location: "/"])
}

router.post("/histoires/:id/supprimer") { _, context -> Response in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr) else {
        return Response(status: .badRequest)
    }

    try Database.supprimerHistoire(db: db, histoireIdRecherche: id)
    return Response(status: .seeOther, headers: [.location: "/"])
}

router.get("/histoires/:id/chapitres") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr),
          let histoire = try Database.recupererHistoireParId(db: db, histoireIdRecherche: id) else {
        return Views.pageErreur()
    }

    let chapitres = try Database.recupererChapitresParHistoire(db: db, histoireIdRecherche: id)
    return Views.pageChapitres(histoire: histoire, chapitres: chapitres)
}

router.post("/histoires/:id/chapitres/ajouter") { request, context -> Response in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr) else {
        return Response(status: .badRequest)
    }

    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let contenu = form["contenu"] ?? ""

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

    return Response(status: .seeOther, headers: [.location: "/histoires/\(id)/chapitres"])
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print("Serveur lancé sur http://localhost:8080")
try await app.runService()