"""graphml/Entity Relationship to OWL

Usage: 

$ python graphml2owl.py graphmlfile

The OWL ontology is written into graphmlfile_owl.ttl

!! requires python 3.7 (uses type annotations)
 
This scripts takes as input a graphml file produced with the yEd graph editor
that contains 'Entity with Attributes' nodes and labelled edges. It translates it
into an OWL ontology in RDF/Turtle format.

The translation rules are:

- every 'Entity with Attributes' node with label C is transformed into a OWL class C
- an edge with label 'subClassOf' from C to D ---> an axiom :C rdfs:subClassOf :D
- an edge with label P from C to D ---> an axiom 
     :C rdfs:subClassOf [a owl:Restriction ; owl:onProperty :P ; owl:allValuesFrom :D]
- an edge with a label of the form 'P min 1' from C to D ---> an axiom 
     :C rdfs:subClassOf [a owl:Restriction ; owl:onProperty :P ; owl:someValuesFrom :D]

G. Falquet 2019

"""
import xml.etree.ElementTree as ET
import re
import sys
from typing import List, FrozenSet, Dict

# usage = python graphml2owl.py file.graphml
ifileName = sys.argv[1]
ofileName = sys.argv[1]+"_owl.ttl"
print('Output to '+ofileName)
sys.stdout = open(ofileName, 'w')

ns = {'g': 'http://graphml.graphdrawing.org/xmlns',
      'x': 'http://www.yworks.com/xml/yfiles-common/markup/2.0',
      'y': 'http://www.yworks.com/xml/graphml'}

root: ET.Element = ET.parse(ifileName).getroot()

print("""
@prefix : <http://cs-eu.net/onto#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xml: <http://www.w3.org/XML/1998/namespace> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .

""")

print(f"""
<http://cs-eu.net/{ofileName}> rdf:type owl:Ontology .

""")

classNames: FrozenSet[str] = frozenset()
classNameOfNode: Dict[str, str] = {}
annotationOfClass: Dict[str, str] = {}

for n in root.findall('.//g:node',ns):
    nodeLabels: List[ET.Element] = n.findall('./g:data/y:GenericNode[@configuration="com.yworks.entityRelationship.big_entity"]/y:NodeLabel',ns)
    
    if len(nodeLabels) > 0 :
        clsLabel: ET.Element = nodeLabels[0]
        nodeId = n.get('id')
        clsName = clsLabel.text
        clsName = re.sub(r'[^a-z^A-Z^0-9^-^:]', '_', clsName)
        classNames = classNames.union({clsName})
        classNameOfNode[nodeId] = clsName
        if len(nodeLabels) > 1 :
            annotLabel = nodeLabels[1]
            if annotLabel.text.strip() != "" :
                annotationOfClass[clsName] = annotLabel.text
        # print(clsName, nodeId)

print()
print("# Classes")
print()
for c in classNames : 
    print(":"+c+"  a  owl:Class  .")
    if c in annotationOfClass : print('   :'+c+'  rdfs:comment """'+annotationOfClass[c]+'"""  .')


print()
print("# Axioms and Properties")
print()

propNames: FrozenSet[str] = frozenset()

for e in root.findall('.//g:edge',ns) :
   src = e.get("source")
   tgt = e.get("target")
   edgeLabel: ET.Element = e.find(".//y:EdgeLabel",ns)
   label = "UNDEF_Property"

   if edgeLabel != None : label = edgeLabel.text 

   restrictionType = 'owl:allValuesFrom'
   #  edge labels of the form 'propertyName min 1' 
   if len(re.findall(r' min 1$', label)) > 0 :
       label = re.sub(r' min 1$', '', label)
       restrictionType = 'owl:someValuesFrom'

   label = re.sub(r'[^a-z^A-Z^0-9^-^:]', '_', label)
   #new property name
   if (label not in propNames ) :
       print(":"+label+"  a  owl:ObjectProperty .")
       propNames = propNames.union({label})
   
   if ((src in classNameOfNode ) and (tgt in classNameOfNode)) :
        if (label.lower() == "subclassof") :
            print(":"+classNameOfNode[src]+"  rdfs:subClassOf  :"+classNameOfNode[tgt]+"  .")
        else :
            print(":"+classNameOfNode[src]+"  rdfs:subClassOf  ")
            print("       [a owl:Restriction ; owl:onProperty :"+label+" ; "+restrictionType+"  :"+classNameOfNode[tgt]+"]  .")
           
   else :
        print("## edge between non-class nodes: "+label)

sys.stdout.flush()
sys.stdout.close()
