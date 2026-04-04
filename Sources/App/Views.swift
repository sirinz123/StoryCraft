import Foundation
import Hummingbird

struct Views {
    static func pageLanding(histoiresPubliees: [HistoirePublique]) -> HTML {
        let histoiresMisesEnAvant = Array(histoiresPubliees.prefix(6))
        let cartes = histoiresMisesEnAvant.map { histoire in
            """
            <a href="/histoires/\(histoire.id)" class="carte-lien">
                <article class="carte-histoire">
                    <div class="carte-cover">
                        \(imageCouvertureHTML(histoire.couverture))
                    </div>

                    <div class="carte-contenu">
                        <div class="badge badge-publie">Publié</div>
                        <h3>\(escapeHTML(histoire.titre))</h3>
                        <p class="muted">Par \(escapeHTML(histoire.pseudoAuteur))</p>
                        <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                        <p>\(escapeHTML(histoire.resume))</p>
                    </div>
                </article>
            </a>
            """
        }.joined()

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>StoryCraft</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/histoires/publiees">Explorer</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page">
                <section class="hero">
                    <div class="hero-texte">
                        <span class="eyebrow">Plateforme d’écriture</span>
                        <h1>Écris, publie et construis ton univers.</h1>
                        <p class="hero-desc">
                            Une expérience d’écriture sombre, douce et lisible pour gérer tes histoires,
                            tes chapitres et tes publications dans un seul espace.
                        </p>

                        <div class="hero-actions">
                            <a href="/dashboard" class="btn">Commencer à écrire</a>
                            <a href="/histoires/publiees" class="btn btn-secondary">Découvrir les histoires</a>
                        </div>
                    </div>

                    <div class="hero-card">
                        <div class="hero-preview-title">Ambiance cosy • mode nuit</div>
                        <p>Un espace pensé pour écrire sans distraction, organiser tes brouillons
                        et publier proprement quand ton histoire est prête.</p>
                    </div>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Histoires publiées</h2>
                        <a href="/histoires/publiees" class="section-link">Tout voir</a>
                    </div>

                    <div class="grid-cards">
                        \(histoiresMisesEnAvant.isEmpty ? "<p class=\"muted\">Aucune histoire publiée pour le moment.</p>" : cartes)
                    </div>
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func pageTableauDeBord(
        pseudoUtilisateur: String,
        brouillons: [Histoire],
        publiees: [Histoire]
    ) -> HTML {
        let cartesBrouillons = renduCartes(histoires: brouillons)
        let cartesPubliees = renduCartes(histoires: publiees)

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Dashboard • StoryCraft</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/histoires/publiees">Explorer</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page">
                <section class="page-header">
                    <div>
                        <span class="eyebrow">Tableau de bord</span>
                        <h1>Bienvenue \(escapeHTML(pseudoUtilisateur)).</h1>
                        <p class="muted">Gère tes brouillons, tes publications et tes chapitres dans un espace clair.</p>
                    </div>
                </section>

                <section class="section">
                    <article class="bloc-formulaire">
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
                                <input type="text" name="couverture" id="input-couverture-creation" placeholder="https://...">
                            </label>

                            <div id="preview-zone-creation" class="preview-zone" style="display:none;">
                                <p class="muted">Aperçu de la couverture</p>
                                <img id="preview-couverture-creation" src="" alt="Aperçu couverture" class="preview-img">
                            </div>

                            <label>Statut
                                <select name="statut" required>
                                    <option value="brouillon">Brouillon</option>
                                    <option value="publie">Publié</option>
                                </select>
                            </label>

                            <button type="submit" class="btn">Créer l’histoire</button>
                        </form>
                    </article>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Mes brouillons</h2>
                    </div>
                    \(brouillons.isEmpty ? "<p class=\"muted\">Aucun brouillon pour le moment.</p>" : cartesBrouillons)
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Mes histoires publiées</h2>
                    </div>
                    \(publiees.isEmpty ? "<p class=\"muted\">Aucune histoire publiée pour le moment.</p>" : cartesPubliees)
                </section>
            </main>

            <script>
                const inputCreation = document.getElementById("input-couverture-creation");
                const previewZoneCreation = document.getElementById("preview-zone-creation");
                const previewCreation = document.getElementById("preview-couverture-creation");

                if (inputCreation && previewZoneCreation && previewCreation) {
                    inputCreation.addEventListener("input", () => {
                        const valeur = inputCreation.value.trim();

                        if (valeur !== "") {
                            previewCreation.src = valeur;
                            previewZoneCreation.style.display = "block";
                        } else {
                            previewCreation.src = "";
                            previewZoneCreation.style.display = "none";
                        }
                    });

                    previewCreation.addEventListener("error", () => {
                        previewZoneCreation.style.display = "none";
                    });
                }
            </script>
        </body>
        </html>
        """)
    }

    static func renduCartes(histoires: [Histoire]) -> String {
        histoires.map { histoire in
            """
            <article class="carte-histoire">
                <div class="carte-cover">
                    \(imageCouvertureHTML(histoire.couverture))
                </div>

                <div class="carte-contenu">
                    <div class="carte-top">
                        <h3>\(escapeHTML(histoire.titre))</h3>
                        <span class="badge \(histoire.statut == "publie" ? "badge-publie" : "badge-brouillon")">
                            \(histoire.statut == "publie" ? "Publié" : "Brouillon")
                        </span>
                    </div>

                    <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                    <p><strong>Résumé :</strong> \(escapeHTML(histoire.resume))</p>
                    <p class="muted small">Créée le : \(escapeHTML(histoire.dateCreation))</p>
                    <p class="muted small">Modifiée le : \(escapeHTML(histoire.dateModification))</p>

                    <div class="actions">
                        <a href="/histoires/\(histoire.id ?? 0)" class="btn btn-secondary">Voir</a>
                        <a href="/histoires/\(histoire.id ?? 0)/modifier" class="btn btn-secondary">Modifier</a>
                        <a href="/histoires/\(histoire.id ?? 0)/chapitres" class="btn btn-secondary">Chapitres</a>

                        <form action="/histoires/\(histoire.id ?? 0)/supprimer" method="post" style="margin:0;">
                            <button type="submit" class="btn btn-danger">Supprimer</button>
                        </form>
                    </div>
                </div>
            </article>
            """
        }.joined()
    }

    static func pageDetailHistoire(
        histoire: Histoire,
        auteur: Utilisateur,
        chapitres: [Chapitre]
    ) -> HTML {
        let listeChapitres = chapitres.map { chapitre in
            """
            <a href="/histoires/\(histoire.id ?? 0)/chapitres" class="chapitre-ligne">
                <div>
                    <strong>Chapitre \(chapitre.numero)</strong> — \(escapeHTML(chapitre.titre))
                    <div class="muted small">Mis à jour le \(escapeHTML(chapitre.dateModification))</div>
                </div>
                <span class="muted">→</span>
            </a>
            """
        }.joined()

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(escapeHTML(histoire.titre)) • StoryCraft</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/histoires/publiees">Explorer</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page">
                <section class="detail-grid">
                    <div>
                        \(imageGrandeCouvertureHTML(histoire.couverture))
                    </div>

                    <div class="detail-meta">
                        <span class="eyebrow">Fiche histoire</span>
                        <h1>\(escapeHTML(histoire.titre))</h1>
                        <p class="muted">Par \(escapeHTML(auteur.pseudo))</p>

                        <div class="meta-pills">
                            <span class="badge \(histoire.statut == "publie" ? "badge-publie" : "badge-brouillon")">
                                \(histoire.statut == "publie" ? "Publié" : "Brouillon")
                            </span>
                            <span class="meta-pill">Genre : \(escapeHTML(histoire.genre))</span>
                            <span class="meta-pill">\(chapitres.count) chapitre(s)</span>
                        </div>

                        <div class="bloc-resume">
                            <h3>Résumé</h3>
                            <p>\(escapeHTMLAvecRetours(histoire.resume))</p>
                        </div>

                        <div class="actions">
                            <a href="/histoires/\(histoire.id ?? 0)/chapitres" class="btn">Gérer les chapitres</a>
                            <a href="/histoires/\(histoire.id ?? 0)/modifier" class="btn btn-secondary">Modifier l’histoire</a>
                        </div>
                    </div>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Chapitres</h2>
                    </div>

                    <div class="liste-chapitres">
                        \(chapitres.isEmpty ? "<p class=\"muted\">Aucun chapitre pour le moment.</p>" : listeChapitres)
                    </div>
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func pageModificationHistoire(histoire: Histoire) -> HTML {
        HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Modifier l’histoire</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page page-narrow">
                <section class="section">
                    <article class="bloc-formulaire">
                        <h1>Modifier l’histoire</h1>

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
                                <input type="text" name="couverture" id="input-couverture-modification" value="\(escapeHTMLAttribute(histoire.couverture))">
                            </label>

                            <div id="preview-zone-modification" class="preview-zone" style="\((histoire.couverture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? "display:none;" : "display:block;")">
                                <p class="muted">Aperçu de la couverture</p>
                                <img id="preview-couverture-modification" src="\(escapeHTMLAttribute(histoire.couverture))" alt="Aperçu couverture" class="preview-img">
                            </div>

                            <label>Statut
                                <select name="statut" required>
                                    <option value="brouillon" \(histoire.statut == "brouillon" ? "selected" : "")>Brouillon</option>
                                    <option value="publie" \(histoire.statut == "publie" ? "selected" : "")>Publié</option>
                                </select>
                            </label>

                            <div class="actions">
                                <button type="submit" class="btn">Enregistrer</button>
                                <a href="/dashboard" class="btn btn-secondary">Annuler</a>
                            </div>
                        </form>
                    </article>
                </section>
            </main>

            <script>
                const inputModification = document.getElementById("input-couverture-modification");
                const previewZoneModification = document.getElementById("preview-zone-modification");
                const previewModification = document.getElementById("preview-couverture-modification");

                if (inputModification && previewZoneModification && previewModification) {
                    inputModification.addEventListener("input", () => {
                        const valeur = inputModification.value.trim();

                        if (valeur !== "") {
                            previewModification.src = valeur;
                            previewZoneModification.style.display = "block";
                        } else {
                            previewModification.src = "";
                            previewZoneModification.style.display = "none";
                        }
                    });

                    previewModification.addEventListener("error", () => {
                        previewZoneModification.style.display = "none";
                    });
                }
            </script>
        </body>
        </html>
        """)
    }

    static func pageHistoiresPubliees(histoires: [HistoirePublique]) -> HTML {
        let cartes = histoires.map { histoire in
            """
            <a href="/histoires/\(histoire.id)" class="carte-lien">
                <article class="carte-histoire">
                    <div class="carte-cover">
                        \(imageCouvertureHTML(histoire.couverture))
                    </div>

                    <div class="carte-contenu">
                        <div class="carte-top">
                            <h3>\(escapeHTML(histoire.titre))</h3>
                            <span class="badge badge-publie">Publié</span>
                        </div>

                        <p><strong>Auteur :</strong> \(escapeHTML(histoire.pseudoAuteur))</p>
                        <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                        <p><strong>Résumé :</strong> \(escapeHTML(histoire.resume))</p>
                    </div>
                </article>
            </a>
            """
        }.joined()

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Histoires publiées</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/histoires/publiees">Explorer</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page">
                <section class="page-header">
                    <div>
                        <span class="eyebrow">Explorer</span>
                        <h1>Histoires publiées</h1>
                        <p class="muted">Découvre les histoires déjà visibles publiquement.</p>
                    </div>
                </section>

                <section class="section">
                    \(histoires.isEmpty ? "<p class=\"muted\">Aucune histoire publiée pour le moment.</p>" : cartes)
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func pageGestionChapitres(histoire: Histoire, chapitres: [Chapitre]) -> HTML {
        let liste = chapitres.map { chapitre in
            """
            <article class="chapitre-admin">
                <div>
                    <h3>Chapitre \(chapitre.numero) — \(escapeHTML(chapitre.titre))</h3>
                    <p class="muted small">Dernière modification : \(escapeHTML(chapitre.dateModification))</p>
                    <p>\(resumeCourt(chapitre.contenu))</p>
                </div>

                <div class="actions">
                    <a href="/chapitres/\(chapitre.id ?? 0)/modifier" class="btn btn-secondary">Modifier</a>

                    <form action="/chapitres/\(chapitre.id ?? 0)/supprimer" method="post" style="margin:0;">
                        <button type="submit" class="btn btn-danger">Supprimer</button>
                    </form>
                </div>
            </article>
            """
        }.joined()

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Chapitres</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page page-narrow">
                <section class="page-header">
                    <div>
                        <span class="eyebrow">Gestion des chapitres</span>
                        <h1>\(escapeHTML(histoire.titre))</h1>
                        <p class="muted">Ajoute, modifie et organise tes chapitres.</p>
                    </div>
                </section>

                <section class="section">
                    <article class="bloc-formulaire">
                        <h2>Ajouter un chapitre</h2>

                        <form action="/histoires/\(histoire.id ?? 0)/chapitres/ajouter" method="post">
                            <label>Titre du chapitre
                                <input type="text" name="titre" required>
                            </label>

                            <label>Contenu
                                <textarea name="contenu" rows="12" required></textarea>
                            </label>

                            <button type="submit" class="btn">Ajouter le chapitre</button>
                        </form>
                    </article>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Liste des chapitres</h2>
                    </div>
                    \(chapitres.isEmpty ? "<p class=\"muted\">Aucun chapitre pour le moment.</p>" : liste)
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func pageModificationChapitre(chapitre: Chapitre) -> HTML {
        HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Modifier un chapitre</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <header class="navbar">
                <div class="logo">StoryCraft</div>
                <nav class="nav-links">
                    <a href="/">Accueil</a>
                    <a href="/dashboard" class="btn btn-secondary">Dashboard</a>
                </nav>
            </header>

            <main class="page page-narrow">
                <section class="section">
                    <article class="bloc-formulaire">
                        <h1>Modifier un chapitre</h1>

                        <form action="/chapitres/\(chapitre.id ?? 0)/update" method="post">
                            <label>Numéro
                                <input type="number" name="numero" value="\(chapitre.numero)" min="1" required>
                            </label>

                            <label>Titre
                                <input type="text" name="titre" value="\(escapeHTMLAttribute(chapitre.titre))" required>
                            </label>

                            <label>Contenu
                                <textarea name="contenu" rows="14" required>\(escapeHTML(chapitre.contenu))</textarea>
                            </label>

                            <div class="actions">
                                <button type="submit" class="btn">Enregistrer</button>
                                <a href="/histoires/\(chapitre.histoireId)/chapitres" class="btn btn-secondary">Annuler</a>
                            </div>
                        </form>
                    </article>
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func pageErreur() -> HTML {
        HTML(content: """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Introuvable</title>
            <style>
                \(styleGlobal())
            </style>
        </head>
        <body>
            <main class="page page-narrow">
                <section class="section">
                    <article class="bloc-formulaire">
                        <h1>404</h1>
                        <p class="muted">La page demandée est introuvable.</p>
                        <a href="/" class="btn btn-secondary">Retour à l’accueil</a>
                    </article>
                </section>
            </main>
        </body>
        </html>
        """)
    }

    static func imageCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !propre.isEmpty else {
            return """
            <div class="cover-placeholder">
                Pas de couverture
            </div>
            """
        }

        return "<img src=\"\(escapeHTMLAttribute(propre))\" alt=\"Couverture\" class=\"cover-img\">"
    }

    static func imageGrandeCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !propre.isEmpty else {
            return """
            <div class="cover-placeholder-large">
                Pas de couverture
            </div>
            """
        }

        return "<img src=\"\(escapeHTMLAttribute(propre))\" alt=\"Couverture\" class=\"cover-img-large\">"
    }

    static func resumeCourt(_ texte: String) -> String {
        let texteSansRetours = texte.replacingOccurrences(of: "\n", with: " ")
        if texteSansRetours.count <= 180 {
            return escapeHTML(texteSansRetours)
        }
        let index = texteSansRetours.index(texteSansRetours.startIndex, offsetBy: 180)
        return escapeHTML(String(texteSansRetours[..<index]) + "…")
    }

    static func escapeHTML(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func escapeHTMLAvecRetours(_ texte: String) -> String {
        escapeHTML(texte).replacingOccurrences(of: "\n", with: "<br>")
    }

    static func escapeHTMLAttribute(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func styleGlobal() -> String {
        """
        :root {
            --bg: #111318;
            --panel: #171a21;
            --panel-2: #1d212b;
            --border: #2a3140;
            --text: #f4f4f3;
            --muted: #a5acb8;
            --accent: #8fbc8f;
            --accent-2: #6f9a6f;
            --danger: #ad5d5d;
            --shadow: rgba(0,0,0,0.22);
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            background:
                radial-gradient(circle at top left, rgba(143,188,143,0.08), transparent 28%),
                radial-gradient(circle at top right, rgba(90,110,140,0.10), transparent 24%),
                var(--bg);
            color: var(--text);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            line-height: 1.6;
        }

        a {
            color: inherit;
            text-decoration: none;
        }

        .navbar {
            position: sticky;
            top: 0;
            z-index: 20;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            padding: 1rem 1.5rem;
            background: rgba(17, 19, 24, 0.88);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--border);
        }

        .logo {
            font-size: 1.2rem;
            font-weight: 700;
            letter-spacing: 0.02em;
        }

        .nav-links {
            display: flex;
            align-items: center;
            gap: 0.8rem;
            flex-wrap: wrap;
        }

        .nav-links a:not(.btn) {
            color: var(--muted);
        }

        .nav-links a:not(.btn):hover {
            color: var(--text);
        }

        .page {
            max-width: 1120px;
            margin: 0 auto;
            padding: 2rem 1.25rem 4rem;
        }

        .page-narrow {
            max-width: 900px;
        }

        .hero {
            display: grid;
            grid-template-columns: 1.5fr 1fr;
            gap: 1.5rem;
            align-items: center;
            min-height: 58vh;
            padding: 2rem 0 3rem;
        }

        .hero-texte h1 {
            font-size: clamp(2.3rem, 5vw, 4.6rem);
            line-height: 1.03;
            margin: 0 0 1rem;
            letter-spacing: -0.03em;
        }

        .hero-desc {
            max-width: 640px;
            color: var(--muted);
            font-size: 1.05rem;
        }

        .hero-actions {
            display: flex;
            gap: 0.9rem;
            flex-wrap: wrap;
            margin-top: 1.4rem;
        }

        .hero-card,
        .bloc-formulaire,
        .carte-histoire,
        .chapitre-admin {
            background: rgba(23, 26, 33, 0.92);
            border: 1px solid var(--border);
            border-radius: 18px;
            box-shadow: 0 12px 30px var(--shadow);
        }

        .hero-card {
            padding: 1.4rem;
        }

        .hero-preview-title,
        .eyebrow {
            display: inline-block;
            color: var(--accent);
            font-size: 0.85rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            margin-bottom: 0.75rem;
        }

        .page-header h1,
        .section h2,
        .bloc-formulaire h1,
        .bloc-formulaire h2,
        .detail-meta h1 {
            margin-top: 0;
            line-height: 1.15;
        }

        .section {
            margin-bottom: 2.3rem;
        }

        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            margin-bottom: 1rem;
        }

        .section-link {
            color: var(--accent);
            font-size: 0.95rem;
        }

        .grid-cards {
            display: grid;
            gap: 1rem;
        }

        .carte-lien {
            display: block;
        }

        .carte-histoire {
            padding: 1rem;
            transition: transform 0.16s ease, border-color 0.16s ease;
        }

        .carte-histoire:hover {
            transform: translateY(-2px);
            border-color: #3c4658;
        }

        .carte-histoire,
        .detail-grid {
            display: grid;
            gap: 1rem;
        }

        .carte-histoire {
            grid-template-columns: 120px 1fr;
        }

        .carte-cover {
            width: 120px;
        }

        .carte-contenu h3 {
            margin: 0 0 0.5rem;
        }

        .carte-top {
            display: flex;
            justify-content: space-between;
            gap: 1rem;
            align-items: start;
            flex-wrap: wrap;
        }

        .detail-grid {
            grid-template-columns: 280px 1fr;
            align-items: start;
            margin-bottom: 2rem;
        }

        .detail-meta {
            background: rgba(23, 26, 33, 0.78);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 1.4rem;
        }

        .bloc-resume {
            margin: 1.25rem 0;
            padding: 1rem;
            border-radius: 14px;
            background: rgba(255,255,255,0.02);
            border: 1px solid rgba(255,255,255,0.04);
        }

        .meta-pills {
            display: flex;
            gap: 0.6rem;
            flex-wrap: wrap;
            margin: 1rem 0 1.25rem;
        }

        .meta-pill {
            padding: 0.45rem 0.75rem;
            border-radius: 999px;
            background: rgba(255,255,255,0.03);
            border: 1px solid var(--border);
            font-size: 0.9rem;
            color: var(--muted);
        }

        .liste-chapitres {
            display: grid;
            gap: 0.8rem;
        }

        .chapitre-ligne,
        .chapitre-admin {
            padding: 1rem 1.1rem;
        }

        .chapitre-ligne {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            background: rgba(23, 26, 33, 0.82);
            border: 1px solid var(--border);
            border-radius: 16px;
        }

        .chapitre-admin {
            display: flex;
            justify-content: space-between;
            gap: 1rem;
            align-items: start;
            margin-bottom: 1rem;
        }

        .cover-img,
        .preview-img {
            width: 120px;
            height: 170px;
            object-fit: cover;
            border-radius: 14px;
            border: 1px solid var(--border);
            display: block;
        }

        .cover-img-large {
            width: 100%;
            max-width: 280px;
            aspect-ratio: 2 / 3;
            object-fit: cover;
            border-radius: 20px;
            border: 1px solid var(--border);
            display: block;
            box-shadow: 0 18px 40px rgba(0,0,0,0.25);
        }

        .cover-placeholder,
        .cover-placeholder-large {
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            color: var(--muted);
            border: 1px dashed #3d475c;
            border-radius: 14px;
            background: rgba(255,255,255,0.02);
            padding: 0.75rem;
        }

        .cover-placeholder {
            width: 120px;
            height: 170px;
            font-size: 0.9rem;
        }

        .cover-placeholder-large {
            width: 100%;
            max-width: 280px;
            aspect-ratio: 2 / 3;
        }

        .bloc-formulaire {
            padding: 1.35rem;
        }

        form {
            display: grid;
            gap: 1rem;
        }

        label {
            display: grid;
            gap: 0.45rem;
            font-weight: 500;
            color: var(--text);
        }

        input,
        textarea,
        select {
            width: 100%;
            border-radius: 12px;
            border: 1px solid var(--border);
            background: rgba(255,255,255,0.02);
            color: var(--text);
            padding: 0.9rem 1rem;
            font: inherit;
            outline: none;
        }

        input:focus,
        textarea:focus,
        select:focus {
            border-color: var(--accent-2);
            box-shadow: 0 0 0 3px rgba(143,188,143,0.12);
        }

        textarea {
            min-height: 120px;
            resize: vertical;
        }

        .actions {
            display: flex;
            gap: 0.75rem;
            flex-wrap: wrap;
            align-items: center;
            margin-top: 1rem;
        }

        .btn,
        button {
            appearance: none;
            border: none;
            cursor: pointer;
            border-radius: 12px;
            padding: 0.8rem 1rem;
            font: inherit;
            font-weight: 600;
            transition: transform 0.12s ease, opacity 0.12s ease, background 0.12s ease;
        }

        .btn:hover,
        button:hover {
            transform: translateY(-1px);
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: var(--accent);
            color: #132013;
        }

        .btn-secondary {
            background: #232836;
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-danger {
            background: rgba(173,93,93,0.16);
            color: #f0c1c1;
            border: 1px solid rgba(173,93,93,0.4);
        }

        .badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            padding: 0.35rem 0.7rem;
            font-size: 0.82rem;
            font-weight: 600;
            border: 1px solid var(--border);
        }

        .badge-publie {
            background: rgba(143,188,143,0.12);
            color: #bfe1bf;
            border-color: rgba(143,188,143,0.35);
        }

        .badge-brouillon {
            background: rgba(135,149,175,0.12);
            color: #c7d1e0;
            border-color: rgba(135,149,175,0.35);
        }

        .muted {
            color: var(--muted);
        }

        .small {
            font-size: 0.9rem;
        }

        .preview-zone {
            margin-top: -0.25rem;
        }

        @media (max-width: 900px) {
            .hero,
            .detail-grid,
            .carte-histoire {
                grid-template-columns: 1fr;
            }

            .carte-cover {
                width: 100%;
            }

            .cover-img,
            .cover-placeholder {
                width: 140px;
            }
        }
        """
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