import Foundation
import Hummingbird

struct Views {
    static func layout(
        titre: String,
        utilisateur: Utilisateur?,
        contenu: String,
        masquerNavigation: Bool = false,
        classeBody: String = ""
    ) -> HTML {
        HTML(
            content: """
            <!DOCTYPE html>
            <html lang="fr">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>\(escapeHTML(titre))</title>
                <style>\(styleGlobal())</style>
            </head>
            <body class="\(escapeHTMLAttribute(classeBody))">
                \(!masquerNavigation ? """
                <header class="navbar">
                    <div class="logo"><a href="/">StoryCraft</a></div>
                    <nav class="nav-links">
                        \(utilisateur != nil ? """
                        <a href="/dashboard">Dashboard</a>
                        <a href="/histoires/publiees">Explorer</a>
                        <a href="/profil">Profil</a>
                        <form action="/logout" method="post" style="display:inline;">
                            <button type="submit" class="btn btn-secondary">Déconnexion</button>
                        </form>
                        """ : """
                        <a href="/login" class="btn btn-secondary">Connexion</a>
                        <a href="/register" class="btn">Inscription</a>
                        """)
                    </nav>
                </header>
                """ : "")

                <main class="page">
                    \(contenu)
                </main>
            </body>
            </html>
            """
        )
    }

    static func pageAuthAccueil(messageErreur: String? = nil) -> HTML {
        layout(
            titre: "Connexion",
            utilisateur: nil,
            contenu: """
            <section class="auth-minimal-shell">
                <article class="auth-minimal-card">
                    <div class="auth-minimal-header">
                        <div class="auth-minimal-logo">StoryCraft</div>
                        <span class="eyebrow">Connexion</span>
                        <h1>Bienvenue sur StoryCraft</h1>
                        <p class="muted">Connecte-toi pour accéder à ton espace d’écriture.</p>
                    </div>

                    \(messageErreur != nil ? "<p class=\"erreur\">\(escapeHTML(messageErreur!))</p>" : "")

                    <form action="/login" method="post">
                        <label>Email
                            <input type="email" name="email" required>
                        </label>

                        <label>Mot de passe
                            <input type="password" name="motDePasse" required>
                        </label>

                        <button type="submit" class="btn btn-auth">Se connecter</button>
                    </form>

                    <div class="auth-minimal-actions">
                        <a href="/register" class="btn btn-secondary btn-full">Créer un compte</a>
                        <a href="/histoires/publiees" class="auth-link-secondary">Continuer en lecture</a>
                    </div>
                </article>
            </section>
            """,
            masquerNavigation: true,
            classeBody: "body-auth"
        )
    }

    static func pageRegister(messageErreur: String? = nil) -> HTML {
        layout(
            titre: "Inscription",
            utilisateur: nil,
            contenu: """
            <section class="auth-minimal-shell">
                <article class="auth-minimal-card">
                    <div class="auth-minimal-header">
                        <div class="auth-minimal-logo">StoryCraft</div>
                        <span class="eyebrow">Inscription</span>
                        <h1>Créer un compte</h1>
                        <p class="muted">Rejoins StoryCraft et commence à écrire.</p>
                    </div>

                    \(messageErreur != nil ? "<p class=\"erreur\">\(escapeHTML(messageErreur!))</p>" : "")

                    <form action="/register" method="post">
                        <label>Pseudo
                            <input type="text" name="pseudo" required>
                        </label>

                        <label>Email
                            <input type="email" name="email" required>
                        </label>

                        <label>Mot de passe
                            <input type="password" name="motDePasse" required>
                        </label>

                        <button type="submit" class="btn btn-auth">Créer le compte</button>
                    </form>

                    <div class="auth-minimal-actions">
                        <a href="/login" class="btn btn-secondary btn-full">Déjà un compte ? Se connecter</a>
                        <a href="/histoires/publiees" class="auth-link-secondary">Continuer en lecture</a>
                    </div>
                </article>
            </section>
            """,
            masquerNavigation: true,
            classeBody: "body-auth"
        )
    }

    static func pageDashboard(
        utilisateur: Utilisateur,
        brouillons: [Histoire],
        publiees: [Histoire]
    ) -> HTML {
        layout(
            titre: "Dashboard",
            utilisateur: utilisateur,
            contenu: """
            <section class="page-header">
                <div>
                    <span class="eyebrow">Tableau de bord</span>
                    <h1>Bienvenue \(escapeHTML(utilisateur.pseudo))</h1>
                    <p class="muted">Gère ton profil, tes histoires et tes chapitres.</p>
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
                            <input type="text" name="couverture">
                        </label>
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
                <div class="section-header"><h2>Mes brouillons</h2></div>
                \(brouillons.isEmpty ? "<p class=\"muted\">Aucun brouillon.</p>" : renduCartes(histoires: brouillons))
            </section>

            <section class="section">
                <div class="section-header"><h2>Mes histoires publiées</h2></div>
                \(publiees.isEmpty ? "<p class=\"muted\">Aucune histoire publiée.</p>" : renduCartes(histoires: publiees))
            </section>
            """
        )
    }

    static func renduCartes(histoires: [Histoire]) -> String {
        histoires.map { histoire in
            """
            <article class="carte-histoire">
                <div class="carte-cover">\(imageCouvertureHTML(histoire.couverture))</div>
                <div class="carte-contenu">
                    <div class="carte-top">
                        <h3>\(escapeHTML(histoire.titre))</h3>
                        <span class="badge \(histoire.statut == "publie" ? "badge-publie" : "badge-brouillon")">
                            \(histoire.statut == "publie" ? "Publié" : "Brouillon")
                        </span>
                    </div>
                    <p><strong>Genre :</strong> \(escapeHTML(histoire.genre))</p>
                    <p><strong>Résumé :</strong> \(escapeHTML(histoire.resume))</p>
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

    static func pageProfil(utilisateur: Utilisateur) -> HTML {
        layout(
            titre: "Profil",
            utilisateur: utilisateur,
            contenu: """
            <section class="section form-centered-section">
                <article class="bloc-formulaire form-centered-card">
                    <h1>Mon profil</h1>
                    <form action="/profil/update" method="post">
                        <label>Pseudo unique
                            <input type="text" name="pseudo" value="\(escapeHTMLAttribute(utilisateur.pseudo))" required>
                        </label>
                        <label>Bio
                            <textarea name="bio">\(escapeHTML(utilisateur.bio))</textarea>
                        </label>
                        <label>URL avatar
                            <input type="text" name="avatarURL" value="\(escapeHTMLAttribute(utilisateur.avatarURL))">
                        </label>
                        <button type="submit" class="btn">Mettre à jour le profil</button>
                    </form>
                </article>
            </section>
            """
        )
    }

    static func pageHistoiresPubliees(histoires: [HistoirePublique], utilisateur: Utilisateur?) -> HTML {
        let cartes = histoires.map { histoire in
            """
            <a href="/histoires/\(histoire.id)" class="carte-lien">
                <article class="carte-histoire">
                    <div class="carte-cover">\(imageCouvertureHTML(histoire.couverture))</div>
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

        return layout(
            titre: "Histoires publiées",
            utilisateur: utilisateur,
            contenu: """
            <section class="page-header">
                <div>
                    <span class="eyebrow">Explorer</span>
                    <h1>Histoires publiées</h1>
                </div>
            </section>

            <section class="section">
                \(histoires.isEmpty ? "<p class=\"muted\">Aucune histoire publiée.</p>" : cartes)
            </section>
            """
        )
    }

    static func pageDetailHistoire(
        histoire: Histoire,
        auteur: Utilisateur,
        chapitres: [ChapitreAvecStats],
        commentaires: [CommentaireAffichage],
        utilisateur: Utilisateur?
    ) -> HTML {
        let listeChapitres = chapitres.map { item in
            let maNoteTexte = item.maNote != nil ? " • Ta note : \(item.maNote!)/5" : ""
            return """
            <article class="chapitre-admin">
                <div>
                    <h3>Chapitre \(item.chapitre.numero) — \(escapeHTML(item.chapitre.titre))</h3>
                    <p class="muted small">Mise à jour : \(escapeHTML(item.chapitre.dateModification))</p>
                    <p class="muted small">Moyenne : \(String(format: "%.1f", item.moyenne))/5 • \(item.nombreNotes) note(s)\(maNoteTexte)</p>
                    <p>\(resumeCourt(item.chapitre.contenu))</p>
                </div>

                <div class="actions">
                    \(utilisateur != nil ? """
                    <form action="/chapitres/\(item.chapitre.id ?? 0)/noter" method="post">
                        <select name="note">
                            <option value="1">1/5</option>
                            <option value="2">2/5</option>
                            <option value="3">3/5</option>
                            <option value="4">4/5</option>
                            <option value="5">5/5</option>
                        </select>
                        <button type="submit" class="btn btn-secondary">Noter</button>
                    </form>
                    """ : "<p class=\"muted\">Connecte-toi pour noter</p>")
                </div>
            </article>
            """
        }.joined()

        let blocCommentaires = commentaires.map { commentaire in
            """
            <article class="commentaire">
                <p><strong>\(escapeHTML(commentaire.pseudoUtilisateur))</strong></p>
                <p class="muted small">\(escapeHTML(commentaire.dateCreation))</p>
                <p>\(escapeHTMLAvecRetours(commentaire.contenu))</p>
            </article>
            """
        }.joined()

        return layout(
            titre: histoire.titre,
            utilisateur: utilisateur,
            contenu: """
            <section class="detail-grid">
                <div>\(imageGrandeCouvertureHTML(histoire.couverture))</div>
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
                </div>
            </section>

            <section class="section">
                <div class="section-header"><h2>Chapitres</h2></div>
                \(chapitres.isEmpty ? "<p class=\"muted\">Aucun chapitre.</p>" : listeChapitres)
            </section>

            <section class="section">
                <div class="section-header"><h2>Canal de discussion</h2></div>
                \(utilisateur != nil ? """
                <article class="bloc-formulaire">
                    <form action="/histoires/\(histoire.id ?? 0)/commentaires/ajouter" method="post">
                        <label>Ton message
                            <textarea name="contenu" required></textarea>
                        </label>
                        <button type="submit" class="btn">Publier</button>
                    </form>
                </article>
                """ : "<p class=\"muted\">Connecte-toi pour participer au canal de discussion.</p>")
                <div class="liste-chapitres">
                    \(commentaires.isEmpty ? "<p class=\"muted\">Aucun message pour le moment.</p>" : blocCommentaires)
                </div>
            </section>
            """
        )
    }

    static func pageGestionChapitres(
        histoire: Histoire,
        chapitres: [Chapitre],
        utilisateur: Utilisateur
    ) -> HTML {
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

        return layout(
            titre: "Gestion des chapitres",
            utilisateur: utilisateur,
            contenu: """
            <section class="page-header">
                <div>
                    <span class="eyebrow">Gestion des chapitres</span>
                    <h1>\(escapeHTML(histoire.titre))</h1>
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
                <div class="section-header"><h2>Liste des chapitres</h2></div>
                \(chapitres.isEmpty ? "<p class=\"muted\">Aucun chapitre.</p>" : liste)
            </section>
            """
        )
    }

    static func pageModificationHistoire(histoire: Histoire, utilisateur: Utilisateur) -> HTML {
        layout(
            titre: "Modifier l’histoire",
            utilisateur: utilisateur,
            contenu: """
            <section class="section form-centered-section">
                <article class="bloc-formulaire form-centered-card">
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
                            <input type="text" name="couverture" value="\(escapeHTMLAttribute(histoire.couverture))">
                        </label>
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
            """
        )
    }

    static func pageModificationChapitre(chapitre: Chapitre, utilisateur: Utilisateur) -> HTML {
        layout(
            titre: "Modifier un chapitre",
            utilisateur: utilisateur,
            contenu: """
            <section class="section form-centered-section">
                <article class="bloc-formulaire form-centered-card">
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
            """
        )
    }

    static func pageErreur(
        message: String = "La page demandée est introuvable.",
        utilisateur: Utilisateur? = nil
    ) -> HTML {
        layout(
            titre: "Erreur",
            utilisateur: utilisateur,
            contenu: """
            <section class="section form-centered-section">
                <article class="bloc-formulaire form-centered-card">
                    <h1>Erreur</h1>
                    <p class="muted">\(escapeHTML(message))</p>
                    <a href="/" class="btn btn-secondary">Retour à l’accueil</a>
                </article>
            </section>
            """
        )
    }

    static func imageCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !propre.isEmpty else {
            return "<div class=\"cover-placeholder\">Pas de couverture</div>"
        }
        return "<img src=\"\(escapeHTMLAttribute(propre))\" alt=\"Couverture\" class=\"cover-img\">"
    }

    static func imageGrandeCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !propre.isEmpty else {
            return "<div class=\"cover-placeholder-large\">Pas de couverture</div>"
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
        escapeHTML(texte)
    }

    static func styleGlobal() -> String {
        """
        :root {
            --bg: #0b0f17;
            --bg-soft: #121826;
            --panel: rgba(19, 24, 36, 0.86);
            --panel-strong: rgba(15, 19, 29, 0.96);
            --border: #253049;
            --border-soft: rgba(255,255,255,0.08);
            --text: #f6f7fb;
            --muted: #aab2c5;
            --accent: #b5d8ae;
            --accent-2: #7ba873;
            --accent-3: #6d8eff;
            --danger: #ad5d5d;
            --shadow: rgba(0, 0, 0, 0.34);
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            min-height: 100vh;
            background:
                radial-gradient(circle at top left, rgba(109, 142, 255, 0.10), transparent 22%),
                radial-gradient(circle at bottom right, rgba(181, 216, 174, 0.08), transparent 24%),
                var(--bg);
            color: var(--text);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            line-height: 1.6;
        }

        .body-auth {
            background:
                radial-gradient(circle at top left, rgba(109, 142, 255, 0.16), transparent 24%),
                radial-gradient(circle at bottom left, rgba(181, 216, 174, 0.10), transparent 24%),
                linear-gradient(135deg, #0a0e16 0%, #101728 50%, #0a0f18 100%);
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
            padding: 1.1rem 2rem;
            background: rgba(11, 15, 23, 0.76);
            backdrop-filter: blur(14px);
            border-bottom: 1px solid var(--border-soft);
        }

        .logo {
            font-size: 1.35rem;
            font-weight: 800;
            letter-spacing: 0.02em;
        }

        .nav-links {
            display: flex;
            align-items: center;
            gap: 0.9rem;
            flex-wrap: wrap;
        }

        .nav-links a:not(.btn) {
            color: var(--muted);
            font-size: 1rem;
        }

        .nav-links a:not(.btn):hover {
            color: var(--text);
        }

        .page {
            width: min(1520px, 100%);
            margin: 0 auto;
            padding: 1.25rem;
        }

        .page-narrow {
            width: min(950px, 100%);
        }

        .auth-minimal-shell {
            min-height: calc(100vh - 2.5rem);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
        }

        .auth-minimal-card {
            width: min(520px, 100%);
            background: var(--panel-strong);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 28px;
            box-shadow: 0 26px 65px rgba(0, 0, 0, 0.35);
            padding: 2rem;
        }

        .auth-minimal-header {
            margin-bottom: 1.5rem;
        }

        .auth-minimal-logo {
            font-size: 1.5rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            margin-bottom: 1rem;
        }

        .auth-minimal-header h1 {
            margin: 0 0 0.55rem;
            font-size: clamp(2rem, 4vw, 2.8rem);
            line-height: 1.06;
        }

        .auth-minimal-header p {
            margin: 0;
            font-size: 1rem;
        }

        .auth-minimal-actions {
            display: grid;
            gap: 0.9rem;
            margin-top: 1.2rem;
        }

        .auth-link-secondary {
            display: inline-flex;
            justify-content: center;
            align-items: center;
            color: var(--muted);
            font-size: 0.98rem;
            font-weight: 600;
            padding: 0.25rem 0;
        }

        .auth-link-secondary:hover {
            color: var(--text);
        }

        .eyebrow {
            display: inline-block;
            color: var(--accent);
            font-size: 0.86rem;
            font-weight: 800;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            margin-bottom: 1rem;
        }

        .btn-full {
            width: 100%;
        }

        .btn-auth {
            width: 100%;
            min-height: 56px;
            font-size: 1rem;
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-header h1,
        .section h2,
        .bloc-formulaire h1,
        .bloc-formulaire h2,
        .detail-meta h1 {
            margin-top: 0;
            margin-bottom: 0.7rem;
            line-height: 1.12;
        }

        .page-header h1,
        .detail-meta h1,
        .bloc-formulaire h1 {
            font-size: clamp(2rem, 4vw, 3rem);
        }

        .section {
            margin-bottom: 3rem;
        }

        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            margin-bottom: 1.3rem;
        }

        .section-header h2 {
            font-size: 1.9rem;
        }

        .section-link {
            color: var(--accent);
            font-size: 1rem;
            font-weight: 600;
        }

        .hero-card,
        .bloc-formulaire,
        .carte-histoire,
        .chapitre-admin,
        .commentaire,
        .detail-meta {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 22px;
            box-shadow: 0 18px 50px var(--shadow);
        }

        .grid-cards,
        .liste-chapitres {
            display: grid;
            gap: 1.2rem;
        }

        .carte-lien {
            display: block;
        }

        .carte-histoire {
            display: grid;
            grid-template-columns: 170px 1fr;
            gap: 1.25rem;
            padding: 1.25rem;
            transition: transform 0.15s ease, border-color 0.15s ease;
        }

        .carte-histoire:hover {
            transform: translateY(-2px);
            border-color: #415068;
        }

        .carte-cover {
            width: 170px;
        }

        .carte-contenu h3 {
            margin: 0 0 0.65rem;
            font-size: 1.45rem;
            line-height: 1.2;
        }

        .carte-contenu p {
            font-size: 1.02rem;
            margin: 0.45rem 0;
        }

        .carte-top {
            display: flex;
            justify-content: space-between;
            gap: 1rem;
            align-items: flex-start;
            flex-wrap: wrap;
        }

        .detail-grid {
            display: grid;
            grid-template-columns: 340px minmax(0, 1fr);
            align-items: start;
            gap: 2rem;
            margin-bottom: 2.5rem;
        }

        .detail-meta {
            padding: 1.7rem;
        }

        .bloc-resume {
            margin: 1.4rem 0;
            padding: 1.1rem 1.2rem;
            border-radius: 16px;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .bloc-resume p {
            font-size: 1.05rem;
        }

        .meta-pills {
            display: flex;
            gap: 0.75rem;
            flex-wrap: wrap;
            margin: 1rem 0 1.4rem;
        }

        .meta-pill {
            padding: 0.55rem 0.9rem;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border);
            font-size: 0.95rem;
            color: var(--muted);
        }

        .chapitre-admin,
        .commentaire {
            padding: 1.2rem 1.25rem;
        }

        .chapitre-admin {
            display: flex;
            justify-content: space-between;
            gap: 1rem;
            align-items: flex-start;
        }

        .chapitre-admin h3 {
            margin: 0 0 0.6rem;
            font-size: 1.25rem;
        }

        .chapitre-admin p {
            font-size: 1rem;
        }

        .cover-img,
        .cover-placeholder {
            width: 170px;
            height: 240px;
            object-fit: cover;
            border-radius: 16px;
            border: 1px solid var(--border);
            display: block;
        }

        .cover-img-large,
        .cover-placeholder-large {
            width: 100%;
            max-width: 340px;
            aspect-ratio: 2 / 3;
            object-fit: cover;
            border-radius: 24px;
            border: 1px solid var(--border);
            display: block;
            box-shadow: 0 22px 55px rgba(0, 0, 0, 0.3);
        }

        .cover-placeholder,
        .cover-placeholder-large {
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            color: var(--muted);
            border-style: dashed;
            background: rgba(255, 255, 255, 0.02);
            padding: 0.8rem;
            font-size: 1rem;
        }

        .bloc-formulaire {
            padding: 1.6rem;
        }

        .bloc-formulaire p,
        .commentaire p {
            font-size: 1rem;
        }

        form {
            display: grid;
            gap: 1.1rem;
        }

        label {
            display: grid;
            gap: 0.45rem;
            font-weight: 600;
            color: var(--text);
            font-size: 1rem;
        }

        input,
        textarea,
        select {
            width: 100%;
            border-radius: 14px;
            border: 1px solid var(--border);
            background: rgba(255, 255, 255, 0.03);
            color: var(--text);
            padding: 1rem 1rem;
            font: inherit;
            font-size: 1rem;
            outline: none;
        }

        input:focus,
        textarea:focus,
        select:focus {
            border-color: var(--accent-2);
            box-shadow: 0 0 0 3px rgba(166, 201, 174, 0.12);
        }

        textarea {
            min-height: 140px;
            resize: vertical;
        }

        .actions {
            display: flex;
            gap: 0.8rem;
            flex-wrap: wrap;
            align-items: center;
            margin-top: 1rem;
        }

        .btn,
        button {
            appearance: none;
            border: none;
            cursor: pointer;
            border-radius: 14px;
            padding: 0.95rem 1.2rem;
            font: inherit;
            font-weight: 700;
            font-size: 1rem;
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
            background: #232b39;
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-danger {
            background: rgba(173, 93, 93, 0.16);
            color: #f0c1c1;
            border: 1px solid rgba(173, 93, 93, 0.4);
        }

        .badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            padding: 0.45rem 0.8rem;
            font-size: 0.88rem;
            font-weight: 700;
            border: 1px solid var(--border);
        }

        .badge-publie {
            background: rgba(166, 201, 161, 0.12);
            color: #c8e7c4;
            border-color: rgba(166, 201, 161, 0.35);
        }

        .badge-brouillon {
            background: rgba(135, 149, 175, 0.12);
            color: #c7d1e0;
            border-color: rgba(135, 149, 175, 0.35);
        }

        .muted {
            color: var(--muted);
        }

        .small {
            font-size: 0.94rem;
        }

        .erreur {
            color: #ffb4b4;
            background: rgba(173, 93, 93, 0.12);
            border: 1px solid rgba(173, 93, 93, 0.35);
            padding: 1rem;
            border-radius: 14px;
            font-size: 1rem;
            margin-bottom: 1rem;
        }

        .form-centered-section {
            min-height: calc(100vh - 170px);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .form-centered-card {
            width: min(720px, 100%);
        }

        @media (max-width: 1200px) {
            .detail-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 800px) {
            .navbar {
                padding: 1rem 1.1rem;
            }

            .page {
                padding: 0.75rem;
            }

            .auth-minimal-shell {
                padding: 1rem 0.25rem;
                min-height: auto;
            }

            .auth-minimal-card {
                padding: 1.35rem;
                border-radius: 24px;
            }

            .carte-histoire,
            .chapitre-admin {
                grid-template-columns: 1fr;
                display: grid;
            }

            .carte-cover {
                width: 100%;
            }

            .cover-img,
            .cover-placeholder {
                width: 150px;
                height: 210px;
            }

            .section-header h2 {
                font-size: 1.5rem;
            }

            .form-centered-section {
                min-height: auto;
                align-items: flex-start;
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