//
//  ActiveSessionsView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za prikaz svih aktivnih sesija
struct ActiveSessionsView: View {
    @ObservedObject var sessionStore: SessionStore
    let onSessionOpen: (SessionMetadata) -> Void
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Active Sessions")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(sessionStore.activeSessions.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Content
            if sessionStore.activeSessions.isEmpty {
                emptyStateView
            } else {
                sessionsGridView
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No active sessions")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            Text("Start a mode to create a session")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var sessionsGridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(sessionStore.activeSessions) { session in
                    ActiveSessionCard(
                        session: session,
                        onDelete: {
                            sessionStore.deleteSession(session)
                        },
                        onOpen: {
                            sessionStore.updateSession(session)
                            onSessionOpen(session)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .frame(height: 200)
    }
    
}


