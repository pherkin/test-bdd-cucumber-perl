FROM perl:5.30
RUN cpanm Carton
WORKDIR /usr/src/app
COPY cpanfile .
RUN carton install
ENV PERL5LIB=/usr/src/app/local/lib/perl5
ENTRYPOINT [ "/usr/src/app/local/bin/pherkin" ]

