FROM postgres
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
        libyaml-perl libgd2-xpm-dev curl xsltproc netcat

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm --notest --force Test::More Heap::Simple Heap::Simple::XS DBIx::DBStag GO::Parser
RUN cpanm --notest DBI Digest::Crc32 Cache::Ref::FIFO URI::Escape HTML::Entities \
        HTML::HeadParser HTML::TableExtract HTTP::Request::Common LWP XML::Parser \
        XML::Parser::PerlSAX XML::SAX::Writer XML::Simple Data::Stag Error \
        PostScript::TextBlock Spreadsheet::ParseExcel Algorithm::Munkres \
        Bio::GFF3::LowLevel::Parser File::Next CGI DBD::Pg SQL::Translator \
        Digest::MD5 Text::Shellwords Module::Build Class::DBI Class::DBI::Pg \
        Class::DBI::Pager Template Bio::Chado::Schema GD
RUN cpanm --notest CJFIELDS/BioPerl-1.6.924.tar.gz

ENV CHADO_DB_HOST localhost
ENV CHADO_DB_NAME postgres
ENV CHADO_DB_USERNAME postgres
ENV PGDATA /var/lib/postgresql/9.4/
ENV CHADO_DB_PASSWORD postgres
ENV CHADO_DB_PORT 5432
ENV POSTGRES_PASSWORD postgres
ENV GMOD_ROOT /usr/share/gmod/

RUN mkdir -p $GMOD_ROOT /build
WORKDIR /build
ADD load.conf.tt2 /opt/load.conf.tt2
ADD cvtermpath_fix.sql /opt/cvtermpath_fix.sql
ADD update_urls.sql /opt/update_urls.sql
ADD fix_relationshiptype_lc.diff /opt/fix_relationshiptype_lc.diff

ADD build.sh /docker-entrypoint-initdb.d/build.sh
