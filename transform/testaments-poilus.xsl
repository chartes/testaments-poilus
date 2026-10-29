<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" xmlns:ord="urn:ordinaux"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:tf="urn:elec:tableau-filtrable"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tp="urn:testaments-poilus:xsl"
  exclude-result-prefixes="tei tf xs tp ord">
  <!-- Testaments de poilus : surcharge de hteiml, reconstruite le 13/10/2026 en partant du
       rendu hteiml nu. Tous les modèles de la version précédente sont repris tels quels
       (sortie identique) : barres de navigation année / mois / jour / testament, bascule
       Transcription / Édition (boutons radio), pages du fac-similé et agrandissement,
       en-tête, apparat, index des testateurs et des lieux par lettre, introduction, liens.
       Le fichier compagnon testaments-poilus-edition.xml (lu par document()) et
       ordinaux.xsl restent nécessaires. La mise en page du site historique (fac-similé à
       gauche, texte à droite) est portée par la CSS. -->
  <!-- ==== 0. DÉCLARATIONS : imports, sortie, paramètres, variables, clés, fonctions ==== -->
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:import href="tableau-filtrable.xsl"/>
  <xsl:import href="bibliographie.xsl"/><!-- bibliographies : module commun (2026-10-15) -->
  <xsl:include href="ordinaux.xsl"/> 
  <xsl:variable name="elec-base" select="'/elec'"/>
  <xsl:param name="images" select="$elec-base"/>
  <xsl:output indent="no"/>
  <xsl:variable name="tp-index-personnes-arbre">
    <xsl:if test="doc-available($tp-uri-edition)">
      <xsl:for-each select="document($tp-uri-edition)//tei:person[@xml:id]">
        <xsl:element name="p" namespace="">
          <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
          <xsl:for-each select="tei:note[@type = 'linkToEdition']/tei:ref[starts-with(@target, '#will-')]">
            <xsl:element name="w" namespace="">
              <xsl:attribute name="id"><xsl:value-of select="substring-after(@target, '#')"/></xsl:attribute>
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:element>
          </xsl:for-each>
        </xsl:element>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="tp-index-personnes" select="$tp-index-personnes-arbre"/>
  <xsl:variable name="tp-uri-edition" select="'testaments-poilus-edition.xml'"/>
  <xsl:variable name="tp-mois"
    select="'|01:janvier|02:février|03:mars|04:avril|05:mai|06:juin|07:juillet|08:août|09:septembre|10:octobre|11:novembre|12:décembre|'"/>
  <xsl:variable name="tp-wills-arbre">
    <xsl:if test="doc-available($tp-uri-edition)">
      <xsl:for-each select="document($tp-uri-edition)//tei:text[starts-with(@xml:id, 'will-')]">
        <xsl:variable name="when" select="string(tei:front/tei:docDate/tei:date/@when)"/>
        <xsl:variable name="m" select="substring($when, 6, 2)"/>
        <xsl:variable name="quantieme" select="substring($when, 9, 2)"/>
        <xsl:variable name="mois" select="substring-before(substring-after($tp-mois, concat('|', $m, ':')), '|')"/>
        <xsl:element name="will" namespace="">
          <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
          <xsl:attribute name="n"><xsl:value-of select="number(substring-after(@xml:id, 'will-'))"/></xsl:attribute>
          <xsl:attribute name="when"><xsl:value-of select="$when"/></xsl:attribute>
          <xsl:attribute name="y"><xsl:value-of select="substring($when, 1, 4)"/></xsl:attribute>
          <xsl:attribute name="m"><xsl:value-of select="$m"/></xsl:attribute>
          <xsl:attribute name="mois"><xsl:value-of select="$mois"/></xsl:attribute>
          <xsl:attribute name="jour">
            <xsl:choose>
              <xsl:when test="$quantieme = '01'">1er</xsl:when>
              <xsl:otherwise><xsl:value-of select="number($quantieme)"/></xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$mois"/>
          </xsl:attribute>
          <xsl:attribute name="nom">
            <xsl:choose>
              <xsl:when test="tei:front/tei:div[@type = 'summary']/tei:p/tei:persName">
                <xsl:value-of select="normalize-space((tei:front/tei:div[@type = 'summary']/tei:p/tei:persName)[1])"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="normalize-space((tei:front//tei:persName)[1])"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="fy">
            <xsl:if test="generate-id(.) = generate-id((ancestor::tei:group[@type = 'year'][1]//tei:text[starts-with(@xml:id, 'will-')])[1])">1</xsl:if>
          </xsl:attribute>
          <xsl:attribute name="fm">
            <xsl:if test="generate-id(.) = generate-id((ancestor::tei:group[@type = 'month'][1]//tei:text[starts-with(@xml:id, 'will-')])[1])">1</xsl:if>
          </xsl:attribute>
          <xsl:attribute name="fd">
            <xsl:if test="generate-id(.) = generate-id((ancestor::tei:group[@type = 'day'][1]//tei:text[starts-with(@xml:id, 'will-')])[1])">1</xsl:if>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="tp-wills" select="$tp-wills-arbre"/>
  <xsl:variable name="tp-unites-arbre">
    <xsl:if test="doc-available($tp-uri-edition)">
      <xsl:for-each select="document($tp-uri-edition)//tei:listPerson[@xml:id]/tei:person[@xml:id]">
        <xsl:element name="unite" namespace="">
          <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
          <xsl:attribute name="res">testaments-poilus-edition</xsl:attribute>
          <xsl:attribute name="ouvrable"><xsl:value-of select="../@xml:id"/></xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:if>
    <xsl:if test="doc-available($tp-uri-edition)">
      <xsl:for-each select="document($tp-uri-edition)//tei:div[@xml:id = 'introduction']/tei:div[@xml:id]/tei:div[@xml:id]">
        <xsl:element name="unite" namespace="">
          <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
          <xsl:attribute name="res">testaments-poilus-edition</xsl:attribute>
          <xsl:attribute name="ouvrable"><xsl:value-of select="../@xml:id"/></xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="tp-unites" select="$tp-unites-arbre"/>
  <xsl:variable name="tp-route" select="concat($elec-base, '/testaments-poilus/document/testaments-poilus-edition?refId=')"/>

  <!-- Clés du filtre Département ou pays : les départements, ou le pays hors de France. -->
  <xsl:function version="3.0" name="tp:lieu-cles" as="xs:string*" xmlns:tp="urn:testaments-poilus:xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="place" as="element()"/>
    <xsl:sequence select="distinct-values(for $l in $place/tei:location[not(@type)]
        return (if (normalize-space($l/tei:country) = ('France', '')) then $l/tei:district[@type = 'departement'][normalize-space(.) != '']/normalize-space(.) else normalize-space($l/tei:country)))"/>
  </xsl:function>

  <!-- ==== 1. HISTORIQUE : surcharge reprise de la feuille de l'ÉLEC (rendu du texte de l'édition) ==== -->
  <!-- (aucun) -->

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes, apparat critique, bibliographie (listBibl) ==== -->
  <xsl:template match="*[local-name() = 'wrapper']" priority="10">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper'][tei:teiHeader]" priority="20">
    <xsl:choose>
      <xsl:when test="tei:text">
        <xsl:apply-templates select="tei:teiHeader"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="node()[not(self::tei:teiHeader)]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper'][tei:div][not(.//tei:text)][not(tei:teiHeader)]" priority="12">
    <xsl:apply-templates/>
    <xsl:variable name="notes-cont" select="."/>
    <xsl:for-each select="/">
      <xsl:call-template name="footnotes">
        <xsl:with-param name="cont" select="$notes-cont"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="tei:note[@type = 'biography' or @type = 'letter-nav'
                              or @type = 'linkToEdition' or @type = 'linksToEdition']"
                mode="fn" priority="20"/>
  <xsl:template match="*[local-name() = 'wrapper']/tei:text[@xml:id]" priority="30">
    <article id="{@xml:id}" class="testament">
      <xsl:call-template name="tp-will-nav"/>
      <xsl:call-template name="tp-mode-bar"/>
      <xsl:call-template name="tp-facs-gallery"/>
      <xsl:apply-templates/>
      <xsl:variable name="tp-apps" select=".//tei:app[not(@rend = 'table')]"/>
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
  <xsl:template match="tei:note[@type = 'letter-nav']" priority="11"/>
  <xsl:template match="tei:note[@type = 'biography']" mode="tp-bio">
    <div class="bio" style="font-size:.96rem;color:#333;margin:0 0 .3rem">
      <xsl:apply-templates mode="tp-inline"/>
    </div>
  </xsl:template>
  <xsl:template match="tei:bibl" mode="tp-bibl">
    <br/>
    <span class="bibl">
      <xsl:text>- </xsl:text>
      <xsl:choose>
        <xsl:when test="tei:msIdentifier">
          <xsl:for-each select="tei:msIdentifier">
            <xsl:for-each select="tei:institution | tei:repository | tei:collection">
              <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
              <span class="{local-name()}"><xsl:value-of select="normalize-space(.)"/></span>
            </xsl:for-each>
            <xsl:if test="tei:msName">
              <xsl:text> : </xsl:text>
              <span class="msName"><xsl:value-of select="normalize-space(tei:msName)"/></span>
            </xsl:if>
            <xsl:if test="tei:idno">
              <xsl:text> (</xsl:text>
              <span class="idno"><xsl:value-of select="normalize-space(tei:idno)"/></span>
              <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:text>. </xsl:text>
          </xsl:for-each>
          <xsl:apply-templates select="*[not(self::tei:msIdentifier)]" mode="tp-inline"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="tei:author">
            <span class="author"><xsl:value-of select="normalize-space(string-join(tei:author, ', '))"/><xsl:text>. </xsl:text></span>
          </xsl:if>
          <xsl:apply-templates select="*[not(self::tei:author)]" mode="tp-inline"/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>
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
  <xsl:template name="tp-will-nav">
    <xsl:variable name="id" select="string(@xml:id)"/>
    <xsl:variable name="me" select="$tp-wills/will[@id = $id]"/>
    <xsl:if test="$me">
      <xsl:variable name="cour-annee" select="concat('annee-', $me/@y)"/>
      <xsl:variable name="cour-mois" select="concat('mois-', $me/@y, '-', $me/@m)"/>
      <xsl:variable name="cour-jour" select="concat('jour-', $me/@when)"/>
      <nav class="tp-will-nav" aria-label="Navigation par année, mois, jour et testament">
        <ul class="tp-years-list">
          <xsl:for-each select="$tp-wills/will[@fy = '1']">
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
          <xsl:for-each select="$tp-wills/will[@fm = '1'][@y = $me/@y]">
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
          <xsl:for-each select="$tp-wills/will[@fd = '1'][@y = $me/@y][number(@m) &lt; number($me/@m)][last()]">
            <li class="tp-nav-prev">
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                <xsl:with-param name="courant" select="$cour-jour"/>
                <xsl:with-param name="libelle" select="string(@jour)"/>
              </xsl:call-template>
              <span class="tp-nav-sep"> «</span>
            </li>
          </xsl:for-each>
          <xsl:for-each select="$tp-wills/will[@fd = '1'][@y = $me/@y][@m = $me/@m]">
            <li>
              <xsl:if test="@when = $me/@when"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('jour-', @when)"/>
                <xsl:with-param name="courant" select="$cour-jour"/>
                <xsl:with-param name="libelle" select="string(@jour)"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
          <xsl:for-each select="$tp-wills/will[@fd = '1'][@y = $me/@y][number(@m) &gt; number($me/@m)][1]">
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
          <xsl:for-each select="$tp-wills/will[@when = $me/@when]">
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
  <xsl:template name="tp-mode-bar">
    <xsl:variable name="w" select="@xml:id"/>
    <input type="radio" class="tp-mode tp-mode-tr" name="tp-mode-{$w}" id="tp-mode-tr-{$w}" checked="checked"/>
    <label class="tp-mode-label" for="tp-mode-tr-{$w}">Transcription</label>
    <input type="radio" class="tp-mode tp-mode-ed" name="tp-mode-{$w}" id="tp-mode-ed-{$w}"/>
    <label class="tp-mode-label" for="tp-mode-ed-{$w}">Édition</label>
  </xsl:template>
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
  <xsl:template match="*[local-name() = 'wrapper']/tei:head | *[local-name() = 'wrapper']/tei:group[count(*) = 1]/tei:head" priority="40">
    <xsl:variable name="lbl" select="normalize-space(.)"/>
    <xsl:variable name="seul" select="count(../*) = 1"/>
    <xsl:variable name="wj" select="$tp-wills/will[concat(@jour, ' ', @y) = $lbl]"/>
    <xsl:variable name="wm" select="$tp-wills/will[concat(@mois, ' ', @y) = $lbl]"/>
    <xsl:variable name="wy" select="$tp-wills/will[@y = $lbl]"/>
    <xsl:choose>
      <xsl:when test="$seul and $wj">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'jour'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="string($wj[1]/@y)"/>
          <xsl:with-param name="m" select="string($wj[1]/@m)"/>
          <xsl:with-param name="when" select="string($wj[1]/@when)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$seul and $wm">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'mois'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="string($wm[1]/@y)"/>
          <xsl:with-param name="m" select="string($wm[1]/@m)"/>
          <xsl:with-param name="when" select="''"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$seul and $wy">
        <xsl:call-template name="tp-groupe-page">
          <xsl:with-param name="niveau" select="'annee'"/>
          <xsl:with-param name="lbl" select="$lbl"/>
          <xsl:with-param name="y" select="$lbl"/>
          <xsl:with-param name="m" select="''"/>
          <xsl:with-param name="when" select="''"/>
        </xsl:call-template>
      </xsl:when>
      <!-- 2026-10-19 : page « Les testaments » : son titre, puis le sommaire de DoTS (années), sans la barre
           d'années ni la liste refaites à la main (décision de Maxime) -->
      <xsl:when test="$seul and $lbl = 'Les testaments'">
        <h1 class="head">Les testaments</h1>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
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
    <xsl:variable name="cour" select="string($courant)"/>
    <xsl:variable name="dedans"
      select="$tp-wills/will[$niveau = 'portail'
                           or ($niveau = 'annee' and @y = $y)
                           or ($niveau = 'mois' and @y = $y and @m = $m)
                           or ($niveau = 'jour' and @when = $when)]"/>
    <section class="tp-groupe" id="{$cour}">
      <nav class="tp-will-nav" aria-label="Navigation par année, mois et jour">
        <ul class="tp-years-list">
          <xsl:for-each select="$tp-wills/will[@fy = '1']">
            <li>
              <xsl:if test="@y = $y"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
              <xsl:call-template name="tp-nav-item">
                <xsl:with-param name="cible" select="concat('annee-', @y)"/>
                <xsl:with-param name="courant" select="$cour"/>
                <xsl:with-param name="libelle" select="string(@y)"/>
                <xsl:with-param name="ancetre" select="@y = $y"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
        <xsl:if test="$y != ''">
          <ul class="tp-months-list">
            <xsl:for-each select="$tp-wills/will[@fm = '1'][@y = $y]">
              <li>
                <xsl:if test="@m = $m"><xsl:attribute name="class">selected</xsl:attribute></xsl:if>
                <xsl:call-template name="tp-nav-item">
                  <xsl:with-param name="cible" select="concat('mois-', @y, '-', @m)"/>
                  <xsl:with-param name="courant" select="$cour"/>
                  <xsl:with-param name="libelle" select="string(@mois)"/>
                  <xsl:with-param name="ancetre" select="@m = $m"/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:if>
        <xsl:if test="$m != ''">
          <ul class="tp-days-list">
            <xsl:for-each select="$tp-wills/will[@fd = '1'][@y = $y][@m = $m]">
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
      <!-- niveau jour : la page du jour affiche le premier testament du jour (pas de page de jour vide) -->
      <xsl:if test="$niveau = 'jour' and $dedans[1]">
        <div class="tp-jour-testament">
          <xsl:apply-templates select="document($tp-uri-edition)//tei:text[@xml:id = string($dedans[1]/@id)]"/>
        </div>
      </xsl:if>
      <xsl:if test="$niveau != 'jour' and $niveau != 'mois'">
      <h1 style="font-size:1.5rem;color:#a73136;margin:0 0 .4rem;font-weight:400">
        <xsl:value-of select="$lbl"/>
      </h1>
      </xsl:if>
      <xsl:if test="$niveau != 'jour' and $niveau != 'mois'">
      <p style="margin:0 0 1.1rem;color:#6b6260;font-size:.95rem">
        <xsl:value-of select="count($dedans)"/>
        <xsl:text> testament</xsl:text>
        <xsl:if test="count($dedans) &gt; 1">s</xsl:if>
        <xsl:choose>
          <xsl:when test="$niveau = 'jour'"><xsl:text>. Cliquez un nom pour lire le testament.</xsl:text></xsl:when>
          <xsl:when test="$niveau = 'mois'">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-wills/will[@fd = '1'][@y = $y][@m = $m])"/>
            <xsl:text> jour</xsl:text>
            <xsl:if test="count($tp-wills/will[@fd = '1'][@y = $y][@m = $m]) &gt; 1">s</xsl:if>
            <xsl:text>. Choisissez un jour ou un testament.</xsl:text>
          </xsl:when>
          <xsl:when test="$niveau = 'annee'">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-wills/will[@fm = '1'][@y = $y])"/>
            <xsl:text> mois. Choisissez un mois.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="count($tp-wills/will[@fy = '1'])"/>
            <xsl:text> années. Choisissez une année.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$niveau = 'portail'">
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$tp-wills/will[@fy = '1']">
              <li style="padding:.3rem 0;border-bottom:1px solid #efeceb">
                <a class="internalLink" href="{concat($tp-route, 'annee-', @y)}"
                   style="color:#28211f;text-decoration:none;font-weight:700"><xsl:value-of select="@y"/></a>
                <xsl:call-template name="tp-groupe-compte">
                  <xsl:with-param name="k" select="count($tp-wills/will[@y = current()/@y])"/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:when test="$niveau = 'annee'">
          <ul class="tp-groupe-liste" style="list-style:none;padding:0;margin:0">
            <xsl:for-each select="$tp-wills/will[@fm = '1'][@y = $y]">
              <xsl:variable name="mm" select="@m"/>
              <li style="padding:.45rem 0;border-bottom:1px solid #efeceb">
                <a class="internalLink" href="{concat($tp-route, 'mois-', @y, '-', $mm)}"
                   style="color:#28211f;text-decoration:none;font-weight:700"><xsl:value-of select="@mois"/></a>
                <xsl:call-template name="tp-groupe-compte">
                  <xsl:with-param name="k" select="count($tp-wills/will[@y = $y][@m = $mm])"/>
                </xsl:call-template>
                <div style="padding:.15rem 0 0 1.2rem;color:#6b6260;font-size:.92rem">
                  <xsl:for-each select="$tp-wills/will[@fd = '1'][@y = $y][@m = $mm]">
                    <xsl:if test="position() &gt; 1"><span style="color:#c9bcbc"> | </span></xsl:if>
                    <a class="internalLink" href="{concat($tp-route, 'jour-', @when)}"
                       style="color:#28211f;text-decoration:none"><xsl:sequence select="ord:html(string(@jour))"/></a>
                  </xsl:for-each>
                </div>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <!-- niveau mois : pas de liste des jours et testaments dans le document (la TOC de dots-vue) -->
        <xsl:when test="$niveau = 'mois'"/>
        <!-- niveau jour : pas de liste des testaments dans le document (la TOC de dots-vue suffit) -->
        <xsl:otherwise/>
      </xsl:choose>
    </section>
  </xsl:template>
  <xsl:template name="tp-groupe-compte">
    <xsl:param name="k"/>
    <span style="color:#8a807e;font-size:.9rem">
      <xsl:text> — </xsl:text>
      <xsl:value-of select="$k"/>
      <xsl:text> testament</xsl:text>
      <xsl:if test="$k &gt; 1">s</xsl:if>
    </span>
  </xsl:template>
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
  <xsl:template match="tei:cit/tei:bibl" priority="12">
    <span class="bibl"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:bibl/tei:respStmt" priority="12">
    <span class="respStmt">
      <xsl:for-each select="tei:persName | tei:orgName | tei:name">
        <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:for-each select="tei:resp">
        <xsl:text> (</xsl:text>
        <xsl:value-of select="normalize-space(translate(., '()', ''))"/>
        <xsl:text>)</xsl:text>
      </xsl:for-each>
    </span>
  </xsl:template>
  <xsl:template match="tei:bibl/tei:msIdentifier" priority="12">
    <span class="idno"><xsl:apply-templates select="tei:idno/node()"/></span>
    <xsl:if test="tei:msName">
      <xsl:text> : </xsl:text>
      <span class="msName"><xsl:apply-templates select="tei:msName/node()"/></span>
    </xsl:if>
  </xsl:template>

  <!-- ==== 3. PROPRE AU PROJET ==== -->
  <xsl:template match="*[local-name() = 'title']" mode="a" priority="20">
    <span class="metadata-title"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="*[local-name() = 'type']" mode="a" priority="20"/>
  <xsl:template match="tei:TEI[tei:teiHeader]/tei:text" priority="15"/>
  <xsl:template match="tei:div[@type = 'index']" priority="9">
    <section class="tp-index" style="max-width:62rem;margin:0 auto;color:#222;font-family:Georgia,'Times New Roman',serif;line-height:1.55">
      <xsl:apply-templates/>
    </section>
  </xsl:template>
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
      <h3 style="font-size:1.1rem;color:#a73136;margin:1.5rem 0 .5rem">
        <xsl:value-of select="concat(if (self::tei:listPerson) then 'Index des testateurs' else 'Index des lieux de décès', '&#160;: lettre ', normalize-space(tei:head))"/>
      </h3>
      <xsl:apply-templates select="tei:person | tei:place"/>
      <xsl:if test="tei:person | tei:place">
        <p class="tp-backtotop"><a href="#tp-top-{@xml:id}">Haut de page</a></p>
      </xsl:if>
    </section>
  </xsl:template>
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
      <xsl:if test="tei:bibl">
        <p class="bibl" style="font-size:.88rem;color:#666;margin:.2rem 0 0">
          <span class="biblLabel">Références bibliographiques&#160;: </span>
          <xsl:apply-templates select="tei:bibl" mode="tp-bibl"/>
        </p>
      </xsl:if>
      <xsl:variable name="tp-w" select="tei:note[@type = 'linkToEdition']/tei:ref[starts-with(@target, '#will-')]"/>
      <xsl:if test="$tp-w">
        <section class="linksToEdition" style="font-size:.9rem">
          <ul style="margin:.2rem 0;padding-left:1.2rem">
            <li>
              <xsl:value-of select="if (count($tp-w) &gt; 1) then 'Auteur des testaments ' else 'Auteur du testament&#160;'"/>
              <xsl:for-each select="$tp-w">
                <xsl:variable name="wid" select="substring-after(@target, '#')"/>
                <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
                <a class="internalLink" title="Consulter le testament" href="{concat($tp-route, $wid)}"><xsl:value-of select="normalize-space(.)"/></a>
                <xsl:call-template name="tp-date-testament">
                  <xsl:with-param name="wid" select="$wid"/>
                </xsl:call-template>
              </xsl:for-each>
            </li>
          </ul>
        </section>
      </xsl:if>
    </article>
  </xsl:template>
  <xsl:template name="tp-date-testament">
    <xsl:param name="wid"/>
    <xsl:variable name="w" select="$tp-wills/will[@id = $wid]"/>
    <xsl:if test="$w/@when != ''">
      <xsl:value-of select="concat(' (', substring($w/@when, 9, 2), ' ', $w/@mois, ' ', $w/@y, ')')"/>
    </xsl:if>
  </xsl:template>
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
    <xsl:for-each select="tei:addName[@type = 'nickname']">
      <xsl:text>, dit </xsl:text>
      <span class="addName"><xsl:value-of select="normalize-space(.)"/></span>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="tei:place" priority="9">
    <article id="{@xml:id}" class="index-entry" style="border-bottom:1px dotted #e0dcd5;padding:.6rem 0;margin:0">
      <h4 class="placeName-Entry" style="margin:0 0 .3rem;font-size:1.05rem">
        <span class="placeName-entry">
          <xsl:call-template name="tp-lieu-nom"/>
          <xsl:variable name="locs" select="tei:location[not(@type)]"/>
          <xsl:variable name="loc">
            <xsl:choose>
              <xsl:when test="count($locs) &gt; 1 and not($locs/tei:country[normalize-space(.) != 'France'])">
                <xsl:for-each select="$locs">
                  <xsl:if test="position() &gt; 1"><xsl:text>, auj. </xsl:text></xsl:if>
                  <xsl:value-of select="normalize-space(tei:district[@type = 'departement'][normalize-space(.) != ''][1])"/>
                </xsl:for-each>
              </xsl:when>
              <xsl:when test="count($locs) &gt; 1">
                <xsl:for-each select="$locs">
                  <xsl:if test="position() &gt; 1"><xsl:text> ; auj. </xsl:text></xsl:if>
                  <xsl:value-of select="string-join((tei:district[@type = 'departement'][normalize-space(.) != ''], tei:country)/normalize-space(.), ', ')"/>
                </xsl:for-each>
              </xsl:when>
              <xsl:when test="$locs">
                <xsl:variable name="pays" select="normalize-space($locs[1]/tei:country[1])"/>
                <xsl:choose>
                  <xsl:when test="$pays = 'France' or $pays = ''">
                    <xsl:value-of select="string-join($locs[1]/tei:district[@type = 'departement'][normalize-space(.) != '']/normalize-space(.), ', ')"/>
                  </xsl:when>
                  <xsl:otherwise><xsl:value-of select="$pays"/></xsl:otherwise>
                </xsl:choose>
                <xsl:if test="$locs[1]/tei:placeName">
                  <xsl:text>, com. </xsl:text>
                  <xsl:for-each select="$locs[1]">
                    <xsl:call-template name="tp-lieu-nom"/>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          <xsl:if test="normalize-space($loc) != ''">
            <span class="displayedLocation" style="font-weight:normal;color:#555"> (<span class="departement"><xsl:value-of select="$loc"/></span>)</span>
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
      <xsl:variable name="morts" select="tei:note[@type = 'linksToEdition']/tei:ref[starts-with(@target, '#')]"/>
      <xsl:if test="$morts">
        <section class="linksToEdition" style="font-size:.9rem">
          <ul style="margin:.2rem 0;padding-left:1.2rem">
            <li>
              <xsl:value-of select="if (count($morts) &gt; 1) then 'Lieu de décès des testateurs suivants&#160;: ' else 'Lieu de décès du testateur suivant&#160;: '"/>
              <xsl:for-each select="$morts">
                <xsl:variable name="pid" select="substring-after(normalize-space(@target), '#')"/>
                <xsl:if test="position() &gt; 1"><xsl:text> ; </xsl:text></xsl:if>
                <a class="internalLink" title="Consulter la notice sur ce testateur dans l’index des testateurs">
                  <xsl:attribute name="href">
                    <xsl:value-of select="$elec-base"/><xsl:text>/testaments-poilus/document/testaments-poilus-edition</xsl:text>
                    <xsl:if test="normalize-space(@corresp) != ''"><xsl:value-of select="concat('?refId=', normalize-space(@corresp))"/></xsl:if>
                    <xsl:value-of select="concat('#', $pid)"/>
                  </xsl:attribute>
                  <xsl:value-of select="normalize-space(.)"/>
                </a>
                <xsl:variable name="tw" select="$tp-index-personnes/p[@id = $pid]/w"/>
                <xsl:if test="$tw">
                  <xsl:value-of select="if (count($tw) &gt; 1) then ' (testaments n° ' else ' (testament n° '"/>
                  <xsl:for-each select="$tw">
                    <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
                    <a class="internalLink" title="Consulter le testament" href="{concat($tp-route, @id)}"><xsl:value-of select="."/></a>
                  </xsl:for-each>
                  <xsl:text>)</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </li>
          </ul>
        </section>
      </xsl:if>
    </article>
  </xsl:template>
  <xsl:template name="tp-lieu-nom">
    <xsl:variable name="anciens" select="tei:placeName[@type = 'old'][not(contains(@when-iso, '/')) or substring-after(@when-iso, '/') = '' or number(substring(substring-after(@when-iso, '/'), 1, 4)) &gt;= 1914]"/>
    <xsl:variable name="actuels" select="tei:placeName[not(@type = 'old')]"/>
    <xsl:choose>
      <xsl:when test="$anciens and $actuels">
        <xsl:value-of select="concat(normalize-space($anciens[1]), ', auj. ', normalize-space($actuels[1]))"/>
      </xsl:when>
      <xsl:when test="$actuels">
        <xsl:value-of select="normalize-space($actuels[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(tei:placeName[1])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:p" mode="tp-inline"><p style="margin:.25rem 0"><xsl:apply-templates mode="tp-inline"/></p></xsl:template>
  <xsl:template match="tei:hi[@rend = 'sup' or @rend = 'super']" mode="tp-inline"><sup><xsl:apply-templates mode="tp-inline"/></sup></xsl:template>
  <xsl:template match="tei:placeName" mode="tp-inline">
    <xsl:choose>
      <xsl:when test="@ref[starts-with(., '#')]">
        <a class="linkToIndex" style="color:inherit;border-bottom:1px dotted #a73136;text-decoration:none">
          <xsl:attribute name="href">
            <xsl:value-of select="$elec-base"/><xsl:text>/testaments-poilus/document/testaments-poilus-edition</xsl:text>
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
  <xsl:template match="tei:pb" priority="10">
    <span class="tp-pb"><xsl:call-template name="tp-page-label"/></span>
    <xsl:call-template name="tp-page-comment"/>
  </xsl:template>
  <xsl:template match="tei:pb[ancestor::tei:div[@subtype = 'edited-from-notary-transcription']]" priority="12"/>
  <xsl:template name="tp-page-comment">
    <xsl:variable name="t" select="normalize-space(@type)"/>
    <xsl:variable name="txt">
      <xsl:choose>
        <xsl:when test="$t = 'whitePage_notDigitized'">(Page blanche, non numérisée)</xsl:when>
        <xsl:when test="$t = 'whitePage'">(Page blanche)</xsl:when>
        <xsl:when test="$t = 'pageWithExtraNotes_notDigitized'">(Page non numérisée, portant des mentions hors teneur postérieures au testament, non éditées)</xsl:when>
        <xsl:when test="contains($t, 'xtraNotes')">(Mentions hors teneur postérieures au testament, non éditées)</xsl:when>
        <xsl:when test="contains($t, 'seals')">(Cachets)</xsl:when>
        <xsl:when test="$t = 'codicil'">(Codicille)</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string($txt) != ''">
      <span class="editorialComment tp-pb-comment"><xsl:value-of select="$txt"/></span>
    </xsl:if>
  </xsl:template>
  <xsl:template name="tp-page-label">
    <xsl:choose>
      <xsl:when test="starts-with(@type, 'envelope-verso')">Verso de l’enveloppe</xsl:when>
      <xsl:when test="starts-with(@type, 'envelope')">Enveloppe</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="n">
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
  <xsl:template name="tp-facs-src">
    <xsl:variable name="fn"><xsl:call-template name="tp-facs-nom"/></xsl:variable>
    <xsl:value-of select="concat($elec-base, '/testaments-poilus/images/vignettes/', substring-before($fn, '.jpg'), '_ptt.jpg')"/>
  </xsl:template>
  <xsl:template name="tp-facs-src-full">
    <xsl:variable name="fn"><xsl:call-template name="tp-facs-nom"/></xsl:variable>
    <xsl:value-of select="concat($elec-base, '/testaments-poilus/images/sources/', $fn)"/>
  </xsl:template>
  <xsl:template name="tp-facs-nom">
    <xsl:choose>
      <xsl:when test="contains(@facs, '../images/')"><xsl:value-of select="substring-after(@facs, '../images/')"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="tokenize(@facs, '/')[last()]"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="tp-nav-item">
    <xsl:param name="cible"/>
    <xsl:param name="courant"/>
    <xsl:param name="libelle"/>
    <!-- ancetre : l'année ou le mois du jour affiché, en rouge comme le jour -->
    <xsl:param name="ancetre" select="false()"/>
    <xsl:choose>
      <xsl:when test="$cible = $courant or $ancetre">
        <strong class="tp-nav-courant"><xsl:sequence select="ord:html(string($libelle))"/></strong>
      </xsl:when>
      <xsl:otherwise>
        <a class="internalLink" href="{concat($tp-route, $cible)}"><xsl:sequence select="ord:html(string($libelle))"/></a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:persName[not(tei:surname)]" priority="9">
    <span class="persName"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:choice[tei:orig and tei:reg] | tei:choice[tei:abbr and tei:expan] | tei:choice[tei:sic and tei:corr]" priority="30">
    <span class="tp-tr tp-var"><xsl:apply-templates select="tei:orig/node() | tei:abbr/node() | tei:sic/node()"/></span>
    <span class="tp-ed tp-var"><xsl:apply-templates select="tei:reg/node() | tei:expan/node() | tei:corr/node()"/></span>
  </xsl:template>
  <xsl:template match="tei:ex" priority="20">
    <span class="tp-ex"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:lb[not(@n)]" priority="20">
    <xsl:if test="@break = 'no'">
      <span class="tp-tr tp-lb-hyph">-</span>
    </xsl:if>
    <br class="tp-tr tp-lb"/>
    <xsl:if test="not(@break = 'no')">
      <span class="tp-ed tp-lb-sp"><xsl:text> </xsl:text></span>
    </xsl:if>
  </xsl:template>
  <!-- 2026-10-29 : lacunes (<gap reason="unreadable"/>, "deleted-unreadable", testaments 18 et 60) : hteiml écrivait la
       raison brute, en anglais (« [deleted-unreadable] »). Mention en français, dans le style des commentaires éditoriaux. -->
  <xsl:template match="tei:gap[@reason = ('unreadable', 'deleted-unreadable', 'illegible')]" priority="20">
    <span class="gap" title="{if (@reason = 'deleted-unreadable') then 'passage biffé illisible' else 'passage illisible'}">
      <xsl:value-of select="if (@reason = 'deleted-unreadable') then '[biffé, illisible]' else '[illisible]'"/>
    </span>
  </xsl:template>
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
  <xsl:template match="tei:persName[tei:surname] | tei:placeName[tei:surname] | tei:name[tei:surname] | tei:orgName[tei:surname] | tei:author[tei:surname]" priority="12">
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:subst" priority="20">
    <span class="subst"><xsl:apply-templates select="*"/></span>
  </xsl:template>
  <xsl:template match="tei:del" priority="20">
    <del class="tp-tr tp-del"><xsl:apply-templates/></del>
  </xsl:template>
  <xsl:template match="tei:add" priority="20">
    <ins>
      <xsl:attribute name="class">
        <xsl:text>tp-add</xsl:text>
        <xsl:if test="normalize-space(@place) != ''"><xsl:value-of select="concat(' tp-add-', normalize-space(@place))"/></xsl:if>
      </xsl:attribute>
      <xsl:apply-templates/>
    </ins>
  </xsl:template>
  <xsl:template match="tei:supplied[not(parent::tei:choice)]" priority="20">
    <span class="tp-ed tp-supplied"><xsl:apply-templates/></span>
  </xsl:template>
  <!-- figure dont la légende (figDesc) répète le titre (head) : seul le titre s'affiche -->
  <xsl:template match="tei:figure/tei:figDesc[normalize-space(.) != '' and normalize-space(.) = normalize-space(../tei:head)]" priority="30"/>
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
  <xsl:template match="tei:front/tei:div[@type = 'reference']/tei:p" priority="20">
    <p class="p tp-reference">
      <xsl:if test="tei:ref">
        <span class="referenceLabel tp-referenceLabel">Cote aux Archives nationales : </span>
      </xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="tei:front//tei:persName[@ref[starts-with(., '#')]] | tei:front//tei:placeName[@ref[starts-with(., '#')]]" priority="25">
    <a>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('tp-linkToIndex linkToIndex ', local-name(), '-linked')"/>
      </xsl:attribute>
      <xsl:variable name="unite" select="substring-after(normalize-space(@ref), '#')"/>
      <xsl:attribute name="href">
        <xsl:value-of select="$elec-base"/><xsl:text>/testaments-poilus/document/testaments-poilus-edition</xsl:text>
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
  <xsl:template match="tei:handShift">
    <span class="tp-handshift" data-medium="{@medium}"/>
  </xsl:template>
  <xsl:template match="tei:opener">
    <div class="opener"><xsl:apply-templates/></div>
  </xsl:template>
  <xsl:template match="tei:byline/tei:docAuthor">
    <span class="author">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="tei:cit" priority="12">
    <span class="cit">
      <xsl:for-each select="*">
        <xsl:if test="position() != 1"><xsl:text> </xsl:text></xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </span>
  </xsl:template>
  <xsl:template match="tei:cit/tei:quote" priority="12">
    <q class="quote"><xsl:apply-templates/></q>
  </xsl:template>
  <xsl:template match="tei:metamark" priority="20">
    <xsl:variable name="r" select="normalize-space(@rend)"/>
    <xsl:variable name="lib">
      <xsl:choose>
        <xsl:when test="$r = 'cross'">croix</xsl:when>
        <xsl:when test="contains($r, 'Wavy')">trait ondulé</xsl:when>
        <xsl:when test="contains($r, 'orizontalLine')">trait horizontal</xsl:when>
        <xsl:when test="contains($r, 'erticalLine')">trait vertical</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string($lib) != ''">
      <span class="metamark tp-tr"><xsl:value-of select="concat('(', $lib, ')')"/></span>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:body/tei:div[@xml:id][@type = 'letter' or @type = 'will']" priority="20">
    <xsl:param name="level" select="count(ancestor::*) - 2"/>
    <xsl:variable name="lettre" select="substring(@xml:id, string-length(@xml:id))"/>
    <xsl:if test="preceding-sibling::tei:div[@type = 'letter' or @type = 'will']"><hr/></xsl:if>
    <p class="editorialComment tp-piece">
      <xsl:value-of select="concat(if (@type = 'letter') then 'Lettre testamentaire ' else 'Testament ', $lettre)"/>
    </p>
    <xsl:next-match>
      <xsl:with-param name="level" select="$level"/>
    </xsl:next-match>
  </xsl:template>

  <!-- ==== 4. MÉCANISMES COMMUNS : tableau filtrable (tf-*), liens vers l'ancien site (D5), liens internes entre fragments ==== -->
  <xsl:template match="tei:ref[@type = 'linkToEdition'] | tei:ref[@type = 'linkToPersonsIndex'] | tei:ref[@type = 'linkToIntro'] | tei:ref[@type = 'linkToBibl']" priority="26">
    <xsl:variable name="cible" select="substring-after(normalize-space(@target), '#')"/>
    <xsl:variable name="co" select="normalize-space(@corresp)"/>
    <xsl:variable name="ouvr" select="string($tp-unites/unite[@id = $cible]/@ouvrable)"/>
    <xsl:choose>
      <xsl:when test="$cible = ''">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <a>
          <xsl:attribute name="class"><xsl:value-of select="concat(@type, ' tp-renvoi')"/></xsl:attribute>
          <xsl:if test="normalize-space(@n) != ''">
            <xsl:attribute name="title"><xsl:value-of select="normalize-space(@n)"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="href">
            <xsl:value-of select="$elec-base"/><xsl:text>/testaments-poilus/document/</xsl:text>
            <xsl:choose>
              <xsl:when test="starts-with($co, 'testaments-poilus-') and $ouvr != ''">
                <xsl:value-of select="concat($co, '?refId=', $ouvr, '#', $cible)"/>
              </xsl:when>
              <xsl:when test="starts-with($co, 'testaments-poilus-')">
                <xsl:value-of select="concat($co, '?refId=', $cible)"/>
              </xsl:when>
              <xsl:when test="$co != ''">
                <xsl:value-of select="concat('testaments-poilus-edition?refId=', $co, '#', $cible)"/>
              </xsl:when>
              <xsl:when test="$ouvr != ''">
                <xsl:value-of select="concat('testaments-poilus-edition?refId=', $ouvr, '#', $cible)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('testaments-poilus-edition?refId=', $cible)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:ref[not(@type)][starts-with(normalize-space(@target), '#will-')]" priority="26">
    <a class="tp-renvoi-testament internalLink">
      <xsl:attribute name="href">
        <xsl:value-of select="concat($tp-route, substring-after(normalize-space(@target), '#'))"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- ====================================================================
       Index des testateurs et des lieux de décès en tableaux triables et filtrables
       (2026-10-13 ; module commun tableau-filtrable.xsl, comportement dans
       testaments-poilus.customJs.js des settings dots-vue).
       - Page d'une lettre (testateurs-A, lieux-B…) : le tableau des entrées de la lettre.
       - Page de l'index entier (index-testateurs, index-lieux) : DoTS n'y donne que le
         titre (les lettres sont des pages du sommaire) ; le tableau complet est lu dans
         le fichier compagnon $tp-uri-edition, comme les autres renvois de cette feuille.
       Chaque ligne garde l'@xml:id de l'entrée : les liens existants vers #EAime, #pl-039…
       tombent sur elle.
       ==================================================================== -->
  <xsl:template version="3.0" match="tei:listPerson[@xml:id = 'index-testateurs'] | tei:listPlace[@xml:id = 'index-lieux']" priority="12">
    <xsl:variable name="personnes" select="self::tei:listPerson"/>
    <xsl:variable name="entrees" select="if (.//tei:person | .//tei:place) then (.//tei:person | .//tei:place)
        else if (doc-available($tp-uri-edition)) then document($tp-uri-edition)//*[@xml:id = current()/@xml:id]//(tei:person | tei:place)
        else ()"/>
    <section id="{@xml:id}" class="{if ($personnes) then 'tp-index-persons' else 'tp-index-places'}">
      <!-- 2026-10-19 : titre de page (h1.head) comme les autres corpus, et non un h2 en style en ligne -->
      <h1 class="head"><xsl:value-of select="if ($personnes) then 'Index des testateurs' else 'Index des lieux de décès'"/></h1>
      <xsl:choose>
        <xsl:when test="$personnes"><xsl:call-template name="tp-tableau-testateurs"><xsl:with-param name="entrees" select="$entrees"/><xsl:with-param name="nom-csv" select="'testaments-testateurs'"/></xsl:call-template></xsl:when>
        <xsl:otherwise><xsl:call-template name="tp-tableau-lieux"><xsl:with-param name="entrees" select="$entrees"/><xsl:with-param name="nom-csv" select="'testaments-lieux-deces'"/></xsl:call-template></xsl:otherwise>
      </xsl:choose>
    </section>
  </xsl:template>

  <xsl:template version="3.0" match="tei:listPerson[starts-with(@xml:id, 'testateurs-')][not(tei:listPerson)] | tei:listPlace[starts-with(@xml:id, 'lieux-')][not(tei:listPlace)]" priority="12">
    <xsl:variable name="personnes" select="self::tei:listPerson"/>
    <section id="{@xml:id}" class="tp-index-letter" style="scroll-margin-top:90px">
      <h3 style="font-size:1.1rem;color:#a73136;margin:1.5rem 0 .5rem">
        <xsl:value-of select="concat(if ($personnes) then 'Index des testateurs' else 'Index des lieux de décès', '&#160;: lettre ', normalize-space(tei:head))"/>
      </h3>
      <xsl:choose>
        <xsl:when test="$personnes"><xsl:call-template name="tp-tableau-testateurs"><xsl:with-param name="entrees" select="tei:person"/><xsl:with-param name="nom-csv" select="concat('testaments-testateurs-', normalize-space(tei:head))"/></xsl:call-template></xsl:when>
        <xsl:otherwise><xsl:call-template name="tp-tableau-lieux"><xsl:with-param name="entrees" select="tei:place"/><xsl:with-param name="nom-csv" select="concat('testaments-lieux-deces-', normalize-space(tei:head))"/></xsl:call-template></xsl:otherwise>
      </xsl:choose>
    </section>
  </xsl:template>

  <!-- Testateurs : Nom · Dates · Notice (domicile, mariage, état ; références) · Décès (le
       paragraphe qui nomme le lieu de décès) · Testament. -->
  <xsl:template version="3.0" name="tp-tableau-testateurs">
    <xsl:param name="entrees"/>
    <xsl:param name="nom-csv"/>
    <xsl:variable name="uca" select="'http://www.w3.org/2013/collation/UCA?lang=fr;strength=primary'"/>
    <div class="tf-cadre tp-tableau-cadre">
      <xsl:call-template name="tf-barre">
        <xsl:with-param name="total" select="count($entrees)"/>
        <xsl:with-param name="unite" select="'testateurs'"/>
      </xsl:call-template>
      <table class="tf-tableau tp-tableau tp-testateurs" data-csv-nom="{$nom-csv}" data-csv-entetes="Nom|Dates|Notice|Décès|Testament">
        <caption class="tf-legende">Cliquer sur un en-tête de colonne pour trier (un second clic inverse l’ordre).</caption>
        <thead>
          <tr>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-nom'"/><xsl:with-param name="libelle" select="'Nom'"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-dates'"/><xsl:with-param name="libelle" select="'Dates'"/><xsl:with-param name="numerique" select="true()"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-notice'"/><xsl:with-param name="libelle" select="'Notice'"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-deces'"/><xsl:with-param name="libelle" select="'Décès'"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-testament'"/><xsl:with-param name="libelle" select="'Testament'"/><xsl:with-param name="numerique" select="true()"/></xsl:call-template>
          </tr>
          <tr class="tf-filtres">
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="0"/><xsl:with-param name="libelle" select="'Nom'"/><xsl:with-param name="liste" select="concat($nom-csv, '-noms')"/><xsl:with-param name="suggestions" select="sort(distinct-values($entrees/tei:persName/tei:surname ! normalize-space(.)), $uca)"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="1"/><xsl:with-param name="libelle" select="'Dates'"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="2"/><xsl:with-param name="libelle" select="'Notice'"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="3"/><xsl:with-param name="libelle" select="'Décès'"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="4"/><xsl:with-param name="libelle" select="'Testament'"/><xsl:with-param name="placeholder" select="'n°'"/></xsl:call-template>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$entrees">
            <xsl:variable name="nom" select="normalize-space(string-join((tei:persName/tei:surname, tei:persName/tei:forename), ' '))"/>
            <xsl:variable name="bio" select="tei:note[@type = 'biography']/tei:p"/>
            <xsl:variable name="deces" select="($bio[tei:placeName])[last()]"/>
            <xsl:variable name="autres" select="$bio except $deces"/>
            <xsl:variable name="dates" select="if (tei:birth or tei:death) then concat(normalize-space(tei:birth), '-', normalize-space(tei:death)) else ''"/>
            <xsl:variable name="ws" select="tei:note[@type = 'linkToEdition']/tei:ref[starts-with(@target, '#will-')]"/>
            <tr id="{@xml:id}" data-o="{position()}">
              <td class="tp-c-nom" data-sort="{$nom}" data-f="{tf:plat($nom)}"><xsl:apply-templates select="tei:persName" mode="tp-name"/></td>
              <td class="tp-c-dates" data-sort="{normalize-space(tei:birth)}" data-f="{tf:plat($dates)}">
                <xsl:choose>
                  <xsl:when test="$dates != ''"><xsl:value-of select="$dates"/></xsl:when>
                  <xsl:otherwise><span class="tf-vide">—</span></xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="tp-c-notice" data-sort="{normalize-space(string-join($autres, ' '))}" data-f="{tf:plat(string-join($autres, ' '))}" data-csv="{normalize-space(string-join($autres, ' '))}">
                <xsl:apply-templates select="$autres" mode="tp-inline"/>
                <xsl:if test="tei:bibl">
                  <p class="bibl tp-refs"><span class="biblLabel">Références&#160;: </span><xsl:apply-templates select="tei:bibl" mode="tp-bibl"/></p>
                </xsl:if>
              </td>
              <td class="tp-c-deces" data-sort="{normalize-space(string-join($deces/tei:placeName, ' '))}" data-f="{tf:plat(string($deces))}" data-csv="{normalize-space($deces)}">
                <xsl:choose>
                  <xsl:when test="$deces"><xsl:apply-templates select="$deces" mode="tp-inline"/></xsl:when>
                  <xsl:otherwise><span class="tf-vide">—</span></xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="tp-c-testament" data-sort="{normalize-space($ws[1])}" data-f="{string-join($ws ! normalize-space(.), ' ')}" data-csv="{string-join($ws ! normalize-space(.), ', ')}">
                <xsl:choose>
                  <xsl:when test="$ws">
                    <xsl:for-each select="$ws">
                      <xsl:variable name="wid" select="substring-after(@target, '#')"/>
                      <xsl:if test="position() &gt; 1"><br/></xsl:if>
                      <a class="internalLink" title="Consulter le testament" href="{concat($tp-route, $wid)}"><xsl:value-of select="concat('n° ', normalize-space(.))"/></a>
                      <xsl:call-template name="tp-date-testament"><xsl:with-param name="wid" select="$wid"/></xsl:call-template>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise><span class="tf-vide">—</span></xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <!-- Lieux de décès : Lieu (et Geonames) · Département ou pays · Testateurs morts en ce lieu
       (avec leur testament). Filtre en liste sur le département, ou le pays hors de France. -->
  <xsl:template version="3.0" name="tp-tableau-lieux">
    <xsl:param name="entrees"/>
    <xsl:param name="nom-csv"/>
    <xsl:variable name="uca" select="'http://www.w3.org/2013/collation/UCA?lang=fr;strength=primary'"/>
    <div class="tf-cadre tp-tableau-cadre">
      <xsl:call-template name="tf-barre">
        <xsl:with-param name="total" select="count($entrees)"/>
        <xsl:with-param name="unite" select="'lieux'"/>
      </xsl:call-template>
      <table class="tf-tableau tp-tableau tp-lieux" data-csv-nom="{$nom-csv}" data-csv-entetes="Lieu|Département ou pays|Testateurs">
        <caption class="tf-legende">Cliquer sur un en-tête de colonne pour trier (un second clic inverse l’ordre).</caption>
        <thead>
          <tr>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-nom'"/><xsl:with-param name="libelle" select="'Lieu'"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-dep'"/><xsl:with-param name="libelle" select="'Département ou pays'"/></xsl:call-template>
            <xsl:call-template name="tf-th"><xsl:with-param name="classe" select="'tp-c-morts'"/><xsl:with-param name="libelle" select="'Testateurs'"/><xsl:with-param name="numerique" select="true()"/></xsl:call-template>
          </tr>
          <tr class="tf-filtres">
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="0"/><xsl:with-param name="libelle" select="'Lieu'"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="1"/><xsl:with-param name="libelle" select="'Département ou pays'"/><xsl:with-param name="type" select="'liste'"/><xsl:with-param name="tous" select="'Tous'"/>
              <xsl:with-param name="options" select="sort(distinct-values(for $p in $entrees return tp:lieu-cles($p)), $uca)" xmlns:tp="urn:testaments-poilus:xsl"/></xsl:call-template>
            <xsl:call-template name="tf-filtre"><xsl:with-param name="col" select="2"/><xsl:with-param name="libelle" select="'Testateurs'"/></xsl:call-template>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$entrees">
            <xsl:variable name="lieu"><xsl:call-template name="tp-lieu-nom"/></xsl:variable>
            <xsl:variable name="cles" select="tp:lieu-cles(.)" xmlns:tp="urn:testaments-poilus:xsl"/>
            <xsl:variable name="locs" select="tei:location[not(@type)]"/>
            <xsl:variable name="dep" select="string-join(distinct-values(for $l in $locs return string-join(($l/tei:district[@type = 'departement'][normalize-space(.) != ''], $l/tei:country[normalize-space(.) != 'France'])/normalize-space(.), ', ')), ' ; auj. ')"/>
            <xsl:variable name="morts" select="tei:note[@type = 'linksToEdition']/tei:ref[starts-with(@target, '#')]"/>
            <xsl:variable name="geo" select="tei:idno[@type = 'geonamesURI']"/>
            <tr id="{@xml:id}" data-o="{position()}">
              <td class="tp-c-nom" data-sort="{normalize-space($lieu)}" data-f="{tf:plat(string($lieu))}" data-csv="{normalize-space($lieu)}">
                <xsl:value-of select="normalize-space($lieu)"/>
                <xsl:if test="$geo"><span class="tp-geonames"><a class="externalLink" href="{normalize-space($geo)}" target="_blank" rel="noopener">Geonames</a></span></xsl:if>
              </td>
              <td class="tp-c-dep" data-sort="{$cles[1]}" data-f="{tf:plat(string-join($cles, ' ; '))}">
                <xsl:choose>
                  <xsl:when test="$dep != ''"><xsl:value-of select="$dep"/></xsl:when>
                  <xsl:otherwise><span class="tf-vide">—</span></xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="tp-c-morts" data-sort="{count($morts)}" data-f="{tf:plat(string-join($morts, ' '))}" data-csv="{string-join($morts ! normalize-space(.), ' ; ')}">
                <xsl:choose>
                  <xsl:when test="$morts">
                    <xsl:for-each select="$morts">
                      <xsl:variable name="pid" select="substring-after(normalize-space(@target), '#')"/>
                      <xsl:if test="position() &gt; 1"><br/></xsl:if>
                      <a class="internalLink" title="Consulter la notice sur ce testateur dans l’index des testateurs">
                        <xsl:attribute name="href">
                          <xsl:value-of select="$elec-base"/><xsl:text>/testaments-poilus/document/testaments-poilus-edition</xsl:text>
                          <xsl:if test="normalize-space(@corresp) != ''"><xsl:value-of select="concat('?refId=', normalize-space(@corresp))"/></xsl:if>
                          <xsl:value-of select="concat('#', $pid)"/>
                        </xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                      </a>
                      <xsl:variable name="tw" select="$tp-index-personnes/p[@id = $pid]/w"/>
                      <xsl:if test="$tw">
                        <xsl:text> (</xsl:text>
                        <xsl:for-each select="$tw">
                          <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
                          <a class="internalLink" title="Consulter le testament" href="{concat($tp-route, @id)}"><xsl:value-of select="concat('n° ', .)"/></a>
                        </xsl:for-each>
                        <xsl:text>)</xsl:text>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise><span class="tf-vide">—</span></xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

</xsl:transform>
