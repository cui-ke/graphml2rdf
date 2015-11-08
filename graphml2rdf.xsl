<?xml version="1.0"?>
<xsl:stylesheet    
xmlns="http://vgibox.eu/"
  
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:java="http://www.yworks.com/xml/yfiles-common/1.0/java" 
xmlns:sys="http://www.yworks.com/xml/yfiles-common/markup/primitives/2.0" 
xmlns:x="http://www.yworks.com/xml/yfiles-common/markup/2.0" 
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xmlns:y="http://www.yworks.com/xml/graphml" 
xmlns:yed="http://www.yworks.com/xml/yed/3" 

xmlns:def="http://graphml.graphdrawing.org/xmlns" 

xmlns:xs="http://www.w3.org/2001/XMLSchema" 

xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         
version="2.0"> 

<!-- 
    Transform a graphml/ER graph into an RDF graph
    
    G. Falquet, 2015
-->

<!-- take as prefix the last element of the base uri, i.e. the xml filename -->
<xsl:param name="prefix" as="xs:string"><xsl:value-of select="substring-before(def:last-part(base-uri()),'.graphml')"/></xsl:param>

<xsl:function name="def:last-part" as="xs:string">
  <xsl:param name="uri" as="xs:string"/>
  <xsl:sequence  
     select="if (contains($uri, '/'))
             then def:last-part(substring-after($uri, '/'))
             else $uri"/>
</xsl:function>

<!-- output namespace -->

<xsl:param name="outns" as="xs:string">http://vgibox.eu/onto</xsl:param>


<xsl:template match="/"> 
   <rdf:RDF
      xml:base="http://vgibox.eu/"
   >
     <xsl:apply-templates /> 
   </rdf:RDF>
</xsl:template>

<!-- ====================================
     Nodes
======================================= -->

<xsl:template match="def:node[def:data/y:GenericNode[@configuration='com.yworks.entityRelationship.big_entity']]"> 
     <xsl:variable name="cname" select="normalize-space(.//y:NodeLabel[@configuration='com.yworks.entityRelationship.label.name'])"/>
     <xsl:variable name="cnameNoWS" select="replace($cname,' ','_')"/>
     <xsl:variable name="iname" select="normalize-space(.//y:NodeLabel[@configuration='com.yworks.entityRelationship.label.attributes'])"/> 
<xsl:text> 

</xsl:text>

   <rdf:Description>
       <xsl:attribute name="rdf:about" ><xsl:call-template name="node-id"><xsl:with-param name="nid" select="@id" /></xsl:call-template></xsl:attribute>
       
       <!-- Class names is present, generate an rdf:type triple -->
   
       <xsl:if test="$cname != ''">
          <xsl:text> 

          </xsl:text>
          <rdf:type> <xsl:attribute name="rdf:resource"><xsl:value-of select="$cnameNoWS"/></xsl:attribute></rdf:type>
     
       </xsl:if>  
   
       <!-- Generate a label -->
       <xsl:text> 

       </xsl:text>       
       <rdfs:label><xsl:call-template name="node-name"><xsl:with-param name="nid" select="@id" /></xsl:call-template> </rdfs:label>
   </rdf:Description>
   
   

</xsl:template>

<xsl:template match="text()"> 
</xsl:template>


<!-- 
=================================================
               Node-name
================================================== 

Principle: 
  (class name, instance name) -> instance name
  (class name, <empty>) -> node id
  (<empty>, instance name) -> instance name
  (<empty>, <empty>) -> node id
  
-->

<xsl:template name="node-name">
  <xsl:param name="nid" /> 
  <xsl:variable name="cname" 
    select="normalize-space(//def:node[@id=$nid]//y:NodeLabel[@configuration='com.yworks.entityRelationship.label.name'])"/>
  <xsl:variable name="iname" select="normalize-space(//def:node[@id=$nid]//y:NodeLabel[@configuration='com.yworks.entityRelationship.label.attributes'])"/>
  <xsl:choose>
     <xsl:when test="string-length($cname) = 0">
        <xsl:if test="$iname != ''"><xsl:value-of select="$iname"/>
        </xsl:if>
        <xsl:if test="$iname = ''"><xsl:value-of select="concat('intance_',$nid)"/>
        </xsl:if>
     </xsl:when>
     <xsl:otherwise>
        <xsl:if test="$iname = ''">
            <xsl:value-of select="concat('instance_',$nid)"/>
        </xsl:if>
        <xsl:if test="$iname != ''">
            <xsl:value-of select="$iname"/>
        </xsl:if>
     </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
===============================
           Node uri
===============================
-->
<xsl:template name="node-id">
  <xsl:param name="nid" />
  <xsl:variable name="nn"><xsl:call-template name="node-name"><xsl:with-param name="nid" select="$nid" /></xsl:call-template> </xsl:variable>
  <xsl:variable name="nprefix"><xsl:value-of select="substring(//def:node[@id=$nid]//y:GenericNode/y:Geometry/@x,1,4)"/>-<xsl:value-of select="substring(//def:node[@id=$nid]//y:GenericNode/y:Geometry/@y,1,4)"/></xsl:variable>

  <xsl:value-of select="concat($prefix,'/',translate($nn,' ?','__'))"/>
</xsl:template>  

<!--=================== 
          Edge 
   =====================
-->
<xsl:template match="def:edge">
  
  <xsl:variable name="pname"  select="normalize-space(.//y:EdgeLabel)"/>
  <xsl:variable name="pid"  select="translate($pname,' ?','__')"/>
  
  <xsl:if test="$pid != ''">
       <xsl:text> 

       </xsl:text>
       <rdf:Description>
         <xsl:attribute name="rdf:about" ><xsl:call-template name="node-id"><xsl:with-param name="nid" select="@source" /></xsl:call-template></xsl:attribute>
     
     
         <xsl:element name="{$pid}" >
               <xsl:attribute name="rdf:resource" ><xsl:call-template name="node-id"><xsl:with-param name="nid" select="@target" /></xsl:call-template></xsl:attribute>
   
         </xsl:element> 
      </rdf:Description>
  
      <xsl:if test="$pname != $pid">
         <xsl:text> 

         </xsl:text>
         <rdf:Description>
            <xsl:attribute name="rdf:about" ><xsl:value-of select="$pid"/></xsl:attribute>
            <rdfs:label><xsl:value-of select="$pname"/></rdfs:label>
          </rdf:Description> 
       </xsl:if>
  </xsl:if>
</xsl:template>


</xsl:stylesheet>