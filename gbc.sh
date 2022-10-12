#!/bin/bash
#if [ -d /usr/local/openresty ]; then ln -sf /usr/local/openresty /app/bin/openresty; fi
#cd /app

VIRTUALENV_VER=16.6.0
VIRTUALENV_VER=16.7.5
#VIRTUALENV_VER=20.0.13

SUPERVISOR_VER=4.0.2
SUPERVISOR_VER=4.0.4
SUPERVISOR_VER=4.1.0
SUPERVISOR_VER=4.2.4

REDIS_VER=5.0.5

# http://kr.github.io/beanstalkd/
BEANSTALKD_VER=1.10.1
# https://github.com/diegonehab/luasocket
LUASOCKET_VER=3.0-rc1
# https://github.com/cloudwu/lua-bson
LUABSON_VER=20160519
# https://github.com/cloudwu/pbc
LUAPBC_VER=20160531
# https://github.com/mah0x211/lua-process
LUAPROCESS_VER=1.6.0

SRC_DIR=$1
#$(cd "$(dirname $0)" && pwd)

echo "SRC_DIR   = $SRC_DIR"

# default configs
DEST_DIR=$2
#SRC_DIR

# ARGS=$(getopt -o h --long help,prefix: -n 'Install GameBox Cloud Core' -- "$@")

# eval set -- "$ARGS"

NEED_COPY_FILES=1
if [ "$DEST_DIR" == "$SRC_DIR" ]; then
	NEED_COPY_FILES=0
fi

echo "NEED_COPY_FILES = $NEED_COPY_FILES"

mkdir -pv $DEST_DIR

if [ $? -ne 0 ]; then
	echo "DEST_DIR  = $DEST_DIR"
	echo ""
	echo "\033[31mCreate install dir failed.\033[0m"
	exit 1
fi

cd $DEST_DIR
DEST_DIR=$(pwd)
#$(pwd)
echo "DEST_DIR  = $DEST_DIR"

BUILD_DIR=$SRC_DIR/build/install
mkdir -p $BUILD_DIR
echo "BUILD_DIR = $BUILD_DIR"
echo ""

DEST_BIN_DIR=$DEST_DIR

SED_BIN='sed -i'

set -e

#rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
#cp -f $SRC_DIR/build/*.tar.gz $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $DEST_BIN_DIR

cd $BUILD_DIR

_env() {

	# ----
	# install virtualenv and supervisor
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] virtualenv"
	cd $BUILD_DIR

	#	sudo apt install -y luajit libluajit-5.1-dev
	#rm ~/.asdf/shims/python*

	tar xfz $SRC_DIR/build/install/virtualenv-$VIRTUALENV_VER.tar.gz
	PYTHON_ENV_DIR=$DEST_BIN_DIR/python_env
	rm -fr $PYTHON_ENV_DIR
	mv virtualenv-$VIRTUALENV_VER $PYTHON_ENV_DIR
	cd $PYTHON_ENV_DIR

	python virtualenv.py --no-download gbc
	cd gbc
	source bin/activate

	curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | python
	#	curl https://bootstrap.pypa.io/get-pip.py | python
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] supervisor"
	cd $BUILD_DIR
	tar zxf $SRC_DIR/build/install/supervisor-$SUPERVISOR_VER.tar.gz
	cd supervisor-$SUPERVISOR_VER
	$SED_BIN "/zip_ok = false/a\\
index-url = http://mirrors.aliyun.com/pypi/simple/" setup.cfg
	python setup.py install
}
_lualib() {
	# install luasocket
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] luasocket"
	cd $BUILD_DIR
	tar zxf $SRC_DIR/build/install/luasocket-$LUASOCKET_VER.tar.gz
	cd luasocket-$LUASOCKET_VER
	mkdir -p $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1/socket/
	$SED_BIN "s#LUAPREFIX_linux?=/usr/local#LUAPREFIX_linux?=$DEST_BIN_DIR/openresty/luajit#g" src/makefile
	# $SED_BIN "s#LUAINC_linux_base?=/usr/include#LUAINC_linux_base?=$DEST_BIN_DIR/openresty/luajit/include#g" src/makefile
	# $SED_BIN "s#\$(LUAINC_linux_base)/lua/\$(LUAV)#\$(LUAINC_linux_base)/luajit-2.1#g" src/makefile

	make -j$(nproc) && make install-unix

	# cp -f src/*.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1/socket/.

	# install luabson
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] luabson"

	cd $BUILD_DIR
	tar zxf luabson-$LUABSON_VER.tar.gz
	cd lua-bson
	# if [ $OSTYPE == "MACOS" ]; then
	# 	$SED_BIN "s#-I/usr/local/include -L/usr/local/bin -llua53#-I$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1 -L$DEST_BIN_DIR/openresty/luajit/lib -lluajit-5.1#g" Makefile
	# else
	$SED_BIN "s#-I/usr/local/include -L/usr/local/bin -llua53#-I/usr/include/luajit-2.1#g" Makefile
	# fi
	make linux

	# cp -f bson.so $DEST_BIN_DIR/openresty/lualib
	cp -f bson.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

	#install luapbc
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] luapbc"

	cd $BUILD_DIR
	tar zxf luapbc-$LUAPBC_VER.tar.gz
	cd pbc
	make lib
	cd binding/lua
	# if [ $OSTYPE == "MACOS" ]; then
	# 	$SED_BIN "s#/usr/local/include#$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1 -L$DEST_BIN_DIR/openresty/luajit/lib -lluajit-5.1#g" Makefile
	# else
	# 	$SED_BIN "s#/usr/local/include#$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1#g" Makefile
	$SED_BIN "s#/usr/local/include#/usr/include/luajit-2.1#g" Makefile
	# fi
	make

	# cp -f protobuf.so $DEST_BIN_DIR/openresty/lualib
	# cp -f protobuf.lua $DEST_BIN_DIR/openresty/lualib

	cp -f protobuf.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1
	cp -f protobuf.lua $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

	# install luaprocess
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] luaprocess"

	cd $BUILD_DIR
	tar zxf $SRC_DIR/build/install/lua-process-$LUAPROCESS_VER.tar.gz
	cd lua-process-$LUAPROCESS_VER
	cp Makefile Makefile_
	echo "PACKAGE=process" >Makefile
	echo "LIB_EXTENSION=so" >>Makefile
	echo "SRCDIR=src" >>Makefile
	echo "TMPLDIR=tmpl" >>Makefile
	echo "VARDIR=var" >>Makefile
	echo "CFLAGS=-Wall -fPIC -O2 -I/usr/include/luajit-2.1 -I_GBC_CORE_ROOT_/openresty/luajit/include/luajit-2.1" >>Makefile
	echo "LDFLAGS=--shared -Wall -fPIC -O2 -L_GBC_CORE_ROOT_/openresty/luajit/lib" >>Makefile
	if [ $OSTYPE == "MACOS" ]; then
		echo "LIBS=-lluajit-5.1" >>Makefile
	fi
	echo "" >>Makefile
	cat Makefile_ >>Makefile
	rm Makefile_

	$SED_BIN "s#_GBC_CORE_ROOT_#$DEST_DIR#g" Makefile
	# $SED_BIN "s#lua ./codegen.lua#$DEST_BIN_DIR/openresty/luajit/bin/luajit ./codegen.lua#g" Makefile

	make

	# cp -f process.so $DEST_BIN_DIR/openresty/lualib
	cp -f process.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1
}
_keydb() {
	# ----
	#install redis
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] redis"

	cd $BUILD_DIR
	rm -rf KeyDB
	#	if [ ! -d "KeyDB" ]; then
	git clone https://github.com/JohnSully/KeyDB.git
	#	fi
	cd KeyDB
	make distclean
	git reset --hard
	git pull
	#tar zxf $SRC_DIR/build/install/redis-$REDIS_VER.tar.gz
	#cd redis-$REDIS_VER
	$SRC_DIR/build/patch_redis_luajit.sh
	mkdir -p $DEST_BIN_DIR/keydb/bin

	make -j$(nproc)
	cp -f src/keydb-server $DEST_BIN_DIR/keydb/bin
	cp -f src/keydb-cli $DEST_BIN_DIR/keydb/bin
	cp -f src/keydb-sentinel $DEST_BIN_DIR/keydb/bin
	cp -f src/keydb-benchmark $DEST_BIN_DIR/keydb/bin
	cp -f src/keydb-check-aof $DEST_BIN_DIR/keydb/bin
	cp -f src/keydb-check-rdb $DEST_BIN_DIR/keydb/bin
}
_redis() {
	# ----
	#install redis
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] redis"

	cd $BUILD_DIR
	tar zxf $SRC_DIR/build/install/redis-$REDIS_VER.tar.gz
	cd redis-$REDIS_VER
	#$SRC_DIR/build/patch_redis_luajit.sh
	mkdir -p $DEST_BIN_DIR/redis/bin

	make -j$(nproc)
	cp -f src/redis-server $DEST_BIN_DIR/redis/bin
	cp -f src/redis-cli $DEST_BIN_DIR/redis/bin
	cp -f src/redis-sentinel $DEST_BIN_DIR/redis/bin
	cp -f src/redis-benchmark $DEST_BIN_DIR/redis/bin
	cp -f src/redis-check-aof $DEST_BIN_DIR/redis/bin
}
_beanstalk() {
	# ----
	# install beanstalkd
	echo ""
	echo -e "[\033[32mINSTALL\033[0m] beanstalkd"

	cd $BUILD_DIR
	tar zxf $SRC_DIR/build/install/beanstalkd-$BEANSTALKD_VER.tar.gz
	cd beanstalkd-$BEANSTALKD_VER
	mkdir -p $DEST_BIN_DIR/beanstalkd/bin

	make -j$(nproc)
	cp -f beanstalkd $DEST_BIN_DIR/beanstalkd/bin
}
_tools() {
	mkdir -p $DEST_BIN_DIR/bin
	curl -o $DEST_BIN_DIR/bin/jemplate https://raw.githubusercontent.com/ingydotnet/jemplate/master/jemplate
	curl -o $DEST_BIN_DIR/bin/lemplate https://raw.githubusercontent.com/openresty/lemplate/master/lemplate
	chmod +x $DEST_BIN_DIR/bin/jemplate $DEST_BIN_DIR/bin/lemplate

	echo "DONE!"
	echo ""
}
#if [ $# -gt 0 ];then $@;exit 0;fi
_env
_lualib
#_keydb
_redis
_beanstalk
_tools
# cd $SRC_DIR/build/install
# rm -rf beanstalkd-* \
# 	lua-process-* \
# 	luasocket-* \
# 	redis-* \
# 	supervisor-*
