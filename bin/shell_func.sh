#/bin/bash

if [ "$ROOT_DIR" == "" ]; then
	echo "Not set ROOT_DIR, exit."
	exit 1
fi

# echo -e "\033[31mROOT_DIR\033[0m=$ROOT_DIR"
# echo ""

#cd $ROOT_DIR

LUA_BIN=$ROOT_DIR/bin/openresty/luajit/bin/luajit

TMP_DIR=$ROOT_DIR/tmp
CONF_DIR=$ROOT_DIR/gbc/conf
CONF_PATH=$CONF_DIR/config.lua
VAR_SUPERVISORD_CONF_PATH=$TMP_DIR/supervisord.conf

# if [ -e "$ROOT_DIR/bin/openresty" ]; then
# 	ln -sf $ROOT_DIR/bin/openresty /usr/local/openresty
# 	cp -rf $ROOT_DIR/gbc/openresty/luajit/share/lua/5.1/* $ROOT_DIR/bin/openresty/luajit/share/lua/5.1/
# 	cp -rf $ROOT_DIR/gbc/openresty/luajit/lib/lua/5.1/* $ROOT_DIR/bin/openresty/luajit/lib/lua/5.1/
# 	echo $(realpath $(realpath $ROOT_DIR/bin/openresty)/..)/lib >/etc/ld.so.conf.d/0openresty.conf
# 	ldconfig
# 	export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ROOT_DIR/bin/openresty/bin:$ROOT_DIR/bin/openresty/luajit/bin:$ROOT_DIR/bin/openresty/nginx/sbin
# else
# 	echo "Missing $ROOT_DIR/bin/openresty"
# 	exit 1

# fi

if [ ! -f "/usr/bin/python" ]; then
	apt update
	apt install -y python-is-python2
fi

# function getOsType()
# {
#     if [ `uname -s` == "Darwin" ]; then
#         echo "MACOS"
#     else
#         echo "LINUX"
#     fi
# }

# OS_TYPE=$(getOsType)
# if [ $OS_TYPE == "MACOS" ]; then
#     SED_BIN='sed -i --'
# else
SED_BIN='sed -i'
#fi

loadEnv() {
	return
	# if [ ! -f "/tmp/loadenv.lock" ]; then
	# 	touch /tmp/loadenv.lock
	# 	ROOT_DIR=$1
	# 	cd $ROOT_DIR
	# 	if [ -z "$MBR_ENV" ]; then
	# 		if [ -f "$ROOT_DIR/.env" ]; then
	# 			source $ROOT_DIR/.env
	# 		fi

	# 	fi

	# 	if [ -n "$MBR_ENV" ]; then

	# 		mkdir -p $ROOT_DIR/src

	# 		tmp=$(mktemp)
	# 		if [ -f "$ROOT_DIR/.env" ]; then
	# 			cat "$ROOT_DIR/.env" >$tmp
	# 			echo >>$tmp
	# 		fi
	# 		# echo "export MBR_ENV=$MBR_ENV" >$tmp
	# 		_file="$ROOT_DIR/.env.$MBR_ENV"
	# 		if [ -f "$_file" ]; then
	# 			cat $_file | awk 'NF > 0 && !/^\s*source/ && !/^\s*#/' >>$tmp
	# 			echo >>$tmp
	# 			cat $_file | awk '/^\s*source/ {print $2}' | while read f; do
	# 				cat $f
	# 				echo

	# 	cat $tmp | sed 's/export\s*//g' | awk -F '=' '{print $1}' | while read k; do
	# 		#	echo "export $k=$((k))"
	# 		if [ -z "$k" ]; then continue; fi
	# 		echo "export $k=${!k}"
	# 	done >${tmp}.1
	# 	cat ${tmp}.1
	# 	# mv ${tmp}.1 $ROOT_DIR/.env_ra
	# 	if [ -f "$SITE_ROOT/.env_raw" ]; then
	# 		rm $SITE_ROOT/.env_raw
	# 	fi

	# 			done | awk "NF > 0 && !/^#/" >>$tmp
	# 		fi
	# 		if [ -d "$ROOT_DIR/env" ]; then
	# 			find $ROOT_DIR/env -type f -iname '*.env' | while read f; do
	# 				if [ -f "$f" ]; then
	# 					cat $f
	# 					echo
	# 				fi
	# 			done | awk "NF > 0 && !/^#/" >>$tmp
	# 		fi
	# 		source $tmp

	# 		cat $tmp | sed 's/export\s*//g' | awk -F '=' '{print $1}' | while read k; do
	# 			#	echo "export $k=$((k))"
	# 			if [ -z "$k" ]; then continue; fi
	# 			echo "export $k=${!k}"
	# 		done >${tmp}.1
	# 		cat ${tmp}.1
	# 		# mv ${tmp}.1 $ROOT_DIR/.env_raw

	# 		awk -F'=' -v q1="'" -v q2='"' '

	# 	{
	# 	        val_1=substr($2,0,1);
	# 	        if(val_1 == q1 || val_1 == q2)
	# 	        print $1"="$2;
	# 	        else
	# 	        print $1"=\""$2"\"";
	# 	}' ${tmp}.1 >$ROOT_DIR/.env_raw

	# 	if [ -f "$SITE_ROOT/.env_raw" ]; then
	# 		source $SITE_ROOT/.env_raw >/dev/null

	# 		# cat $ROOT_DIR/.env_raw
	# 		awk -F'=' -v q1="'" -v q2='"' 'BEGIN{cfg="return {\n"}
	# 	{
	# 	        sub(/^export\s*/,"",$1);
	#         gsub(/ /,"",$1);

	#         if(length($2) == 0)
	# 	        cfg=cfg"[\""$1"\"]""=\""$2"\",\n";
	# 	else {
	# 	        val_1=substr($2,0,1);
	# 	        if(val_1 == q1 || val_1 == q2)
	# 	        cfg=cfg"[\""$1"\"]""="$2",\n";
	# 	        else
	# 	        cfg=cfg"[\""$1"\"]""=\""$2"\",\n";
	# 	}

	# 	}
	# 	END{print cfg"}"}' $ROOT_DIR/.env_raw >$ROOT_DIR/src/_env.lua
	# 		cp $ROOT_DIR/src/_env.lua $ROOT_DIR/src/env.lua

	# 		rm ${tmp}*
	# 	fi
	# 	rm /tmp/loadenv.lock

	# fi
}

function installOpenrestyTest() {
	apt update
	apt install -y make
	export HOME=$ROOT_DIR
	cd $ROOT_DIR
	cpan -i Test::Nginx
	ls -d .cpan/build/* | while read d; do
		cd $d
		make install
		cd -
	done
}

function runOpenrestyTest() {
	cd $ROOT_DIR
	export PATH=$PATH:$ROOT_DIR/bin/openresty/nginx/sbin
	prove -r $@

}
function runTests() {
	cat $ROOT_DIR/.module_paths | while read _site; do
		_dirtest="$_site/apps/tests"
		if [ -d "$_dirtest" ]; then
			TEST_DOMAIN=$TEST_DOMAIN ROOT_DIR=$ROOT_DIR SITE_DIR=$_site bash "$ROOT_DIR/gbc/bin/run_tests"
		fi
	done

}
function updateConfigs() {
	# if [ ! -f "/tmp/updateconfig.lock" ]; then
	# 	touch /tmp/updateconfig.lock
	# echo "ROOT_DIR:$ROOT_DIR"
	if [ -z "$BIND_ADDRESS" ]; then BIND_ADDRESS="0.0.0.0"; fi
	$LUA_BIN -e "BIND_ADDRESS=\"$BIND_ADDRESS\";ROOT_DIR='$ROOT_DIR'; DEBUG=$DEBUG; dofile('$ROOT_DIR/gbc/bin/shell_func.lua'); updateConfigs()"
	# 	rm /tmp/updateconfig.lock
	# fi
}

function startSupervisord() {
	echo "[CMD] supervisord -n -c $VAR_SUPERVISORD_CONF_PATH"
	echo ""
	cd $ROOT_DIR/bin/python_env/gbc
	source bin/activate
	$ROOT_DIR/bin/python_env/gbc/bin/supervisord -n -c $VAR_SUPERVISORD_CONF_PATH
	cd $ROOT_DIR
	echo "Start supervisord DONE"
	echo ""

}

function stopSupervisord() {
	echo "[CMD] supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown"
	echo ""
	cd $ROOT_DIR/bin/python_env/gbc
	source bin/activate
	$ROOT_DIR/bin/python_env/gbc/bin/supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown
	cd $ROOT_DIR
	echo ""
}

function checkStatus() {
	cd $ROOT_DIR/bin/python_env/gbc
	source bin/activate
	$ROOT_DIR/bin/python_env/gbc/bin/supervisorctl -c $VAR_SUPERVISORD_CONF_PATH status
	cd $ROOT_DIR
	echo ""
}
