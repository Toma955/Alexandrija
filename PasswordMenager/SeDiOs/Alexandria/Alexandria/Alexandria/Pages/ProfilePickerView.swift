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

// MARK: - Polje za unos u formi profila
private struct ProfileFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                .foregroundColor(.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
}

// MARK: - Dodaj novi profil (sheet) – puna forma za moderni browser (ime, prezime, naziv, email, mobitel)
struct AddProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var middleName: String = ""
    @State private var preferredDisplayName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    
    var onDismiss: () -> Void
    
    private let accentColor = Color(hex: "ff5c00")
    
    private var canCreate: Bool {
        let n = preferredDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let f = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !n.isEmpty || !f.isEmpty || !l.isEmpty
    }
    
    private func createProfile() {
        guard canCreate else { return }
        ProfileManager.shared.addProfile(
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            middleName: middleName.isEmpty ? nil : middleName,
            preferredDisplayName: preferredDisplayName.isEmpty ? nil : preferredDisplayName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )
        onDismiss()
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Novi profil")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "e11d1d"), Color(hex: "ea580c"), Color(hex: "f97316")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            Text("Sve što je za moderni web browser bitno")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileFormField(label: "Ime", placeholder: "Ime", text: $firstName)
                    ProfileFormField(label: "Prezime", placeholder: "Prezime", text: $lastName)
                    ProfileFormField(label: "Srednje ime", placeholder: "Srednje ime (opcionalno)", text: $middleName)
                    ProfileFormField(label: "Naziv", placeholder: "Kako želite da se prikažete (npr. Ivan P.)", text: $preferredDisplayName)
                    ProfileFormField(label: "Email adresa", placeholder: "email@primjer.hr", text: $email)
                    ProfileFormField(label: "Mobitel", placeholder: "+385 9x xxx xxxx", text: $phone)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 320)
            
            HStack(spacing: 12) {
                Button("Odustani") {
                    onDismiss()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.8))
                
                Button("Dodaj profil") {
                    createProfile()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(accentColor))
                .disabled(!canCreate)
            }
            .padding(24)
        }
        .frame(width: 400, height: 520)
        .background(Color.black.opacity(0.96))
    }
}

#Preview {
    ProfilePickerView()
        .frame(width: 600, height: 500)
}
