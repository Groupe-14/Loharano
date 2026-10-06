# Limites

Ceci décrit ce que Loharano fait aujourd’hui, et ce qu’il ne fait pas.

## Fait

- Questionnaire de dépistage hors ligne, plus une photo facultative d’une marque sous le gobelet.
- Le résultat est un risque (faible non garanti, moyen, élevé, inconnu), jamais une certification.
- Le guide d’actions reprend les gestes déjà écrits : filtrer, bouillir 10 minutes, couvrir.
- Les boutons audio parlent avec la voix du téléphone (`flutter_tts`), en français.
- Chaque dépistage est écrit dans SQLite sur l’appareil.
- L’historique exporte un fichier CSV.
- La carte affiche les dépistages qui ont une position. Le fond de carte OpenStreetMap se charge en ligne la première fois.
- Un QR inconnu n’invente pas de pompe. On peut enregistrer le point seulement si le téléphone a une position.
- L’envoi Supabase est codé, et il reste éteint sans les clés.

## Pas fait

- Pas de bandelettes calibrées, pas de flacon H2S, pas de fichier mp3 enregistré.
- La photo de la marque est une heuristique de contraste. Si elle est incertaine, elle ne tranche pas.
- Les tuiles de la carte ne sont pas pré-téléchargées pour un quartier. Hors ligne, les points locaux restent dans la liste et l’historique ; le fond peut manquer.
- Pas de compte utilisateur, pas de backoffice séparé. Les lignes envoyées se lisent dans le tableau de bord Supabase.
- La fiche `POMPE-001` est un exemple marqué DÉMO. Son fichier `audio/pump-guide.mp3` n’est pas dans le dépôt : le lecteur dit « Fichier audio manquant ».
- Les seuils de laboratoire (chlore, nitrates) ne sont pas dans le moteur : il n’y a pas de réactif.

## À valider par un humain

- Relire les règles du questionnaire avec quelqu’un du domaine de l’eau (WASH) avant de les présenter comme un protocole.
- Enregistrer les textes de `docs/AUDIO_SCRIPTS.md` si la voix du téléphone ne suffit pas.
- Créer le projet Supabase gratuit et exécuter `supabase/schema.sql` seulement au moment de la synchro.
- Vérifier le parcours en mode avion sur un téléphone : dépistage, guide, historique, puis envoi une fois le réseau revenu.
