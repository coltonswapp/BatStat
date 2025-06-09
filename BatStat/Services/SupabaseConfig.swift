import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    // TODO: Replace with your actual Supabase project URL and API key
    private let projectURL = "https://tdzzchbpawiraocgnjlq.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkenpjaGJwYXdpcmFvY2duamxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNDQ4MDIsImV4cCI6MjA2NDcyMDgwMn0.qwKJg1Y4d2jeEuOsW9vDt5bRSmJvxwS_hGV5_X-XlyU"
    
    lazy var client: SupabaseClient = {
        guard let url = URL(string: projectURL) else {
            fatalError("Invalid Supabase project URL")
        }
        
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: apiKey
        )
    }()
    
    private init() {}
}
