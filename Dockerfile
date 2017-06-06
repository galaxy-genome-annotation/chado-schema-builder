FROM postgres:9.5
MAINTAINER Eric Rasche <esr@tamu.edu>

ENV DEBIAN_FRONTEND noninteractive

VOLUME ["/host"]
# Pre-build packages
RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y wget  \
        openssl ca-certificates build-essential build-essential libpng-dev zlib1g \
        zlib1g-dev build-essential make libpq-dev libperlio-gzip-perl \
        libcapture-tiny-perl libtest-differences-perl libperlio-gzip-perl \
        libdevel-size-perl libdbi-perl libjson-perl libjson-xs-perl libheap-perl \
        libhash-merge-perl libdbd-pg-perl libio-string-perl libtest-most-perl \
        libarray-compare-perl libconvert-binary-c-perl libgraph-perl libgraphviz-perl \
        libsoap-lite-perl libsvg-perl libsvg-graph-perl libset-scalar-perl \
        libsort-naturally-perl libxml-sax-perl libxml-twig-perl libxml-writer-perl \
        libyaml-perl libgd2-xpm-dev curl xsltproc netcat && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ && \
    curl -L http://cpanmin.us | perl - App::cpanminus && \
    cpanm --notest --force Test::More Heap::Simple Heap::Simple::XS DBIx::DBStag GO::Parser && \
    cpanm --notest DBI Digest::Crc32 Cache::Ref::FIFO URI::Escape HTML::Entities \
        HTML::HeadParser HTML::TableExtract HTTP::Request::Common LWP XML::Parser \
        XML::Parser::PerlSAX XML::SAX::Writer XML::Simple Data::Stag Error \
        PostScript::TextBlock Spreadsheet::ParseExcel Algorithm::Munkres \
        Bio::GFF3::LowLevel::Parser File::Next CGI DBD::Pg SQL::Translator \
        Digest::MD5 Text::Shellwords Module::Build Class::DBI Class::DBI::Pg \
        Class::DBI::Pager Template Bio::Chado::Schema GD && \
    cpanm --notest CJFIELDS/BioPerl-1.6.924.tar.gz

ENV CHADO_DB_HOST=localhost \
	CHADO_DB_NAME=postgres \
	CHADO_DB_USERNAME=postgres \
	PGDATA=/var/lib/postgresql/9.4/ \
	CHADO_DB_PASSWORD=postgres \
	CHADO_DB_PORT=5432 \
	POSTGRES_PASSWORD=postgres \
	GMOD_ROOT=/usr/share/gmod/
