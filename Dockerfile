FROM alpine:3.14

RUN apk add --no-cache wget cmake unzip gcc build-base perl linux-headers

ARG SSL="/usr/local/ssl"
ARG LIB="${SSL}/lib64"
ARG ENGINES="${LIB}/engines-3"

RUN mkdir "/usr/local/src"

# Build openssl
RUN cd /usr/local/src \
  && wget "https://github.com/openssl/openssl/archive/openssl-3.0.3.zip" -O "openssl.zip" \
  && unzip openssl.zip -d ./ \
  && cd openssl-openssl-3.0.3 \
  && ./config shared -d --prefix=${SSL} --openssldir=${SSL} \
  && make -j$(nproc) all \
  && make install

RUN ln -s ${LIB}/*.so /lib/ \
    && ln -s ${LIB}/*.so.3 /lib/ \
    && ln -s ${ENGINES}/*.so /lib/ \
    && ln -s ${ENGINES}/*.so.3 /lib/

RUN ln -s ${SSL}/bin/openssl /usr/bin/openssl

RUN cd /usr/local/src \
    && wget https://github.com/gost-engine/engine/archive/refs/tags/v3.0.0.zip -O gost-engine.zip \
    && unzip gost-engine.zip -d ./ \
    && cd engine-3.0.0 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release \
      -DOPENSSL_ROOT_DIR=${SSL} \
      -DOPENSSL_LIBRARIES=${LIB} \
      -DOPENSSL_ENGINES_DIR=${ENGINES} .. \
    && cmake --build . --config Release \
    && make install

RUN sed -i '6i openssl_conf=openssl_init' ${SSL}/openssl.cnf \
  && echo "" >>${SSL}/openssl.cnf \
  && echo "# OpenSSL default section" >>${SSL}/openssl.cnf \
  && echo "[openssl_init]" >>${SSL}/openssl.cnf \
  && echo "engines = engine_section" >>${SSL}/openssl.cnf \
  && echo "" >>${SSL}/openssl.cnf \
  && echo "# Engine scetion" >>${SSL}/openssl.cnf \
  && echo "[engine_section]" >>${SSL}/openssl.cnf \
  && echo "gost = gost_section" >>${SSL}/openssl.cnf \
  && echo "" >> ${SSL}/openssl.cnf \
  && echo "# Engine gost section" >>${SSL}/openssl.cnf \
  && echo "[gost_section]" >>${SSL}/openssl.cnf \
  && echo "engine_id = gost" >>${SSL}/openssl.cnf \
  && echo "dynamic_path = ${ENGINES}/gost.so" >>${SSL}/openssl.cnf \
  && echo "default_algorithms = ALL" >>${SSL}/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >>${SSL}/openssl.cnf