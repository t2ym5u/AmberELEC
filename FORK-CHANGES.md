# État du fork — modifications, causes, contournements

Référence des changements apportés à `t2ym5u/AmberELEC` branche `dev` pour
rendre les builds fonctionnels sur GitHub Actions.

- **Base** : `51ea20d8` (18/09/2026), dernier commit avant ces travaux
- **Upstream de référence** : `AmberELEC/AmberELEC@dev`
- **État** : **les 4 devices produisent une image**

| Device | Run | Durée | Artefact |
|---|---|---|---|
| RG351P | `37957287962` | 4h49 | 949 Mo |
| RG552 | `38213191133` | 4h43 | 961 Mo |
| RG351V | `38741140410` | 5h31 | 950 Mo |
| RG351MP | `39208157743` | 4h33 | 950 Mo |

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

### 2.6 Cache d'état de build — **tenté puis retiré**

ccache n'accélère que la compilation. Mesure : un 2ᵉ étage avec cache chaud
atteignait 382 paquets quand le 1ᵉʳ en atteignait 390 — **aucun gain**.

`scripts/build` et `scripts/install` sortent immédiatement si leur *stamp*
correspond, sans `unpack`/`configure`/`link`/`install`. Rien ne transportait ces
stamps entre jobs. Ils sont désormais mis en cache (`.stamps` + `image/` +
`toolchain/` ≈ 1 Go contre 6,7 Go d'arbre complet).

Le transport fonctionnait (restauration et amorçage confirmés dans les logs), et
`calculate_stamp` hache bien les fichiers de l'arbre **source** avec des chemins
normalisés (`config/functions:851`) — le hash est indépendant de la machine.

**Mais l'approche a été retirée.** Le `toolchain/` est un état mutable partagé,
modifié pendant les `install`. Un job coupé en plein paquet le laisse déchiré :
après l'échec sur libtool, le `libtoolize` du toolchain sauvegardé avait perdu
ses fichiers de données (`libltdl/ltdl.mk`). Cet état corrompu était ensuite
**propagé de run en run** — chaque build repartait du toolchain cassé et
échouait au même endroit, à 7 min au lieu d'atteindre 382 paquets.

Or un job coupé en plein paquet est précisément le **cas normal** ici. La
précondition de l'approche — un instantané cohérent du toolchain — n'est donc
pas satisfiable en l'état. Rendre cela sûr demanderait de ne sauvegarder qu'aux
frontières de paquets, ce qui suppose de modifier le système de build lui-même.

Le mécanisme de stamps reste toutefois le bon levier théorique : il est le seul
à pouvoir supprimer le `unpack`/`configure`/`link`/`install` qui consomme
désormais l'essentiel du temps.

### 2.7 Publication des artefacts par l'étage qui aboutit

La préchauffe était conçue pour être interrompue, et seul le job `build`
publiait. Quand elle a commencé à terminer le build (cache chaud), son image
complète était **jetée** et `build` refaisait tout.

Désormais : la préchauffe publie si elle aboutit, et `build` n'est exécuté que
si elle n'a **pas** fini. Un runner économisé, plus d'image perdue.

`continue-on-error` a été retiré de la préchauffe : le repli se décide sur
`needs.build-warmup.result`, et ce drapeau rend ambigu ce que `result` renvoie
en cas d'échec — un faux `success` ferait sauter le repli sans rien produire.

### 2.8 `concurrency` — groupe par device

`group: main` était partagé par les quatre devices. Avec `cancel-in-progress`,
dispatcher RG351V puis RG351MP annulait le premier : **un seul device pouvait
tourner à la fois**. Le groupe est désormais `main-<device>` — les quatre
builds coexistent, et redispatcher le *même* device supersède toujours.

### 2.9 Deux façons d'annuler un build par accident

Deux pièges découverts en poussant pendant qu'un build tournait. Les deux ont
coûté le même warm-up, 37 minutes de compilation jetées.

**`paths-ignore` regarde la poussée, pas le commit.** Le workflow ignore
`**.md` et `docs/**`, donc on peut documenter sans relancer un build de 6 h.
Mais le filtre s'applique à **l'ensemble des fichiers modifiés par la
poussée** : un `git push` qui emporte deux commits de documentation *et* un
commit touchant `tools/` n'est pas ignoré du tout. Avec
`cancel-in-progress: true`, le run ainsi déclenché supersède celui qui tourne.

> Règle : pousser la documentation **seule**, ou ajouter `[skip ci]` au message
> si la poussée emporte autre chose.

**`always()` faisait démarrer un build à l'annulation.** Le job `build` porte
`always()` pour qu'un warm-up en échec obtienne quand même ses six heures.
Mais `always()` maintient aussi le job en vie à travers une annulation, et la
condition qui l'accompagnait — `needs.build-warmup.result != 'success'` — est
satisfaite par `'cancelled'`. Annuler un run pendant son warm-up faisait donc
l'inverse de ce qui était demandé : le warm-up s'arrêtait, et le build
démarrait.

C'est ainsi qu'un dispatch superflu, annulé une minute après sa création, est
revenu sous la forme d'un **second build RG351P** en concurrence avec le vrai,
sur le même cache de compilation — et il a tourné 36 minutes avant d'être
repéré. `gh run cancel` ne suffisait plus à l'en déloger : il a fallu
`POST .../force-cancel`, et le correctif ci-dessus ne vaut que pour les runs
suivants, pas pour celui déjà lancé.

Corrigé en excluant explicitement `'cancelled'` et en ajoutant `!cancelled()`.
Un warm-up qui **échoue** n'est pas affecté : un échec n'est pas une
annulation.

### 2.9bis Sauf qu'un timeout *est* une annulation

La phrase ci-dessus est fausse, et elle a coûté un run entier.

GitHub rapporte l'expiration de `timeout-minutes` avec la conclusion
**`cancelled`**, pas `failure`. La garde `!= 'cancelled'` écrite en 2.9 pour
qu'une annulation humaine ne relance pas six heures de build attrape donc
aussi le cas pour lequel le repli avait été construit. L'étage
warm-up → build ne pouvait pas fonctionner : soit le warm-up finissait tout,
soit il était coupé et le repli refusait de partir.

Run 40652630181 : warm-up de 5 h 54, cache publié à 3566 Mo avec les objets
de mame dedans, cap de 350 min atteint — puis `build` et `build-finalize`
`skipped`, et le run n'a rien produit.

Plutôt que de relâcher la garde, l'ambiguïté est supprimée à la source. Un
`input` `soft_timeout` sur l'action composite arrête la construction depuis
l'intérieur de l'étape :

```bash
timeout --kill-after=5m "330m" make DOCKER_WORK_DIR=/work docker-RG351P
```

`set -e` transforme le code 124 en échec, donc le job se termine en
`failure`. Le `timeout-minutes: 350` reste en filet 20 minutes plus loin, et
`cancelled` retrouve son sens unique : un humain a appuyé sur Annuler.
`--kill-after` parce que TERM n'est qu'une demande, qu'un éditeur de liens
peut ignorer le temps qu'il faut pour dépasser le cap.

Le job `build` ne reçoit pas de `soft_timeout` : aucun repli ne le suit, et
ses étapes de sauvegarde de cache sont déjà en `if: always()` — c'est
d'ailleurs ce qui a sauvé les 3566 Mo malgré l'annulation.

> Contournement immédiat quand le cas se présente : redispatcher avec
> `warmup=false`, qui saute entièrement l'étage et lance `build` sur le cache
> que le warm-up vient de publier.

### 2.10 `tools/audit-sources` + workflow `source-audit`

Vérifie les 613 sources sans télécharger les contenus, en ~10 min. À lancer
**depuis un runner cloud** : `gmplib.org` répond à une IP résidentielle et
refuse les plages cloud — un audit local l'aurait déclaré sain.

Encode deux pièges non évidents : `PKG_URL` interpole
`PKG_SITE`/`SOURCEFORGE_SRC`/`DISTRO_SRC` (sans quoi l'hôte disparaît de l'URL),
et `get_archive` dispose d'un repli mirroir — un paquet n'est cassé que si
**les deux** échouent.

### 2.11 Versions des actions

Aucune des onze actions utilisées n'avait bougé depuis la création du fork ;
plusieurs avaient sauté trois majeures, et `docker/login-action` était pinnée
sur un SHA de 2021 (v1.10.0).

| Action | Avant | Après |
|---|---|---|
| `actions/checkout` | v4 | v7 |
| `actions/upload-artifact` | v4 | v7 |
| `actions/download-artifact` | v4 | v8 |
| `actions/cache/{restore,save}` | v4 | v6 |
| `ncipollo/release-action` | v1.13.0 | v1.21.0 |
| `softprops/action-gh-release` | v1 | v3 |
| `peter-evans/repository-dispatch` | v3 | v4 |
| `peter-evans/create-pull-request` | v5 | v8 |
| `hmarr/debug-action` | v2 | v3 |
| `docker/login-action` | v1.10.0 (SHA) | v4.7.0 (SHA) |

Trois points vérifiés avant de bouger, parce qu'ils touchent le chemin qui
livre réellement les images :

- **`upload-artifact` v7 et `download-artifact` v8 forment une paire.** v7
  ajoute l'envoi direct non zippé (`archive: false`) et v8 le pendant côté
  téléchargement, qui inspecte le `Content-Type` avant de dézipper. Nos
  artefacts restent zippés — `archive` n'est pas utilisé — donc le
  comportement ne change pas ; v8 ajoute en prime l'échec sur un hash qui ne
  correspond pas.
- **`checkout` v7 bloque le checkout d'une PR de fork** sous
  `pull_request_target` et `workflow_run`. Aucun workflow du dépôt n'utilise
  l'un ou l'autre.
- **`create-pull-request` v7 a retiré la variable `PULL_REQUEST_NUMBER`**, que
  `update-dependencies.yaml` n'utilise pas.

Toutes ces majeures passent le runtime à Node 24, qui demande un runner
`>= 2.327.1`. Les runners hébergés en sont largement au-delà. Les workflows
posés sur les labels auto-hébergés d'amont — `main` et `pr`, soit `build-pr`,
`clean-pr`, `clean-main`, `clean-package` et `build-docker-image` — ne tournent
pas dans ce fork faute de ces runners, donc la contrainte ne s'y applique pas
aujourd'hui ; elle s'appliquerait à qui les rebrancherait.

Pas de `dependabot.yml` ajouté : le dépôt porte déjà vingt branches
`update-dependencies-*` abandonnées et le cron qui les produisait a été
désactivé délibérément. Relancer une machine à PR irait contre ce choix. La
commande qui a servi ici tient en une ligne et suffit à refaire le point :
`grep -rhoE 'uses: [^@]+@\S+' .github/ | sort -u`.

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
- **Contrôle du commit assoupli** : `get_git` exigeait que `PKG_VERSION` soit un
  **ancêtre de la branche extraite**. Or les upstreams rebasent — la branche
  `libretro` de SameBoy a été force-push *entre deux jobs d'un même run*,
  rendant le commit divergent (49 devant, 1 derrière). Le clone le contenait
  pourtant : `git clone --branch X` récupère toutes les refs, et le `reset`
  fonctionnait. Le contrôle teste désormais l'**existence de l'objet**, avec
  repli sur un `fetch` par SHA. Couvre les 62 paquets git.

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
| `soundfont-generaluser` | `FAILURE: scripts/install soundfont-generaluser has failed!` — échec à l'étage image, après 460/460 paquets compilés | Le partage Dropbox ne sert plus le fichier mais sa page HTML « voir ce fichier » : **HTTP 200**, `text/html`, 198 Ko, et un sha256 **différent à chaque tentative**. Le miroir LibreELEC répond 404. Passage à GeneralUser GS **2.0.3** depuis le dépôt GitHub de l'auteur, qui l'offre explicitement comme source d'empaquetage automatisé — cf. §5.4 |

> Trois paquets (`doublecherrygb`, `fbneo`, `tic-80`) relèvent du même motif :
> **le projet amont a gagné un fichier de build-system** (`CMakeLists.txt`,
> `meson.build`), ce qui fait basculer `scripts/build` dans un répertoire
> hors-source — et les chemins relatifs du `package.mk` cessent d'être valides.

### 5.4 `soundfont-generaluser` — ce qu'une source morte peut cacher

Ce paquet a traversé **tous** les audits de sources sans être inquiété, en
étant totalement mort. La raison tient en une ligne : Dropbox répond `200`.

Les audits posaient la question « cette URL est-elle joignable ? ». Dropbox
servait sa page d'interstitiel HTML avec un code 200, donc la réponse était
oui. `scripts/get` téléchargeait 198 Ko de HTML, constatait un checksum faux,
et réessayait — sur les trois miroirs, en boucle, le sha256 changeant à chaque
fois puisque la page est générée dynamiquement :

```
got 12a970898da2ccf4...  wanted 4203835164766f42...
got 146bcd881091ae98...  wanted 4203835164766f42...
got a11ef40f6fc89ccb...  wanted 4203835164766f42...
```

Le paquet n'étant que `PKG_TOOLCHAIN="manual"`, rien ne le construit : il n'est
réclamé qu'à l'étage image. L'échec arrivait donc **après** les 460 paquets,
une heure de build plus loin, sur le dernier obstacle avant l'artefact.

D'où `tools/check-source-urls`, qui ne demande plus si l'hôte répond mais **ce
qu'il renvoie**, et signale un corps HTML là où une archive était attendue.
Passé sur l'arbre, le seul autre cas est `rtmpdump`, déjà servi par le miroir.

**Effet de bord traité.** GeneralUser GS 2.x déplace deux choses, et la carte
d'instruments timidity (`packages/tools/sound/timidity/config/GeneralUser.cfg`,
générée pour 1.471) les référençait toutes les deux :

| | 1.471 | 2.0.3 | Traitement |
|---|---|---|---|
| Kits de batterie en presets mélodiques | banque **127** | banque **120** | 11 lookups `%font` corrigés ; numéros de presets inchangés |
| Percussions proprement dites | banque **128** | banque **128** | inchangé — les 13 kits répondent, vérifié |
| 16 presets de variation GS | présents | consolidés | entrées laissées : timidity ignore un `%font` irrésolu et retombe sur la banque 0, ce que fait GS lui-même pour une variation absente |

Vérifié contre la table de presets de 2.0.3 : **256 des 272** paires
`banque:preset` de la carte résolvent exactement, les 16 restantes sont ces
variations, et **les 13 drumsets résolvent tous**. Le nom installé reste
`GeneralUser.sf2` — ni fluidsynth (lien symbolique) ni timidity ne suivent la
version de la banque.

---

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

### 7.1 Durée du build — **résolu pour les 4 devices**

Les quatre images sont produites. Durées du job qui aboutit :

| Device | Durée | Artefact |
|---|---|---|
| RG351P | 4h49 | 949 Mo |
| RG552 | 4h43 | 961 Mo |
| RG351V | 5h31 | 950 Mo |
| RG351MP | **4h33** | 950 Mo |

Ce qui débloque n'est pas un réglage mais l'**accumulation du ccache**,
enrichi run après run — **y compris par les runs coupés au plafond**. C'est
le mécanisme central et il est mesurable : temps mis par RG351MP pour
atteindre le paquet 443, run après run.

| Run | 443 atteint à |
|---|---|
| 2 | 240 min |
| 3 | 238 min |
| 4 | 233 → 224 min |
| 5 | 213 min |
| **6 (réussi)** | **154 min** |

MAME suit la même courbe : 111 min au run réussi contre ~137 à froid. Un
run tué à l'intérieur de MAME laisse ses objets compilés au suivant, qui
entre donc plus loin. Six tentatives pour RG351MP, mais **chacune réduisait
mécaniquement le travail de la suivante** — ce n'était pas du hasard.

Santé du cache, enfin mesurée (§7.1.1) : **84 % de hits**.

#### 7.1.1 Quatre hypothèses fausses, et ce qui les a démenties

Ce point a coûté six runs ; les impasses sont documentées pour ne pas être
refaites.

| Hypothèse | Démentie par |
|---|---|
| RG351MP plafonne à 443 par lenteur générale | 443 est une **frontière** : le paquet 444 est `mame`, 137 min à lui seul, et les 16 suivants 2 min |
| ccache évince MAME au plafond de 6 Go | agrandir à 9 Go n'a rien changé : **238 min avec 4,8 Go, 240 min avec 6,2 Go** |
| RG351MP est un device plus lourd | jeux de paquets **identiques** à RG351V, `TARGET_CPU`/`CPU_FLAGS`/`FPU` identiques |
| le clone de `libretro/mame` coûte les 137 min | 1,1 Go en superficiel / 1,8 Go complet, **14 s** — hors sujet |
| un job muet pendant 1 h 47 est bloqué | la sortie de **chaque paquet est tamponnée et vidée d'un coup à sa fin** : les dizaines de lignes `libtool: compile` de `linux-pam` portent toutes l'horodatage `16:27:15.80…`, une seule rafale juste avant `[441/460] [DONE]`. Le silence veut dire « un paquet est en cours », jamais « rien ne se passe » |

Le réglage sur la **taille** du cache visait une cible inexistante : ccache
tient 84 % de hits, mais **21 % des appels au compilateur sont non
cachables** (édition de liens), et configure/install/I-O ne sont pas
accélérés du tout. D'où l'insensibilité totale à la taille.

> **Cause de l'aveuglement** : l'étape « Compiler cache stats » lançait
> `ccache -s` **dans l'image Docker**, où ccache n'existe pas — il est
> construit dans le *toolchain*, à l'intérieur du volume de build. La
> commande échouait à chaque run, masquée par un `|| true`. **Cinq runs sans
> aucun taux de hit**, d'où des réglages à l'aveugle. Corrigé : l'étape
> pointe désormais le binaire réel.
>
> Leçon transposable : un diagnostic avalé par `|| true` coûte plus cher que
> l'erreur qu'il masque.

> **Corollaire sur la lecture des logs en direct.** Le `Last-Modified` du blob
> de log dit quand le runner a écrit pour la dernière fois, pas où en est le
> build. Le run `40497690702` est resté sans un octet de 16:29:38 à
> l'annulation à 18:16:20 — 1 h 47 — alors qu'il compilait `mame` tout du
> long. Pour savoir où en est un job, lire le dernier `[n/460] [DONE]`, pas
> l'horodatage du dernier octet.

#### 7.1.2 Quota de cache GitHub — 10 Go pour tout le dépôt

Contrainte structurelle découverte en route : un dépôt dispose de **10 Go de
cache Actions au total**, et GitHub évince à l'échelle du dépôt entier une
fois le quota plein.

Quatre devices × deux clés (préchauffe + build) n'y tiennent pas : les
devices **s'évinçaient mutuellement**, chaque run repartant d'un cache plus
froid que le précédent. Le quota était monté à **9933 Mo / 10240**, RG351V
occupant à lui seul 6,1 Go sur trois clés dont deux périmées.

Corrections, dans l'ordre où elles se sont avérées nécessaires :

1. **Une seule clé par device** — suppression des clés périmées.
2. **`permissions: actions: write`** — le dépôt délivre un jeton en lecture
   seule, et supprimer un cache exige `actions:write`. Sans cela la purge
   échouait **en silence** et le quota est remonté à 12645 Mo.
3. **Purger *avant* d'envoyer**, pas après — à 5-6 Go par cache, ancienne +
   nouvelle clé dépassent 10 Go à elles seules, donc l'envoi lui-même
   déclenchait une éviction.
4. **Un device à la fois** — chaque device culmine à ~8,5 Go pendant que ses
   deux clés coexistent ; deux en parallèle refont déborder le quota.

> ⚠️ **À revoir pour les montées de version** : 4 devices × ~6 Go ne tiennent
> pas dans 10 Go. Rebuilder les 4 après un lot imposera soit de les
> séquencer, soit d'accepter des caches froids.

#### 7.1.3 Leviers mesurés — à ne pas retenter

| Levier | Résultat mesuré |
|---|---|
| Cache ccache | **c'est le levier** — 84 % de hits, converge run après run |
| Taille du cache (6 → 9 Go) | **aucun effet** — 238 min vs 240 min |
| 2ᵉ étage (préchauffe) | aucun gain quand le cache est déjà chaud ; utile à froid |
| `THREADCOUNT=3` | 382 en 6h03 vs 382 en 5h53 — aucun gain |
| Profondeur de clone MAME | hors sujet — 14 s |
| Cache d'état de build | **nuisible** — toolchain corrompu propagé (§2.6) |

**La marge reste faible.** GitHub évince un cache après 7 jours
d'inactivité ; un build à froid repasse au-delà de 6 h. Dans ce cas,
dispatcher avec `warmup=true` : le premier étage reconstitue le cache, le
second termine. C'est précisément le rôle du découpage.

Si la marge devient structurellement insuffisante : **larger runner GitHub**
(payant, ~÷2), **runner self-hosted** (ce qu'utilise upstream), ou
**réduction du périmètre** (MAME et ses cores pèsent ~2 h).

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

### 7.5 Fusion `upstream/dev` — non faite, désormais possible

19 commits de retard, 77 conflits. La condition posée — un build vert comme
référence — est **remplie** depuis le run `37957287962`.

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

1. **Les montées de version doivent se faire par petits lots, validés.** Les
   scripts `bump_amberelec.sh` / `update_packages` changent `PKG_VERSION`
   **seul**, alors qu'une version et ses patches forment un couple — c'est
   l'origine de la majorité des pannes documentées ici. Un bump de 136 paquets
   en une fois est invérifiable : la panne suivante coûte un build entier à
   localiser. Procéder par lots de quelques paquets, chacun suivi d'un build,
   et vérifier d'abord `git diff upstream/dev -- <dir>` — quand upstream a déjà
   la version visée, son paquet complet (patches et logique de build inclus)
   est préférable à un simple changement de `PKG_VERSION`.
2. **Lancer `source-audit` avant un build long** — 10 min contre 6 h.
3. **Face à un paquet qui casse, comparer d'abord à upstream** (`git diff
   upstream/dev -- <dir>`). C'est ce qui a résolu la majorité des cas. Vérifier
   ensuite qu'aucun commit manuel n'existe depuis la divergence.
4. **Un code HTTP 200 ne prouve pas qu'on a reçu un fichier.** Plusieurs hôtes
   servaient du HTML avec un 200. Toujours vérifier le `PKG_SHA256`.
5. **Si le runner meurt** (« lost communication with the server »), remettre
   `THREADCOUNT` à 2 — ne pas l'augmenter.
</content>
