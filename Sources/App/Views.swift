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
                    <div class="logo">
                        <a href="\(utilisateur != nil ? "/dashboard" : "/")">StoryCraft</a>
                    </div>

                    <nav class="nav-links">
                        \(utilisateur != nil ? """
                        <a href="/dashboard">Dashboard</a>
                        <a href="/histoires/publiees">Explorer</a>
                        <a href="/profil">Profil</a>
                        <form action="/logout" method="post" class="inline-form">
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

                    <script>\(scriptGlobal())</script>
                </body>
                </html>
                """
        )
    }

    // MARK: - AUTH

    static func pageAuthAccueil(messageErreur: String? = nil) -> HTML {
        layout(
            titre: "Connexion",
            utilisateur: nil,
            contenu: """
                <section class="auth-shell">
                    <article class="auth-card">
                        <div class="auth-header">
                            <div class="auth-logo">StoryCraft</div>
                            <span class="eyebrow">Connexion</span>
                            <h1>Bienvenue sur StoryCraft</h1>
                            <p class="muted">Connecte-toi pour retrouver ton espace d’écriture.</p>
                        </div>

                        \(messageErreur.map { "<p class=\"erreur\">\(escapeHTML($0))</p>" } ?? "")

                        <form action="/login" method="post">
                            <label>Email
                                <input type="email" name="email" required>
                            </label>

                            <label>Mot de passe
                                <input type="password" name="motDePasse" required>
                            </label>

                            <button type="submit" class="btn btn-auth">Se connecter</button>
                        </form>

                        <div class="auth-actions">
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
                <section class="auth-shell">
                    <article class="auth-card">
                        <div class="auth-header">
                            <div class="auth-logo">StoryCraft</div>
                            <span class="eyebrow">Inscription</span>
                            <h1>Créer un compte</h1>
                            <p class="muted">Commence à publier tes histoires et gérer tes chapitres.</p>
                        </div>

                        \(messageErreur.map { "<p class=\"erreur\">\(escapeHTML($0))</p>" } ?? "")

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

                        <div class="auth-actions">
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

    // MARK: - DASHBOARD

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
                        <p class="muted">Crée, modifie et publie tes histoires.</p>
                    </div>
                </section>

                <section class="section">
                    <article class="bloc-formulaire bloc-formulaire-large">
                        <h2>Créer une histoire</h2>
                        <form action="/histoires/ajouter" method="post">
                            <label>Titre
                                <input type="text" name="titre" required>
                            </label>

                            <label>Genre
                                <input type="text" name="genre" required>
                            </label>

                            <label>Résumé
                                <textarea name="resume" rows="6" required></textarea>
                            </label>

                            \(champCouverture(valeurInitiale: "", suffixe: "create"))

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
                    \(brouillons.isEmpty
                    ? "<p class=\"muted\">Aucun brouillon pour le moment.</p>"
                    : renduCartes(histoires: brouillons))
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Mes histoires publiées</h2>
                    </div>
                    \(publiees.isEmpty
                    ? "<p class=\"muted\">Aucune histoire publiée pour le moment.</p>"
                    : renduCartes(histoires: publiees))
                </section>
                """
        )
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

                    <div class="actions">
                        <a href="/histoires/\(histoire.id ?? 0)" class="btn btn-secondary">Voir</a>
                        <a href="/histoires/\(histoire.id ?? 0)/modifier" class="btn btn-secondary">Modifier</a>
                        <a href="/histoires/\(histoire.id ?? 0)/chapitres" class="btn btn-secondary">Chapitres</a>

                        <form action="/histoires/\(histoire.id ?? 0)/supprimer" method="post" class="inline-form">
                            <button type="submit" class="btn btn-danger">Supprimer</button>
                        </form>
                    </div>
                </div>
            </article>
            """
        }.joined()
    }

    // MARK: - PROFIL

    static func pageProfil(utilisateur: Utilisateur) -> HTML {
        layout(
            titre: "Profil",
            utilisateur: utilisateur,
            contenu: """
                <section class="section form-centered-section">
                    <article class="bloc-formulaire form-centered-card">
                        <h1>Mon profil</h1>
                        \(imageAvatarHTML(utilisateur.avatarURL))

                        <form action="/profil/update" method="post">
                            <label>Pseudo
                                <input
                                    type="text"
                                    name="pseudo"
                                    value="\(escapeHTMLAttribute(utilisateur.pseudo))"
                                    required
                                >
                            </label>

                            <label>Bio
                                <textarea name="bio" rows="7">\(escapeHTML(utilisateur.bio))</textarea>
                            </label>

                            <label>URL avatar
                                <input
                                    type="text"
                                    name="avatarURL"
                                    value="\(escapeHTMLAttribute(utilisateur.avatarURL))"
                                    placeholder="https://..."
                                >
                            </label>

                            <button type="submit" class="btn">Mettre à jour le profil</button>
                        </form>
                    </article>
                </section>
                """
        )
    }

    // MARK: - EXPLORER

    static func pageHistoiresPubliees(histoires: [HistoirePublique], utilisateur: Utilisateur?)
        -> HTML
    {
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

        return layout(
            titre: "Histoires publiées",
            utilisateur: utilisateur,
            contenu: """
                <section class="page-header">
                    <div>
                        <span class="eyebrow">Explorer</span>
                        <h1>Histoires publiées</h1>
                        <p class="muted">Découvre les histoires accessibles à la lecture.</p>
                    </div>
                </section>

                <section class="section">
                    \(histoires.isEmpty
                    ? "<p class=\"muted\">Aucune histoire publiée pour le moment.</p>"
                    : cartes)
                </section>
                """
        )
    }

    // MARK: - DETAIL HISTOIRE

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
                <article class="chapitre-admin chapitre-card-hover">
                    <div class="chapitre-contenu">
                        <h3>
                            <a href="/chapitres/\(item.chapitre.id ?? 0)" class="chapitre-lien-titre">
                                Chapitre \(item.chapitre.numero) — \(escapeHTML(item.chapitre.titre))
                            </a>
                        </h3>
                        <p class="muted small">Mise à jour : \(escapeHTML(item.chapitre.dateModification))</p>
                        <p class="muted small">
                            Moyenne : \(String(format: "%.1f", item.moyenne))/5 • \(item.nombreNotes) note(s)\(maNoteTexte)
                        </p>
                        <p>\(resumeCourt(item.chapitre.contenu))</p>

                        <div class="mini-read-row">
                            <a href="/chapitres/\(item.chapitre.id ?? 0)" class="mini-read-link">Lire ce chapitre</a>
                        </div>
                    </div>

                    <div class="actions">
                        \(utilisateur != nil ? """
                    <form action="/chapitres/\(item.chapitre.id ?? 0)/noter" method="post" class="note-form">
                        <select name="note" required>
                            <option value="">Noter</option>
                            <option value="1">1/5</option>
                            <option value="2">2/5</option>
                            <option value="3">3/5</option>
                            <option value="4">4/5</option>
                            <option value="5">5/5</option>
                        </select>
                        <button type="submit" class="btn btn-secondary">Valider</button>
                    </form>
                    """ : """
                    <p class="muted">Connecte-toi pour noter</p>
                    """)
                    </div>
                </article>
                """
        }.joined()

        let blocCommentaires = commentaires.map { commentaire in
            """
            <article class="commentaire">
                <div class="commentaire-top">
                    <p><strong>\(escapeHTML(commentaire.pseudoUtilisateur))</strong></p>
                    <p class="muted small">\(escapeHTML(commentaire.dateCreation))</p>
                </div>
                <p>\(escapeHTMLAvecRetours(commentaire.contenu))</p>
            </article>
            """
        }.joined()

        return layout(
            titre: histoire.titre,
            utilisateur: utilisateur,
            contenu: """
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
                    </div>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Chapitres</h2>
                    </div>

                    \(chapitres.isEmpty
                    ? "<p class=\"muted\">Aucun chapitre pour le moment.</p>"
                    : listeChapitres)
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Canal de discussion</h2>
                    </div>

                    \(utilisateur != nil ? """
                <article class="bloc-formulaire">
                    <form action="/histoires/\(histoire.id ?? 0)/commentaires/ajouter" method="post">
                        <label>Ton message
                            <textarea name="contenu" rows="5" required></textarea>
                        </label>
                        <button type="submit" class="btn">Publier</button>
                    </form>
                </article>
                """ : """
                <p class="muted">Connecte-toi pour participer au canal de discussion.</p>
                """)

                    <div class="liste-chapitres">
                        \(commentaires.isEmpty
                        ? "<p class=\"muted\">Aucun message pour le moment.</p>"
                        : blocCommentaires)
                    </div>
                </section>
                """
        )
    }

    // MARK: - LECTURE CHAPITRE

    static func pageLectureChapitre(
        histoire: Histoire,
        auteur: Utilisateur,
        chapitre: Chapitre,
        chapitrePrecedent: Chapitre?,
        chapitreSuivant: Chapitre?,
        utilisateur: Utilisateur?
    ) -> HTML {
        let prevURL = chapitrePrecedent != nil ? "/chapitres/\(chapitrePrecedent!.id ?? 0)" : ""
        let nextURL = chapitreSuivant != nil ? "/chapitres/\(chapitreSuivant!.id ?? 0)" : ""

        return layout(
            titre: "\(histoire.titre) - \(chapitre.titre)",
            utilisateur: utilisateur,
            contenu: """
                <section
                    class="lecture-shell"
                    data-prev-url="\(escapeHTMLAttribute(prevURL))"
                    data-next-url="\(escapeHTMLAttribute(nextURL))"
                >
                    <article class="lecture-header">
                        <p class="eyebrow">Lecture</p>
                        <h1>\(escapeHTML(chapitre.titre))</h1>
                        <p class="muted">
                            \(escapeHTML(histoire.titre)) • Chapitre \(chapitre.numero) • par \(escapeHTML(auteur.pseudo))
                        </p>
                    </article>

                    <article class="lecture-content" id="lecture-content">
                        \(formatteTexteLecture(chapitre.contenu))
                    </article>

                    <nav class="lecture-navigation">
                        <div>
                            \(chapitrePrecedent != nil
                            ? "<a class=\"btn btn-secondary\" href=\"/chapitres/\(chapitrePrecedent!.id ?? 0)\">← Chapitre précédent</a>"
                            : "")
                        </div>

                        <div class="lecture-actions-centre">
                            <a class="btn btn-secondary" href="/histoires/\(histoire.id ?? 0)">Retour à l’histoire</a>
                        </div>

                        <div>
                            \(chapitreSuivant != nil
                            ? "<a class=\"btn\" href=\"/chapitres/\(chapitreSuivant!.id ?? 0)\">Chapitre suivant →</a>"
                            : "")
                        </div>
                    </nav>

                    <p class="muted small lecture-hint">
                        Sur mobile, vous pouvez aussi swiper à gauche ou à droite pour changer de chapitre.
                    </p>
                </section>
                """
        )
    }

    static func formatteTexteLecture(_ texte: String) -> String {
        let lignes = texte.components(separatedBy: "\n")

        return lignes.map { ligne in
            let propre = ligne.trimmingCharacters(in: .whitespacesAndNewlines)

            if propre.isEmpty {
                return "<p class=\"lecture-space\"></p>"
            }

            return "<p>\(escapeHTML(propre))</p>"
        }.joined()
    }

    // MARK: - CHAPITRES

    static func pageGestionChapitres(
        histoire: Histoire,
        chapitres: [Chapitre],
        utilisateur: Utilisateur
    ) -> HTML {
        let liste = chapitres.map { chapitre in
            """
            <article class="chapitre-admin">
                <div class="chapitre-contenu">
                    <h3>Chapitre \(chapitre.numero) — \(escapeHTML(chapitre.titre))</h3>
                    <p class="muted small">Dernière modification : \(escapeHTML(chapitre.dateModification))</p>
                    <p>\(resumeCourt(chapitre.contenu))</p>
                    <div class="mini-read-row">
                        <a href="/chapitres/\(chapitre.id ?? 0)" class="mini-read-link">Prévisualiser en lecture</a>
                    </div>
                </div>

                <div class="actions">
                    <a href="/chapitres/\(chapitre.id ?? 0)/modifier" class="btn btn-secondary">Modifier</a>

                    <form action="/chapitres/\(chapitre.id ?? 0)/supprimer" method="post" class="inline-form">
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
                                <textarea name="contenu" rows="14" required></textarea>
                            </label>

                            <button type="submit" class="btn">Ajouter le chapitre</button>
                        </form>
                    </article>
                </section>

                <section class="section">
                    <div class="section-header">
                        <h2>Liste des chapitres</h2>
                    </div>

                    \(chapitres.isEmpty
                    ? "<p class=\"muted\">Aucun chapitre pour le moment.</p>"
                    : liste)
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
                                <input
                                    type="text"
                                    name="titre"
                                    value="\(escapeHTMLAttribute(histoire.titre))"
                                    required
                                >
                            </label>

                            <label>Genre
                                <input
                                    type="text"
                                    name="genre"
                                    value="\(escapeHTMLAttribute(histoire.genre))"
                                    required
                                >
                            </label>

                            <label>Résumé
                                <textarea name="resume" rows="7" required>\(escapeHTML(histoire.resume))</textarea>
                            </label>

                            \(champCouverture(valeurInitiale: histoire.couverture, suffixe: "edit-\(histoire.id ?? 0)"))

                            <label>Statut
                                <select name="statut" required>
                                    <option value="brouillon" \(histoire.statut == "brouillon" ? "selected" : "")>
                                        Brouillon
                                    </option>
                                    <option value="publie" \(histoire.statut == "publie" ? "selected" : "")>
                                        Publié
                                    </option>
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
            titre: "Modifier le chapitre",
            utilisateur: utilisateur,
            contenu: """
                <section class="section form-centered-section">
                    <article class="bloc-formulaire form-centered-card">
                        <h1>Modifier le chapitre</h1>

                        <form action="/chapitres/\(chapitre.id ?? 0)/update" method="post">
                            <label>Numéro
                                <input
                                    type="number"
                                    name="numero"
                                    value="\(chapitre.numero)"
                                    min="1"
                                    required
                                >
                            </label>

                            <label>Titre
                                <input
                                    type="text"
                                    name="titre"
                                    value="\(escapeHTMLAttribute(chapitre.titre))"
                                    required
                                >
                            </label>

                            <label>Contenu
                                <textarea name="contenu" rows="18" required>\(escapeHTML(chapitre.contenu))</textarea>
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

    // MARK: - ERREUR

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

    // MARK: - HELPERS HTML

    static func champCouverture(valeurInitiale: String, suffixe: String) -> String {
        let valeur = valeurInitiale.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview =
            valeur.isEmpty
            ? "<div class=\"cover-placeholder cover-preview-box\">Aperçu de la couverture</div>"
            : "<img src=\"\(escapeHTMLAttribute(valeur))\" alt=\"Aperçu\" class=\"cover-preview-img\">"

        return """
            <div class="cover-uploader">
                <label>Couverture</label>
                <input type="hidden" name="couverture" id="couverture-hidden-\(escapeHTMLAttribute(suffixe))" value="\(escapeHTMLAttribute(valeur))">

                <div class="cover-upload-grid">
                    <div id="cover-preview-\(escapeHTMLAttribute(suffixe))" class="cover-preview-zone">
                        \(preview)
                    </div>

                    <div class="cover-upload-controls">
                        <label>URL de l’image
                            <input
                                type="text"
                                id="couverture-url-\(escapeHTMLAttribute(suffixe))"
                                value="\(escapeHTMLAttribute(valeur))"
                                placeholder="https://... ou laisse vide si tu importes un fichier"
                                oninput="storycraftSyncCoverFromUrl('\(escapeHTMLAttribute(suffixe))')"
                            >
                        </label>

                        <label class="btn btn-secondary file-btn">
                            Importer une image
                            <input
                                type="file"
                                accept="image/*"
                                onchange="storycraftImportCover(event, '\(escapeHTMLAttribute(suffixe))')"
                            >
                        </label>

                        <button type="button" class="btn btn-secondary" onclick="storycraftClearCover('\(escapeHTMLAttribute(suffixe))')">
                            Retirer la couverture
                        </button>

                        <p class="muted small">
                                vous pouvez coller une URL ou choisir une image depuis ton appareil. L’image est compressée dans le navigateur pour éviter de casser le projet.
                        </p>
                    </div>
                </div>
            </div>
            """
    }

    static func imageCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !propre.isEmpty else {
            return "<div class=\"cover-placeholder\">Pas de couverture</div>"
        }

        return """
            <img
                src="\(escapeHTMLAttribute(propre))"
                alt="Couverture"
                class="cover-img"
                loading="lazy"
            >
            """
    }

    static func imageGrandeCouvertureHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !propre.isEmpty else {
            return "<div class=\"cover-placeholder-large\">Pas de couverture</div>"
        }

        return """
            <img
                src="\(escapeHTMLAttribute(propre))"
                alt="Couverture"
                class="cover-img-large"
                loading="lazy"
            >
            """
    }

    static func imageAvatarHTML(_ url: String) -> String {
        let propre = url.trimmingCharacters(in: .whitespacesAndNewlines)

        if propre.isEmpty {
            return """
                <div style="width:80px; height:80px; border-radius:50%; display:flex; align-items:center; justify-content:center; margin-bottom:15px; background:rgba(255,255,255,0.04); border:1px solid var(--border); font-size:1.5rem;">
                    👤
                </div>
                """
        }

        return """
            <img
                src="\(escapeHTMLAttribute(propre))"
                alt="Avatar"
                style="width:80px; height:80px; border-radius:50%; object-fit:cover; margin-bottom:15px; border:1px solid var(--border);"
            >
            """
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

    static func scriptGlobal() -> String {
        """
        function storycraftGetCoverElements(suffix) {
            return {
                hidden: document.getElementById("couverture-hidden-" + suffix),
                url: document.getElementById("couverture-url-" + suffix),
                preview: document.getElementById("cover-preview-" + suffix)
            };
        }

        function storycraftRenderPreview(previewEl, value) {
            if (!previewEl) return;

            previewEl.innerHTML = "";

            if (!value || !value.trim()) {
                const placeholder = document.createElement("div");
                placeholder.className = "cover-placeholder cover-preview-box";
                placeholder.textContent = "Aperçu de la couverture";
                previewEl.appendChild(placeholder);
                return;
            }

            const img = document.createElement("img");
            img.className = "cover-preview-img";
            img.alt = "Aperçu";
            img.src = value;
            previewEl.appendChild(img);
        }

        function storycraftApplyCover(suffix, value) {
            const els = storycraftGetCoverElements(suffix);
            if (!els.hidden || !els.url || !els.preview) return;

            els.hidden.value = value || "";
            els.url.value = value || "";
            storycraftRenderPreview(els.preview, value || "");
        }

        function storycraftSyncCoverFromUrl(suffix) {
            const els = storycraftGetCoverElements(suffix);
            if (!els.hidden || !els.url || !els.preview) return;

            els.hidden.value = els.url.value || "";
            storycraftRenderPreview(els.preview, els.url.value || "");
        }

        function storycraftClearCover(suffix) {
            storycraftApplyCover(suffix, "");
        }

        function storycraftImportCover(event, suffix) {
            const file = event.target.files && event.target.files[0];
            if (!file) return;

            const reader = new FileReader();

            reader.onload = function(e) {
                const img = new Image();

                img.onload = function() {
                    const maxDimension = 900;
                    let width = img.width;
                    let height = img.height;

                    if (width > height && width > maxDimension) {
                        height = Math.round(height * (maxDimension / width));
                        width = maxDimension;
                    } else if (height >= width && height > maxDimension) {
                        width = Math.round(width * (maxDimension / height));
                        height = maxDimension;
                    }

                    const canvas = document.createElement("canvas");
                    canvas.width = width;
                    canvas.height = height;

                    const ctx = canvas.getContext("2d");
                    ctx.drawImage(img, 0, 0, width, height);

                    const compressed = canvas.toDataURL("image/jpeg", 0.82);
                    storycraftApplyCover(suffix, compressed);
                };

                img.src = e.target.result;
            };

            reader.readAsDataURL(file);
        }

        document.addEventListener("DOMContentLoaded", function() {
            const lectureShell = document.querySelector(".lecture-shell");

            if (lectureShell) {
                const prevURL = lectureShell.dataset.prevUrl || "";
                const nextURL = lectureShell.dataset.nextUrl || "";

                let startX = 0;
                let endX = 0;

                lectureShell.addEventListener("touchstart", function(e) {
                    startX = e.changedTouches[0].clientX;
                }, { passive: true });

                lectureShell.addEventListener("touchend", function(e) {
                    endX = e.changedTouches[0].clientX;
                    const diff = endX - startX;

                    if (diff < -70 && nextURL) {
                        window.location.href = nextURL;
                    } else if (diff > 70 && prevURL) {
                        window.location.href = prevURL;
                    }
                }, { passive: true });

                document.addEventListener("keydown", function(e) {
                    if (e.key === "ArrowRight" && nextURL) {
                        window.location.href = nextURL;
                    } else if (e.key === "ArrowLeft" && prevURL) {
                        window.location.href = prevURL;
                    }
                });
            }
        });
        """
    }

    // MARK: - CSS

    static func styleGlobal() -> String {
        """
        :root {
            --bg: #07101c;
            --bg-soft: #101a2c;
            --panel: rgba(17, 25, 42, 0.88);
            --panel-strong: rgba(11, 17, 30, 0.96);
            --border: #243450;
            --border-soft: rgba(255,255,255,0.08);
            --text: #f6f7fb;
            --muted: #aab2c5;
            --accent: #c8e6b7;
            --accent-2: #8eb37f;
            --accent-3: #87a8ff;
            --danger: #ad5d5d;
            --shadow: rgba(0, 0, 0, 0.34);
            --reading-width: 860px;
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
            background: rgba(8, 13, 24, 0.78);
            backdrop-filter: blur(14px);
            border-bottom: 1px solid var(--border-soft);
        }

        .logo {
            font-size: 1.4rem;
            font-weight: 900;
            letter-spacing: -0.02em;
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

        .inline-form {
            display: inline;
            margin: 0;
        }

        .page {
            width: min(1500px, 100%);
            margin: 0 auto;
            padding: 1.5rem;
        }

        .auth-shell {
            min-height: calc(100vh - 2rem);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
        }

        .auth-card {
            width: min(540px, 100%);
            background: var(--panel-strong);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 28px;
            box-shadow: 0 26px 65px rgba(0, 0, 0, 0.35);
            padding: 2rem;
        }

        .auth-header {
            margin-bottom: 1.5rem;
        }

        .auth-logo {
            font-size: 1.5rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            margin-bottom: 1rem;
        }

        .auth-header h1 {
            margin: 0 0 0.55rem;
            font-size: clamp(2rem, 4vw, 2.8rem);
            line-height: 1.06;
        }

        .auth-header p {
            margin: 0;
            font-size: 1rem;
        }

        .auth-actions {
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
        .detail-meta h1,
        .lecture-header h1 {
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

        .bloc-formulaire,
        .carte-histoire,
        .chapitre-admin,
        .commentaire,
        .detail-meta,
        .lecture-header,
        .lecture-content {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 24px;
            box-shadow: 0 18px 50px var(--shadow);
        }

        .bloc-formulaire-large {
            padding: 1.8rem;
        }

        .liste-chapitres {
            display: grid;
            gap: 1.2rem;
            margin-top: 1.2rem;
        }

        .carte-lien {
            display: block;
        }

        .carte-histoire {
            display: grid;
            grid-template-columns: 170px 1fr;
            gap: 1.25rem;
            padding: 1.25rem;
            transition: transform 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
        }

        .carte-histoire:hover {
            transform: translateY(-2px);
            border-color: #415068;
            box-shadow: 0 24px 52px rgba(0,0,0,0.42);
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
            background:
                linear-gradient(180deg, rgba(19,29,49,0.96) 0%, rgba(15,24,40,0.92) 100%);
        }

        .bloc-resume {
            margin: 1.4rem 0;
            padding: 1.1rem 1.2rem;
            border-radius: 18px;
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

        .chapitre-card-hover {
            transition: transform 0.15s ease, border-color 0.15s ease;
        }

        .chapitre-card-hover:hover {
            transform: translateY(-1px);
            border-color: #415068;
        }

        .chapitre-contenu {
            flex: 1;
            min-width: 0;
        }

        .chapitre-admin h3 {
            margin: 0 0 0.6rem;
            font-size: 1.25rem;
        }

        .chapitre-admin p {
            font-size: 1rem;
        }

        .chapitre-lien-titre {
            color: inherit;
            text-decoration: none;
        }

        .chapitre-lien-titre:hover {
            color: var(--accent);
        }

        .mini-read-row {
            margin-top: 0.8rem;
        }

        .mini-read-link {
            color: var(--accent);
            font-weight: 700;
            font-size: 0.98rem;
        }

        .mini-read-link:hover {
            color: #e0f2d2;
        }

        .note-form {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 0.75rem;
        }

        .commentaire-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            flex-wrap: wrap;
        }

        .cover-img,
        .cover-placeholder {
            width: 170px;
            height: 240px;
            object-fit: cover;
            border-radius: 18px;
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
        .cover-placeholder-large,
        .cover-preview-box {
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

        .cover-uploader {
            display: grid;
            gap: 0.8rem;
        }

        .cover-upload-grid {
            display: grid;
            grid-template-columns: 180px minmax(0, 1fr);
            gap: 1rem;
            align-items: start;
        }

        .cover-preview-zone {
            width: 180px;
        }

        .cover-preview-img,
        .cover-preview-box {
            width: 180px;
            height: 255px;
            border-radius: 18px;
            border: 1px solid var(--border);
            display: block;
            object-fit: cover;
        }

        .cover-upload-controls {
            display: grid;
            gap: 0.9rem;
        }

        .file-btn {
            position: relative;
            overflow: hidden;
            width: fit-content;
        }

        .file-btn input[type="file"] {
            display: none;
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
            width: min(760px, 100%);
        }

        .lecture-shell {
            width: min(var(--reading-width), 100%);
            margin: 0 auto;
            padding: 0.5rem 0 3rem;
        }

        .lecture-header {
            padding: 1.7rem;
            margin-bottom: 1.4rem;
            background:
                linear-gradient(180deg, rgba(20,30,49,0.96) 0%, rgba(15,24,40,0.92) 100%);
        }

        .lecture-header h1 {
            font-size: clamp(2rem, 4vw, 2.8rem);
            line-height: 1.08;
            margin-bottom: 0.7rem;
        }

        .lecture-content {
            padding: 2rem 2.2rem;
            background: rgba(13, 20, 33, 0.96);
        }

        .lecture-content p {
            font-size: 1.08rem;
            line-height: 2;
            margin: 0 0 1.4rem;
            color: #f4f6fb;
        }

        .lecture-space {
            height: 0.85rem;
            margin: 0;
        }

        .lecture-navigation {
            display: grid;
            grid-template-columns: 1fr auto 1fr;
            gap: 1rem;
            align-items: center;
            margin-top: 1.5rem;
        }

        .lecture-navigation > div:last-child {
            display: flex;
            justify-content: flex-end;
        }

        .lecture-actions-centre {
            display: flex;
            justify-content: center;
        }

        .lecture-hint {
            text-align: center;
            margin-top: 1rem;
        }

        @media (max-width: 1200px) {
            .detail-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 900px) {
            .cover-upload-grid {
                grid-template-columns: 1fr;
            }

            .cover-preview-zone,
            .cover-preview-img,
            .cover-preview-box {
                width: 100%;
                max-width: 260px;
            }
        }

        @media (max-width: 800px) {
            .navbar {
                padding: 1rem 1.1rem;
            }

            .page {
                padding: 0.75rem;
            }

            .auth-shell {
                padding: 1rem 0.25rem;
                min-height: auto;
            }

            .auth-card {
                padding: 1.35rem;
                border-radius: 24px;
            }

            .carte-histoire {
                grid-template-columns: 1fr;
            }

            .chapitre-admin {
                flex-direction: column;
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

            .lecture-content {
                padding: 1.35rem;
            }

            .lecture-content p {
                font-size: 1rem;
                line-height: 1.9;
            }

            .lecture-navigation {
                grid-template-columns: 1fr;
            }

            .lecture-navigation > div,
            .lecture-navigation > div:last-child,
            .lecture-actions-centre {
                justify-content: stretch;
            }

            .lecture-navigation a {
                width: 100%;
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
