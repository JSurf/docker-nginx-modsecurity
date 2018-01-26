FROM nginx:stable
# Build libmodsecurity
RUN apt-get update && apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev \
    && git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure \
    && make \
    && make install 

RUN NGINX_SRC=`nginx -v 2>&1 | cut -d / -f 2` \
    && git clone --depth 1 --single-branch https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && wget http://nginx.org/download/nginx-$NGINX_SRC.tar.gz \
    && tar zxvf nginx-$NGINX_SRC.tar.gz \
    && cd nginx-$NGINX_SRC \
    && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules 

RUN sed -i '1iload_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

RUN mkdir /etc/nginx/modsec \
    && wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
    && mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf \
    && sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    && git clone --depth 1 https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/nginx/modsec/owasp-modsecurity-crs \    
    && mv /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf \
    && cd /etc/nginx/modsec/owasp-modsecurity-crs/rules \
    && mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf \
    && mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

ADD main.conf /etc/nginx/modsec/
ADD modsecurity.conf /etc/nginx/conf.d/
