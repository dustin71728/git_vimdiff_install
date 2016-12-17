#!/bin/bash

BIN_PATH=$HOME"/bin"
GIT_REPO_PATH=$HOME"/git-repo"
GIT_THEME_PATH=$GIT_REPO_PATH"/vim-distinguished"
USER_VIM_PATH=$HOME"/.vim"
USER_VIM_COLOR_PATH=$USER_VIM_PATH"/colors"
THEME_URL="https://github.com/Lokaltog/vim-distinguished"
VIM_COLOR_FILE=$GIT_THEME_PATH"/colors/distinguished.vim"
VIM_RC_FILE=$HOME"/.vimrc"
GIT_USER_CONFIG_FILE=$HOME"/.gitconfig"
ARY_VIM_CONFIG=( 
	'set t_Co=256' 
	'syntax on' 
	'colorscheme distinguished' 
)
ARY_CHK_VIM_CONFIG=( 
	'set[[:space:]]+t_Co' 
	'syntax' 
	'colorscheme' 
)

checkDir ()
{
	declare E_IS_NOT_DIR=200
	echo -n "Check directory: $1..."
	if [ -e "$1" ]
	then
		if [ -d "$1" ]
		then
			echo "Done"
		else
			echo "Not directory!" 1>&2
			echo "Error!"  1>&2
			exit $E_IS_NOT_DIR
		fi
	else
		mkdir $1
		if [ $? -ne 0 ]
		then
			echo "Create failed" 1>&2
			echo "Error!" 1>&2
			exit $E_IS_NOT_DIR
		fi
	fi	
}

check_git_theme ()
{
	declare E_GIT_CHECK_FAIL=201
	# $1 	$GIT_REPO_PATH
	# $2 	$THEME_URL
	echo -n "Check git repository directory: "$1" and its url: "$2"..."
	if [ -d $1 ]
	then
		if [ -d $1"/.git" ] && [ -e $1"/.git/config" ]
		then
			url=$( grep url $1"/.git/config"  | awk -F '=' '{print $2}' | tr -d '[[:space:]]' )
			if [ "$2" != "$url" ]
			then
				echo "Not expected git repository!" 1>&2
				echo "Error!" 1>&2
				exit $E_GIT_CHECK_FAIL
			else
				echo "Done"
			fi
		else
			echo "Not a valid git repository!" 1>&2
			echo "Error!" 1>&2
			exit $E_GIT_CHECK_FAIL
		fi
	else
		echo "Start fetching"
		git clone $2 $1
	fi
}

check_file()
{
	echo -n "Check file $1..."
	if [ ! -e $1 ]
	then
		touch $1
		if [ $? -ne 0 ]
		then
			echo "Touch $1 failed !" 1>&2
			echo "Exit" 1>&2
			echo $?
		fi
	fi
	echo "Done."
}

append_aryConfig_to_file()
{
	#$1			config array
	#$2 		check array
	#$3 		appended file
	declare ary_config=("${!1}")
	declare ary_check_config=("${!2}")
	declare wirte_file=$3
	declare index=0
	declare num_ary_length=${#ary_config[@]}
	declare tmp_file_old='/tmp/vim_rc_ori_'$$
	declare tmp_file_new='/tmp/vim_rc_new_'$$
	echo -n "Append/Overwrite options to "$wirte_file"..."

	touch $tmp_file_new
	cp $wirte_file $tmp_file_old

	for (( index=0; index < num_ary_length; ++index ))
	do
		egrep ${ary_check_config[$index]} $wirte_file > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			cmd="sed -r ""'"'s/'${ary_check_config[$index]}'.+/'${ary_config[$index]}'/'"'"" $tmp_file_old > $tmp_file_new"
			/bin/bash -c "$cmd"
			mv $tmp_file_new $tmp_file_old
		else
			echo ${ary_config[$index]} >> $tmp_file_old
		fi
	done

	if [ -e $wirte_file ]
	then
		cp $wirte_file ${wirte_file}.$$.bak
	fi
	mv $tmp_file_old $wirte_file
	rm -f $tmp_file_new
	rm -f $tmp_file_old
	echo "Done."
}

checkDir $BIN_PATH
checkDir $GIT_REPO_PATH
checkDir $USER_VIM_PATH
checkDir $USER_VIM_COLOR_PATH
check_file $VIM_RC_FILE
check_file $GIT_USER_CONFIG_FILE
check_git_theme $GIT_THEME_PATH $THEME_URL

echo -n "Set terminal type to enable 256 support..."
export TERM=xterm-256color
echo "Done."

echo -n "Copy $VIM_COLOR_FILE file to $USER_VIM_COLOR_PATH"
cp $VIM_COLOR_FILE $USER_VIM_COLOR_PATH
if [ $? -ne 0 ]
then
	echo
	echo "Copy failed." 1>&2
	echo "Exit" 1>&2
	exit $?
else
	echo "...Done."
fi

append_aryConfig_to_file ARY_VIM_CONFIG[@] ARY_CHK_VIM_CONFIG[@] $VIM_RC_FILE

echo -n "Install git_dif_wrapper in "$BIN_PATH"..."
GIT_DIFF_WRAPPER='
#!/bin/bash
vimdiff -c "windo set wrap" -c "windo set number" "$2" "$5"
'

echo "$GIT_DIFF_WRAPPER" > $BIN_PATH"/git_diff_wrapper"
chmod +x $BIN_PATH"/git_diff_wrapper"
echo "Done."

echo -n "Configure git in user scope..."
git config --global core.editor "vim"
git config --global diff.external "git_diff_wrapper"
git config --global diff.tool "vimdiff"
git config --global pager.diff ""
git config --global difftool.prompt "false"
git config --global alias.d "difftool"
echo "Done."
