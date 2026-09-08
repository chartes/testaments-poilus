#!/usr/bin/env python3
"""Inscrit dans l'index les renvois croisés que l'ÉLEC calculait à la volée.

Deux liens de l'édition ÉLEC ne peuvent pas être reconstruits par la feuille de
style sous DoTS :

  - de la notice d'un testateur vers son testament. Le rapprochement se fait
    par le <persName ref="#id"> que porte le testament ; or l'index et
    l'édition sont deux ressources DTS distinctes, et une clef XSLT ne traverse
    pas cette frontière.
  - de la notice d'un lieu vers les testateurs qui y sont morts. Le
    rapprochement se fait à l'intérieur du seul index, mais entre la liste des
    lieux et celle des personnes : servies séparément, une lettre à la fois,
    elles ne se voient plus.

On calcule donc les deux ici, et on les inscrit dans la source sous forme de
<note subtype="generated">, que la feuille sait rendre. Les notes sont
remplacées à chaque exécution ; ne pas les modifier à la main.

    python scripts/generer-liens-index.py
"""
import re, sys
from lxml import etree

TEI = "{http://www.tei-c.org/ns/1.0}"
XID = "{http://www.w3.org/XML/1998/namespace}id"
BASE = "xml/"
EDITION = BASE + "testaments-poilus-edition.xml"
INDEX = BASE + "testaments-poilus-index.xml"
INTRODUCTION = BASE + "testaments-poilus-introduction.xml"


def nom(pers):
    pn = pers.find(TEI + "persName")
    if pn is None:
        return pers.get(XID) or ""
    surname = pn.find(TEI + "surname")
    prenoms = [re.sub(r"\s+", " ", "".join(f.itertext())).strip() for f in pn.findall(TEI + "forename")]
    nf = re.sub(r"\s+", " ", "".join(surname.itertext())).strip() if surname is not None else ""
    return ", ".join(x for x in (nf, " ".join(prenoms)) if x)


def dates(pers):
    n = pers.find(TEI + "birth")
    m = pers.find(TEI + "death")
    a = "".join(n.itertext()).strip() if n is not None else ""
    b = "".join(m.itertext()).strip() if m is not None else ""
    return f" ({a}-{b})" if (a or b) else ""


edition = etree.parse(EDITION).getroot()
arbre = etree.parse(INDEX)
index = arbre.getroot()

# testateur -> testament, par le persName que porte le testament
testament_de = {}
for texte in edition.iter(TEI + "text"):
    wid = texte.get(XID)
    if not wid:
        continue
    for pn in texte.iter(TEI + "persName"):
        ref = pn.get("ref") or ""
        if ref.startswith("#"):
            testament_de.setdefault(ref[1:], wid)

# lieu -> testateurs morts là, par le placeName des notices biographiques
morts_a = {}
for pers in index.iter(TEI + "person"):
    pid = pers.get(XID)
    for pl in pers.iter(TEI + "placeName"):
        ref = pl.get("ref") or ""
        if ref.startswith("#") and pid:
            morts_a.setdefault(ref[1:], []).append(pers)


# Lettre d'appartenance de chaque entrée, prise sur la sous-liste qui la porte.
lettre_de = {}
for liste in list(index.iter(TEI + "listPerson")) + list(index.iter(TEI + "listPlace")):
    lid = liste.get(XID)
    if not lid:
        continue
    for e in list(liste.findall(TEI + "person")) + list(liste.findall(TEI + "place")):
        if e.get(XID):
            lettre_de[e.get(XID)] = lid


def poser(parent, type_, contenu):
    for vieux in parent.findall(TEI + "note"):
        if vieux.get("subtype") == "generated":
            parent.remove(vieux)
    note = etree.SubElement(parent, TEI + "note", type=type_, subtype="generated")
    contenu(note)
    note.tail = "\n               "


n_pers = n_lieux = 0
for pers in index.iter(TEI + "person"):
    wid = testament_de.get(pers.get(XID))
    if not wid:
        continue

    def contenu(note, wid=wid):
        r = etree.SubElement(note, TEI + "ref", type="linkToEdition")
        r.set("target", "#" + wid)
        r.text = wid.replace("will-", "")
    poser(pers, "linkToEdition", contenu)
    n_pers += 1

for lieu in index.iter(TEI + "place"):
    gens = morts_a.get(lieu.get(XID), [])
    if not gens:
        continue

    def contenu(note, gens=gens):
        note.text = "\n                  "
        for p in gens:
            item = etree.SubElement(note, TEI + "ref", type="linkToPersonsIndex")
            item.set("target", "#" + p.get(XID))
            if lettre_de.get(p.get(XID)):
                item.set("corresp", lettre_de[p.get(XID)])
            item.text = nom(p) + dates(p)
            item.tail = "\n                  "
    poser(lieu, "linksToEdition", contenu)
    n_lieux += 1

# Sommaire de la page « Les testaments ». DoTS sert cette unité avec
# excludeFragments : ses 134 <text> enfants, qui sont des unités citables, en
# sont retirés et la page reste vide. Un <note> est admis dans un <group> par
# le modèle TEI et, n'ayant pas d'@xml:id, il traverse le filtrage.
arbre_ed = etree.parse(EDITION)
groupe = arbre_ed.getroot().find(f"{TEI}text/{TEI}group")
for vieux in groupe.findall(TEI + "note"):
    if vieux.get("subtype") == "generated":
        groupe.remove(vieux)
sommaire = etree.Element(TEI + "note", type="summary", subtype="generated")
liste = etree.SubElement(sommaire, TEI + "list", type="summary")
liste.text = "\n            "
n_tt = 0
for texte in groupe.findall(TEI + "text"):
    wid = texte.get(XID)
    if not wid:
        continue
    resume = texte.find(f"{TEI}front/{TEI}div[@type='summary']")
    item = etree.SubElement(liste, TEI + "item")
    r = etree.SubElement(item, TEI + "ref", type="linkToEdition")
    r.set("target", "#" + wid)
    r.text = re.sub(r"\s+", " ", "".join(resume.itertext())).strip() if resume is not None else wid
    item.tail = "\n            "
    n_tt += 1
groupe.insert(0, sommaire)
arbre_ed.write(EDITION, encoding="UTF-8", xml_declaration=True)
sys.stdout.write(f"{n_tt} testaments au sommaire de l'édition\n")

# Barre des lettres, sur le modèle de christofle : précalculée dans chaque
# sous-liste, elle survit à excludeFragments et évite d'avoir à charger l'index
# entier pour passer d'une lettre à l'autre.
n_barres = 0
for tag in ("listPerson", "listPlace"):
    listes = [l for l in index.iter(TEI + tag) if l.get(XID)]
    for liste in listes:
        for vieux in liste.findall(TEI + "note"):
            if vieux.get("subtype") == "generated":
                liste.remove(vieux)
        barre = etree.Element(TEI + "note", type="letter-nav", subtype="generated")
        barre.text = "\n            "
        for autre in listes:
            r = etree.SubElement(barre, TEI + "ref", type="letterNav")
            r.set("target", "#" + autre.get(XID))
            r.set("corresp", autre.get(XID))
            if autre is liste:
                r.set("rend", "current")
            tete = autre.find(TEI + "head")
            r.text = (tete.text or "").strip() if tete is not None else autre.get(XID)[-1]
            r.tail = "\n            "
        tete = liste.find(TEI + "head")
        liste.insert((list(liste).index(tete) + 1) if tete is not None else 0, barre)
        n_barres += 1

# Les renvois du texte vers l'index ne disent pas quelle lettre ouvrir :
# « MRPatey » se range sous P, « pl-076 » sous le nom du lieu. On inscrit donc
# la lettre à côté du renvoi, dans un @corresp, pour que la feuille puisse
# ouvrir la bonne page plutôt que l'index entier.
n_corresp = 0
for fichier in (EDITION, INTRODUCTION):
    a = etree.parse(fichier)
    for el in list(a.getroot().iter(TEI + "persName")) + list(a.getroot().iter(TEI + "placeName")):
        ref = el.get("ref") or ""
        if ref.startswith("#") and lettre_de.get(ref[1:]):
            el.set("corresp", lettre_de[ref[1:]])
            n_corresp += 1
    for el in a.getroot().iter(TEI + "ref"):
        cible = (el.get("target") or "")[1:]
        if lettre_de.get(cible):
            el.set("corresp", lettre_de[cible])
            n_corresp += 1
    a.write(fichier, encoding="UTF-8", xml_declaration=True)

arbre.write(INDEX, encoding="UTF-8", xml_declaration=True)
sys.stdout.write(f"{n_barres} barres de lettres\n")
sys.stdout.write(f"{n_pers} testateurs reliés à leur testament\n")
sys.stdout.write(f"{n_lieux} lieux reliés à leurs testateurs "
                 f"({sum(len(v) for v in morts_a.values())} renvois)\n")
