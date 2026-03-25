import Foundation
import Hummingbird

struct Views {
    static func pageAccueil(histoires: [Histoire], pseudoUtilisateur: String) -> HTML {
        let cartes = histoires.map { histoire in
            """
            <article style="margin-bottom: 1rem; padding: 1rem; border: 1px solid #ddd; border-radius: 12px;">
                \(histoire.couverture.isEmpty ? "" : "<img src=\"\(escapeHTMLAttribute(histoire.couverture))\" alt=\"Couverture\" style=\"max-width: 120px; border-radius: 8px; margin-bottom: 1rem;\">")
                <h3 style="margin-bottom: 0.5rem;">\(escapeHTML(histoire.titre))</h3>
                <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                <p><strong>Statut :</strong> \(escapeHTML(histoire.statut))</p>
                <p><strong>Résumé :</strong> \(escapeHTML(histoire.resume))</p>
                <p><small>Créée le : \(escapeHTML(histoire.dateCreation))</small></p>
                <p><small>Modifiée le : \(escapeHTML(histoire.dateModification))</small></p>

                <div style="display: flex; gap: 10px; margin-top: 1rem; flex-wrap: wrap;">
                    <a href="/histoires/\(histoire.id ?? 0)/modifier" role="button" class="secondary">Modifier</a>
                    <a href="/histoires/\(histoire.id ?? 0)/chapitres" role="button">Chapitres</a>

                    <form action="/histoires/\(histoire.id ?? 0)/supprimer" method="post" style="margin: 0;">
                        <button type="submit" class="contrast">Supprimer</button>
                    </form>
                </div>
            </article>
            """
        }.joined()

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>StoryCraft</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 900px;">
                    <header>
                        <h1>StoryCraft</h1>
                        <p>Bienvenue \(escapeHTML(pseudoUtilisateur)).</p>
                        <p><a href="/histoires/publiees">Voir les histoires publiées</a></p>
                    </header>

                    <main>
                        <section style="margin-bottom: 2rem;">
                            <h2>Créer une histoire</h2>
                            <form action="/histoires/ajouter" method="post">
                                <label>Titre
                                    <input type="text" name="titre" required>
                                </label>

                                <label>Genre
                                    <input type="text" name="genre" required>
                                </label>

                                <label>Résumé
                                    <textarea name="resume" required></textarea>
                                </label>

                                <label>URL de couverture
                                    <input type="text" name="couverture" placeholder="https://...">
                                </label>

                                <label>Statut
                                    <select name="statut" required>
                                        <option value="brouillon">Brouillon</option>
                                        <option value="publie">Publié</option>
                                    </select>
                                </label>

                                <button type="submit">Créer l’histoire</button>
                            </form>
                        </section>

                        <section>
                            <h2>Mes histoires</h2>
                            \(histoires.isEmpty ? "<p>Aucune histoire pour le moment.</p>" : cartes)
                        </section>
                    </main>
                </body>
                </html>
                """)
    }

    static func pageModification(histoire: Histoire) -> HTML {
        HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Modifier une histoire</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 900px;">
                    <header>
                        <h1>Modifier l’histoire</h1>
                        <p><a href="/">← Retour à l’accueil</a></p>
                    </header>

                    <main>
                        <form action="/histoires/\(histoire.id ?? 0)/update" method="post">
                            <label>Titre
                                <input type="text" name="titre" value="\(escapeHTMLAttribute(histoire.titre))" required>
                            </label>

                            <label>Genre
                                <input type="text" name="genre" value="\(escapeHTMLAttribute(histoire.genre))" required>
                            </label>

                            <label>Résumé
                                <textarea name="resume" required>\(escapeHTML(histoire.resume))</textarea>
                            </label>

                            <label>URL de couverture
                                <input type="text" name="couverture" value="\(escapeHTMLAttribute(histoire.couverture))">
                            </label>

                            <label>Statut
                                <select name="statut" required>
                                    <option value="brouillon" \(histoire.statut == "brouillon" ? "selected" : "")>Brouillon</option>
                                    <option value="publie" \(histoire.statut == "publie" ? "selected" : "")>Publié</option>
                                </select>
                            </label>

                            <button type="submit">Enregistrer les modifications</button>
                        </form>
                    </main>
                </body>
                </html>
                """)
    }

    static func pageHistoiresPubliees(histoires: [HistoirePublique]) -> HTML {
        let cartes = histoires.map { histoire in
            """
            <article style="margin-bottom: 1rem; padding: 1rem; border: 1px solid #ddd; border-radius: 12px;">
                \(histoire.couverture.isEmpty ? "" : "<img src=\"\(escapeHTMLAttribute(histoire.couverture))\" alt=\"Couverture\" style=\"max-width: 120px; border-radius: 8px; margin-bottom: 1rem;\">")
                <h3>\(escapeHTML(histoire.titre))</h3>
                <p><strong>Auteur :</strong> \(escapeHTML(histoire.pseudoAuteur))</p>
                <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                <p><strong>Résumé :</strong> \(escapeHTML(histoire.resume))</p>
            </article>
            """
        }.joined()

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Histoires publiées</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 900px;">
                    <h1>Histoires publiées</h1>
                    <p><a href="/">← Retour à l’accueil</a></p>
                    \(histoires.isEmpty ? "<p>Aucune histoire publiée pour le moment.</p>" : cartes)
                </body>
                </html>
                """)
    }

    static func pageChapitres(histoire: Histoire, chapitres: [Chapitre]) -> HTML {
        let liste = chapitres.map { chapitre in
            """
            <article style="margin-bottom: 1rem; padding: 1rem; border: 1px solid #ddd; border-radius: 12px;">
                <h3>Chapitre \(chapitre.numero) — \(escapeHTML(chapitre.titre))</h3>
                <p>\(escapeHTML(chapitre.contenu))</p>
            </article>
            """
        }.joined()

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Chapitres</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 900px;">
                    <h1>Chapitres de \(escapeHTML(histoire.titre))</h1>
                    <p><a href="/">← Retour à l’accueil</a></p>

                    <section style="margin-bottom: 2rem;">
                        <h2>Ajouter un chapitre</h2>
                        <form action="/histoires/\(histoire.id ?? 0)/chapitres/ajouter" method="post">
                            <label>Titre du chapitre
                                <input type="text" name="titre" required>
                            </label>

                            <label>Contenu
                                <textarea name="contenu" rows="10" required></textarea>
                            </label>

                            <button type="submit">Ajouter le chapitre</button>
                        </form>
                    </section>

                    <section>
                        <h2>Liste des chapitres</h2>
                        \(chapitres.isEmpty ? "<p>Aucun chapitre pour le moment.</p>" : liste)
                    </section>
                </body>
                </html>
                """)
    }

    static func pageErreur() -> HTML {
        HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>Introuvable</title>
                </head>
                <body style="font-family: sans-serif; padding: 2rem;">
                    <h1>404</h1>
                    <p>Page introuvable.</p>
                    <p><a href="/">Retour à l’accueil</a></p>
                </body>
                </html>
                """)
    }

    static func escapeHTML(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }

    static func escapeHTMLAttribute(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

struct HTML: ResponseGenerator {
    let content: String

    func response(from request: Request, context: some RequestContext) throws -> Response {
        Response(
            status: .ok,
            headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: content))
        )
    }
}
