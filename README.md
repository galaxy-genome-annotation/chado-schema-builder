# Chado Schema Builder [![Build Status](https://build.galaxyproject.eu/buildStatus/icon?job=usegalaxy-eu%2Fchado-schema-builder)](https://build.galaxyproject.eu/job/usegalaxy-eu/job/chado-schema-builder/)

This project provides a dockerfile to automatically build the chado database
dumps. These schema dumps are necessary due to how much time and memory the
process of parsing ontologies takes. For older machines such as the author's
aging infrastructure, installing the 5 default ontologies can take upwards of 8
hours. Installing a dumped .sql.gz from this project takes under 20 seconds,
and can even be done "live" during docker launches.

## Running

```console
make
make schema
```

The container is set up and ready to run. As soon as you launch an instance of
this container, it will bring up the postgres database, start processing (you
may wish to customize)

## LICENSE

GPLv3

(This does not preclude you [customising a copy of this](https://www.gnu.org/licenses/gpl-faq.en.html#GPLOutput), producing output, and [not sharing the customisations](https://www.gnu.org/licenses/gpl-faq.en.html#GPLRequireSourcePostedPublic) to the main program.)
