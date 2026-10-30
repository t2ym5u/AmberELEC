# Journal des modifications

Ce fichier retrace ce qui distingue ce fork de [`AmberELEC/AmberELEC`](https://github.com/AmberELEC/AmberELEC),
dans l'ordre où les choses se sont faites.

Il reste volontairement court. Le **pourquoi** de chaque décision, les
diagnostics et les fausses pistes sont dans [`FORK-CHANGES.md`](FORK-CHANGES.md) ;
ce qui n'est pas encore fait est dans [`UPDATE-PLAN.md`](UPDATE-PLAN.md).

État au 28 octobre 2026 : **117 commits** d'avance sur `upstream/dev`, 37 de
retard.

---

## Non publié — en préparation sur branches

Rien de ce qui suit n'a encore été validé par un build complet. La capacité de
build est le goulot : six heures par appareil, un seul cache de compilation
utilisable à la fois.

| Branche | Contenu | Commits |
|---|---|---|
| `lot3-prep` | toolchain et dépendances larges | 8 |
| `lot4-prep` | paquets morts et leurs remplaçants | 2 |

Ordre prévu : `lot3` → `lot4`, un build par étape. `lot4-prep` porte encore
l'ancien commit du lot 2 et devra être rebasé sur `dev` avant d'atterrir.

### Lot 4 — paquets morts

- **`pcre` 8.45 retiré.** En fin de vie depuis 2021, compilé à chaque build et
  lié par personne : `git` 2.55 a supprimé `--with-libpcre1` de son
  `configure.ac`, MC retombe sur `glib-regexp` (qui est PCRE2 depuis glib
  2.73), et tous les autres paquets qui savent le détecter le refusent
  explicitement.
- **`p7zip` 16.02 → 7-Zip 26.05.** p7zip est un portage tiers abandonné en
  2016 ; Debian, Fedora et Arch sont passés à la source POSIX officielle.
  Construit et éprouvé nativement en aarch64 avant d'être écrit, ce qui a
  révélé le seul vrai piège : `7zz` ne connaît pas le `-l` de p7zip, et le
  retirer est l'équivalent exact puisque `7zz` déréférence les liens
  symboliques par défaut.

---

## 2026-10-30 — Lot 2 : les paquets porteurs de patches

Validé par un build RG351P complet (run 41015343552).

### Mis à jour

- `libunwind` 1.6.2 → 1.8.2, `memtester` 4.5.0 → 4.7.1, `SDL2` 2.32.4 →
  2.32.10, `SDL2_ttf` 2.22.0 → 2.24.0, `e2fsprogs` 1.45.3 → 1.47.4, `strace`
  5.10 → 6.15, `MC` 4.8.22 → 4.8.33, et `udevil` 0.4.4 → `arnie97/udevil-ng`,
  l'amont d'origine étant mort en 2015. Chaque répertoire pris entier chez
  upstream, patches compris, et les cinq piles restantes rejouées contre les
  nouvelles sources avant le build.

### Modifié

- **ext4 retrouve `64bit` dans ses options par défaut.** Le patch d'e2fsprogs
  qui l'en retirait, hérité de 351ELEC, disparaît avec la montée de version,
  comme chez upstream. Les systèmes de fichiers créés sont désormais ceux
  qu'upstream livre sur les mêmes appareils.

### Coût

Le build a demandé deux runs. Monter SDL2 invalide le cache de compilation de
tout ce qui l'inclut, et mame — 1 h 50 à lui seul avec un cache chaud — a été
recompilé presque de zéro : le premier run s'est arrêté deux fois sur lui, à
442 paquets sur 459, et le second a fini en 4 h 38 sur le cache accumulé.

---

## 2026-10-28 — Infrastructure

### Corrigé

- **Un timeout de job se lit `cancelled`, pas `failure`.** Le job de repli
  `build` était gardé par `needs.build-warmup.result != 'cancelled'`, écrit
  pour qu'une annulation humaine ne relance pas six heures de build. Mais
  GitHub rapporte aussi l'expiration de `timeout-minutes` avec cette
  conclusion : l'étage warm-up → build ne pouvait pas fonctionner. Un nouvel
  `input` `soft_timeout` arrête désormais la construction depuis l'intérieur
  de l'étape, vingt minutes avant le cap du job, pour que `cancelled`
  retrouve son sens unique.

### Mis à jour

- **Les onze actions GitHub**, dont aucune n'avait bougé depuis la création du
  fork : `checkout` v4→v7, `upload-artifact` v4→v7, `download-artifact` v4→v8,
  `cache` v4→v6, `release-action` v1.13→v1.21, `gh-release` v1→v3,
  `repository-dispatch` v3→v4, `create-pull-request` v5→v8, `debug-action`
  v2→v3, et `docker/login-action` d'un SHA de 2021 (v1.10.0) à v4.7.0, toujours
  pinnée par SHA.

---

## 2026-09 / 2026-10 — Remise en route

### Ajouté

- **CI sur runners hébergés.** Upstream construit sur ses propres machines
  (`runs-on: main`, `runs-on: pr`), absentes d'un fork. `build-main.yaml` a été
  porté sur `ubuntu-latest`, ce qui a demandé de libérer ~100 Go de disque, de
  plafonner le parallélisme à deux paquets simultanés, et de découper le build
  en un étage de préchauffage de cache suivi d'un étage de construction, les
  six heures d'un job ne suffisant pas.
- **`tools/audit-sources` et le workflow `source-audit`**, qui vérifient les
  613 sources sans télécharger les contenus. À lancer depuis un runner cloud :
  `gmplib.org` refuse les plages d'adresses cloud, et un audit local le
  déclarerait sain à tort.
- **`tools/check-patches`**, qui rejoue la pile de patches d'un paquet contre
  la source que son `package.mk` désigne aujourd'hui, cumulativement et avec
  GNU `patch` — deux builds de six heures avaient été perdus l'un après
  l'autre sur un patch devenu caduc.
- **`tools/check-gh-hashes`**, qui revérifie `PKG_SHA256` contre ce que GitHub
  sert aujourd'hui pour chaque archive `/archive/`. Ces tarballs sont générés
  à la demande et leurs octets ne sont pas stables : `flycast2021` a changé de
  somme le jour où libretro a renommé le dépôt.

### Corrigé

- **`scripts/get_archive`** : repli miroir étendu aux versions Savannah, après
  une panne qui rendait plusieurs paquets introuvables.
- **`scripts/get_git`** : arrêt du clonage récursif des sous-modules et refus
  d'honorer leur indication de clone superficiel, qui faisait perdre
  l'historique nécessaire à la construction.

### Mis à jour

- **47 paquets resynchronisés sur upstream** (31 puis 16), le fork ayant
  accumulé un an de retard.

---

## 2026-04 / 2026-05 — Premiers correctifs

Reverts ciblés sur des sources amont devenues inaccessibles, et corrections
individuelles diagnostiquées une par une. Le détail est en §5 de
[`FORK-CHANGES.md`](FORK-CHANGES.md).
