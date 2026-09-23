<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/><!-- autopilote 2026-09-11 : sinon DoTS-vue colle les mots (condense) -->

  <!-- Certaines métadonnées DTS (dct:title/schema:type) peuvent être reprises
       par le mode="a" générique lorsqu'un fragment d'index les cite. Elles ne
       sont pas des balises éditoriales à afficher en rouge : le titre se rend
       comme texte, le type technique se tait. -->
  <xsl:template match="*[local-name() = 'title']" mode="a" priority="20">
    <span class="metadata-title"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="*[local-name() = 'type']" mode="a" priority="20"/>

  <!--
    Page de garde a la racine (meme correctif que chroniqueslatines.xsl) :
    au rendu du document entier (currentLevel=0), le teiHeader (page de garde) est
    present ; on neutralise alors le corps <text> (le <group> des testaments) pour
    n'afficher que la garde. Les fragments (un testament) arrivent dans un
    <dts:wrapper> SANS teiHeader : ils ne sont pas touches.
    Priorite 15 pour dominer proprement les templates priorite 10 de ce fichier.
  -->
  <!-- L'index complet est une page d'accueil d'index : deux barres, pas les
       notices. -->
  <xsl:template match="tei:TEI[@xml:id = 'testaments-poilus-index']/tei:text" priority="20">
    <section class="tp-index" style="max-width:62rem;margin:0 auto;color:#222;font-family:Georgia,'Times New Roman',serif;line-height:1.55">
      <xsl:apply-templates select=".//tei:body/tei:div/tei:listPerson[tei:listPerson] | .//tei:body/tei:div/tei:listPlace[tei:listPlace]"/>
    </section>
  </xsl:template>

  <!-- Cas 1 : rendu du TEI complet (racine) : masquer le corps <text>. -->
  <xsl:template match="tei:TEI[tei:teiHeader][@xml:id != 'testaments-poilus-index']/tei:text" priority="15"/>

  <!-- Cas 2 : contenu servi dans un <dts:wrapper> embarquant le teiHeader
       (rendu racine via excludeFragments) : ne produire que la page de garde. -->
  <xsl:template match="*[local-name() = 'wrapper'][tei:teiHeader]" priority="20">
    <xsl:choose>
      <!-- Rendu racine via excludeFragments : le wrapper contient le <text>
           complet. On conserve uniquement la page de garde issue du teiHeader. -->
      <xsl:when test="tei:text">
        <xsl:apply-templates select="tei:teiHeader"/>
      </xsl:when>
      <!-- Fragment DTS auquel DoTS a adjoint le teiHeader : le contenu citable
           est directement dans le wrapper (div/group/etc.). Ne pas le masquer. -->
      <xsl:otherwise>
        <xsl:apply-templates select="node()[not(self::tei:teiHeader)]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ====================================================================
       D43 (2026-09-14) — corps des notes d'une unité servie sans son <text>
       ====================================================================
       DÉFAUT : `hteiml/xsl/tei2html.xsl` l. 212-222 n'appelle le modèle nommé
       « footnotes » que dans le modèle de `tei:text` (et seulement si ce
       <text> n'a pas de <group>). Les pages d'introduction de ce corpus sont
       servies comme <dts:wrapper><div xml:id="projet-partie-1"> : aucun
       tei:text, donc aucun appel à « footnotes ». Le lecteur voyait les
       appels (#note1…) sans cible et le texte des notes était perdu —
       mesuré sur projet-partie-1 (1 note), cite (3), et leurs parents
       projet (1) et mentionsLegales (3).

       POURQUOI ICI ET NON DANS LA FEUILLE COMMUNE : 23 corpus importent
       `hteiml/xsl/tei2html.xsl` ; l'utilisateur a tranché le 2026-09-14
       (« fix ça dans les surcharges xsl »). La correction vit donc dans la
       feuille de chaque corpus concerné.

       PAS DE DOUBLE — trois garde-fous dans le motif :
        - not(.//tei:text) : dès qu'un <text> est là (un testament, une année,
          la racine), c'est le modèle tei:text — celui de hteiml ou celui de
          cette feuille, l. 60, qui pose déjà son bloc d'apparat — qui s'en
          charge ; on ne double donc jamais ;
        - tei:div : les notices d'index arrivent dans un <person> ou un
          <listPerson>, jamais dans un <div> ; elles gardent leur rendu
          dédié (modes tp-bio / tp-letter-nav) ;
        - not(tei:teiHeader) : le rendu racine est traité l. 42.

       FIDÉLITÉ DU CONTEXTE : le <xsl:for-each select="/"> n'est pas
       décoratif. Dans la branche « notes par page » de « footnotes »
       (tei2html.xsl l. 2203) $notes1 vaut `.//tei:note[…]`, relatif au NŒUD
       COURANT et non à $cont : hteiml appelle donc toujours « footnotes »
       depuis la racine, conteneur passé en paramètre. On reproduit ce couple
       à l'identique. -->
  <xsl:template match="*[local-name() = 'wrapper'][tei:div][not(.//tei:text)][not(tei:teiHeader)]" priority="12">
    <xsl:apply-imports/>
    <xsl:variable name="notes-cont" select="."/>
    <xsl:for-each select="/">
      <xsl:call-template name="footnotes">
        <xsl:with-param name="cont" select="$notes-cont"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Les <note> de ce corpus dont le @type est STRUCTUREL ne sont pas des
       notes de bas de page : elles ont déjà leur rendu propre (notice
       biographique, barre de lettres, renvoi vers l'édition). Le mode « fn »
       de hteiml ne filtre pas sur @type ; sans cette règle, un appel à
       « footnotes » sur un conteneur d'index en recopierait le texte en bas
       de page. Garde-fou, en complément du motif ci-dessus. -->
  <xsl:template match="tei:note[@type = 'biography' or @type = 'letter-nav'
                              or @type = 'linkToEdition' or @type = 'linksToEdition']"
                mode="fn" priority="20"/>

  <!-- Fragment testamentaire DTS : le refId pointe sur un <text xml:id="will-…">
       servi directement dans le wrapper. La page de garde masque les <text> du
       TEI complet, mais ici il faut rendre le testament lui-même. -->
  <xsl:template match="*[local-name() = 'wrapper']/tei:text[@xml:id]" priority="30">
    <article id="{@xml:id}" class="testament">
      <!-- 2026-09-14 (agentwill) : barre annees / mois / jours / testament de
           l'ancien site (nav#specific-menu-wills), en tete comme chez lui. Elle
           precede les <input> : ceux-ci restent enfants directs de l'article et
           precedent toujours le contenu que leurs regles `~` commandent. -->
      <xsl:call-template name="tp-will-nav"/>
      <!-- D14e-1 (2026-09-12) : bascule Transcription / Édition de l'ancien site
           (utils.js, displaySection). Boutons radio + CSS : aucun script ne
           s'execute dans un fragment DoTS-vue. Defaut = Transcription, comme
           l'ancien site (#edition y etait en display:none au chargement).
           Les <input> doivent rester enfants directs de l'article : les regles
           CSS reposent sur `.tp-mode-*:checked ~ * .tp-tr`. -->
      <xsl:call-template name="tp-mode-bar"/>
      <!-- D14e-1 : colonne de fac-similes de l'ancien site (section#facsimile +
           loadImageSectionBis) : une image a la fois, choisie dans la liste des
           pages. Boutons radio + CSS. -->
      <xsl:call-template name="tp-facs-gallery"/>
      <xsl:apply-templates/>
      <!-- 2026-09-11 (autopilote, B8b 3) : ce modèle remplace le tei:text de hteiml, qui appelait « footnotes » ;
           les appels d'apparat (#app1…) restaient donc sans note. Bloc d'apparat de hteiml (note-inline) rétabli :
           même nœud, même modèle « id », donc même identifiant que l'appel. Sauvegarde *.bak_b8b3_20260911. -->
      <xsl:variable name="tp-apps" select=".//tei:app[not(@rend = 'table')]"/>
      <!-- 2026-09-13 : les notes IMBRIQUÉES dans une variante d'apparat manquaient au bloc.
           Deux testaments (will-030, will-036) portent un <note> à l'intérieur d'un
           <add place="marginLeft"> lui-même dans <lem><choice><orig> : le HTEIML en produit
           bien l'appel « 1 », mais la liste ci-dessous ne rassemblait que les <app>, si bien
           que l'appel pointait vers une ancre inexistante (relevé par verify_corpus,
           notes_sans_cible=2 sur 135 unités). On ajoute donc les notes descendantes d'un <app>
           qui n'en sont pas l'enfant direct — celles-là seules sont orphelines, la note fille
           de l'<app> étant déjà rendue avec lui. -->
      <xsl:variable name="tp-notes-app"
                    select=".//tei:app[not(@rend = 'table')]//tei:note[not(parent::tei:app)]"/>
      <xsl:if test="$tp-apps or $tp-notes-app">
        <section class="footnotes tp-apparat">
          <p class="apparatus">
            <xsl:for-each select="$tp-notes-app">
              <xsl:call-template name="note-inline"/>
            </xsl:for-each>
            <xsl:for-each select="$tp-apps">
              <xsl:call-template name="note-inline"/>
            </xsl:for-each>
          </p>
        </section>
      </xsl:if>
    </article>
  </xsl:template>

  <!-- 2026-09-11 (autopilote, B8b 3) : appel de note <ref type="note" xml:id="will-010-001" target="#will-010-footnote001"/>.
       Le noteref de hteiml calcule la cible depuis @target mais écrit href="#{id de l'appel}" (cible inexistante).
       On garde son rendu et on corrige href (note visée par @target) et id (= @xml:id, que vise le @target de la note). -->
  <xsl:template match="tei:ref[@type = 'note'][@xml:id][starts-with(normalize-space(@target), '#')]" priority="10">
    <xsl:variable name="cible" select="substring-after(substring-before(concat(normalize-space(@target), ' '), ' '), '#')"/>
    <xsl:variable name="appel-id" select="string(@xml:id)"/>
    <xsl:variable name="appel">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:for-each select="$appel/node()">
      <xsl:choose>
        <xsl:when test="self::*[local-name() = 'a'][contains(@class, 'noteref')]">
          <xsl:copy>
            <xsl:copy-of select="@*[not(local-name() = 'href' or local-name() = 'id')]"/>
            <xsl:attribute name="href"><xsl:value-of select="concat('#', $cible)"/></xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="$appel-id"/></xsl:attribute>
            <xsl:copy-of select="node()"/>
          </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- ===================================================================
       TESTAMENTS DE POILUS — index des testateurs et des lieux de décès

       La générique ne connaît pas <person>/<place>/<listPerson>/<listPlace>
       et affiche tout l'index en rouge (balises non gérées). On restitue ici
       la présentation de l'édition Élec :
         - testateur : nom en vedette, dates, notice biographique, bibliographie
         - lieu de décès : nom + localisation + Geonames + testateurs morts là
           (croisement via les <placeName ref="#pl-…"> des notices biographiques)
       =================================================================== -->

  <!-- clef lieu -> testateurs qui y sont morts -->
  <xsl:key name="tp-deces" match="tei:person" use=".//tei:placeName/@ref"/>

  <xsl:template match="tei:div[@type = 'index']" priority="9">
    <section class="tp-index" style="max-width:62rem;margin:0 auto;color:#222;font-family:Georgia,'Times New Roman',serif;line-height:1.55">
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- ===================================================================
       2026-09-14 (agent_tp) — « A B C D dans la toc et pas dans la page ».
       Demande de l'utilisateur : un comportement homogène entre le sommaire
       de gauche et la page, sans doublon. Les 19 lettres de chaque index
       SONT déjà des unités citables de DoTS (navigation?resource=
       testaments-poilus-index&down=-1 : 38 membres, mesuré) et le sommaire
       de gauche les liste toutes. La barre « A | B | C … » répétée dans la
       page était donc le doublon : elle est retirée des TROIS chemins de
       rendu (page d'une lettre, section d'index, index complet).
       Le <note type="letter-nav"> reste dans le TEI, intact : il n'est plus
       rendu, c'est tout.
       CE QUI N'EST PAS RETIRÉ : la liste des noms (nav.tp-entry-nav). Le
       sommaire ne la contient PAS — les personnes et les lieux ne sont pas
       des unités citables. La retirer ferait disparaître un contenu sans
       remplacement. Voir le rapport : cela demande un niveau « testateur » /
       « lieu » dans le refsDecl, donc une écriture en base.
       =================================================================== -->
  <xsl:template match="tei:note[@type = 'letter-nav']" priority="11"/>

  <xsl:template match="tei:listPerson" priority="9">
    <section class="tp-index-persons">
      <h2 style="font-size:1.25rem;color:#a73136;border-bottom:1px solid #d7d1ca;padding-bottom:.3rem;margin:0 0 1rem">Index des testateurs</h2>
      <xsl:apply-templates select="tei:person"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:listPlace" priority="9">
    <section class="tp-index-places">
      <h2 style="font-size:1.25rem;color:#a73136;border-bottom:1px solid #d7d1ca;padding-bottom:.3rem;margin:2rem 0 1rem">Index des lieux de décès</h2>
      <xsl:apply-templates select="tei:place"/>
    </section>
  </xsl:template>

  <!--
    Sous-listes par lettre (<listPerson xml:id="testateurs-H">, <listPlace
    xml:id="lieux-H">). Elles ne sont pas des passages DTS : un lien
    ?refId=testateurs-H renvoyait à la racine de l'application. On les rend
    dans la page d'index avec leur id, et les barres de lettres y pointent en
    ancre locale (#testateurs-H), que DoTS-vue fait défiler.
  -->
  <xsl:template match="tei:listPerson[tei:listPerson] | tei:listPlace[tei:listPlace]" priority="10">
    <section class="{if (self::tei:listPerson) then 'tp-index-persons' else 'tp-index-places'}">
      <h2 style="font-size:1.25rem;color:#a73136;border-bottom:1px solid #d7d1ca;padding-bottom:.3rem;margin:2rem 0 1rem">
        <xsl:value-of select="if (self::tei:listPerson) then 'Index des testateurs' else 'Index des lieux de décès'"/>
      </h2>
      <xsl:apply-templates select="tei:listPerson | tei:listPlace"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:listPerson[@xml:id][not(tei:listPerson)] | tei:listPlace[@xml:id][not(tei:listPlace)]" priority="10">
    <section id="{@xml:id}" class="tp-index-letter" style="scroll-margin-top:90px">
      <span class="tp-anchor" id="tp-top-{@xml:id}"></span>
      <h3 style="font-size:1.1rem;color:#a73136;margin:1.5rem 0 .5rem"><xsl:value-of select="normalize-space(tei:head)"/></h3>
      <!-- 2026-09-14 (agent_tp) : la barre « A | B | C … » de la lettre affichée
           seule est retirée — les 19 lettres sont dans le sommaire de gauche. -->
      <!-- 2026-09-14 (D28) : le sommaire des noms de la lettre est RETIRÉ de la page.
           C'était le second doublon signalé par l'utilisateur (« on a pas besoin d'avoir la
           liste des noms et d'avoir a b c d, je veux tout dans le toc »). Il ne pouvait pas
           l'être tant que le sommaire de gauche ne portait que les lettres : ce jour, deux
           niveaux `testateur` et `lieu` ont été ajoutés au refsDecl et le registre de
           fragments reconstruit (38 → 270 unités), si bien que les 128 testateurs et les
           104 lieux sont désormais des unités citables, listées sous leur lettre dans le
           sommaire. La page d'une lettre garde ses NOTICES — c'est le contenu — et perd la
           liste qui les répétait.
           Le modèle qui la produisait est conservé plus bas, inutilisé, pour un retour en
           arrière en une ligne. -->
      <xsl:apply-templates select="tei:person | tei:place"/>
      <!-- « Top » de l'ancien site (p#backToTop) -->
      <xsl:if test="tei:person | tei:place">
        <p class="tp-backtotop"><a href="#tp-top-{@xml:id}">Haut de page</a></p>
      </xsl:if>
    </section>
  </xsl:template>

  <!-- 2026-09-14 (agent_tp) : PLUS APPELÉ. Conservé tel quel pour pouvoir
       rétablir la barre en une ligne (un apply-templates mode="tp-letter-nav")
       si la décision était revue. Aucun chemin de rendu ne l'invoque. -->
  <xsl:template match="tei:note[@type = 'letter-nav']" mode="tp-letter-nav">
    <nav class="tp-letter-nav" style="margin:.2rem 0 1rem;font-size:1rem">
      <xsl:for-each select="tei:ref[@type = 'letterNav']">
        <xsl:if test="position() &gt; 1">
          <span style="color:#777"> | </span>
        </xsl:if>
        <!-- D14e-1 (2026-09-12) : sur l'ancien site, chaque lettre etait une page
             (lettre-B.html). Les lettres sont des unites citables de DoTS
             (?refId=testateurs-B, verifie : HTTP 200) : l'ancre locale #testateurs-B
             etait morte des qu'une seule lettre etait servie (18 liens morts sur 19
             par page-lettre). On pointe donc la route de l'unite. -->
        <a class="tp-letter-link" href="/testaments-poilus/document/testaments-poilus-index?refId={normalize-space(@corresp)}" style="color:#a73136;text-decoration:none">
          <xsl:if test="@rend = 'current'">
            <xsl:attribute name="style">color:#a73136;text-decoration:none;font-weight:bold</xsl:attribute>
          </xsl:if>
          <xsl:value-of select="normalize-space(.)"/>
        </a>
      </xsl:for-each>
    </nav>
  </xsl:template>

  <!-- testateur -->
  <xsl:template match="tei:person" priority="9">
    <article id="{@xml:id}" class="index-entry" style="border-bottom:1px dotted #e0dcd5;padding:.6rem 0;margin:0">
      <h4 class="persName-Entry" style="margin:0 0 .3rem;font-size:1.05rem">
        <xsl:apply-templates select="tei:persName" mode="tp-name"/>
        <xsl:if test="tei:birth or tei:death">
          <span class="dates" style="font-weight:normal;color:#555">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="normalize-space(tei:birth)"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="normalize-space(tei:death)"/>
            <xsl:text>)</xsl:text>
          </span>
        </xsl:if>
      </h4>
      <xsl:apply-templates select="tei:note[@type = 'biography']" mode="tp-bio"/>
      <xsl:apply-templates select="tei:bibl" mode="tp-bibl"/>
    </article>
  </xsl:template>

  <!-- nom en vedette : Surname, Forename(s) -->
  <xsl:template match="tei:persName" mode="tp-name">
    <span class="surname" style="font-variant:small-caps;font-weight:bold"><xsl:value-of select="normalize-space(tei:surname)"/></span>
    <xsl:if test="tei:forename">
      <xsl:text>, </xsl:text>
      <span class="forename">
        <xsl:for-each select="tei:forename">
          <xsl:if test="position() &gt; 1"><xsl:text> </xsl:text></xsl:if>
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:for-each>
      </span>
    </xsl:if>
    <xsl:if test="tei:nameLink"><xsl:text> </xsl:text><xsl:value-of select="normalize-space(tei:nameLink)"/></xsl:if>
  </xsl:template>

  <!-- notice biographique -->
  <xsl:template match="tei:note[@type = 'biography']" mode="tp-bio">
    <div class="bio" style="font-size:.96rem;color:#333;margin:0 0 .3rem">
      <xsl:apply-templates mode="tp-inline"/>
    </div>
  </xsl:template>

  <!-- bibliographie -->
  <xsl:template match="tei:bibl" mode="tp-bibl">
    <p class="bibl" style="font-size:.88rem;color:#666;margin:.2rem 0 0">
      <xsl:apply-templates mode="tp-inline"/>
    </p>
  </xsl:template>

  <!-- lieu de deces -->
  <xsl:template match="tei:place" priority="9">
    <article id="{@xml:id}" class="index-entry" style="border-bottom:1px dotted #e0dcd5;padding:.6rem 0;margin:0">
      <h4 class="placeName-Entry" style="margin:0 0 .3rem;font-size:1.05rem">
        <span class="placeName-entry">
          <xsl:value-of select="normalize-space(tei:placeName/tei:settlement | tei:placeName)"/>
          <xsl:variable name="dep" select="tei:location[not(@type)]/tei:district[@type = 'departement']"/>
          <xsl:if test="$dep">
            <span class="displayedLocation" style="font-weight:normal;color:#555"> (<span class="departement"><xsl:value-of select="normalize-space($dep)"/></span>)</span>
          </xsl:if>
        </span>
      </h4>
      <xsl:variable name="geo" select="tei:idno[@type = 'geonamesURI']"/>
      <xsl:if test="$geo">
        <p class="geonamesURI" style="font-size:.85rem;margin:.15rem 0">
          <span style="color:#666">Dans la base Geonames&#160;: </span>
          <a class="externalLink" href="{normalize-space($geo)}" target="_blank" style="color:#a73136"><xsl:value-of select="normalize-space($geo)"/></a>
        </p>
      </xsl:if>
      <!-- testateurs morts à ce lieu (croisement via les notices biographiques) -->
      <xsl:variable name="morts" select="key('tp-deces', concat('#', @xml:id))"/>
      <xsl:if test="$morts">
        <section class="linksToEdition" style="font-size:.9rem">
          <ul style="margin:.2rem 0;padding-left:1.2rem">
            <xsl:for-each select="$morts">
              <li>Lieu de décès de <a class="internalLink" href="#{@xml:id}" style="color:#a73136;text-decoration:none;border-bottom:1px dotted #a73136">
                <xsl:apply-templates select="tei:persName" mode="tp-name"/>
                <xsl:if test="tei:birth or tei:death"><xsl:text> (</xsl:text><xsl:value-of select="normalize-space(tei:birth)"/><xsl:text>-</xsl:text><xsl:value-of select="normalize-space(tei:death)"/><xsl:text>)</xsl:text></xsl:if>
              </a></li>
            </xsl:for-each>
          </ul>
        </section>
      </xsl:if>
    </article>
  </xsl:template>

  <!-- contenu inline sur (bio, bibl) : aucune balise rouge -->
  <xsl:template match="tei:p" mode="tp-inline"><p style="margin:.25rem 0"><xsl:apply-templates mode="tp-inline"/></p></xsl:template>
  <xsl:template match="tei:hi[@rend = 'sup' or @rend = 'super']" mode="tp-inline"><sup><xsl:apply-templates mode="tp-inline"/></sup></xsl:template>
  <xsl:template match="tei:hi" mode="tp-inline"><span><xsl:apply-templates mode="tp-inline"/></span></xsl:template>
  <xsl:template match="tei:placeName" mode="tp-inline">
    <xsl:choose>
      <!-- D14e-1 : l'ancre locale #pl-039 est morte quand une seule lettre est servie
           (l'entree visee est dans une autre unite). @corresp donne l'unite-lettre. -->
      <xsl:when test="@ref[starts-with(., '#')]">
        <a class="linkToIndex" style="color:inherit;border-bottom:1px dotted #a73136;text-decoration:none">
          <xsl:attribute name="href">
            <xsl:text>/testaments-poilus/document/testaments-poilus-index</xsl:text>
            <xsl:if test="normalize-space(@corresp) != ''"><xsl:value-of select="concat('?refId=', normalize-space(@corresp))"/></xsl:if>
            <xsl:value-of select="@ref"/>
          </xsl:attribute>
          <xsl:apply-templates mode="tp-inline"/>
        </a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates mode="tp-inline"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:ref" mode="tp-inline">
    <a class="externalLink" href="{@target}" target="_blank" style="color:#a73136"><xsl:apply-templates mode="tp-inline"/></a>
  </xsl:template>
  <xsl:template match="tei:title" mode="tp-inline"><span style="font-style:italic"><xsl:apply-templates mode="tp-inline"/></span></xsl:template>
  <xsl:template match="tei:author" mode="tp-inline"><xsl:apply-templates mode="tp-inline"/></xsl:template>
  <xsl:template match="text()" mode="tp-inline"><xsl:value-of select="."/></xsl:template>
  <xsl:template match="*" mode="tp-inline"><xsl:apply-templates mode="tp-inline"/></xsl:template>

  <!-- ================================================================
       Re-branchement du comportement historique ELEC : facsimilés de folio.
       La base hteiml (tei:pb) n'émet rien quand @n est vide ; or les
       <pb facs="../images/FRAN_xxx.jpg"/> de poilus n'ont que @facs.
       On restitue donc l'image (source média ELEC).
       Sauvegarde : *.bak_before_rebranchements_*
       ================================================================ -->
  <!-- D14e-1 (2026-09-12) : dans le texte, l'ancien site ne mettait pas l'image
       mais le repere de page « [Première page] » (span.pb, crochets en CSS) ;
       les images vivaient dans la colonne #facsimile, une a la fois
       (tp-facs-gallery ci-dessous). Sauvegarde : *.bak_d14e1_20260912. -->
  <!-- 2026-09-14 (agentwill) : le modele ne visait que les <pb @facs>, si bien que
       les 76 <pb> SANS image (whitePage_notDigitized, pageWithExtraNotes_notDigitized)
       ne produisaient rien du tout — ni leur repere de page, ni la mention
       editoriale qui va avec. L'ELEC les rendait : releve sur ses 134 pages,
       « (Page blanche, non numerisee) » y parait 150 fois (75 <pb>, rendus deux
       fois, transcription et edition). On rend donc TOUS les <pb>. -->
  <xsl:template match="tei:pb" priority="10">
    <span class="tp-pb"><xsl:call-template name="tp-page-label"/></span>
    <xsl:call-template name="tp-page-comment"/>
  </xsl:template>

  <!-- will-018, seul cas : le testament est illisible et n'a pas ete transcrit
       (`div type="will" subtype="edited-from-notary-transcription"`, la seule du
       corpus) ; l'ELEC n'y met aucun repere de page dans le fil du texte — rien
       ne serait numerote — mais garde bien ses quatre images dans la colonne de
       fac-similes. On ne tait donc que le fil du texte. -->
  <xsl:template match="tei:pb[ancestor::tei:div[@subtype = 'edited-from-notary-transcription']]" priority="12"/>

  <!-- Mention editoriale attachee au @type d'un <pb>, mot pour mot celle de
       l'ELEC (relevee sur les 134 pages capturees ; les comptes divises par
       deux collent un a un aux @type du TEI : whitePage_notDigitized 75,
       *_extraNotes 73, envelope-verso_seals 7, pageWithExtraNotes_notDigitized 2,
       codicil 1). L'ordre des tests compte : « _notDigitized » avant sa racine. -->
  <xsl:template name="tp-page-comment">
    <xsl:variable name="t" select="normalize-space(@type)"/>
    <xsl:variable name="txt">
      <xsl:choose>
        <xsl:when test="$t = 'whitePage_notDigitized'">(Page blanche, non numérisée)</xsl:when>
        <xsl:when test="$t = 'whitePage'">(Page blanche)</xsl:when>
        <xsl:when test="$t = 'pageWithExtraNotes_notDigitized'">(Page non numérisée, portant des mentions hors teneur postérieures au testament, non éditées)</xsl:when>
        <!-- « xtraNotes » et non « extraNotes » : le TEI ecrit tantot
             `pageWithExtraNotes` (E majuscule), tantot `envelope_extraNotes`. -->
        <xsl:when test="contains($t, 'xtraNotes')">(Mentions hors teneur postérieures au testament, non éditées)</xsl:when>
        <xsl:when test="contains($t, 'seals')">(Cachets)</xsl:when>
        <xsl:when test="$t = 'codicil'">(Codicille)</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string($txt) != ''">
      <span class="editorialComment tp-pb-comment"><xsl:value-of select="$txt"/></span>
    </xsl:if>
  </xsl:template>

  <!-- Libelle de page de l'ancien site : « Première page » … « Septième page »,
       « Enveloppe », « Verso de l’enveloppe » (releve sur testament-001, -003,
       -121, -124 le 2026-09-12). L'ordinal ne compte que les pages du testament,
       pas les enveloppes.
       CORRECTION 2026-09-14 (agentwill) : l'ordinal comptait les seuls <pb @facs>,
       ce qui decalait tout des qu'une page sans image precedait une page avec image.
       Mesure sur l'ELEC (testament-055) : ses reperes sont « Premiere / Deuxieme /
       Troisieme / Quatrieme page » puis « Enveloppe », la Quatrieme etant justement
       une page blanche non numerisee, donc SANS @facs. L'ordinal porte donc sur TOUS
       les <pb> hors enveloppe. -->
  <xsl:template name="tp-page-label">
    <xsl:choose>
      <xsl:when test="starts-with(@type, 'envelope-verso')">Verso de l’enveloppe</xsl:when>
      <xsl:when test="starts-with(@type, 'envelope')">Enveloppe</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="n">
          <!-- `from` repart a chaque sous-document : will-045 reunit une lettre
               (will-045-A) et un testament (will-045-B), et l'ELEC y recommence
               bien a « Premiere page » pour le second. C'est le seul cas du
               corpus (2 div[@xml:id] sous body, tous deux dans will-045). -->
          <xsl:number count="tei:pb[not(starts-with(@type, 'envelope'))]" level="any" from="tei:text | tei:div[@xml:id]"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$n = '1'">Première page</xsl:when>
          <xsl:when test="$n = '2'">Deuxième page</xsl:when>
          <xsl:when test="$n = '3'">Troisième page</xsl:when>
          <xsl:when test="$n = '4'">Quatrième page</xsl:when>
          <xsl:when test="$n = '5'">Cinquième page</xsl:when>
          <xsl:when test="$n = '6'">Sixième page</xsl:when>
          <xsl:when test="$n = '7'">Septième page</xsl:when>
          <xsl:when test="$n = '8'">Huitième page</xsl:when>
          <xsl:otherwise>Page <xsl:value-of select="$n"/></xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Nom de fichier de la vignette locale.
       E2 (2026-09-12) : il y en a maintenant 312, une par image citee en @facs.
       Il n'y en avait que 291 : les 21 autres (FRAN_0045_00281, 00383, 00422-00424,
       00499, 00596, 00668, 00722, 00732, 00884, 01014, 01140, 01239, 01460, 01461,
       01478, 01497, 01498, 01517, 01518) n'avaient aucune vignette et laissaient
       autant d'images cassees ; elles ont ete derivees des sources a 400 px de large,
       largeur dominante relevee sur les 291 existantes
       (dots-autopilot/scripts/e2_vignettes_manquantes.py). -->
  <xsl:template name="tp-facs-src">
    <xsl:variable name="fn"><xsl:call-template name="tp-facs-nom"/></xsl:variable>
    <xsl:value-of select="concat('/testaments-poilus/images/vignettes/', substring-before($fn, '.jpg'), '_ptt.jpg')"/>
  </xsl:template>

  <!-- Image PLEINE TAILLE locale. E2 (2026-09-12) : les 312 sources citees ont ete
       rapatriees depuis l'ancien site avant sa fermeture
       (media/testaments-de-poilus/images/sources/, 312/312, 106,8 Mo) ; elles font
       1 500 px de large pour 2 000 a 17 250 px de haut. -->
  <xsl:template name="tp-facs-src-full">
    <xsl:variable name="fn"><xsl:call-template name="tp-facs-nom"/></xsl:variable>
    <xsl:value-of select="concat('/testaments-poilus/images/sources/', $fn)"/>
  </xsl:template>

  <!-- Nom de fichier nu, quel que soit le prefixe porte par @facs. -->
  <xsl:template name="tp-facs-nom">
    <xsl:choose>
      <xsl:when test="contains(@facs, '../images/')"><xsl:value-of select="substring-after(@facs, '../images/')"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="tokenize(@facs, '/')[last()]"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Colonne de fac-similes : liste des pages (labels) + une seule image
       affichee, celle du bouton radio coche (defaut : la premiere), soit le
       comportement de loadImageSectionBis. La loupe elevateZoom de l'ancien
       site exigeait les images pleine taille (media/.../sources/), absentes de
       la machine : non reproduite (decision a proposer). -->
  <xsl:template name="tp-facs-gallery">
    <xsl:variable name="w" select="@xml:id"/>
    <xsl:variable name="ref" select="normalize-space(tei:front/tei:div[@type = 'reference'])"/>
    <xsl:variable name="pbs" select=".//tei:pb[@facs]"/>
    <xsl:if test="$pbs">
      <section class="tp-facs">
        <xsl:for-each select="$pbs">
          <input type="radio" class="tp-facs-r tp-facs-r{position()}" name="tp-facs-{$w}" id="tp-facs-{$w}-{position()}">
            <xsl:if test="position() = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
          </input>
        </xsl:for-each>
        <nav class="tp-facs-nav">
          <xsl:for-each select="$pbs">
            <xsl:if test="position() &gt; 1"><span class="tp-facs-sep"> | </span></xsl:if>
            <label class="tp-facs-lab tp-facs-l{position()}" for="tp-facs-{$w}-{position()}">
              <xsl:attribute name="title">
                <xsl:if test="$ref != ''"><xsl:value-of select="concat('Archives nationales, ', $ref, ' : ')"/></xsl:if>
                <xsl:call-template name="tp-page-label"/>
              </xsl:attribute>
              <xsl:call-template name="tp-page-label"/>
            </label>
          </xsl:for-each>
        </nav>
        <div class="tp-facs-imgs">
          <xsl:for-each select="$pbs">
            <figure class="tp-facs-fig tp-facs-f{position()}">
              <!-- E2 (2026-09-12) : agrandissement DANS la page, sans script, par
                   <details> (meme motif que christofle-facsimile et sgdp-figure).
                   L'ancien site ouvrait la loupe elevateZoom sur l'image pleine
                   taille de media/.../sources/ ; ces 312 sources sont desormais en
                   local, la loupe au survol reste hors de portee sans script mais
                   l'image pleine taille est accessible au clic.
                   ATTENTION : html.css l. 48-51 masque `details > *` sauf
                   `details.minus` — les regles de contournement sont dans la CSS du
                   corpus (testaments-poilus.customCss.css, bloc E2). -->
              <details class="tp-facs-zoom">
                <summary title="Voir l'image en pleine taille">
                  <img class="tp-facsimile" alt="">
                    <xsl:attribute name="src"><xsl:call-template name="tp-facs-src"/></xsl:attribute>
                    <xsl:attribute name="alt"><xsl:call-template name="tp-page-label"/></xsl:attribute>
                    <xsl:attribute name="loading">lazy</xsl:attribute>
                  </img>
                  <span class="tp-facs-ouvrir">Voir en pleine taille</span>
                  <span class="tp-facs-fermer">Revenir a la vignette</span>
                </summary>
                <img class="tp-facs-full" alt="">
                  <xsl:attribute name="src"><xsl:call-template name="tp-facs-src-full"/></xsl:attribute>
                  <xsl:attribute name="alt"><xsl:call-template name="tp-page-label"/></xsl:attribute>
                  <xsl:attribute name="loading">lazy</xsl:attribute>
                </img>
              </details>
              <figcaption>
                <xsl:if test="$ref != ''">
                  <span class="tp-facs-ref"><xsl:value-of select="concat('Archives nationales, ', $ref)"/></span>
                  <br/>
                </xsl:if>
                <span class="tp-facs-page"><xsl:call-template name="tp-page-label"/> du testament</span>
              </figcaption>
            </figure>
          </xsl:for-each>
        </div>
      </section>
    </xsl:if>
  </xsl:template>

  <!-- ===================================================================
       D14e-1 — bascule Transcription / Édition (ancien displaySection)

       L'ancien site rendait DEUX fois le testament : #transcription (formes
       du document : orig, abbr, ratures, lignes du manuscrit, apparat en
       bulle) et #edition (formes normalisees : reg, expan, corr, texte
       restitue, pas de retour de ligne ni d'apparat). Le rendu generique de
       hteiml ne garde qu'une version (reg/expan/corr) et met l'autre dans
       @title : aucune bascule n'etait donc possible. On emet les deux, dans
       .tp-tr et .tp-ed, que le CSS montre ou masque selon le bouton radio.
       =================================================================== -->
  <!-- ===================================================================
       2026-09-14 (agentwill) — BARRE DE NAVIGATION DES TESTAMENTS
       (nav#specific-menu-wills de l'ELEC : #years-list, #months-list,
       #days-list, #wills-list ; 134/134 de ses pages la portent, nous 0).
       C'est le bloc que l'utilisateur reclame : « on avait une page avec les
       minutes et ca marchait bien » — la page de christofle, dont la barre
       mois/jours est le meme dispositif.

       Christofle a ces listes PRE-CALCULEES DANS SON TEI (build_indexes.py les
       ecrit dans chaque minute). Ici on n'ecrit pas dans la base : DoTS servant
       chaque testament SEUL dans un <dts:wrapper>, sans ses freres, la feuille
       ne peut pas connaitre les 133 autres dates. D'ou un side-car a cote de la
       feuille — meme motif que delescluze-persons.xml — engendre par
       dots-autopilot/scripts/agentwill_nav_sidecar.py.

       Semantique relevee sur les captures de l'ELEC, et non devinee :
         annees  : les 5, chacune vers son PREMIER testament ;
         mois    : ceux de l'annee courante, vers leur premier testament ;
         jours   : ceux du mois courant, encadres par << le dernier jour du mois
                   precedent DE LA MEME ANNEE et >> le premier du mois suivant ;
         testaments : ceux de la MEME DATE, encadres par << celui qui precede le
                   groupe et >> celui qui le suit (sans limite d'annee).
       Verifie contre testament-001, -080, -093, -129 et -134.

       Piege DoTS-vue : un <a> vers la route COURANTE vide la page. L'element
       courant sort donc en <strong>, jamais en <a> — ce qui est aussi plus juste.
       =================================================================== -->
  <xsl:variable name="tp-nav" select="document('testaments-poilus-nav.xml')/tp-nav"/>
  <xsl:variable name="tp-route">/testaments-poilus/document/testaments-poilus-edition?refId=</xsl:variable>

  <xsl:template name="tp-will-nav">
    <xsl:variable name="id" select="string(@xml:id)"/>
    <xsl:variable name="me" select="$tp-nav/will[@id = $id]"/>
    <xsl:if test="$me">
      <!-- 2026-09-14 (renvoistp) : l'annee, le mois et le jour de cette barre visaient
           encore le PREMIER TESTAMENT de la periode (`?refId=will-XXX`), faute d'unites
           de date citables. Elles existent depuis le versement du 2026-09-14 (5 annees,
           35 mois, 79 jours ; l'edition est passee de 135 a 254 unites), et la barre des
           pages de groupe (`tp-groupe-page`) les vise deja. On aligne celle-ci, avec les
           memes conventions d'identifiant, relevees dans le registre et non devinees :
           `annee-1915`, `mois-1915-05`, `jour-1915-05-25`.
           `courant` n'est plus l'identifiant du testament mais celui de l'unite de date
           de la periode courante : c'est ce qui fait sortir l'annee, le mois et le jour
           courants en <strong> (piege DoTS-vue : un <a> vers la route courante vide la
           page). La liste des testaments, elle, garde bien `will-XXX`. -->
      <xsl:variable name="cour-annee" select="concat('annee-', $me/@y)"/>
      <xsl:variable name="cour-mois" select="concat('mois-', $me/@y, '-', $me/@m)"/>
      <xsl:variable name="cour-jour" select="concat('jour-', $me/@when)"/>
      <nav class="tp-will-nav" aria-label="Navigation par année, mois, jour et testament">
        <ul class="tp-years-list">
          <xsl:for-each select="$tp-nav/will[@fy = '1']">
            <li>
              <xsl:if test="@y = $me/@y"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('annee-', @y)"/>
                <xsl:with-param name="courant" select="$cour-annee"/>
                <xsl:with-param name="libelle" select="string(@y)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
        <ul class="tp-months-list">
          <xsl:for-each select="$tp-nav/will[@fm = '1'][@y = $me/@y]">
            <li>
              <xsl:if test="@m = $me/@m"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('mois-', @y, '-', @m)"/>
                <xsl:with-param name="courant" select="$cour-mois"/>
                <xsl:with-param name="libelle" select="string(@mois)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
        <ul class="tp-days-list">
          <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $me/@y][number(@m) &lt; number($me/@m)][last()]">
            <li class="tp-nav-prev">
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                <xsl:with-param name="courant" select="$cour-jour"/>
                <xsl:with-param name="libelle" select="string(@jour)"/>
              </xsl:call-template>
              <span class="tp-nav-sep"> «</span>
            </li>
          </xsl:for-each>
          <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $me/@y][@m = $me/@m]">
            <li>
              <xsl:if test="@when = $me/@when"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                <xsl:with-param name="courant" select="$cour-jour"/>
                <xsl:with-param name="libelle" select="string(@jour)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
          <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $me/@y][number(@m) &gt; number($me/@m)][1]">
            <li class="tp-nav-next">
              <span class="tp-nav-sep">» </span>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                <xsl:with-param name="courant" select="$cour-jour"/>
                <xsl:with-param name="libelle" select="string(@jour)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
        <ul class="tp-wills-list">
          <!-- 2026-09-14 : « Testament précédent » / « Testament suivant » RETIRÉS.
               Demande de l'utilisateur : « jpense ça on peut enlever, on a déjà la
               navigation ». C'est exact depuis ce jour : les 134 testaments sont rangés
               sous année → mois → jour dans le sommaire de gauche (registre 135 → 254),
               et la barre de dates ci-dessus donne déjà les voisins du même jour. Deux
               flèches de plus étaient le doublon d'une navigation qui dit mieux où l'on est.
               Les attributs @pw et @nw restent dans le side-car : rien à régénérer si l'on
               voulait les rétablir. -->
          <xsl:for-each select="$tp-nav/will[@when = $me/@when]">
            <li>
              <xsl:if test="@id = $id"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="string(@id)"/>
                <xsl:with-param name="courant" select="$id"/>
                <xsl:with-param name="libelle" select="string(@n)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
      </nav>
    </xsl:if>
  </xsl:template>

  <!-- Un lien, sauf vers la page courante : DoTS-vue confie tout <a> de meme
       origine a son routeur, et un lien vers la route courante vide la page. -->
  <xsl:template name="tp-nav-item">
    <xsl:param name="cible"/>
    <xsl:param name="courant"/>
    <xsl:param name="libelle"/>
    <xsl:choose>
      <xsl:when test="$cible = $courant">
        <strong class="tp-nav-courant"><xsl:value-of select="$libelle"/></strong>
      </xsl:when>
      <xsl:otherwise>
        <a class="internalLink" href="{concat($tp-route, $cible)}"><xsl:value-of select="$libelle"/></a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================================
       2026-09-14 (renvoistp) — LES RENVOIS INTER-RESSOURCES RETROUVENT LEUR href.

       Mesure avant correction, sur les 545 unites des trois ressources, en
       demandant a l'API exactement ce que DoTS-vue demande (mediaType=html,
       SANS excludeFragments — verifie au reseau du navigateur) : 534 <a> sans
       href dans le TEXTE, dont 320 renvois types de l'introduction
       (307 linkToEdition, 6 linkToIntro, 6 linkToPersonsIndex, 1 linkToBibl).

       Pourquoi ils etaient nus : hteiml resout `@target` par cle DANS LE MEME
       document. Or la cible est dans une AUTRE ressource (l'edition, l'index),
       ou dans une autre unite de la meme ressource : la cle ne trouve rien et
       le modele sort un <a> sans href — un mot souligne qui ne mene nulle part.

       Aucune cible n'est devinee : le TEI les porte toutes, et les 320 ont ete
       verifiees une a une contre le registre des trois ressources (0 orpheline).
         @target  = l'identifiant vise (« #will-124 », « #NDeToledo »)
         @corresp = soit la RESSOURCE (« testaments-poilus-edition|-index »),
                    soit, pour une cible interne a l'introduction, l'UNITE qui
                    la contient (« introduction-partie-6 » pour #DallozRepDCivil).
         @n       = l'infobulle de l'ancien site (« Consulter le testament »).

       Forme absolue obligatoire : un href relatif (`?refId=…`) se resoudrait a
       la racine de l'application, pas dans le corpus.

       Profondeur : les cibles de l'introduction sont de niveau 2 ou 3, plus
       profond que l'`editByLevel` de la conf. On emet donc `?refId=<unite>#<ancre>` ;
       DoTS-vue remonte lui-meme a l'ancetre ouvrable et defile jusqu'a l'ancre
       (mesure au navigateur : `?refId=introduction-partie-2-3` devient
       `?refId=introduction-partie-2#introduction-partie-2-3`).

       Sans cible utilisable, on ne fabrique rien : le texte sort nu.
       ================================================================ -->
  <xsl:template match="tei:ref[@type = 'linkToEdition'] | tei:ref[@type = 'linkToPersonsIndex'] | tei:ref[@type = 'linkToIntro'] | tei:ref[@type = 'linkToBibl']" priority="26">
    <xsl:variable name="cible" select="substring-after(normalize-space(@target), '#')"/>
    <xsl:variable name="co" select="normalize-space(@corresp)"/>
    <!-- Si la cible n'est pas une unite OUVRABLE, le side-car donne l'ancetre a
         mettre en refId ; la cible devient alors l'ancre. Voir le commentaire de
         `unites_non_ouvrables` dans agentwill_nav_sidecar.py : la correction que
         DoTS-vue fait lui-meme ne joue qu'au chargement, jamais au clic. -->
    <xsl:variable name="ouvr" select="string($tp-nav/unite[@id = $cible]/@ouvrable)"/>
    <xsl:choose>
      <xsl:when test="$cible = ''">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <a>
          <!-- le nom de classe de l'ancien site d'abord : DoTS-vue ne garde que
               le PREMIER jeton de classe, et c'est lui que porte la CSS. -->
          <xsl:attribute name="class"><xsl:value-of select="concat(@type, ' tp-renvoi')"/></xsl:attribute>
          <xsl:if test="normalize-space(@n) != ''">
            <xsl:attribute name="title"><xsl:value-of select="normalize-space(@n)"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="href">
            <xsl:text>/testaments-poilus/document/</xsl:text>
            <xsl:choose>
              <!-- @corresp nomme une ressource (edition, index) : la cible y est une
                   unite. Ouvrable (un testament), on la vise ; non ouvrable (une
                   notice de l'index), on vise sa lettre et la notice passe en ancre. -->
              <xsl:when test="starts-with($co, 'testaments-poilus-') and $ouvr != ''">
                <xsl:value-of select="concat($co, '?refId=', $ouvr, '#', $cible)"/>
              </xsl:when>
              <xsl:when test="starts-with($co, 'testaments-poilus-')">
                <xsl:value-of select="concat($co, '?refId=', $cible)"/>
              </xsl:when>
              <!-- @corresp nomme l'unite de l'introduction qui contient la cible
                   (une entree de bibliographie, qui n'est pas une unite citable) -->
              <xsl:when test="$co != ''">
                <xsl:value-of select="concat('testaments-poilus-introduction?refId=', $co, '#', $cible)"/>
              </xsl:when>
              <!-- Pas de @corresp : la cible EST une unite de l'introduction -->
              <xsl:when test="$ouvr != ''">
                <xsl:value-of select="concat('testaments-poilus-introduction?refId=', $ouvr, '#', $cible)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('testaments-poilus-introduction?refId=', $cible)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Renvois d'un testament a l'autre DANS l'edition : « Voir le 2e testament »,
       « Voir le testament de Maurice Rogue ». Le TEI porte `<ref target="#will-094">`
       sans @type ; meme panne de cle que ci-dessus, meme <a> nu (49 occurrences
       servies, 18 dans le TEI, 0 cible manquante, 0 renvoi sur lui-meme).
       Les appels de note (`@type='note'`, cible `#will-001-footnote001`) sont
       exclus par `not(@type)` : ils ont deja leur href. -->
  <xsl:template match="tei:ref[not(@type)][starts-with(normalize-space(@target), '#will-')]" priority="26">
    <a class="tp-renvoi-testament internalLink">
      <xsl:attribute name="href">
        <xsl:value-of select="concat($tp-route, substring-after(normalize-space(@target), '#'))"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- Les <persName> du CORPS sortaient en <a> nu : 165 mots soulignes qui ne
       menaient nulle part (`<persName ref="#EAGorand">Emile Gorand</persName>`
       sans <surname> : ni le modele de priorite 8, qui exige un <surname>, ni
       celui de priorite 25, limite au <front>, ne les prenait).

       Ils ne deviennent PAS des liens, et ce n'est pas un renoncement : c'est ce
       que faisait l'ancien site. Verifie sur ses 134 pages archivees
       (dots-migrations/testaments-poilus/site-context/testaments/) : 344 <a
       class="persName-linked linkToIndex"> avec href — tous dans la notice, en
       tete de page — et 404 <span class="persName"> SANS lien dans le corps du
       testament, pour ZERO <a> sans href. L'ELEC liait la notice, jamais la
       transcription. On rend donc exactement son <span>.
       Ceux qui ont un <surname> passent deja par le modele de priorite 8. -->
  <xsl:template match="tei:persName[not(tei:surname)]" priority="9">
    <span class="persName"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template name="tp-mode-bar">
    <xsl:variable name="w" select="@xml:id"/>
    <input type="radio" class="tp-mode tp-mode-tr" name="tp-mode-{$w}" id="tp-mode-tr-{$w}" checked="checked"/>
    <label class="tp-mode-label" for="tp-mode-tr-{$w}">Transcription</label>
    <input type="radio" class="tp-mode tp-mode-ed" name="tp-mode-{$w}" id="tp-mode-ed-{$w}"/>
    <label class="tp-mode-label" for="tp-mode-ed-{$w}">Édition</label>
  </xsl:template>

  <!-- orig/reg, abbr/expan, sic/corr : les deux etats, pas un @title -->
  <xsl:template match="tei:choice[tei:orig and tei:reg] | tei:choice[tei:abbr and tei:expan] | tei:choice[tei:sic and tei:corr]" priority="30">
    <span class="tp-tr tp-var"><xsl:apply-templates select="tei:orig/node() | tei:abbr/node() | tei:sic/node()"/></span>
    <span class="tp-ed tp-var"><xsl:apply-templates select="tei:reg/node() | tei:expan/node() | tei:corr/node()"/></span>
  </xsl:template>

  <!-- developpement silencieux : l'ancien site ecrivait « Madame », sans
       crochets ni soulignement (hteiml produit <ins class="ex">). -->
  <xsl:template match="tei:ex" priority="20">
    <span class="tp-ex"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- lignes du manuscrit : visibles en transcription, remplacees par une
       espace en edition (sinon les mots se collent la ou la source n'a pas
       d'espace autour du <lb/>). -->
  <xsl:template match="tei:lb[not(@n)]" priority="20">
    <!-- 2026-09-14 (agentwill) : @break="no" (48 cas) = le mot est coupe par la fin
         de ligne. L'ELEC ecrivait « compose-<br/>ront » en transcription et
         « composeront » en edition ; nous n'ecrivions ni le trait d'union, ni —
         plus grave — la bonne edition : l'espace generique coupait le mot en deux
         (« compose ront »). Le trait d'union ne parait qu'en transcription. -->
    <xsl:if test="@break = 'no'">
      <span class="tp-tr tp-lb-hyph">-</span>
    </xsl:if>
    <br class="tp-tr tp-lb"/>
    <xsl:if test="not(@break = 'no')">
      <span class="tp-ed tp-lb-sp"><xsl:text> </xsl:text></span>
    </xsl:if>
  </xsl:template>

  <!-- 2026-09-14 (agentwill) : <space dim="vertical"> (179 cas). hteiml en faisait
       quatre espaces insecables ; l'ELEC ecrivait la mention editoriale
       « (Espace d'une ligne laisse blanc) » / « (Espace de N lignes environ laisse
       blanc) », et dans la TRANSCRIPTION seulement — sur ses 134 pages ces mentions
       paraissent 179 fois exactement, c'est-a-dire une fois par <space>, alors que
       les mentions de <pb> y paraissent deux fois. -->
  <xsl:template match="tei:space[@dim = 'vertical']" priority="20">
    <span class="tp-tr space tp-space">
      <span class="editorialComment tp-space-comment">
        <xsl:choose>
          <xsl:when test="@quantity = '1' or not(@quantity)">(Espace d’une ligne laissé blanc)</xsl:when>
          <xsl:otherwise>(Espace de <xsl:value-of select="@quantity"/> lignes environ laissé blanc)</xsl:otherwise>
        </xsl:choose>
      </span>
    </span>
  </xsl:template>

  <!-- 2026-09-14 (agentwill) — DU TEXTE MANQUAIT, et le defaut vient de la feuille
       commune. `hteiml/xsl/teiHeader2html.xsl` l. 463 declare
       `<xsl:template match="*[tei:surname]">` : un modele ecrit pour le teiHeader,
       mais SANS mode, donc actif dans le corps du texte, ou il l'emporte sur le
       modele de nom de `tei2html.xsl` l. 2098 (meme priorite, inclus apres — Saxon
       le signale : « XTDE0540 Ambiguous rule match »). Ce modele boucle sur
       `select="*"` : il ne garde que les ELEMENTS enfants et jette tous les noeuds
       de texte. `<persName><surname>Foudriat</surname> Albert Alexandre</persName>`
       sortait donc « Foudriat » tout court.
       Mesure avant correction, sur les 134 testaments : 141 <persName> du CORPS
       perdaient du texte, 165 mots au total, dans 98 testaments. Le <front> etait
       deja sauve par le modele de renvoi ci-dessous (priorite 25).
       On ne corrige ici que ce corpus : la meme faute atteint les 23 corpus qui
       importent cette feuille, ce qui est une decision, pas une retouche. -->
  <xsl:template match="tei:persName[tei:surname] | tei:placeName[tei:surname] | tei:name[tei:surname] | tei:orgName[tei:surname]" priority="8">
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- rature : transcription seulement (l'edition normalisee l'omet) -->
  <xsl:template match="tei:del" priority="20">
    <del class="tp-tr tp-del"><xsl:apply-templates/></del>
  </xsl:template>

  <!-- ajout : les deux etats, avec la mention « (En marge : ) » / l'exposant
       de l'ancien site selon @place -->
  <xsl:template match="tei:add" priority="20">
    <ins>
      <xsl:attribute name="class">
        <xsl:text>tp-add</xsl:text>
        <xsl:if test="normalize-space(@place) != ''"><xsl:value-of select="concat(' tp-add-', normalize-space(@place))"/></xsl:if>
      </xsl:attribute>
      <xsl:apply-templates/>
    </ins>
  </xsl:template>

  <!-- restitution editoriale : edition seulement, entre crochets (CSS) -->
  <xsl:template match="tei:supplied[not(parent::tei:choice)]" priority="20">
    <span class="tp-ed tp-supplied"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- Apparat : sur l'ancien site, appel [a] survole = bulle (displayApparatusNote /
       hideApparatusNote), dans la transcription seulement. Le <span> garde
       l'identifiant que vise le lien de retour de la liste d'apparat de fin de
       fragment (retablie en B8b), qui reste en place. -->
  <xsl:template match="tei:app[not(@rend = 'table')]" priority="20">
    <span class="tp-app">
      <xsl:attribute name="id">
        <xsl:call-template name="id"><xsl:with-param name="suffix">_</xsl:with-param></xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates select="tei:lem/node()"/>
      <span class="tp-tr tp-app-anchor" tabindex="0">
        <xsl:variable name="l"><xsl:number count="tei:app[not(@rend = 'table')]" level="any" from="tei:text" format="a"/></xsl:variable>
        <span class="tp-app-call">[<xsl:value-of select="$l"/>]</span>
        <span class="tp-app-note"><xsl:value-of select="$l"/><xsl:text>. </xsl:text>
          <xsl:apply-templates select="tei:note/node() | tei:rdg | tei:witDetail"/>
        </span>
      </span>
    </span>
  </xsl:template>

  <!-- ================================================================
       2026-09-14 (agentwill) — en-tete de notice de l'ELEC (header.recordMetadata).

       L'ELEC ouvrait CHAQUE testament par un <h2> centre portant son NUMERO, puis
       la date et le lieu : « 93 / 1915, 25 mai. Paris. » (releve sur les 134 pages,
       134/134 en portent un). Nous n'affichions que la date : le lecteur n'avait
       nulle part le numero du testament qu'il lisait, alors meme que la barre de
       navigation de l'ancien site le designait par ce numero.
       Le numero se lit sur l'identifiant de l'unite (`will-093`) : rien a ajouter
       dans la base. `number()` retire les zeros de tete.
       ================================================================ -->
  <xsl:template match="tei:front/tei:docDate" priority="20">
    <xsl:variable name="id" select="string(ancestor::tei:text[@xml:id][1]/@xml:id)"/>
    <xsl:variable name="n" select="number(substring-after($id, 'will-'))"/>
    <h2 class="tp-num">
      <xsl:if test="string($n) != 'NaN'">
        <span class="tp-num-n"><xsl:value-of select="$n"/></span>
        <br/>
      </xsl:if>
      <span class="docDate tp-docDate"><xsl:apply-templates/></span>
    </h2>
  </xsl:template>

  <!-- L'ELEC annonçait la cote par « Cote aux Archives nationales : » — sur ses 134
       pages, 112 le portent, exactement les 112 <div type="reference"> qui
       contiennent un <ref> vers la salle des inventaires ; les 22 autres donnent la
       cote en texte nu, sans libelle. On reprend la meme regle. -->
  <xsl:template match="tei:front/tei:div[@type = 'reference']/tei:p" priority="20">
    <p class="p tp-reference">
      <xsl:if test="tei:ref">
        <span class="referenceLabel tp-referenceLabel">Cote aux Archives nationales : </span>
      </xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Renvois du testament vers l'index (persName-linked / placeName-linked
       linkToIndex de l'ancien site : 372 persName et 134 placeName portent
       @corresp = l'unite-lettre). hteiml cherchait la cible par cle dans le
       meme document : elle est dans une autre ressource, d'ou un <a> sans
       href (et le prenom perdu). On lie la route de l'unite ; sans @corresp,
       l'index complet, ou l'ancre existe aussi (verifie au navigateur). -->
  <xsl:template match="tei:front//tei:persName[@ref[starts-with(., '#')]] | tei:front//tei:placeName[@ref[starts-with(., '#')]]" priority="25">
    <a>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('tp-linkToIndex linkToIndex ', local-name(), '-linked')"/>
      </xsl:attribute>
      <!-- 2026-09-14 (suite de D28) : on vise l'UNITÉ de la notice, et non plus la page de sa
           lettre suivie d'une ancre.
           Le TEI donne les deux : `@corresp` = l'unité-lettre (« testateurs-G »), `@ref` =
           l'identifiant de la notice (« #EAGorand »). Tant que seules les lettres étaient
           citables, il fallait bien passer par la lettre. Depuis que les 128 testateurs et les
           104 lieux sont des unités à part entière (registre reconstruit, 38 → 270), la page
           d'une lettre est servie en `excludeFragments` — donc SANS ses notices — et l'ancre
           tombait dans le vide : le lecteur arrivait sur la simple liste des noms.
           Signalé par l'utilisateur sur `will-002` : « le ref ne marche pas ».
           `@ref` porte le « # » : on le retire pour en faire un refId. Si `@ref` était vide,
           on retombe sur l'unité-lettre plutôt que sur une adresse sans cible. -->
      <xsl:variable name="unite" select="substring-after(normalize-space(@ref), '#')"/>
      <xsl:attribute name="href">
        <xsl:text>/testaments-poilus/document/testaments-poilus-index</xsl:text>
        <xsl:choose>
          <xsl:when test="$unite != ''">
            <xsl:value-of select="concat('?refId=', $unite)"/>
          </xsl:when>
          <xsl:when test="normalize-space(@corresp) != ''">
            <xsl:value-of select="concat('?refId=', normalize-space(@corresp))"/>
          </xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="title">
        <xsl:choose>
          <xsl:when test="self::tei:persName">Consulter la notice de ce testateur dans l’index</xsl:when>
          <xsl:otherwise>Consulter la notice de ce lieu dans l’index des lieux de décès</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- ================================================================
       2026-09-13 — deux éléments TEI que rien ne prenait en charge.

       `hteiml/xsl/common.xsl` intercepte tout élément sans modèle et l'imprime TEL QUEL, en
       rouge, balise et attributs compris (`<span class="error"><b style="color:red">&lt;handShift
       medium="fadeInk"&gt;</b>`). C'est un repli de déboguage ; sur un site publié, c'est du
       balisage qui s'affiche sous les yeux du lecteur. L'audit de cohérence l'a mesuré : ces deux
       éléments sont les SEULS du périmètre dans ce cas (balayage de 665 unités sur 17 corpus,
       `scripts/d24_elements_non_traites.py`), et tous deux dans ce corpus.
       ================================================================ -->

  <!-- <handShift/> : changement d'encre ou de main, 20 occurrences (toutes dans will-095).
       Aucune des 134 pages de l'ÉLEC capturées n'en affiche la moindre marque : on ne rend donc
       rien de visible. L'information n'est pas perdue pour autant — elle reste dans le TEI, et
       l'attribut est conservé ici en clair pour qu'une feuille de style puisse s'en saisir un
       jour sans retoucher la transformation. -->
  <xsl:template match="tei:handShift">
    <span class="tp-handshift" data-medium="{@medium}"/>
  </xsl:template>

  <!-- <opener> : l'adresse en tête du testament, 1 occurrence (will-055). L'ÉLEC en faisait un
       <div class="opener"> enveloppant l'adresse — relevé dans sa propre page,
       logs/d14e_legacy_tp/testaments__testament-055.html. On reprend la même enveloppe. -->
  <xsl:template match="tei:opener">
    <div class="opener"><xsl:apply-templates/></div>
  </xsl:template>

  <!-- ================================================================
       D35 (agent D35, 2026-09-14) — GARNIR LES PAGES ANNÉE / MOIS / JOUR

       À VERSER AVANT QUE CECI NE SERVE À QUELQUE CHOSE :
       dots-autopilot/scripts/d35_testaments_dates.xq, qui enveloppe les
       134 testaments dans des <group type="year|month|day"> portant un
       <head> et un @xml:id (annee-1914, mois-1914-07, jour-1914-07-31).

       LE PROBLÈME QUE CE BLOC RÉSOUT (mesuré, non supposé)
       repo/resolver/utils.xqm l. 603-630 : en mode excludeFragments — le
       seul que DoTS-vue emploie — tout enfant direct portant un @xml:id
       ENREGISTRÉ au registre est retiré du <dts:wrapper>. Les enfants
       d'un groupe d'année sont les groupes de mois, ceux d'un groupe de
       mois les groupes de jour, ceux d'un groupe de jour les testaments :
       tous enregistrés, donc tous retirés. Il ne resterait que le <head>.
       Sans ce bloc, le versement produirait 119 pages à un seul titre.

       POURQUOI LE SIDE-CAR ET NON UN <argument> EN BASE (modèle christofle)
       christofle garnit ses pages de mois avec un <argument> d'index écrit
       DANS le TEI, qui n'a pas d'@xml:id et survit donc au filtrage (sa
       page mois-01 : 12 616 caractères, mesurés au navigateur le
       2026-09-14). Il faudrait pour cela écrire 119 index de plus en base,
       dans une requête déjà validée à blanc. Le side-car
       testaments-poilus-nav.xml contient déjà tout ce qu'il faut
       (@y, @m, @jour, @mois, @nom) : rien de plus à écrire en base.

       COMMENT LA PAGE EST RECONNUE
       routes.xqm l. 273 ne passe à la feuille que {static_path, resource} :
       le refId n'est PAS transmis. La page ne peut donc être identifiée que
       par son contenu — ici l'unique <head> restant. Son libellé est celui
       que fabrique la requête, et le side-car le reconstitue exactement :
         année : @y                          → « 1914 »
         mois  : concat(@mois, ' ', @y)      → « juillet 1914 »
         jour  : concat(@jour, ' ', @y)      → « 1er août 1914 »
       (la requête écrit « 1er » pour le quantième 1, le side-car aussi).

       PREUVE D'INNOCUITÉ AVANT VERSEMENT
       Le modèle ne se déclenche que sur un <dts:wrapper> dont le SEUL enfant
       élément est un <head> dont le libellé est l'un de ceux ci-dessus.
       Balayage des 405 fragments des deux ressources (édition 135 + index
       270), en XML et en HTML, le 2026-09-14 : ZÉRO fragment présente
       aujourd'hui un <head> seul dans son wrapper. Dans tous les autres cas
       le modèle rend la main à hteiml par <xsl:apply-imports/>, donc à
       l'octet près le rendu d'aujourd'hui (vérifié : 405 empreintes SHA-1
       identiques avant et après cette modification).
       ================================================================ -->

  <!-- Page « Les testaments » : voir le rapport. Le <group> porteur n'a pas
       de <head> ; après versement ses cinq enfants (les années) sont tous
       retirés et la page reste vide. Un <head>Les testaments</head> ajouté
       au groupe porteur par la requête (il n'a pas d'@xml:id, il survit au
       filtrage) suffit à déclencher la branche « portail » ci-dessous. Tant
       que ce <head> n'existe pas, la branche ne se déclenche jamais. -->

  <xsl:template match="*[local-name() = 'wrapper']/tei:head" priority="40">
    <xsl:variable name="lbl" select="normalize-space(.)"/>
    <!-- « seul enfant élément du wrapper » : la signature exacte d'une page
         de groupe servie en excludeFragments, et d'elle seule. -->
    <xsl:variable name="seul" select="count(../*) = 1"/>
    <xsl:variable name="wj" select="$tp-nav/will[concat(@jour, ' ', @y) = $lbl]"/>
    <xsl:variable name="wm" select="$tp-nav/will[concat(@mois, ' ', @y) = $lbl]"/>
    <xsl:variable name="wy" select="$tp-nav/will[@y = $lbl]"/>
    <xsl:choose>
      <!-- JOUR — testé en premier : « 31 juillet 1914 » ne peut pas être pris
           pour un mois ni pour une année, mais l'ordre le garantit. -->
      <xsl:when test="$seul and $wj">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'jour'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="string($wj[1]/@y)"/>
          <xsl:with-param name="m" select="string($wj[1]/@m)"/>
          <xsl:with-param name="when" select="string($wj[1]/@when)"/>
        </xsl:call-template>
      </xsl:when>
      <!-- MOIS -->
      <xsl:when test="$seul and $wm">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'mois'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="string($wm[1]/@y)"/>
          <xsl:with-param name="m" select="string($wm[1]/@m)"/>
          <xsl:with-param name="when" select="''"/>
        </xsl:call-template>
      </xsl:when>
      <!-- ANNÉE -->
      <xsl:when test="$seul and $wy">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'annee'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="$lbl"/>
          <xsl:with-param name="m" select="''"/>
          <xsl:with-param name="when" select="''"/>
        </xsl:call-template>
      </xsl:when>
      <!-- PORTAIL « Les testaments » (n'existe pas encore : voir ci-dessus) -->
      <xsl:when test="$seul and $lbl = 'Les testaments'">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'portail'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="''"/>
          <xsl:with-param name="m" select="''"/>
          <xsl:with-param name="when" select="''"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Tout le reste : rendu de hteiml, inchangé. -->
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Le corps d'une page de groupe : la barre de l'ÉLEC, le titre, le compte,
       puis la liste des enfants. Les quatre niveaux partagent ce modèle pour
       que les pages se ressemblent, comme sur l'ancien site. -->
  <xsl:template name="tp-groupe-page">
    <xsl:param name="niveau"/>
    <xsl:param name="lbl"/>
    <xsl:param name="y"/>
    <xsl:param name="m"/>
    <xsl:param name="when"/>
    <xsl:variable name="courant">
      <xsl:choose>
        <xsl:when test="$niveau = 'jour'"><xsl:value-of select="concat('jour-', $when)"/></xsl:when>
        <xsl:when test="$niveau = 'mois'"><xsl:value-of select="concat('mois-', $y, '-', $m)"/></xsl:when>
        <xsl:when test="$niveau = 'annee'"><xsl:value-of select="concat('annee-', $y)"/></xsl:when>
        <xsl:otherwise>les-testaments</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- forcee en chaine : un xsl:variable a contenu est un arbre, et la
         comparer a une chaine dans tp-nav-item doit rester une comparaison
         de chaines quel que soit le moteur. -->
    <xsl:variable name="cour" select="string($courant)"/>
    <!-- Les testaments couverts par la page, dans l'ordre du side-car (= celui
         du TEI, chronologique strict : 0 inversion mesurée le 2026-09-14). -->
    <xsl:variable name="dedans"
      select="$tp-nav/will[$niveau = 'portail'
                           or ($niveau = 'annee' and @y = $y)
                           or ($niveau = 'mois' and @y = $y and @m = $m)
                           or ($niveau = 'jour' and @when = $when)]"/>
    <section class="tp-groupe" id="{$cour}">
      <!-- Même classe que la barre des pages de testament : elle hérite telle
           quelle du CSS du corpus (bloc A de testaments-poilus.customCss.css),
           aucune règle nouvelle à écrire. -->
      <nav class="tp-will-nav" aria-label="Navigation par année, mois et jour">
        <ul class="tp-years-list">
          <xsl:for-each select="$tp-nav/will[@fy = '1']">
            <li>
              <xsl:if test="@y = $y"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('annee-', @y)"/>
                <xsl:with-param name="courant" select="$cour"/>
                <xsl:with-param name="libelle" select="string(@y)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
        <xsl:if test="$y != ''">
          <ul class="tp-months-list">
            <xsl:for-each select="$tp-nav/will[@fm = '1'][@y = $y]">
              <li>
                <xsl:if test="@m = $m"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
                <xsl:call-template name="tp-nav-item">
                  <xsl:with-param name="cible" select="concat('mois-', @y, '-', @m)"/>
                  <xsl:with-param name="courant" select="$cour"/>
                  <xsl:with-param name="libelle" select="string(@mois)"/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:if>
        <xsl:if test="$m != ''">
          <ul class="tp-days-list">
            <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $y][@m = $m]">
              <li>
                <xsl:if test="@when = $when"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
                <xsl:call-template name="tp-nav-item">
                  <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                  <xsl:with-param name="courant" select="$cour"/>
                  <xsl:with-param name="libelle" select="string(@jour)"/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:if>
      </nav>

      <h1 style="font-size:1.5rem;color:#a73136;margin:0 0 .4rem;font-weight:400">
        <xsl:value-of select="$lbl"/>
      </h1>

      <p style="margin:0 0 1.1rem;color:#6b6260;font-size:.95rem">
        <xsl:value-of select="count($dedans)"/>
        <xsl:text> testament</xsl:text>
        <xsl:if test="count($dedans) &gt; 1">s</xsl:if>
        <xsl:choose>
          <xsl:when test="$niveau = 'jour'"><xsl:text>. Cliquez un nom pour lire le testament.</xsl:text></xsl:when>
          <xsl:when test="$niveau = 'mois'">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-nav/will[@fd = '1'][@y = $y][@m = $m])"/>
            <xsl:text> jour</xsl:text>
            <xsl:if test="count($tp-nav/will[@fd = '1'][@y = $y][@m = $m]) &gt; 1">s</xsl:if>
            <xsl:text>. Choisissez un jour ou un testament.</xsl:text>
          </xsl:when>
          <xsl:when test="$niveau = 'annee'">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-nav/will[@fm = '1'][@y = $y])"/>
            <xsl:text> mois. Choisissez un mois.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-nav/will[@fy = '1'])"/>
            <xsl:text> années. Choisissez une année.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </p>

      <xsl:choose>
        <!-- Portail : les cinq années. -->
        <xsl:when test="$niveau = 'portail'">
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$tp-nav/will[@fy = '1']">
              <li style="padding:.3rem 0;border-bottom:1px solid #efeceb">
                <a class="internalLink" href="{concat($tp-route, 'annee-', @y)}"
                   style="color:#28211f;text-decoration:none;font-weight:700"><xsl:value-of select="@y"/></a>
                <xsl:call-template name="tp-groupe-compte">
                  <xsl:with-param name="k" select="count($tp-nav/will[@y = current()/@y])"/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <!-- Année : les mois de l'année, et sous chacun ses jours. Les
             testaments eux-mêmes ne sont pas listés ici (jusqu'à 79 pour
             1914) : c'est le rôle des pages de mois et de jour. -->
        <xsl:when test="$niveau = 'annee'">
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$tp-nav/will[@fm = '1'][@y = $y]">
              <xsl:variable name="mm" select="@m"/>
              <li style="padding:.45rem 0;border-bottom:1px solid #efeceb">
                <a class="internalLink" href="{concat($tp-route, 'mois-', @y, '-', $mm)}"
                   style="color:#28211f;text-decoration:none;font-weight:700"><xsl:value-of select="@mois"/></a>
                <xsl:call-template name="tp-groupe-compte">
                  <xsl:with-param name="k" select="count($tp-nav/will[@y = $y][@m = $mm])"/>
                </xsl:call-template>
                <div style="padding:.15rem 0 0 1.2rem;color:#6b6260;font-size:.92rem">
                  <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $y][@m = $mm]">
                    <xsl:if test="position() &gt; 1"><span style="color:#c9bcbc"> | </span></xsl:if>
                    <a class="internalLink" href="{concat($tp-route, 'jour-', @when)}"
                       style="color:#28211f;text-decoration:none"><xsl:value-of select="@jour"/></a>
                  </xsl:for-each>
                </div>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <!-- Mois : les jours, et sous chacun ses testaments — c'est la
             disposition de la page de mois de christofle. -->
        <xsl:when test="$niveau = 'mois'">
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$tp-nav/will[@fd = '1'][@y = $y][@m = $m]">
              <xsl:variable name="w" select="@when"/>
              <li style="padding:.45rem 0;border-bottom:1px solid #efeceb">
                <a class="internalLink" href="{concat($tp-route, 'jour-', $w)}"
                   style="color:#28211f;text-decoration:none;font-weight:700"><xsl:value-of select="@jour"/></a>
                <xsl:call-template name="tp-groupe-compte">
                  <xsl:with-param name="k" select="count($tp-nav/will[@when = $w])"/>
                </xsl:call-template>
                <ul style="list-style:none;padding:0 0 0 1.2rem;margin:.2rem 0 0">
                  <xsl:for-each select="$tp-nav/will[@when = $w]">
                    <li style="padding:.1rem 0">
                      <xsl:call-template name="tp-groupe-testament"/>
                    </li>
                  </xsl:for-each>
                </ul>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <!-- Jour : les testaments du jour. -->
        <xsl:otherwise>
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$dedans">
              <li style="padding:.3rem 0;border-bottom:1px solid #efeceb">
                <xsl:call-template name="tp-groupe-testament"/>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:otherwise>
      </xsl:choose>
    </section>
  </xsl:template>

  <!-- « — 12 testaments », en gris, après un lien de groupe. -->
  <xsl:template name="tp-groupe-compte">
    <xsl:param name="k"/>
    <span style="color:#8a807e;font-size:.9rem">
      <xsl:text> — </xsl:text>
      <xsl:value-of select="$k"/>
      <xsl:text> testament</xsl:text>
      <xsl:if test="$k &gt; 1">s</xsl:if>
    </span>
  </xsl:template>

  <!-- Une entrée de testament : le numéro puis le nom du testateur. Le nom
       vient de @nom (ajouté au side-car le 2026-09-14) ; s'il manque — side-car
       régénéré par une version antérieure du script — on retombe sur le seul
       numéro, sans jamais produire un lien vide. -->
  <xsl:template name="tp-groupe-testament">
    <a class="internalLink" href="{concat($tp-route, @id)}"
       style="color:#28211f;text-decoration:none">
      <xsl:text>n</xsl:text><sup>o</sup><xsl:text> </xsl:text>
      <xsl:value-of select="@n"/>
      <xsl:if test="string(@nom) != ''">
        <xsl:text> — </xsl:text>
        <xsl:value-of select="@nom"/>
      </xsl:if>
    </a>
  </xsl:template>

</xsl:transform>
