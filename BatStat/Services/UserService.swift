import Foundation
import Supabase

class UserService {
    private let supabase = SupabaseConfig.shared.client
    static let shared = UserService()
    
    private init() {}
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(
            email: email,
            password: password
        )
    }
    
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    // MARK: - Session Management
    
    var currentUser: User? {
        return supabase.auth.currentUser
    }
    
    var isSignedIn: Bool {
        return currentUser != nil
    }
    
    func getCurrentSession() async throws -> Session? {
        return try await supabase.auth.session
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Auth State Listening
    
    func onAuthStateChange(callback: @escaping (AuthChangeEvent, Session?) -> Void) {
        Task {
            do {
                try await supabase.auth.onAuthStateChange { event, session in
                    callback(event, session)
                }
            } catch {
                
            }
        }
        
    }
}
