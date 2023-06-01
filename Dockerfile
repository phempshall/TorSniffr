FROM perl:5.30.0

RUN apt-get update &&\
#	apt-get upgrade -y &&\
	apt-get install -y tor build-essential

RUN cpanm --quiet Net::Server@2.012 Dancer2 Starman Modern::Perl FindBin Template LWP@6.68 LWP::Protocol::socks HTTP::Headers HTTP::Response Compress::Zlib Time::HiRes URI::Encode HTML::Entities

COPY . /TorSniffr

EXPOSE 8080

WORKDIR /TorSniffr

RUN ["chmod", "+x", "./startup.sh"]

CMD ./startup.sh