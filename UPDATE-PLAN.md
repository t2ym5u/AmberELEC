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

### Hors paquets : les actions GitHub *(fait le 28 octobre 2026)*

Les onze actions utilisées par les workflows sont aussi des composants, et
aucune n'avait bougé depuis la création du fork — `docker/login-action` était
pinnée sur un SHA de 2021. Toutes montées, détail en §2.11 de
`FORK-CHANGES.md`. Sans effet sur les paquets ni sur l'ordre des lots
ci-dessous : les seuls workflows qui auraient pu souffrir du passage à Node 24
sont ceux posés sur les runners auto-hébergés d'amont, qui ne tournent pas
dans ce fork.

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

Huit commits, chacun autonome, à poser un par un avec un build entre chaque.

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
| **3g** | `libmali` 00aa2ae4, `quasi88` + contournement | somme `libmali` vérifiée (691,9 Mo) ; diff amont = 2 blobs g52 |

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
| `quasi88`, `libmali` | diffèrent aussi par la version → arbitrés dans le **3g**, voir ci-dessous |

Ce ne sont pas des compléments au bump de `gcc`, ce sont ses **préconditions**.
Sans eux, le bump échoue sur chacun à son tour, un build de 6 h par paquet.
`gmp` est le cas le plus net : c'est une dépendance de construction de `gcc`,
donc il échoue avant tout le reste.

##### Les deux arbitrages du 3g

Prendre le fichier d'upstream aurait déplacé la version en même temps que le
contournement. Les deux cas vont en sens opposés :

| | Nous | Upstream | Décision |
|---|---|---|---|
| `libmali` | `9b1375cf` (2022-02-28) | `00aa2ae4` (2026-10-11) | **pris entier** |
| `quasi88` | `459bbc6e` (2026-09-06) | `b5a0e044` (2026-07-22) | **notre version gardée**, contournement ajouté |

`libmali` : un seul commit nous sépare, et la comparaison GitHub dit qu'il
ajoute deux fichiers et ne touche à rien d'autre —
`lib/{aarch64-linux-gnu,arm-linux-gnueabihf}/libmali-bifrost-g52-g29p1.so`.
`MALI_FAMILY` vaut `g31` sur RG351P/V/MP et `t86x` sur RG552 : aucun appareil
ne lit ces blobs, et `PKG_PATCH_DIRS` sélectionne par famille, donc le
répertoire de patches `g52` qui les accompagne n'est jamais ouvert. Nos
patches `g31` et `t86x` sont identiques au bit près à ceux d'upstream. Le bump
est donc inerte pour les quatre appareils, et apporte la partie qui ne l'est
pas : `-Dc_std=gnu11` / `-Dcpp_std=gnu++11`, sans quoi la construction meson
échoue sous gcc 15.

`quasi88` : l'inverse, nous sommes en avance et synchroniser aurait été une
régression. Des trois commits qui nous séparent, un seul touche aux normes C
— « libretro: define gnu17 on vita » — et il vise une plateforme qui n'est pas
la nôtre. Le contournement reste donc nécessaire. `-Wno-error=` ne peut que
ramener une erreur au rang d'avertissement : le porter sur une source qui n'en
a plus besoin ne coûte rien, ne pas le porter sur une source qui en a besoin
coûte un build de 6 h.

> **`gcc` n'avait aucune somme de contrôle**, ni ici ni chez upstream ni chez
> LibreELEC. Le compilateur de toute la distribution était le seul paquet
> récupéré sur parole. Corrigé dans le commit 3c.

---

### Lot 4 — paquets morts, et ce qui les remplace

Les sept paquets restés en arrière ne sont **pas** un retard du fork :
upstream porte exactement les mêmes versions. Ce sont des projets dont
l'amont s'est arrêté. Chacun demande donc un arbitrage propre, pas un bump.

| Paquet | Version | Amont | Conclusion |
|---|---|---|---|
| `pcre` | 8.45 | fin de vie (2021) | **fait** — personne ne le liait, retiré (4a) |
| `p7zip` | 16.02 | mort en 2016 | **fait** — 7-Zip 26.05, construit et éprouvé localement (4b) |
| `freeimage` | 3.18.0 | mort en 2018 | **aucune version plus récente n'existe** (4c) |
| `distutilscross` | 0.1 | mort en 2012 | bloque Python ≥ 3.12 → lot 5 (4d) |
| `plymouth-lite` | 0.6.0 | meego.com éteint | source auto-hébergée, sans urgence |
| `bluetool` | 0.2.3 | PyPI, dernier envoi 2019 | à évaluer au runtime |
| `tcpbridge` | 1.1.1 | idem, tiré par `bluetool` | idem |

#### 4a — `pcre` retiré *(fait, branche `lot4-prep`)*

Deux paquets le déclaraient, aucun ne s'en servait. `git` 2.55 a **supprimé**
`--with-libpcre1` de son `configure.ac` (il émet une erreur si on le passe) et
`--with-libpcre2` vaut NO par défaut. `MC` choisit son moteur dans
`mc-check-search-type.m4`, dont le cas « aucune option passée » vaut
`glib-regexp` — et depuis glib 2.73, GRegex repose lui-même sur PCRE2. Les
quatre paquets qui savent détecter PCRE le refusent nommément (`slang` et
`swig` par `--without-pcre`, `systemd` par `-Dpcre2=disabled`). Une
bibliothèque en fin de vie était compilée à chaque build pour n'être liée
nulle part.

#### 4b — `p7zip` → 7-Zip officiel *(fait, branche `lot4-prep`)*

Debian (`trixie`), Fedora et Arch ont tous basculé : `p7zip` y est devenu un
paquet de transition vers `7zip`. Le fork `jinfeihan57/p7zip` 17.05, souvent
cité, n'a plus de commit de fond depuis décembre 2022 — ce n'est pas un amont
vivant, seulement un palier.

Les appels sont peu nombreux et tous en ligne de commande, donc portables :

| Appelant | Appel |
|---|---|
| `sanity_check.py` | `/usr/bin/7z l -slt <archive>` |
| `runemu.py:101` | `/usr/bin/7z e -o<dir> <archive> <membre>` |
| `scripts/install_addon` | `${TOOLCHAIN}/bin/7za a -tzip …` |
| `MC` (`mc.ext`, `mc.menu`) | `7za l`, `7za a -si`, `7za e -so` |
| `Skyscraper`, `virtual/toolchain` | dépendance `p7zip:host` |
| `emulationstation` | dépendance cible |

Le binaire officiel s'appelle `7zz` et accepte les mêmes commutateurs. La
migration consiste donc à construire `7zz` et à poser les trois noms
historiques (`7z`, `7za`, `7zr`) en enveloppes — exactement ce que fait le
paquet Debian — **sans toucher à un seul appelant**. Ce qui disparaît est le
modèle à greffons de p7zip (`7z.so` et `Codecs/`), que rien ici n'utilise en
dehors d'un commentaire dans `sanity_check.py`.

La machine de travail étant arm64, `7zz` a pu être **construit nativement
pour aarch64** dans un conteneur avant d'écrire le `package.mk` — les deux
passes aboutissent dans un même arbre (`b/host`, `b/target`), le binaire est
un ELF aarch64 lié dynamiquement et s'annonce `7-Zip (z) 26.05 (arm64) … ASM`.

L'essai a trouvé ce qu'une relecture aurait manqué :

```
7za a -l -mx9 … -tzip
Command Line Error: Unknown switch: -l
```

Le `-l` de p7zip (suivre les liens symboliques) n'existe pas dans `7zz` — la
dépendance inverse exacte dont parle l'équipe LTS Debian. Il est retiré des
deux appels de `scripts/install_addon`, et c'est le bon équivalent plutôt
qu'un pis-aller : sans lui, l'archive donne au lien symbolique la taille de
sa cible, donc `7zz` déréférence par défaut ce que p7zip ne faisait que sur
demande. Les six autres appels ont été rejoués un par un sur le binaire
construit et passent tous.

Version retenue : **26.05** et non 26.04, dont les notes annoncent « some
bugs and vulnerabilities were fixed » — ce binaire ouvre des archives
fournies par l'utilisateur. `-Werror`, que porte le makefile d'amont, est
retiré de la passe cible : il a sa place dans la CI de l'auteur, pas dans une
distribution où gcc 15 arrive avec le lot 3.

#### 4c — `freeimage` : il n'y a rien vers quoi monter

3.18.0 est la **dernière version publiée**, en juillet 2018 ; le projet est
arrêté et Debian l'a retiré de `testing`. Il n'existe donc pas de montée de
version possible, et le remplacer supposerait de modifier le fork
`AmberELEC/emulationstation`, qui en fait une dépendance CMake dure — hors du
périmètre d'une passe de montée de versions.

Ce qui reste faisable, par ordre de coût : reprendre la pile de correctifs que
Debian portait avant le retrait, ou laisser en l'état en connaissance de
cause. Les CVE visent des décodeurs de formats exotiques (PSD, XPM, TIFF),
atteignables uniquement par une image fournie par l'utilisateur — jaquettes
scrapées ou thème.

#### 4d — `distutilscross` : le verrou Python 3.11

`distutilscross` 0.1 (2012) rapièce `distutils`, que **Python 3.12 a supprimé
de la bibliothèque standard**. C'est la raison pour laquelle le lot 3a reste
dans la série 3.11 et ne va pas au-delà.

Quatre paquets en dépendent : `SDL2:host`, `Pillow`, `pycryptodome`,
`simplejson`. Les sortir demande de reprendre leur méthode de construction —
`crossenv`, maintenu, est le chemin usuel. C'est un lot à part entière, et
le seul qui débloque Python 3.12/3.13.

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
