# Loharano

Aide au dépistage et au traitement de l’eau, sur le téléphone, sans serveur obligatoire.

L’application ne dit pas qu’une eau est potable. Elle estime un risque à partir de questions simples et, si vous le voulez, d’une photo de gobelet posé sur une marque noire. Ensuite elle affiche les gestes : filtrer, faire bouillir dix minutes, couvrir le récipient.

## Hors ligne

Le questionnaire, le guide, la voix du téléphone, l’historique et les points enregistrés fonctionnent sans réseau. La base est SQLite, sur l’appareil. Le bandeau en haut indique « Hors ligne » ou « Réseau » selon la connexion détectée.

Le fond de carte OpenStreetMap a besoin d’un passage en ligne la première fois. Les tuiles déjà affichées sont gardées sur le téléphone. Les mesures restent lisibles dans l’historique même si le fond manque.

`flutter build web` produit le service worker qui met en cache les fichiers de la version web. Le manifeste d’installation est `web/manifest.json` : application autonome, orientation portrait.

## Synchro

Rien n’est envoyé tant que vous ne lancez pas l’application avec les clés d’un projet Supabase gratuit :

```powershell
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Le script SQL est dans `supabase/schema.sql`. Les photos ne partent pas. Sans ces clés, le bouton d’envoi explique que les mesures restent sur le téléphone.

## Lancer

```powershell
flutter pub get
flutter test
flutter run
```

## Ce qui n’est pas dans cette version

Bandelettes chimiques, flacon H2S, fichiers audio enregistrés, certification de laboratoire. Le détail est dans `docs/LIMITES.md`.
