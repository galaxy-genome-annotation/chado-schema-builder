update db set urlprefix = 'http://www.uniprot.org/uniprot/' where name = 'uniprot';
update db set urlprefix = 'http://www.ncbi.nlm.nih.gov/nuccore/' where name = 'refseq:mrna';
update db set urlprefix = 'http://www.ncbi.nlm.nih.gov/protein/' where name = 'refseq:protein';
update db set urlprefix = 'http://www.ncbi.nlm.nih.gov/nuccore/' where name = 'genbank:mrna';
update db set urlprefix = 'http://www.ncbi.nlm.nih.gov/protein/' where name = 'genbank:protein';
update db set urlprefix = 'http://www.uniprot.org/uniprot/' where name = 'swissprot:display';
update db set urlprefix = 'http://pfam.xfam.org/family/' where name = 'pfam';
