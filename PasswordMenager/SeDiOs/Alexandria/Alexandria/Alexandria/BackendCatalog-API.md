# Alexandria Backend – katalog (teme, jezici, plug-ini)

Aplikacija se spaja na **Alexandria backend** (Postavke → Status spajanja → Alexandria backend, ili koristi Server kataloga ako je prazno) i preuzima katalog za Market.

## Endpoint

```
GET /api/alexandria/catalog
```

Odgovor: JSON s poljima `themes`, `languages`, `plugins` (sva opcionalna).

## Format odgovora

```json
{
  "themes": [
    {
      "id": "custom-dark",
      "name": "Custom Dark",
      "description": "Tamna tema s prilagođenim ikonama",
      "downloadURL": "https://example.com/themes/custom-dark.zip",
      "version": "1.0",
      "iconOverrides": { "settings": "gearshape.fill", "appLibrary": "square.grid.2x2" }
    }
  ],
  "languages": [
    {
      "id": "hr",
      "name": "Hrvatski",
      "locale": "hr",
      "description": "Jezični paket za hrvatski",
      "downloadURL": "https://example.com/languages/hr.zip",
      "version": "1.0"
    }
  ],
  "plugins": [
    {
      "id": "my-extension",
      "name": "My Extension",
      "description": "Opis plugina",
      "downloadURL": "https://example.com/plugins/my-extension.zip",
      "version": "1.0",
      "enabledByDefault": false
    }
  ],
  "message": null
}
```

- **downloadURL** – opcionalno; ako nema, za teme se može poslati **iconOverrides** izravno u odgovoru (tema se tada ne preuzima, nego se koristi ugrađeno).
- **iconOverrides** – mapiranje Island ključeva (npr. `settings`, `appLibrary`, `newTab`, `favorites`, `search`, `back`, `forward`, `globe`, `home`, `reload`, `devMode`, `person`, …) na SF Symbol nazive (npr. `gearshape.fill`).

## Lokalni cache

- Katalog: `Application Support/Alexandria/Catalog/catalog.json`
- Teme: `Application Support/Alexandria/Themes/<id>/` (unutar: `theme.json` ili preuzeti zip)
- Jezici: `Application Support/Alexandria/Languages/<id>/`
- Plug-ini: `Application Support/Alexandria/Plugins/<id>/`

## Postavke

- **Alexandria backend URL** – ako je postavljen, koristi se za katalog; inače se koristi **Server kataloga** (isti kao za pretragu aplikacija).
- **Osvježi katalog pri pokretanju** – pri startu aplikacije poziva se `GET /api/alexandria/catalog` i ažurira se lokalni cache.
