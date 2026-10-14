# Plan de montée de versions

Préparé pendant les builds RG351V / RG351MP. **Rien n'est appliqué** : ce
document est l'analyse qui doit précéder les changements.

Référence : `FORK-CHANGES.md` pour l'état du fork et les causes des pannes
passées.

---

## 1. Pourquoi ne pas tout mettre à jour d'un coup

Deux raisons, l'une technique et l'autre historique.

**`calculate_stamp` hache `$PKG_DIR`** (`config/functions:842`), donc le
contenu de `package.mk`. Changer un `PKG_VERSION` invalide **le stamp et le
ccache** du paquet. Une mise à jour de masse jette donc le cache accumulé —
or c'est précisément l'accumulation du ccache qui a permis aux builds
d'aboutir (§7.1 de `FORK-CHANGES.md`).

**C'est la cause racine de cette session.** 136 paquets bumpés en une fois,
jamais compilés, ont produit des dizaines de pannes trouvées une par une à
plusieurs heures chacune. 142 paquets d'un coup rejouerait exactement ça.

---

## 2. Ce que « mettre à jour » recouvre vraiment

142 paquets ont une version différente d'upstream. Mais ils forment **deux
populations opposées**, et la distinction change la stratégie.

| Population | Nombre | Qui est en avance | Ce que « sync upstream » ferait |
|---|---|---|---|
| Versions sémantiques (libs système) | 62 | **upstream**, dans les 62 cas | une vraie montée de version |
| Pins git (cœurs libretro) | 80 | **le fork**, majoritairement¹ | un **retour en arrière** |

¹ Sur 14 échantillonnés : 9 fork en avance, 2 upstream en avance, 3
indéterminés. Cohérent avec l'historique — les commits `8874e922` et
`d721f8a4` ont poussé les cœurs en avant.

**Conséquence** : pour les 80 cœurs, la montée de version **a déjà eu lieu**
(par les bumps). Le problème n'est pas qu'ils soient anciens, c'est qu'ils
n'étaient pas validés — et les builds actuels les valident désormais. Y
retoucher serait régresser.

Le gisement réel est donc **les 62 paquets sémantiques**, où upstream est en
avance et où son CI a déjà compilé ces versions.

---

## 3. Lots proposés

Classement par rayon d'impact croissant. Un build par lot, sur RG351P
(le device le plus éprouvé).

### Lot 1 — bibliothèques feuilles, sans patches (≈ 34 paquets)

Les 48 paquets sémantiques sans patches, **moins les 7 du lot 3**. Exemples :

| Paquet | Actuel | Upstream |
|---|---|---|
| `fluidsynth` | 2.3.4 | 2.6.0 |
| `openal-soft` | 1.23.1 | 1.24.3 |
| `libarchive` | 3.7.2 | 3.8.9 |
| `libzip` | 1.9.2 | 1.11.4 |
| `zstd` | 1.5.5 | 1.5.7 |
| `json-c` | 0.18 | 0.19 |

Faible risque : pas de patches à décaler, rayon d'impact limité, et upstream
les compile déjà. **C'est le lot à faire en premier.**

#### Vérification préalable — 45 candidats, 41 retenus

Chaque candidat a été contrôlé comme les 47 paquets déjà synchronisés :
upstream porte-t-il bien la version, et le fork a-t-il un commit manuel
dessus depuis la divergence ? Quatre cas sont ressortis, et ils valident la
méthode :

| Paquet | Problème détecté | Décision |
|---|---|---|
| `readline` 8.0→8.3 | upstream utilise encore `ftpmirror.gnu.org`, le redirecteur mort | prendre la **version** upstream, garder **notre URL** |
| `libidn2` 2.1.1a→2.3.8 | idem | idem |
| `bash` 5.1.16→5.3 | upstream en `http://`, nous en `https://` | prendre la version, garder `https` |
| `portaudio` | **faux positif** : upstream pointe `zhang-ray/portaudio`, dépôt **supprimé**. `sort -V` a classé le hash `64d1bf91…` après `19.7.0` | **exclu** — upstream est strictement moins bon |

`nettle` était signalé pour la même raison mais son URL upstream est déjà
identique à la nôtre : reversé dans le lot.

C'est exactement le piège de §7.5 de `FORK-CHANGES.md` — synchroniser à
l'aveugle régresserait les correctifs d'URL. Appliquer le lot paquet par
paquet avec ce contrôle, jamais un `git checkout upstream/dev -- packages/`
global.

### Lot 2 — paquets avec patches (≈ 19 paquets)

`libunwind`, `memtester`, `SDL2`, `SDL2_ttf`, `e2fsprogs`, `parted`,
`strace`, `MC`, `udevil`…

Risque réel : un patch écrit pour l'ancienne version peut ne plus
s'appliquer — **c'est le mode de panne dominant de cette session**. Prendre le
répertoire upstream **en entier** (version + patches ensemble), jamais la
seule ligne `PKG_VERSION`.

À découper en 2-3 sous-lots.

### Lot 3 — toolchain et dépendances larges (7 paquets, **un build chacun**)

| Paquet | Actuel | Upstream | Remarque |
|---|---|---|---|
| `gcc` | 13.3.0 | **15.3.0** | 2 versions majeures ; peut casser n'importe quel paquet |
| `cmake` | 3.28.1 | **4.4.2** | version majeure ; CMake 4 refuse les `cmake_minimum_required` < 3.5 |
| `binutils` | 2.41 | 2.43 | |
| `Python3` | 3.11.7 | 3.11.15 | correctif mineur, sûr |
| `ccache` | 4.8.3 | 4.13.6 | touche la compilation de tout |
| `boost` / `glib` | 1.82.0 / 2.78.3 | 1.92.0 / 2.89.4 | très largement dépendus |

`glibc` **n'est pas concerné** : 2.38 des deux côtés — sa divergence porte sur
les patches, pas la version.

Rayon d'impact maximal : ces paquets recompilent **tout**, et invalident le
ccache entier. `gcc 15` et `cmake 4` sont connus pour casser du code ancien —
exactement le profil des cœurs d'émulateurs.

**Un build dédié par paquet.** `Python3` peut passer en premier (correctif
mineur), `gcc` et `cmake` en dernier et séparément.

---

## 4. Méthode par lot

1. `git diff upstream/dev -- <dir>` — si upstream porte la version visée,
   prendre **tout le répertoire**, pas la seule version
2. Vérifier qu'aucun commit manuel du fork n'existe depuis la divergence
   (`git log <merge-base>..dev -- <dir>`) — sinon arbitrer
3. Lancer `source-audit` (10 min) avant le build (6 h)
4. Un build RG351P par lot ; en cas d'échec, le lot est petit donc le coupable
   est évident
5. Propager aux 3 autres devices une fois RG351P vert

**Ne pas utiliser `bump_amberelec.sh` / `update_packages`** : ils changent
`PKG_VERSION` seul, ce qui dissocie version et patches.

---

## 5. Coût et alternative

Environ **11 builds** (1 + 3 + 7 lots), soit ~50 h de CI, étalés.

La fusion `upstream/dev` (19 commits, 77 conflits) apporterait les lots 1 et 2
d'un coup — mais mélange les deux populations et **régresserait les cinq
correctifs d'URL** qu'upstream n'a pas (`configtools`, `dav1d`, `x264`,
`zlib`, `pulseaudio` — cf. §7.5 de `FORK-CHANGES.md`). Faisable, mais demande
d'arbitrer 77 conflits un par un.

---

## 6. Recommandation

Lot 1 d'abord : meilleur rapport bénéfice/risque, et il valide la méthode à
peu de frais. Lot 3 (`gcc`, `cmake`) en dernier, séparément — ce sont les
seuls capables de casser l'ensemble d'un coup.
