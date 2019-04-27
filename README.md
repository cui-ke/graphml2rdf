## graphml/Entity Relationship to OWL

This python script takes as input a graphml file, produced with the yEd graph editor,
that contains 'Entity with Attributes' nodes and labelled edges. It translates it
into an OWL ontology in RDF/Turtle format.

The translation rules are:

- every 'Entity with Attributes' node with label C is transformed into a OWL class C
- an edge with label 'subClassOf' from C to D ---> an axiom 

         :C rdfs:subClassOf :D
         
- an edge with label P from C to D ---> an axiom 

         :C rdfs:subClassOf [a owl:Restriction ; owl:onProperty :P ; owl:allValuesFrom :D]
         
- an edge with a label of the form 'P min 1' from C to D ---> an axiom 

         :C rdfs:subClassOf [a owl:Restriction ; owl:onProperty :P ; owl:someValuesFrom :D]
 
 - the second label (in the attribute box of the node) is considered as a comment. It yields
 
         :C rdfs:comment Text-of-the-attribute-box
         
### Usage: 

$ python graphml2owl.py graphmlfile

The OWL ontology is written into graphmlfile_owl.ttl

!! requires python 3.7 (uses type annotations)


     
## graphml2rdf: a Graphml to RDF translator

This xsl stylesheets transforms a graphml file produced by yEd using the Entity-Relationship elements into an RDF graph.

The graph must be composed of _Entity with Attributes_ or _Entity_ nodes (from the Entity-Relationship palette in yEd). For _Entity with Attributes_ nodes

  - the Entity field (top) must contain a class name (or empty)
  - the Attributes field (bottom) must contain an instance name (or empty)

See the file _ex-1.graphml_ for an example.

_Entity_ nodes represent literal values. The node label must contain the value without quotes. Literal types are not supportent yet.

See the file _ex-lit.graphml_ for an example.
  
To run the transformation tool

  1. Download graphml2rdf.xsl and saxon9he.jar (the Saxon xml library)
  2. Execute the following command:

    java -jar saxon9he.jar -xsl:graphml2rdf.xsl graphml-file > rdf-file
   
The output file is an RDF/XML file. It can be directly uploaded into a triple store.

#### Transformation principles

 ![transformation principles](graphml2rdf_Principles.png)

The instance names generate "local" URIs, based on the input file name.  Thus several generated RDF files can be uploaded to a repository without mixing up the instance names. The class names generate "global" URIs, independent of the source file. So the same class name appearing in different graphml graphs will generate the same URI. In this sense class names are global.
