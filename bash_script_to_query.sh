skip_headers=1
echo > results.tsv
i=0
while IFS=, read -r col1 col2
do
    if ((skip_headers))
    then
        ((skip_headers--))
    else
	protein_id=$col1
	go_id="$(echo "$col2" | tr -d '\n\r')"
	
	if (( $i % 1000 == 0 )) ;
	then
		echo "Now at $i....";
	fi

	i=$((i + 1))
	query="PREFIX up: <http://purl.uniprot.org/core/>
	PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    	SELECT ?doi ?pubMedId ?title ?abstract
    	WHERE { <$col1>  a up:Protein ; up:attribution ?attribution.
        ?attribution up:source ?citation.
        ?protein_classified_with_go_property up:attribution ?attribution.
        ?protein_classified_with_go_property rdf:subject <$col1>. 
        ?protein_classified_with_go_property rdf:object <${col2//[$'\t\r\n']}> .

        ?citation a <http://purl.uniprot.org/core/Journal_Citation>.

        ?citation <http://purl.org/dc/terms/identifier> ?doi.

        ?citation <http://www.w3.org/2004/02/skos/core#exactMatch> ?pubMedId.

        ?citation <http://purl.uniprot.org/core/title> ?title.

        ?citation <http://www.w3.org/2000/01/rdf-schema#comment> ?abstract.
    	}"

	query_fixed=`echo "$query" | tr '\n' ' '`
        	
	OUTPUT="$(tdb2.tdbquery --loc Uniprot_DB_loc "$query_fixed")"
	OUTPUT=${OUTPUT##*=}

	# DOI = $2 PubmedID = $3 Title = $4 Abstract = $5
	#echo "$OUTPUT" | awk -F'[|]' '{print $1 $2 $3 $4}'
	doi="$(echo "$OUTPUT" | awk -F'[|]' '{print $2'}| tr -d '\n')"
	pubmedid="$(echo "$OUTPUT" | awk -F'[|]' '{print $3'}| tr -d '\n')"
	title="$(echo "$OUTPUT" | awk -F'[|]' '{print $4'}| tr -d '\n')"
	abstract="$(echo "$OUTPUT" | awk -F'[|]' '{print $5'}| tr -d '\n')"
    	echo -e "${protein_id}\t${go_id}\t${doi}\t${pubmedid}\t${title}\t${abstract}">> results.tsv
    fi
done < data.csv

