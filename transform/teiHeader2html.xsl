<?xml version="1.0" encoding="UTF-8"?>
<!-- [testaments-poilus] Page de titre (route /api/dts/cover?id=testaments-poilus-edition).
     Adaptée à la marge du modèle des chroniques latines (teiHeader2html 1.xsl) et de
     dubourg/transform/teiHeader2html.xsl : titre, « Édité par » (principal), « Édition
     électronique par » (editor), date lue dans le TEI (publicationStmt/date).
     Ajouts propres à ce corpus : respStmt (contributions) ; funder non rendu (voir RAPPORT.md). -->
<xsl:transform   version="1.1"   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:eg="http://www.tei-c.org/ns/Examples"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  exclude-result-prefixes="eg html rng tei epub"

  xmlns:exslt="http://exslt.org/common"
  extension-element-prefixes="exslt">

  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
      <div id="aside">to delete</div>
      <div id="center">
        <div id="main">
          <div id="article"><xsl:apply-templates select="//tei:fileDesc/tei:titleStmt"/></div>
        </div>
      </div>
    </html>
  </xsl:template>

  <xsl:template match="tei:titleStmt">
    <div class="titlestmt">
      <!-- Premier titre uniquement. [testaments-poilus] Le teiHeader porte « Testaments de poilus :
           édition numérique » ; la page de l'ancien site porte « Testaments de guerre de Poilus
           parisiens (1914-1918) : une édition critique » (ELEC, accueil). Le TEI fait foi ici. -->
      <h1 class="head">
        <xsl:value-of select="normalize-space(tei:title[1])"/>
      </h1>

      <!-- Éditeur scientifique. [testaments-poilus] un seul <principal> : Christine Nougaret. -->
      <xsl:if test="tei:principal">
        <p class="editors">
          <span class="editors-label">Édité par </span>
          <xsl:for-each select="tei:principal">
            <span class="editor">
              <xsl:value-of select="normalize-space(.)"/>
            </span>
            <xsl:choose>
              <xsl:when test="position() = last() - 1"> et </xsl:when>
              <xsl:when test="position() &lt; last()">, </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </p>
      </xsl:if>

      <!-- [Du Bourg] Édition électronique : <editor>. [testaments-poilus] un seul <editor> : Florence Clavaud. -->
      <xsl:if test="tei:editor">
        <p class="editors">
          <span class="editors-label">Édition électronique par </span>
          <xsl:for-each select="tei:editor">
            <span class="editor">
              <xsl:value-of select="normalize-space(.)"/>
            </span>
            <xsl:choose>
              <xsl:when test="position() = last() - 1"> et </xsl:when>
              <xsl:when test="position() &lt; last()">, </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </p>
      </xsl:if>

      <!-- Date de la première édition électronique, lue dans le teiHeader.
           [testaments-poilus] publicationStmt/date = « 2016 » ; l'ELEC écrit « 2017-.... » (citation
           et pied de page). Le TEI fait foi ici, l'écart est à arbitrer (RAPPORT.md). -->
      <span class="date">
        <xsl:value-of select="normalize-space(../tei:publicationStmt/tei:date[1])"/>
      </span>
    </div>
  </xsl:template>

</xsl:transform>
