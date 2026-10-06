# Analyse de Loharano

## État actuel (`feat/optimisation`)

L’application dépiste et guide. Elle ne certifie pas.

| Fonction | Statut | Preuve |
|---|---|---|
| Questionnaire de risque, sans tirage au hasard | Fait | `lib/core/risk/risk_engine.dart`, `test/risk_engine_test.dart` |
| Photo facultative d’une marque sous le gobelet | Partiel | `lib/features/test_flow/mark_photo.dart`. Heuristique, pas un laboratoire |
| Guide filtrer / bouillir / couvrir, branché au résultat | Fait | `lib/features/purification/` |
| Voix | Partiel | Voix du téléphone. Pas de mp3 dans le dépôt |
| Historique SQLite et export CSV | Fait | `lib/core/db/local_database.dart` |
| Carte des mesures locales | Partiel | Fond OpenStreetMap en ligne la première fois |
| QR inconnu | Fait | Message « non reconnu », pas de fiche inventée |
| Synchro | Prête, éteinte | `lib/features/sync/sync_service.dart`, `supabase/schema.sql` |
| Bandelettes, H2S, backoffice séparé | Pas fait | `docs/LIMITES.md` |

## Constat initial (commit 6babc80)

Avant cette branche, le bouton « Capturer et analyser » choisissait SAFE, WARNING ou DANGER avec la seconde de l’horloge. Le guide restait sur « eau saine ». L’historique n’était jamais rempli. Tout QR inconnu devenait une pompe avec un débit inventé. Le fichier audio annoncé n’existait pas. Ce comportement a été retiré. Le détail des limites restantes est dans `docs/LIMITES.md`.
