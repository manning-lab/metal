FROM r-base:3.5.0

MAINTAINER tim majarian (tmajaria@broadinstitute.org)

RUN apt-get update
RUN apt-get install -y build-essential zlib1g-dev git

RUN cd /bin
# COPY generic-metal-2011-03-25.tar.gz ./
RUN wget -O generic-metal-2011-03-25.tar.gz http://csg.sph.umich.edu/abecasis/Metal/download/generic-metal-2011-03-25.tar.gz
RUN tar -xzf ./generic-metal-2011-03-25.tar.gz && rm generic-metal-2011-03-25.tar.gz && cd generic-metal && make all && mv executables/metal /bin && cd /

RUN echo 'install.packages(c("qqman","data.table","tools","RColorBrewer"),repos="http://cran.us.r-project.org")' > install.R && \
	Rscript --vanilla install.R && \
	rm install.R
	
RUN git clone https://github.com/manning-lab/metal.git

