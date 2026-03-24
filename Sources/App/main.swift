import Foundation
import Hummingbird
@preconcurrency import SQLite

let db = try Database.setup()
let router = Router()

func lireFormulaire(_ request: Request) async throws -> [String: String] {
    let buffer = try await request.body.collect(upTo: 1024 * 64)
    let bodyString = String(buffer: buffer)

    var components = URLComponents()
    components.percentEncodedQuery = bodyString

    var data: [String: String] = [:]
    components.queryItems?.forEach { item in
        data[item.name] = item.value ?? ""
    }

    return data
}

router.get("/") { _, _ -> HTML in
    let histoires = try Database.recupererHistoires(db: db)
    return Views.pageAccueil(histoires: histoires)
}

router.post("/histoires/ajouter") { request, _ -> Response in
    let form = try await lireFormulaire(request)

    let titre = form["titre"] ?? ""
    let genre = form["genre"] ?? ""
    let resume = form["resume"] ?? ""
    let contenu = form["contenu"] ?? ""
    let statut = form["statut"] ?? "brouillon"

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty, !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.ajouterHistoire(
        db: db,
        titre: titre,
        genre: genre,
        resume: resume,
        contenu: contenu,
        statut: statut
    )

    return Response(status: .seeOther, headers: [.location: "/"])
}

router.get("/histoires/:id/modifier") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr),
          let histoire = try Database.recupererHistoireParId(db: db, histoireId: id) else {
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
    let contenu = form["contenu"] ?? ""
    let statut = form["statut"] ?? "brouillon"

    guard !titre.isEmpty, !genre.isEmpty, !resume.isEmpty, !contenu.isEmpty else {
        return Response(status: .badRequest)
    }

    try Database.modifierHistoire(
        db: db,
        histoireId: id,
        titre: titre,
        genre: genre,
        resume: resume,
        contenu: contenu,
        statut: statut
    )

    return Response(status: .seeOther, headers: [.location: "/"])
}

router.post("/histoires/:id/supprimer") { _, context -> Response in
    guard let idStr = context.parameters.get("id"),
          let id = Int64(idStr) else {
        return Response(status: .badRequest)
    }

    try Database.supprimerHistoire(db: db, histoireId: id)
    return Response(status: .seeOther, headers: [.location: "/"])
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print(" Serveur lancé sur http://localhost:8080")
try await app.runService()