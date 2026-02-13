//
//  ProfilePickerView.swift
//  Alexandria
//
//  Odabir profila – Chrome/Safari/Edge style grid profila.
//

import SwiftUI

struct ProfilePickerView: View {
    @ObservedObject private var manager = ProfileManager.shared
    @State private var showAddProfile = false
    
    private let defaultAccent = Color(hex: "ff5c00")
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 32) {
                Text("Tko koristi Alexandria?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 24)
                ], spacing: 24) {
                    ForEach(manager.profiles) { profile in
                        ProfileAvatarButton(profile: profile) {
                            manager.switchTo(profile)
                        }
                    }
                    
                    AddProfileButton(accentColor: defaultAccent) {
                        showAddProfile = true
                    }
                }
                .padding(.horizontal, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddProfile) {
            AddProfileView(onDismiss: {
                showAddProfile = false
            })
        }
    }
}

// MARK: - Gumb profila
private struct ProfileAvatarButton: View {
    let profile: Profile
    let action: () -> Void
    private let accentColor = Color(hex: "ff5c00")
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(accentColor)
                Text(profile.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dodaj profil gumb
private struct AddProfileButton: View {
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 80, height: 80)
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(accentColor)
                }
                Text("Dodaj profil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dodaj novi profil (sheet)
struct AddProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    
    var onDismiss: () -> Void
    
    private let accentColor = Color(hex: "ff5c00")
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Novi profil")
                .font(.title2.bold())
                .foregroundColor(accentColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ime")
                    .font(.headline)
                    .foregroundColor(.white)
                TextField("Ime profila", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Odustani") {
                    onDismiss()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.8))
                
                Button("Dodaj") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    ProfileManager.shared.addProfile(name: trimmed)
                    onDismiss()
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(accentColor))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320, height: 220)
        .background(Color.black.opacity(0.95))
    }
}

#Preview {
    ProfilePickerView()
        .frame(width: 600, height: 500)
}
