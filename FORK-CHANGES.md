# État du fork — modifications, causes, contournements

Référence des changements apportés à `t2ym5u/AmberELEC` branche `dev` pour
rendre le build RG351P fonctionnel sur GitHub Actions.

- **Base** : `51ea20d8` (18/09/2026), dernier commit avant ces travaux
- **Portée** : 52 commits, 125 fichiers
- **Upstream de référence** : `AmberELEC/AmberELEC@dev`

---

## 1. Pourquoi tout cela était nécessaire

Trois causes racines expliquent la quasi-totalité des pannes rencontrées.

### 1.1 Des bumps de version jamais compilés

Les commits `8874e922`, `5448b86f`, `d721f8a4`, `36b7bc8c`, `732bef50` ont
déplacé **136 paquets** vers de nouvelles révisions. Ils ont été poussés
**pendant que GitHub Actions était désactivé sur le dépôt** — aucun n'a donc
jamais été compilé.

Le défaut de construction est systématique : ces scripts changent
`PKG_VERSION` **seul**, alors qu'upstream change la version **et** ajuste les
patches, les options cmake ou la logique de build dans le même commit. Le fork
s'est donc retrouvé avec des sources récentes et des patches écrits pour des
sources anciennes.

Mesure faite sur RetroArch, qui illustre le mécanisme :

| Configuration | Patches appliqués | Échecs |
|---|---|---|
| pin fork + patches fork | 9 | 4 |
| pin d'avant le bump + patches fork | 11 | 2 |
| **pin upstream + patches upstream** | **13** | **0** |

Revenir sur le bump ne suffisait pas — seul le couple version ↔ patches
d'upstream est cohérent.

### 1.2 Un fork en retard d'un an sur upstream

Point de divergence : `f8f0c07c` (09/10/2025). Upstream a depuis corrigé des
problèmes que le fork subit encore. Le commit `795bc99c` (« update
cores/emulators ») explique à lui seul quatre pannes : `glsl-shaders`,
`retroarch`, `mojozork`, `ppssppsa`.

### 1.3 Des sources amont disparues ou inaccessibles

Indépendant du fork : redirecteurs morts, hôtes bloquant les IP cloud,
archives régénérées invalidant les checksums, et une panne complète de
l'infrastructure GNU pendant ces travaux.

---

## 2. Infrastructure CI

### 2.1 Actions réactivées

Elles étaient désactivées **au niveau du dépôt** (`"enabled": false`), pas au
niveau des workflows. Les runs restaient en attente 24 h puis étaient annulés.

### 2.2 `build-main.yaml` — portage sur runners GitHub

Le workflow exigeait un runner self-hosted étiqueté `main`, que ce fork n'a
pas. Mais changer `runs-on` ne suffisait pas : tout le workflow supposait **une
machine persistante** — `build-init` faisait le checkout, les jobs device
lançaient `make` dans ce même workspace **sans checkout à eux**, et
`build-finalize` y récupérait les artefacts. Sur des runners hébergés, chaque
job repart d'une VM vierge.

Restructuration :

- `build-init` ne calcule plus que branche/version/date/sha, exposés en outputs
- les 4 jobs device deviennent une **matrice** qui fait son propre checkout et
  publie son résultat en artefact — ils ne sont plus chaînés, donc **parallèles**
- `build-finalize` redescend les artefacts avant les étapes de release
- ajout d'un input `device` (build d'une seule cible) et `warmup`
- `DOCKER_IMAGE` pointe sur l'image **upstream** : ce fork n'en publie aucune et
  son `Dockerfile` est en retard (il manque `bison`, `flex`,
  `linux-libc-dev-arm64-cross`, le pin gcc-10)

### 2.3 `concurrency` — runs qui s'annulaient mutuellement

`group: main` sans `cancel-in-progress` : les runs faisaient la queue. Un run
dispatché est resté **en attente de 06:15 à 10:59** avant d'être supplanté par
le cron quotidien. Ajout de `cancel-in-progress: true`.

### 2.4 `release-dev.yaml` — cron désactivé

Son cron quotidien déclenchait un build complet, se battait pour le même groupe
de concurrence et publiait vers un dépôt inaccessible à ce fork. Passé en
manuel uniquement.

### 2.5 Action composite `.github/actions/build-device`

Factorise les étapes de build entre les deux étages. Contient :

| Réglage | Raison |
|---|---|
| `PYTHON_EGG_CACHE=/tmp/python-eggs` | `HOME=/home/runner` n'existe pas dans le conteneur ; sans ça MarkupSafe (egg zippé avec extension C) n'est pas extractible, `import jinja2` échoue et meson déclare jinja2 manquant |
| `THREADCOUNT=2` | `nproc`(4) × `-j4` = ~16 compilateurs → runner tué. 1 = trop lent. 3 mesuré : aucun gain |
| `CCACHE_DIR=$HOME/.cache/...` | le défaut pointe dans le volume conteneur, perdu à chaque job |
| `CCACHE_MAXSIZE=6G` | 2G provoquait du *thrashing* (cache bloqué à 1,9G, +4 Mo en 5h30) |
| nettoyage disque étendu | ~13 Go de plus (ghcup, swift, powershell, miniconda, az, julia, images Docker) |
| arrêt du conteneur avant sauvegarde | sinon `tar` échoue (« file changed as we read it ») et le cache est perdu |
| garde-fou de cache **relatif** | on ne publie que si le cache est ≥ au meilleur déjà stocké ; un seuil fixe avait laissé un cache de 662 Mo écraser celui de 2,8 Go |

### 2.6 Cache d'état de build (dernier ajout)

ccache n'accélère que la compilation. Mesure : un 2ᵉ étage avec cache chaud
atteignait 382 paquets quand le 1ᵉʳ en atteignait 390 — **aucun gain**.

`scripts/build` et `scripts/install` sortent immédiatement si leur *stamp*
correspond, sans `unpack`/`configure`/`link`/`install`. Rien ne transportait ces
stamps entre jobs. Ils sont désormais mis en cache (`.stamps` + `image/` +
`toolchain/` ≈ 1 Go contre 6,7 Go d'arbre complet).

Viable car `calculate_stamp` hache les fichiers de l'arbre **source** et
normalise les chemins (`config/functions:851`) — le hash est indépendant de la
machine.

### 2.7 `tools/audit-sources` + workflow `source-audit`

Vérifie les 613 sources sans télécharger les contenus, en ~10 min. À lancer
**depuis un runner cloud** : `gmplib.org` répond à une IP résidentielle et
refuse les plages cloud — un audit local l'aurait déclaré sain.

Encode deux pièges non évidents : `PKG_URL` interpole
`PKG_SITE`/`SOURCEFORGE_SRC`/`DISTRO_SRC` (sans quoi l'hôte disparaît de l'URL),
et `get_archive` dispose d'un repli mirroir — un paquet n'est cassé que si
**les deux** échouent.

---

## 3. Système de build (`scripts/`, `Makefile`)

### `scripts/get_archive`

- **Backoff entre réessais** : les 10 tentatives s'enchaînaient sans pause, soit
  ~2 s au total. Élargi ensuite à ~5 min (pas de 6 s), `download.samba.org`
  ayant dépassé la première fenêtre deux fois.
- **Repli mirroir GNU** → `mirrors.kernel.org`. Couvre les **trois** écritures
  présentes (`/gnu/`, `/pub/gnu/`, `http://`) : ne matcher que la première
  laissait `gettext` et `glibc` découverts.
- **Repli mirroir Savannah** → `mirror.netcologne.de`.

### `scripts/get_git`

- **Réessais sur le clone** : il n'y en avait aucun, contrairement aux archives.
  Une erreur HTTP 500 d'une seconde détruisait un run de 3 h.
- **Repli mirroir** pour `configtools` → `github.com/build2/config`, avec
  réalignement de l'origine (les contrôles comparent l'origine à `PKG_URL`).
- **`--recursive` retiré du clone** : il peuplait les sous-modules avant le
  checkout sur `PKG_VERSION` et respectait `shallow = true`, rendant inatteignable
  le commit `vendor/quickjs` de TIC-80. La mise à jour explicite des sous-modules
  qui suit le reset s'en charge correctement.

### `Makefile`

`JAVA_HOME` filtré du `.env` : le runner pointe
`/usr/lib/jvm/temurin-17-jdk-amd64`, absent du conteneur, ce qui faisait échouer
`freej2me`. Étend le filtre existant (`TMPDIR`, `SHELL`).

---

## 4. Paquets — changements d'hôte (version inchangée)

29 paquets repointés sans changer de version. **Aucun impact fonctionnel** :
checksums vérifiés identiques sauf mention contraire.

| Paquets | Ancien hôte | Nouvel hôte | Raison |
|---|---|---|---|
| 24 paquets GNU : `autoconf`, `autoconf-archive`, `automake`, `bash`, `bison`, `cpio`, `gcc`, `gdb`, `grep`, `libcdio`, `libidn2`, `libmicrohttpd`, `libtool`, `m4`, `make`, `mpc`, `mpfr`, `mtools`, `nettle`, `parallel`, `parted`, `readline`, `sed`, `wget` | `ftpmirror.gnu.org` | `ftp.gnu.org` | Redirecteur distribuant des mirroirs morts (404/timeout) |
| `gmp` | `gmplib.org` | `ftp.gnu.org` | Hôte bloquant les plages IP cloud |
| `zlib` | `zlib.net` | release GitHub `madler/zlib` | Servait du HTML au lieu du tarball |
| `pulseaudio` | `freedesktop.org` | clone git `pulseaudio/pulseaudio` (tag v17.0) | HTTP 418 pour les runners, sur les deux vhosts, par intermittence |
| `dav1d` | `code.videolan.org` | `downloads.videolan.org` | Hôte injoignable + archive GitLab régénérée (checksum instable) → `PKG_SHA256` mis à jour, contenu vérifié identique |
| `x264` | `code.videolan.org` | clone git `github.com/mirror/x264` | Même hôte mort ; clone git = plus de checksum fragile |
| `configtools` | snapshot cgit Savannah | clone git Savannah | Endpoint snapshot cassé (HTTP 400 sur le préfixe custom) |
| `squashfs-tools` | — | — | GitHub a changé la compression de ses archives auto-générées → `PKG_SHA256` mis à jour, contenu vérifié identique au tag `4.5` |

> **Leçon récurrente** : les archives auto-générées (GitHub `/archive/`, GitLab
> `/-/archive/`) ne garantissent **aucune stabilité d'octets**. Épingler un
> `PKG_SHA256` dessus est fragile par construction. Un clone git épinglé sur un
> hash est préférable — le hash est sa propre garantie d'intégrité.

---

## 5. Paquets — changements de version

**47 répertoires de paquets sont désormais identiques à `upstream/dev`.**
La règle appliquée : reprendre le paquet upstream *en entier* (version +
patches + logique de build), après avoir vérifié qu'aucun travail local n'était
perdu — tous les commits les touchant depuis la divergence étaient des bumps
automatiques.

### 5.1 Reverts ciblés (sources upstream cassées)

| Paquet | De → vers | Raison |
|---|---|---|
| `RTL8812AU` | `1be3d390` → `3e8c7322` | `rtw_xmit.c` utilise `_FW_UNDER_SURVEY`, jamais définie — régression upstream à ce commit |
| `RTL8821AU` | `0afd9bac` → `847c74b1` | Même défaut, même macro |

Les 4 autres drivers du bump (`RTL8188FU`, `RTL8814AU`, `RTL88x2BU`,
`RTL8852BU`) ont été vérifiés sains pour ce défaut et laissés en l'état.

### 5.2 Synchronisations sur upstream (31 + 16 paquets)

Deux lots. Le second (16 paquets) avait d'abord été classé « risque moindre »
car leurs patches étaient identiques à upstream — **classement erroné** : le
patch qui bloquait RetroArch était lui aussi identique à celui d'upstream. Des
patches identiques ne disent rien sur leur applicabilité à une version bumpée.

`atari800`, `beetle-supafaust`, `dosbox-pure`, `duckstation`, `ecwolf`,
`emuscv`, `freej2me`, `freej2me-plus`, `gambatte`, `hatari`, `hypseus-singe`,
`luajit`, `mame`, `mame2015`, `mame2016`, `mgba`, `mupen64plus-nx`, `openbor`,
`parallel-n64`, `pcsx_rearmed`, `physfs`, `ppsspp`, `prboom`, `px68k`,
`same_cdi`, `snes9x2010`, `solarus`, `stella`, `stella-2014`, `uae4arm`,
`virtualjaguar`

### 5.3 Corrections individuelles diagnostiquées

| Paquet | Problème | Correction |
|---|---|---|
| `retroarch` | Patch `0001-video_thread_wrapper` : 2 hunks/3 rejetés | Paquet upstream (`69a4f0ea`) — mesure en §1.1 |
| `glsl-shaders` | `cp: cannot copy a directory into itself` — le `Makefile` du projet copie `./.` dans un sous-répertoire de la source | Upstream a remplacé `make install` par une copie explicite |
| `mojozork` | SDL3 tiré par FetchContent exige X11/Wayland, absents du conteneur | Options cmake upstream (`-DLIBRETRO=ON`) ; les deux révisions référencent SDL3, ce sont les options qui décident |
| `ppssppsa` | Patch `005-fix-window-size` : 3 hunks/4 rejetés | Upstream l'a supprimé ; restaure aussi `USE_SYSTEM_FFMPEG=OFF` |
| `doublecherrygb` | `make: No targets specified and no makefile found` | **`PKG_TOOLCHAIN` seul changé** (`make` → `cmake`) : le projet a gagné un `CMakeLists.txt`, ce qui fait basculer le build hors-source. Version récente du fork conservée |
| `fbneo` | `sed: can't read ./src/burner/libretro/Makefile` | **Chemins `./` → `../` seuls** : le projet a gagné un `meson.build`. Version récente du fork conservée |
| `gzdoom` | `undefined reference to SDL_GameControllerHasRumble` (SDL2 ≥ 2.0.18, conteneur en 2.0.10) | Upstream ne construit que les générateurs côté host (`make lemon zipdir re2c`) — plus rien ne lie SDL2 |
| `raze` | `No rule to make target .../libzmusic.so` | Même remède que `gzdoom` |
| `np2kai` | `unknown type name 'OEMCHAR'` | Version upstream (`1ea561cd`) |
| `amiberry` | `Could NOT find OpenGL (OPENGL_glx_LIBRARY)` — ces appareils utilisent OpenGL ES | Paquet upstream (révision 09/2025) + sous-paquet `libpcap` |
| `yabasanshiroSA` | Patch `threads.h` inapplicable | `51ea20d8` avait repointé le dépôt sans ajuster les patches ; upstream utilise `sydarn/yabause` branche `pi4-update` avec les patches correspondants |
| `tic-80` | `upload-pack: not our ref` sur `vendor/quickjs` | **Pas un problème de version** — upstream épingle le même commit quickjs. Corrigé dans `scripts/get_git` (§3) |

> Trois paquets (`doublecherrygb`, `fbneo`, `tic-80`) relèvent du même motif :
> **le projet amont a gagné un fichier de build-system** (`CMakeLists.txt`,
> `meson.build`), ce qui fait basculer `scripts/build` dans un répertoire
> hors-source — et les chemins relatifs du `package.mk` cessent d'être valides.

---

## 6. Patches

### 6.1 Supprimés (12)

Repris de la suppression upstream, ou devenus inapplicables :

`ppssppsa/005-fix-window-size`, `solarus/luajit/luajit-crosscompile`,
`yabasanshiroSA/01-yabasanshiroSA-fixes`,
`dosbox-pure/dosbox-pure-add-emuelec-platform`, `dosbox-pure/svga_fix`,
`freej2me-plus/jarname`, `mame2015/fix-mame2015-python-3.11`,
`mame2016/fix-mame2016-python-3.11`, `same_cdi/mame-crosscompile`,
`snes9x2010/snes9x2010-add-oga`, `virtualjaguar/001-optimize`,
`retroarch/retroarch-04-enablecontent`

### 6.2 Ajoutés (8)

Apportés par la synchronisation upstream :

`amiberry/libpcap/0001-remove-manpages`, `solarus/solarus-001-padnum`,
`yabasanshiroSA/02-use-system-libpng`, `yabasanshiroSA/05-cmake-fixes`,
`emuscv/build-tools`, `emuscv/emuscv_platform2`,
`parallel-n64/aarch64/02-enable-fp-delay-slot`,
`retroarch/retroarch-11-mbedtls-aes-optimization`

### 6.3 Modifiés (11)

Versions upstream des patches, cohérentes avec les versions synchronisées.

---

## 7. Ce qui n'est pas résolu

### 7.1 Le build dépasse le plafond de 6 h — problème ouvert

**Le build compile entièrement** : derniers runs à 382-400 paquets installés,
**zéro échec**, étape d'assemblage de l'image atteinte. Le blocage est un
plafond de ressources, pas un défaut du code.

Leviers gratuits mesurés et épuisés :

| Levier | Résultat mesuré |
|---|---|
| Cache ccache | +47 % au début, puis saturé |
| 2ᵉ étage (préchauffe) | 382 paquets après 390 — aucun gain |
| `THREADCOUNT=3` | 382 en 6h03 vs 382 en 5h53 — aucun gain |

Le temps restant part dans `unpack`/`configure`/`link`/`install`. Le cache
d'état (§2.6) est la tentative en cours ; **son efficacité n'est pas encore
mesurée**.

Si elle ne suffit pas, les options sont : **larger runner GitHub** (payant,
~÷2 sur le temps), **runner self-hosted** (ce qu'utilise upstream), ou
**réduction du périmètre** (les cores MAME pèsent ~2 h).

### 7.2 Espace disque — marge étroite

Mesuré : 122 Go libres au départ, 99 Go consommés (70 Go d'arbre de build,
~29 Go de sources), **23 Go restants** à l'assemblage de l'image — où un run a
échoué. Le nettoyage étendu ajoute ~13 Go.

> `/mnt` **n'est pas** un second disque sur cette image de runner : `df` montre
> `/` et `/mnt` sur le même `/dev/root` de 145 Go. Une tentative de déplacer
> les sources là-bas a été annulée pour cette raison.

### 7.3 Risque connu du cache d'état

26 paquets référencent le répertoire de build d'un autre via `get_build_dir` ;
ces répertoires ne sont pas conservés. Le risque n'existe qu'à la frontière —
un paquet construit au job 2 dont la dépendance a été sautée au job 1 — et
échouerait de façon explicite.

### 7.4 Sources cassées restantes (hors périmètre RG351P)

- `imx-gpu-viv` — blob GPU i.MX6, référencé par rien dans l'arbre
- `linux_org` — nom générique du noyau LibreELEC, surchargé par
  `projects/Rockchip/packages/linux`
- `portaudio` — le fork `zhang-ray/portaudio` a été supprimé de GitHub ;
  basculé sur upstream v19.7.0 (décision validée, change le code compilé)

### 7.5 Fusion `upstream/dev` — non faite

19 commits de retard, 77 conflits. Décision prise d'attendre un build vert
comme référence.

**Attention** : upstream a **toujours les URLs cassées** pour `configtools`,
`dav1d`, `x264`, `zlib` et `pulseaudio` — ses runners self-hosted ont les
sources en cache et ne rencontrent pas ces pannes. Une fusion résolue en faveur
d'upstream **régresserait ces cinq correctifs**.

### 7.6 Workflows encore sur runner self-hosted

`clean-main.yaml` et `build-docker-image.yaml` référencent toujours
`runs-on: main`. Le second se déclenche sur modification du `Dockerfile` et
attendrait 24 h pour rien.

---

## 8. Recommandations de maintenance

1. **Ne pas relancer `bump_amberelec.sh` / `update_packages`** sans build vert
   de référence. Ces scripts changent `PKG_VERSION` seul, ce qui est à
   l'origine de la majorité des pannes documentées ici.
2. **Lancer `source-audit` avant un build long** — 10 min contre 6 h.
3. **Face à un paquet qui casse, comparer d'abord à upstream** (`git diff
   upstream/dev -- <dir>`). C'est ce qui a résolu la majorité des cas. Vérifier
   ensuite qu'aucun commit manuel n'existe depuis la divergence.
4. **Un code HTTP 200 ne prouve pas qu'on a reçu un fichier.** Plusieurs hôtes
   servaient du HTML avec un 200. Toujours vérifier le `PKG_SHA256`.
5. **Si le runner meurt** (« lost communication with the server »), remettre
   `THREADCOUNT` à 2 — ne pas l'augmenter.
</content>
