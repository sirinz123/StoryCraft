import Crypto
import Foundation

enum Security {
    static func genererToken() -> String {
        UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
    }

    static func genererSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
    }

    static func hasherMotDePasse(_ motDePasse: String, salt: String) -> String {
        let valeur = salt + motDePasse
        let data = Data(valeur.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verifierMotDePasse(_ motDePasse: String, hash: String, salt: String) -> Bool {
        hasherMotDePasse(motDePasse, salt: salt) == hash
    }
}
