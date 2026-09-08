<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>

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

  <!-- Les miniatures de l'ÉLEC historique étaient servies depuis le répertoire
       global /media/. Dans DoTS Vue, elles sont conservées sous public/ afin
       que l'édition reste lisible hors de l'ancien serveur.

       Deux paramètres pilotent ces chemins. $tp_images_base reste local et
       prioritaire ; $tp_images_fallback ne sert que si le fichier local manque
       — c'est le cas tant que les fac-similés ne sont pas déployés, et sans lui
       toutes les vignettes sont en 404. La vignette est en outre enveloppée
       d'un lien vers la pleine résolution : l'ÉLEC historique offrait cet
       agrandissement (elevateZoom), qui manquait ici. -->
  <xsl:param name="tp_images_base">/testaments-poilus/images/</xsl:param>
  <xsl:param name="tp_images_fallback">http://elec.enc.sorbonne.fr/media/testaments-de-poilus/images/</xsl:param>

  <xsl:template name="tp-facsimile">
    <xsl:param name="nom"/>
    <a class="tp-facsimile-link" href="{$tp_images_base}sources/{$nom}.jpg"
       target="_blank" rel="noopener" title="Agrandir le fac-similé">
      <img class="tp-facsimile" src="{$tp_images_base}vignettes/{$nom}_ptt.jpg" alt="{$nom}" loading="lazy"
           onerror="this.onerror=null;this.src='{$tp_images_fallback}vignettes/{$nom}_ptt.jpg';this.parentNode.href='{$tp_images_fallback}sources/{$nom}.jpg'"/>
    </a>
  </xsl:template>

  <xsl:template match="tei:graphic[contains(@url, '/media/testaments-de-poilus/images/vignettes/')]" priority="10">
    <xsl:call-template name="tp-facsimile">
      <xsl:with-param name="nom" select="substring-before(substring-after(@url, '/vignettes/'), '_ptt.jpg')"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:pb[starts-with(@facs, '../images/FRAN_0045_')]" priority="10">
    <span class="tp-page-break" id="{@xml:id}"><xsl:value-of select="@n"/></span>
    <xsl:call-template name="tp-facsimile">
      <xsl:with-param name="nom" select="substring-before(substring-after(@facs, '../images/'), '.jpg')"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Les notes des testaments sont regroupées dans des div de type
       footnotes-will-XXX. Elles ne correspondent pas au type générique
       « footnotes » : on rend donc explicitement leur ancre de retour. -->
  <xsl:template match="tei:div[starts-with(@type, 'footnotes-')]/tei:note" priority="20">
    <aside class="note" id="{@xml:id}">
      <!-- will-001-footnote001 vise #will-001-001, qui n'existe nulle part dans
           la source : la publication ÉLEC n'affichait pas cette note, faute
           d'appel. On garde le texte, sans lien de retour mort. -->
      <xsl:if test="key('id', substring-after(@target, '#'))">
        <a class="noteback" href="{@target}" title="Retour à l’appel de note"><xsl:text>↩ </xsl:text></a>
      </xsl:if>
      <xsl:apply-templates/>
    </aside>
  </xsl:template>

  <!-- Les notices biographiques de l'index sont affichées en place, dans
       l'entrée du testateur (mode tp-bio). Sans cette règle, la générique les
       ramasse une seconde fois en notes de fin, avec un lien de retour vers
       un appel qui n'existe pas : 131 renvois morts dans l'index. -->
  <xsl:template match="tei:person//tei:note | tei:place//tei:note" mode="fn" priority="20"/>

  <!-- Le corpus tient en trois documents DTS — l'édition, l'index, les
       paratextes — et ses renvois les traversent. Quand la cible sort du
       fragment servi, il faut donc dire dans lequel la chercher. On s'appuie
       sur ce qui porte le renvoi plutôt que sur la forme de l'identifiant :
       un patronyme et une entrée de bibliographie se ressemblent trop
       (LWidhalm, DallozRepDCivil) pour qu'un critère lexical les sépare. -->
  <xsl:template name="dts-resource-for-anchor">
    <xsl:param name="anchor"/>
    <xsl:choose>
      <!-- un testament, quel que soit le document d'où part le renvoi -->
      <xsl:when test="starts-with($anchor, 'will-')">testaments-poilus-edition</xsl:when>
      <!-- une entrée d'index : lieu de décès, ou notice de testateur -->
      <xsl:when test="starts-with($anchor, 'pl-')">testaments-poilus-index</xsl:when>
      <xsl:when test="self::tei:persName | self::tei:placeName
        | parent::tei:persName | parent::tei:placeName">testaments-poilus-index</xsl:when>
      <!-- les paratextes nomment eux-mêmes la cible de leurs renvois -->
      <xsl:when test="self::tei:ref[@type = 'linkToPersonsIndex']
        | parent::tei:ref[@type = 'linkToPersonsIndex']">testaments-poilus-index</xsl:when>
      <xsl:when test="self::tei:ref[@type = 'linkToEdition']
        | parent::tei:ref[@type = 'linkToEdition']">testaments-poilus-edition</xsl:when>
      <!-- sinon la cible est ailleurs dans le document courant -->
      <xsl:otherwise><xsl:call-template name="tp-current-resource"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Route du visualiseur. Les trois ressources du corpus étant connues, la
       feuille les nomme elle-même : rien n'a besoin de transiter par
       routes.xqm. Le seul réglage est la racine de l'application, à changer
       si elle n'est pas montée à la racine du domaine. -->
  <xsl:param name="tp_app_base">/</xsl:param>
  <xsl:variable name="tp_collection">testaments-poilus</xsl:variable>

  <!-- Document servi, déduit de son contenu : les trois ressources ont des
       structures disjointes — l'index seul porte des person/place, l'édition
       seule des divisions de testament. -->
  <xsl:template name="tp-current-resource">
    <xsl:choose>
      <xsl:when test="//tei:listPerson | //tei:listPlace | //tei:person | //tei:place">testaments-poilus-index</xsl:when>
      <xsl:when test="//tei:div[@type = 'will'] | //tei:text[starts-with(@xml:id, 'will-')]">testaments-poilus-edition</xsl:when>
      <xsl:otherwise>testaments-poilus-introduction</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="tp-href">
    <xsl:param name="anchor"/>
    <xsl:param name="unite"/>
    <xsl:variable name="res">
      <xsl:call-template name="dts-resource-for-anchor">
        <xsl:with-param name="anchor" select="$anchor"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <!-- La page est nommée : on l'ouvre et on saute à l'ancre. -->
      <xsl:when test="$unite != ''">
        <xsl:value-of select="concat($tp_app_base, $tp_collection, '/document/', $res, '?refId=', $unite, '#', $anchor)"/>
      </xsl:when>
      <!-- Une unité citable — un testament, une lettre d'index — s'ouvre par
           son ref ; une ancre interne se rejoint dans le document entier. -->
      <xsl:when test="starts-with($anchor, 'will-') and substring-after(substring-after($anchor, '-'), '-') = ''">
        <xsl:value-of select="concat($tp_app_base, $tp_collection, '/document/', $res, '?refId=', $anchor)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($tp_app_base, $tp_collection, '/document/', $res, '#', $anchor)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ====================================================================
       Correctifs repris dans la feuille de corpus plutôt que dans hteiml.

       teiHeader2html.xsl est *incluse* par tei2html.xsl : elle a donc la même
       précédence d'import que la générique, et ses motifs — plus spécifiques —
       l'emportent partout, en-tête ou non. Redéclarer ces motifs ici les
       neutralise, la précédence d'import primant sur la priorité, et laisse la
       générique intacte pour les autres corpus.
       ==================================================================== -->

  <!-- Une ancre dont la cible est hors du fragment servi ne recevait aucun
       href : le renvoi devenait muet. -->
  <xsl:template match="@ref | @target | @lemmaRef" priority="1">
    <xsl:param name="path" select="."/>
    <xsl:choose>
      <xsl:when test="starts-with($path, '#')">
        <xsl:variable name="cible" select="key('id', substring($path, 2))"/>
        <xsl:choose>
          <xsl:when test="$cible">
            <xsl:for-each select="$cible[1]">
              <xsl:attribute name="href"><xsl:call-template name="href"/></xsl:attribute>
            </xsl:for-each>
          </xsl:when>
          <!-- Le @corresp inscrit par generer-liens-index.py nomme la page
               qui porte la cible : « MRPatey » se range sous testateurs-P,
               « pl-076 » sous lieux-M. Sans lui il faudrait ouvrir l'index
               entier, les deux listes à la fois. -->
          <xsl:when test="../@corresp">
            <xsl:attribute name="href">
              <xsl:call-template name="tp-href">
                <xsl:with-param name="anchor" select="substring($path, 2)"/>
                <xsl:with-param name="unite" select="../@corresp"/>
              </xsl:call-template>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="href">
              <xsl:call-template name="tp-href">
                <xsl:with-param name="anchor" select="substring($path, 2)"/>
              </xsl:call-template>
            </xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- « *[tei:surname] », de priorité 0,5, l'emportait sur le gabarit général
       et ne parcourait que les éléments enfants : un persName du corps perdait
       son lien vers l'index et ses nœuds de texte — « Fernand Lucien Jules
       Melchior <surname>Chatin</surname> » ne rendait que « Chatin ». 477 des
       533 persName du corpus sont dans ce cas. -->
  <xsl:template match="tei:persName | tei:placeName" priority="1">
    <xsl:choose>
      <xsl:when test="@ref and starts-with(@ref, '#')">
        <a>
          <xsl:attribute name="property">
            <xsl:choose>
              <xsl:when test="self::tei:persName">dbo:person</xsl:when>
              <xsl:otherwise>dbo:place</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:call-template name="atts"/>
          <xsl:variable name="cible" select="key('id', substring-after(@ref, '#'))"/>
          <xsl:if test="$cible">
            <xsl:attribute name="title">
              <xsl:apply-templates select="$cible[1]" mode="txt"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <span><xsl:call-template name="atts"/><xsl:apply-templates/></span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Sommaire de la page « Les testaments ». DoTS sert cette unité avec
       excludeFragments : ses 134 enfants, unités citables, en sont retirés et
       la page restait vide. La source porte donc une liste, produite par
       scripts/generer-liens-index.py ; un <note> étant admis dans un <group>
       par le modèle TEI et n'ayant pas d'@xml:id, il traverse le filtrage. -->
  <xsl:template match="tei:note[@type = 'summary']" priority="30">
    <xsl:apply-templates select="tei:list"/>
  </xsl:template>

  <!-- …et ne pas la ramasser une seconde fois en note de fin, avec un lien de
       retour vers un appel qui n'existe pas. -->
  <xsl:template match="tei:note[@type = 'summary']" mode="fn" priority="30"/>

  <!-- Barre des lettres, précalculée dans chaque sous-liste (christofle fait
       de même pour ses mois) : une lettre servie seule ne voit pas ses
       voisines, la feuille ne pourrait donc pas la construire. -->
  <xsl:template match="tei:note[@type = 'letter-nav']" priority="30">
    <nav class="tp-letter-nav" aria-label="Navigation par lettre"
         style="margin:.4rem 0 1rem;font-size:1.05rem">
      <xsl:for-each select="tei:ref">
        <xsl:if test="position() &gt; 1"><span style="color:#c9c2bf"> | </span></xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </nav>
  </xsl:template>

  <xsl:template match="tei:note[@type = 'letter-nav']" mode="fn" priority="30"/>

  <xsl:template match="tei:ref[@type = 'letterNav']" priority="10">
    <a class="tp-letter-link">
      <xsl:if test="@rend = 'current'">
        <xsl:attribute name="style">font-weight:700;color:#a73136</xsl:attribute>
      </xsl:if>
      <xsl:attribute name="href">
        <xsl:call-template name="tp-href">
          <xsl:with-param name="anchor" select="substring-after(@target, '#')"/>
          <xsl:with-param name="unite" select="@corresp"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match="tei:list[@type = 'summary']" priority="5">
    <ul class="sommaire" style="list-style:square;margin:1rem 0 0 1.5rem;padding:0">
      <xsl:apply-templates select="tei:item"/>
    </ul>
  </xsl:template>

  <xsl:template match="tei:list[@type = 'summary']/tei:item" priority="5">
    <li style="margin:.18rem 0"><xsl:apply-templates/></li>
  </xsl:template>

  <!-- Les cinq notes logées dans une <bibl> tombaient sous le motif
       « tei:bibl//tei:note » de teiHeader2html : rendues en ligne, sans appel. -->
  <xsl:template match="tei:bibl//tei:note">
    <xsl:call-template name="noteref"/>
  </xsl:template>

  <!-- L'appel déporté <ref type="note" xml:id="x"> est visé par le @target de
       sa note, sans suffixe ; la générique suffixait son ancre d'un « _ », ce
       qui rendait muets les onze liens de retour du corpus. -->
  <xsl:template match="tei:ref[@type = 'note'][@xml:id]" priority="1">
    <a class="noteref" id="{@xml:id}" href="{@target}">
      <sup><xsl:call-template name="note-n"/></sup>
    </a>
  </xsl:template>

  <!-- Une note logée sous un lem ou un rdg relève de l'apparat : la ramasser
       en note de fin produisait une entrée dont l'appel n'est jamais rendu,
       l'édition n'affichant pas cette branche de la leçon. -->
  <xsl:template match="tei:note[ancestor::tei:app]" mode="fn" priority="30"/>

  <!-- Seule section à ne pas porter son identifiant : le lien « § » que son
       propre titre engendre visait donc une ancre absente. -->
  <xsl:template match="tei:div[@type = 'notes' or @type = 'footnotes']" priority="1">
    <section class="footnotes">
      <xsl:attribute name="id"><xsl:call-template name="id"/></xsl:attribute>
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- <ref type="email"> ne porte pas de @target : la générique produisait donc
       un lien sans href, et l'ÉLEC historique un « mailto: » vide. L'adresse
       étant dans le contenu, on l'utilise. -->
  <xsl:template match="tei:ref[@type = 'email']" priority="20">
    <a class="email" href="mailto:{normalize-space(.)}"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'index']" priority="9">
    <section class="tp-index" style="max-width:62rem;margin:0 auto;color:#222;font-family:Georgia,'Times New Roman',serif;line-height:1.55">
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- Les deux index sont groupés par lettre : une liste englobante, puis une
       sous-liste nommée par lettre, qui est l'unité de page de l'ÉLEC
       historique. Les deux niveaux ont leur propre gabarit, la sous-liste
       pouvant être servie seule comme fragment DTS. -->
  <xsl:template match="tei:listPerson[tei:listPerson]" priority="10">
    <section class="tp-index-persons">
      <h2 style="font-size:1.25rem;color:#a73136;border-bottom:1px solid #d7d1ca;padding-bottom:.3rem;margin:0 0 1rem">Index des testateurs</h2>
      <xsl:apply-templates select="tei:listPerson"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:listPerson[tei:person]" priority="9">
    <section class="tp-index-letter" id="{@xml:id}">
      <xsl:call-template name="tp-index-lettre"/>
      <xsl:apply-templates select="tei:note[@type = 'letter-nav']"/>
      <xsl:apply-templates select="tei:person"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:listPlace[tei:listPlace]" priority="10">
    <section class="tp-index-places">
      <h2 style="font-size:1.25rem;color:#a73136;border-bottom:1px solid #d7d1ca;padding-bottom:.3rem;margin:2rem 0 1rem">Index des lieux de décès</h2>
      <xsl:apply-templates select="tei:listPlace"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:listPlace[tei:place]" priority="9">
    <section class="tp-index-letter" id="{@xml:id}">
      <xsl:call-template name="tp-index-lettre"/>
      <xsl:apply-templates select="tei:note[@type = 'letter-nav']"/>
      <xsl:apply-templates select="tei:place"/>
    </section>
  </xsl:template>

  <xsl:template name="tp-index-lettre">
    <h3 class="tp-index-initial" style="font-size:1.6rem;color:#a73136;font-weight:bold;margin:1.2rem 0 .4rem">
      <xsl:value-of select="normalize-space(tei:head)"/>
    </h3>
  </xsl:template>

  <!-- La lettre est déjà rendue en titre de section. -->
  <xsl:template match="tei:listPerson/tei:head | tei:listPlace/tei:head" priority="10"/>

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
      <!-- Renvoi vers le testament du testateur, comme sur l'ÉLEC. -->
      <xsl:if test="tei:note[@type = 'linkToEdition']/tei:ref">
        <p class="linkToEdition" style="font-size:.9rem;margin:.2rem 0">
          <xsl:text>Testament </xsl:text>
          <xsl:apply-templates select="tei:note[@type = 'linkToEdition']/tei:ref"/>
        </p>
      </xsl:if>
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
    <!-- surnom : « Bezy, Ferdinand Albert, dit André » -->
    <xsl:if test="tei:addName">
      <xsl:text>, dit </xsl:text>
      <span class="addName"><xsl:value-of select="normalize-space(tei:addName)"/></span>
    </xsl:if>
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

  <!-- Nom d'un lieu, dans le contexte de l'élément qui porte ses <placeName> :
       le nom porté pendant la guerre, suivi du nom actuel — « Marcheville,
       auj. Marchéville-en-Woëvre ». Le nom ancien n'est retenu que si son
       @when-iso couvre encore 1914 ; sinon c'est le nom actuel seul, comme
       Villequier-Aumont, qui ne s'appelait plus Genlis depuis 1801. -->
  <xsl:template name="tp-nom-lieu">
    <xsl:variable name="ancien" select="tei:placeName[@type = 'old']
      [not(@when-iso) or substring-after(@when-iso, '/') = ''
       or number(substring(substring-after(@when-iso, '/'), 1, 4)) &gt;= 1914][1]"/>
    <xsl:variable name="actuel" select="tei:placeName[not(@type = 'old')][1]"/>
    <xsl:variable name="repli" select="tei:placeName[1]"/>
    <xsl:choose>
      <xsl:when test="$ancien">
        <xsl:value-of select="normalize-space($ancien/tei:settlement | $ancien[not(tei:settlement)])"/>
        <xsl:if test="$actuel">
          <xsl:text>, auj. </xsl:text>
          <xsl:value-of select="normalize-space($actuel/tei:settlement | $actuel[not(tei:settlement)])"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$actuel">
        <xsl:value-of select="normalize-space($actuel/tei:settlement | $actuel[not(tei:settlement)])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space($repli/tei:settlement | $repli[not(tei:settlement)])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- lieu de deces -->
  <xsl:template match="tei:place" priority="9">
    <article id="{@xml:id}" class="index-entry" style="border-bottom:1px dotted #e0dcd5;padding:.6rem 0;margin:0">
      <h4 class="placeName-Entry" style="margin:0 0 .3rem;font-size:1.05rem">
        <span class="placeName-entry">
          <!-- L'ÉLEC historique donne le nom porté pendant la guerre, suivi du
               nom actuel : « Marcheville, auj. Marchéville-en-Woëvre ». Le nom
               ancien n'est retenu que si son @when-iso couvre encore 1914 —
               sans quoi c'est le nom actuel seul, comme pour Villequier-Aumont,
               qui ne s'appelait plus Genlis depuis 1801. -->
          <xsl:call-template name="tp-nom-lieu"/>
          <!-- Quatre lieux ont changé de département ou de pays depuis la
               guerre (Houilles, Bellemagny, Metzeral, Monastir) : l'ÉLEC donne
               la circonscription du temps, puis l'actuelle. -->
          <xsl:variable name="locs" select="tei:location[not(@type)]"/>
          <xsl:variable name="guerre" select="$locs[not(@when-iso)
            or (number(substring(@when-iso, 1, 4)) &lt;= 1914
                and (substring-after(@when-iso, '/') = ''
                     or number(substring(substring-after(@when-iso, '/'), 1, 4)) &gt;= 1914))][1]"/>
          <xsl:variable name="actuel"
            select="$locs[substring-after(@when-iso, '/') = ''][count(. | $guerre) != 1][1]"/>
          <xsl:variable name="dep" select="$guerre/tei:district[@type = 'departement']"/>
          <xsl:variable name="pays" select="$guerre/tei:country"/>
          <xsl:variable name="a-dep" select="normalize-space($dep) != ''"/>
          <xsl:if test="$a-dep or $pays or $guerre/tei:placeName">
            <span class="displayedLocation" style="font-weight:normal;color:#555">
              <xsl:text> (</xsl:text>
              <xsl:choose>
                <!-- hors de France, l'ÉLEC situe par le pays -->
                <xsl:when test="$a-dep"><span class="departement"><xsl:value-of select="normalize-space($dep)"/></span></xsl:when>
                <xsl:otherwise><span class="pays"><xsl:value-of select="normalize-space($pays)"/></span></xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$actuel">
                <xsl:variable name="dep2" select="$actuel/tei:district[@type = 'departement']"/>
                <xsl:choose>
                  <!-- même pays : seul le département a changé -->
                  <xsl:when test="$a-dep and normalize-space($dep2) != '' and normalize-space($pays) = normalize-space($actuel/tei:country)">
                    <xsl:text>, auj. </xsl:text>
                    <span class="departement"><xsl:value-of select="normalize-space($dep2)"/></span>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text> ; auj. </xsl:text>
                    <xsl:if test="$dep2"><span class="departement"><xsl:value-of select="normalize-space($dep2)"/></span><xsl:text>, </xsl:text></xsl:if>
                    <span class="pays"><xsl:value-of select="normalize-space($actuel/tei:country)"/></span>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
              <!-- lieu-dit ou bois : la commune de rattachement -->
              <xsl:if test="$guerre/tei:placeName">
                <xsl:text>, com. </xsl:text>
                <xsl:for-each select="$guerre"><xsl:call-template name="tp-nom-lieu"/></xsl:for-each>
              </xsl:if>
              <xsl:text>)</xsl:text>
            </span>
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
      <!-- Les testateurs morts ici. Le rapprochement se faisait par la clef
           tp-deces, qui ne voit plus rien dès que les deux index sont servis
           lettre par lettre : il est désormais inscrit dans la source par
           scripts/generer-liens-index.py. -->
      <xsl:if test="tei:note[@type = 'linksToEdition']/tei:ref">
        <section class="linksToEdition" style="font-size:.9rem">
          <ul style="margin:.2rem 0;padding-left:1.2rem">
            <xsl:for-each select="tei:note[@type = 'linksToEdition']/tei:ref">
              <li>Lieu de décès de <xsl:apply-templates select="."/></li>
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
      <!-- L'index des lieux est un fragment DTS distinct de celui des
           testateurs : le renvoi d'une notice vers son lieu de décès ne peut
           pas rester une simple ancre, elle n'existe pas dans la page. -->
      <xsl:when test="@ref[starts-with(., '#')]">
        <xsl:variable name="anchor" select="substring-after(@ref, '#')"/>
        <a class="linkToIndex" style="color:inherit;border-bottom:1px dotted #a73136;text-decoration:none">
          <xsl:attribute name="href">
            <xsl:choose>
              <xsl:when test="key('id', $anchor)"><xsl:value-of select="@ref"/></xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="tp-href">
                  <xsl:with-param name="anchor" select="$anchor"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
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

</xsl:transform>
