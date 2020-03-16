FROM alpine:3.10 AS builder

#trunk rev HEAD (may be unstable)
#4.8.5 rev 2589
#4.8.6 rev 2600
#4.9.0 rev 2652
#5.0.0 rev 2801
#5.1.0 rev 2891
#5.2.0 rev 2961
#5.3.1 rev 3079
#5.4.0 rev 3135
ARG DAVMAIL_REV=3135

# Install tools
RUN apk add --update --no-cache openjdk8 maven subversion

# Get svn TRUNK or released REVISION based on build-arg: DAVMAIL_REV
RUN svn co -r ${DAVMAIL_REV} https://svn.code.sf.net/p/davmail/code/trunk /davmail-code

# Build
RUN cd /davmail-code && mvn clean package #jar

# Prepare result
RUN mkdir -vp /target/davmail /target/davmail/lib
WORKDIR /target/davmail

#RUN mv -v $(find ${HOME}/.m2/repository/ /davmail-code/lib\
#               -name 'httpclient*.jar'\
#            -o -name 'httpcore*.jar'\
#            -o -name 'log4j*.jar'\
#            -o -name 'commons-httpclient*.jar'\
#            -o -name 'jackrabbit-webdav*.jar'\
#            -o -name 'commons-logging*.jar'\
#            -o -name 'javax.mail*.jar'\
#            -o -name 'commons-codec*.jar'\
#            -o -name 'htmlcleaner*.jar'\
#            )\
#          ./lib/

# We run headless. No junit tests, ant tasks, graphics support and winrun deps.
RUN mv -v $(for dep in activation commons-codec commons-collections\
                       commons-httpclient commons-logging hamcrest-core\
                       htmlcleaner httpclient httpcore jackrabbit-webdav\
                       javax.mail jcharset jcifs jdom jettison log4j slf4j-api\
                       slf4j-log4j12 stax-api stax2-api woodstox-core;\
            do find ./lib/ ~/.m2/repository/ -name "${dep}*.jar"\
               | sort\
               | tail -n 1;\
            done)\
     ./lib/

#activation commons-codec commons-collections 
#commons-httpclient commons-logging hamcrest-core\
#htmlcleaner httpclient httpcore jackrabbit-webdav\
#javax.mail jcharset jcifs jdom jettison log4j\
#slf4j-api slf4j-log4j12 stax-api stax2-api woodstox-core

RUN mv -v /davmail-code/target/davmail-*.jar .
RUN ln -s davmail-*.jar davmail.jar

## Build completed, the result is in in the builder:/target directory ##

FROM openjdk:8-jre-alpine
#FROM kran0/tiny:openjdk8-jre
COPY --from=builder /target /

EXPOSE 1110 1025 1143 1080 1389
ENTRYPOINT [ "java", "-Xmx512M", "-Dsun.net.inetaddr.ttl=60",\
             "-cp", "/davmail/davmail.jar:/davmail/lib/*",\
             "davmail.DavGateway", "-notray" ]
CMD [ "/davmail/davmail.properties" ]
