<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">

    <xsl:param name="preserve-empty-whitespace" select="'true'"/>

    <xsl:template match="@*|node()">
        <xsl:choose>
            <xsl:when test="ancestor::*[matches(local-name(),'^h[d\d]$')]">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="self::* and (parent::*/text() or $preserve-empty-whitespace='false') and normalize-space(string-join(parent::*/text(),''))=''">
                    <xsl:text>
</xsl:text>
                    <xsl:for-each select="1 to count(ancestor::*)">
                        <xsl:text>    </xsl:text>
                    </xsl:for-each>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                    <xsl:if test="not(self::*[matches(local-name(),'^h[d\d]$')]) and self::* and * and (text() or $preserve-empty-whitespace='false') and normalize-space(string-join(text(),''))=''">
                        <xsl:text>
</xsl:text>
                        <xsl:for-each select="1 to count(ancestor::*)">
                            <xsl:text>    </xsl:text>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="/*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:if test="normalize-space(string-join(text(),''))=''">
                <xsl:text>
</xsl:text>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()[not(ancestor::*[matches(local-name(),'^h[d\d]$')]) and not(.='') and normalize-space(.)='']">
        <xsl:text> </xsl:text>
    </xsl:template>

</xsl:stylesheet>
