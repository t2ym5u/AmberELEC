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

### Lot 3 — toolchain et dépendances larges (9 paquets, **un build chacun**)

| Paquet | Actuel | Upstream | Remarque |
|---|---|---|---|
| `gcc` | 13.3.0 | **15.3.0** | 2 versions majeures ; peut casser n'importe quel paquet |
| `cmake` | 3.28.1 | **4.4.2** | version majeure ; CMake 4 refuse les `cmake_minimum_required` < 3.5 |
| `binutils` | 2.41 | 2.43 | |
| `Python3` | 3.11.7 | 3.11.15 | correctif mineur, sûr |
| `ccache` | 4.8.3 | 4.13.6 | touche la compilation de tout |
| `boost` / `glib` | 1.82.0 / 2.78.3 | 1.92.0 / 2.89.4 | très largement dépendus |
| `gdb` | 11.1 | **17.2** | **reporté du lot 1** : gdb 17.2 exige gcc 15 — « redeclaration of C++ built-in type 'bool' » sous gcc 13.3.0 |
| `poppler` | 23.10.0 | **26.08.0** | **reporté du lot 1** : exige C++23 |

`glibc` **n'est pas concerné** : 2.38 des deux côtés — sa divergence porte sur
les patches, pas la version.

Rayon d'impact maximal : ces paquets recompilent **tout**, et invalident le
ccache entier. `gcc 15` et `cmake 4` sont connus pour casser du code ancien —
exactement le profil des cœurs d'émulateurs.

**Un build dédié par paquet.** `Python3` peut passer en premier (correctif
mineur), `gcc` et `cmake` en dernier et séparément.

#### Couplages hors `package.mk` — à embarquer avec le lot

Trois choses conditionnent ce lot et ne vivent dans aucun `package.mk`. Les
oublier, c'est un build de 6 h perdu par oubli.

| Couplage | Où | Pourquoi |
|---|---|---|
| `export CMAKE_POLICY_VERSION_MINIMUM="3.5"` | `scripts/build` (upstream : ligne 112) | **Obligatoire avec cmake 4**, qui refuse tout projet déclarant `cmake_minimum_required` < 3.5 — le profil exact des vieux cœurs libretro. Variable d'environnement globale, inoffensive sous cmake 3.28 : elle peut donc précéder le bump |
| Drapeau `o3` | `config/functions` | `PKG_BUILD_FLAGS="+o3"` était **inerte** dans cet arbre : le lot 1 a pris le `package.mk` de `systemd` qui le porte, mais rien ne lisait le drapeau. Corrigé (branche `lot3-prep`) par substitution en place `-Ofast` → `-O3`, ce qui laisse les 459 autres lignes de commande identiques au bit près — donc **sans invalider le ccache** |
| `-std=gnu17` par paquet | `package.mk` | gcc 15 compile en **C23 par défaut** : `bool`/`true`/`false` deviennent des mots réservés, les déclarations implicites et les conversions de pointeurs incompatibles deviennent des **erreurs**. Upstream ne fixe pas de standard global, il corrige paquet par paquet — trois de ces correctifs sont déjà ici (`git`, `libidn2`, `parallel-n64`), arrivés avec le lot 1 |

#### Où se situe le risque réel

L'arbre ne contient **aucun paquet propre au fork** : les 679 `package.mk`
existent tous chez upstream. Comme upstream construit ces quatre mêmes
appareils avec gcc 15.3.0, tout paquet identique à upstream est déjà prouvé.

Le risque se réduit donc aux **181 paquets qui diffèrent**, et plus précisément
aux **103 qui diffèrent par la version** — dont la grande majorité sont des
cœurs libretro épinglés sur des commits plus anciens. C'est du code ancien
compilé par un compilateur C23 : c'est là que les ruptures tomberont, et
upstream n'a pas écrit de correctif pour *ces* révisions-là, seulement pour les
siennes.

> Conséquence de méthode : ce lot se fera en **plusieurs itérations**, chacune
> révélant quelques paquets. Épingler les cœurs est la raison d'être du fork —
> les faire avancer jusqu'aux révisions d'upstream pour contourner une rupture
> gcc 15 est un **changement de comportement d'émulateur**, à arbitrer au cas
> par cas, pas un réflexe.

#### État : lot 3 préparé sur la branche `lot3-prep`

Sept commits, chacun autonome, à poser un par un avec un build entre chaque.

| Commit | Contenu | Vérifié |
|---|---|---|
| `o3` | `PKG_BUILD_FLAGS="+o3"` rendu effectif dans `config/functions` | substitution en place : **n'invalide pas le ccache** |
| `CMAKE_POLICY_VERSION_MINIMUM` | export dans `scripts/build` | inoffensif sous cmake 3.28 — peut partir en avance |
| **3a** | `Python3` 3.11.15, `ccache` 4.13.6, `binutils` 2.43 | patches OK (3 / 35 / —) |
| **3b** | `cmake` 4.4.2 | somme + patch vérifiés deux fois |
| **3c** | `gcc` 15.3.0 **+ `PKG_SHA256`** | 3 patches OK ; somme confirmée par deux miroirs **et la signature GNU** |
| **3d** | `glib` 2.89.4, `boost` 1.92.0 | sommes OK ; options meson renommées reprises |
| **3e** | les 7 prérequis C23 | patches OK |
| **3f** | `gdb` 17.2, `poppler` 26.08.0 | patches OK |

**Le lot 3e est le résultat le plus utile de cette préparation.** En cherchant
les fonctions de build qu'upstream porte et pas nous, dix paquets sont
ressortis avec un contournement gcc 15 — une norme C rabattue, ou une erreur
C23 ramenée au rang d'avertissement :

| Paquet | Contournement |
|---|---|
| `gmp` | `-std=gnu11`, `-Wno-error=implicit-function-declaration`, `-Wno-error=incompatible-pointer-types`, et `-Ofast` → `-O2` |
| `ncurses` | `-Wno-incompatible-pointer-types -Wno-array-parameter` |
| `lzdoom` | `-std=gnu17` |
| `easyrpg` | `-Wno-template-body` *(drapeau gcc 15)* |
| `flycast2021` | `-Wno-error=implicit-function-declaration` |
| `freeimage` | `-std=gnu11 -Wno-error=implicit-function-declaration` |
| `joyutils` | `-Wno-implicit-function-declaration -Wno-builtin-declaration-mismatch` |
| `SDL2` | `-Wno-error=incompatible-pointer-types -Wno-error=int-conversion` — **déjà dans le lot 2** |
| `quasi88`, `libmali` | diffèrent aussi par la version → à arbitrer, pas à synchroniser |

Ce ne sont pas des compléments au bump de `gcc`, ce sont ses **préconditions**.
Sans eux, le bump échoue sur chacun à son tour, un build de 6 h par paquet.
`gmp` est le cas le plus net : c'est une dépendance de construction de `gcc`,
donc il échoue avant tout le reste.

> **`gcc` n'avait aucune somme de contrôle**, ni ici ni chez upstream ni chez
> LibreELEC. Le compilateur de toute la distribution était le seul paquet
> récupéré sur parole. Corrigé dans le commit 3c.

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
