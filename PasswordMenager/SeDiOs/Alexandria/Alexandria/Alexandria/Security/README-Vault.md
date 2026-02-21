# Vault – priprema za sistemsku izolaciju

Ovaj folder sadrži **samo pripremu** koda. Ništa se ne poziva iz glavne aplikacije.

## 1. Kriptirani Sparse Bundle (sistemska izolacija)

- **VaultSparseBundle.swift** – kreiranje encrypted sparse bundle (AES-256) preko `hdiutil`, montiranje s `-nobrowse`, remount s `MNT_NOEXEC` / `MNT_NOSUID` (no-exec, sandboxing na razini kernela).
- Virtualni disk raste s podacima; cijeli disk je kriptiran.

## 2. Hardverska zaštita ključeva (Secure Enclave)

- **VaultSecureEnclaveKey.swift** – CryptoKit, Secure Enclave na Apple silikonu (M1/M2/M3). Privatni ključ ne napušta čip; koristi se za seal/unseal passphrase za vault. Lozinka se ne drži u kodu.

## 3. No-Execute i sandboxing

- U **VaultSparseBundle** remount s `noexec,nosuid` – kernel odbija izvršavati kod s tog diska.
- U **entitlements** (kad se uključi): ograničiti `com.apple.security.files.user-selected.read-write` na specifičnu Vault putanju.

## 4. Data leakage (nevidljivost)

- **VaultDataLeakagePrevention.swift** – Time Machine exclusion (`isExcludedFromBackup`), Spotlight (extended attribute za ne-indeksiranje). Mapu programski označiti da backup preskače.

## Uključivanje u budućnosti

- Pozvati orkestraciju iz `VaultOrchestrator` (npr. pri startu / pri prvom pristupu "heavy-duty" appu).
- Dodati potrebne entitlements za pristup vault putanji i eventualno za remount (ako sandbox dozvoli).
