FROM debian AS base
RUN apt update && \
    apt install -q -y \
        libcurl4 \
        libjansson4 && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

FROM debian AS build
WORKDIR /usr/local/src
RUN apt update && \
    apt install -y -q \
    build-essential \
    automake \
    autoconf \
    pkg-config \
    libcurl4-openssl-dev \
    libjansson-dev \
    libssl-dev \
    libgmp-dev \
    zlib1g-dev \
    make \
    g++ \
    git
RUN git clone https://github.com/lucasjones/cpuminer-multi.git
RUN cd cpuminer-multi && \
    make clean || echo clean && \
    rm -f config.status && \
    ./autogen.sh && \
    extracflags="$extracflags -Ofast -flto -fuse-linker-plugin -ftree-loop-if-convert-stores" && \
    ./configure --with-crypto --with-curl CFLAGS="-O2 $extracflags -DUSE_ASM -pg" --prefix=/app/cpuminer && \
    make -j 4 && \
    strip -s minerd && \
    make install

FROM base AS final
WORKDIR /app/cpuminer/bin
COPY --from=build /app/cpuminer /app/cpuminer
COPY run.sh /app/cpuminer/bin
RUN chmod +x /app/cpuminer/bin/run.sh

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "./run.sh" ]
