Testaments de guerre de Poilus parisiens (1914-1918)
===
* Elec 32. http://elec.enc.sorbonne.fr/testaments-de-poilus/
* Sources XML de l’édition.

Le 1er août 1914, l’ordre de mobilisation générale est décrété en France. Partant à la guerre sans savoir s’ils en reviendront, de nombreux Parisiens rédigent leurs testaments. Pour ceux d’entre eux morts au front ou de leurs blessures, ces testaments de guerre sont désormais conservés au Minutier central des notaires de Paris.
L’École nationale des chartes et les Archives nationales se sont associées pour donner la première édition scientifique et numérique des testaments des morts pour la France de trois études parisiennes, qui témoignent, dans leur forme même et leur contenu, de l’urgence de la situation et du sentiment bien présent de la mort imminente.

Dépôt DoTS (branche `migration`)
---
* `data/testaments-poilus-edition.xml` : un seul TEI depuis le 4 octobre 2026. Les trois fichiers d’origine (édition, index, introduction) y sont réunis : paratextes, testaments (groupés par année, mois, jour) et index des testateurs et des lieux, sous un seul `refsDecl` (547 unités citables). Le texte et les identifiants sont ceux des trois fichiers.
* `metadata/` : `collection.tsv` et `dots_metadata_mapping.xml` (espace de noms `https://github.com/dots-suite/dots`).
* `transform/testaments-poilus.xsl` : feuille de rendu, version serveur (`$elec-base = '/elec'`, import `../../renderers/hteiml/xsl/tei2html.xsl`). Elle lit le TEI complet par `document('testaments-poilus-edition.xml')` (barre année/mois/jour, renvois entre testaments et index) : ce fichier doit être posé à côté de la feuille au déploiement.
