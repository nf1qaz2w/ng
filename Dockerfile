ARG NGINX_VERSION="1.20.2"

FROM nginx:${NGINX_VERSION}

ARG VTS_VERSION="v0.2.2"

RUN apt-get update && \
 apt-get install -y git wget gcc make libpcre3-dev zlib1g-dev libssl-dev libxslt-dev libgd-dev libgeoip-dev vim

RUN git clone --branch ${VTS_VERSION} https://github.com/vozlt/nginx-module-vts.git /tmp/nginx-module-vts && \
  git clone https://github.com/yaoweibin/nginx_upstream_check_module.git /tmp/nginx_upstream_check_module && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar -zxvf nginx-${NGINX_VERSION}.tar.gz

RUN cd /nginx-${NGINX_VERSION} && \
  patch -p1 < /tmp/nginx_upstream_check_module/check_1.20.1+.patch && \
  ./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-mail \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_geoip_module=dynamic \
  --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-${NGINX_VERSION}/debian/debuild-base/nginx-${NGINX_VERSION}=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
  --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
  --add-module=/tmp/nginx-module-vts \
  --add-module=/tmp/nginx_upstream_check_module && \
  make && make install

# COPY ./default.conf /etc/nginx/conf.d/default.conf
# COPY ./nginx.conf /etc/nginx/nginx.conf

ARG TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get remove --purge -y git wget gcc make && \
  apt-get -y --purge autoremove && \
  rm -rf /var/lib/apt/lists/* /nginx-* /tmp/*

ENTRYPOINT ["/bin/bash", "-c", "exec nginx -g 'daemon off;'"]
