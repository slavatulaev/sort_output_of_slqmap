#!/bin/bash
#########################################################################
#   This script to prosess results of sqlmap for further analysing v2
#
#   it takes no arguments, just work in .sqlmap directory sorting results of 
# 	previous sqlmap work and saves results in directory SorRes_{DateTime} 
#	which is subdirectory if $SQLMAP_OUTPUT_PATH
#   
#########################################################################
FILE_NAME_PREFIX='SortRes_'
INJECTABLE='Injectable'
INJECTABLE_CSV='Injectable_CSV'
MAYBEINJECTABLE='MaybeInjectable'
NOTINJECTABLE='NotInjectable'
SQLMAP_HIDDEN_PATH=$HOME'/.sqlmap/'
SQLMAP_OUTPUT_PATH=$HOME'/.sqlmap/output/'               # path to sqlmap output directory
ACTION='mv -f'
### Check if sqlmap output directory exists

if ! [ -d $SQLMAP_OUTPUT_PATH ]; then
	echo -e "No sqlmap output directory exists.\nExiting..."
	exit
fi

### End initial check

cd $SQLMAP_HIDDEN_PATH
### Creating directory for outputting results
RESULT_DIR_NAME=$FILE_NAME_PREFIX$IS_CSV$(date +"%y-%m-%d_%T")   # name of directory with results of processing
mkdir $RESULT_DIR_NAME
cd $RESULT_DIR_NAME
RESULT_DIR_PATH=$(pwd)
echo 'Outputing results to directory '$RESULT_DIR_PATH

GetDirNameFromStr() {					# function to get directory name from the string that been read from CSV file
	local _HTTP='http://'
	local _HTTPS='https://'
	local TMPSTR='' 
	TMPSTR=${1/$_HTTPS/''}
	TMPSTR=${TMPSTR/$_HTTP/''}
	TMPSTR=`expr "$TMPSTR" : '\([a-z0-9.-]*\)'`
	DIRNAME=$TMPSTR
}

cd $SQLMAP_OUTPUT_PATH
for CSVFile in `find ./ -maxdepth 0 -type f -name "*.csv"`;do 					# processing CSV files
	FILE=$SQLMAP_OUTPUT_PATH$CSVFile
	echo 'Processing CSV file: '$FILE
	while read LINE
	do
		echo 'String been read from CSV: '$LINE
		if [ ${LINE: -4 } == ',,,,' ];then
			if ! [ -d $RESULT_DIR_PATH'/'$NOTINJECTABLE ]; then
				mkdir $RESULT_DIR_PATH'/'$NOTINJECTABLE
			fi
			GetDirNameFromStr $LINE
			echo 'Directory name: '$DIRNAME
			$ACTION $SQLMAP_OUTPUT_PATH$DIRNAME $RESULT_DIR_PATH'/'$NOTINJECTABLE'/' 2>/dev/null
			echo $LINE >> $RESULT_DIR_PATH'/'$NOTINJECTABLE'/'websiteslist.txt
		elif [ ${LINE: -4 } == 'e(s)' ];then
			echo 'e(s)' > /dev/null
		elif [ ${LINE: -4 } == 'able' ];then
			if ! [ -d $RESULT_DIR_PATH'/'$MAYBEINJECTABLE ]; then
				mkdir $RESULT_DIR_PATH'/'$MAYBEINJECTABLE
			fi
			GetDirNameFromStr $LINE
			echo 'Directory name: '$DIRNAME
			$ACTION $SQLMAP_OUTPUT_PATH$DIRNAME $RESULT_DIR_PATH'/'$MAYBEINJECTABLE'/' 2>/dev/null
			echo $LINE >> $RESULT_DIR_PATH'/'$MAYBEINJECTABLE'/'websiteslist.txt
		else
			if ! [ -d $RESULT_DIR_PATH'/'$INJECTABLE ]; then
				mkdir $RESULT_DIR_PATH'/'$INJECTABLE
			fi
			GetDirNameFromStr $LINE
			echo 'Directory name: '$DIRNAME
			$ACTION $SQLMAP_OUTPUT_PATH$DIRNAME $RESULT_DIR_PATH'/'$INJECTABLE'/' 2>/dev/null
			echo $LINE >> $RESULT_DIR_PATH'/'$INJECTABLE'/'websiteslist.txt
		fi
	done < $FILE
	rm $FILE
done                                                         # processing the rest of directories
#	for dir in `ls -F1 $SQLMAP_OUTPUT_PATH | grep -e ./ | tr -d \/`
#	do 
#		echo 'directory name: '$dir
#	done
for DIR in `find $SQLMAP_OUTPUT_PATH -maxdepth 0 -type d`
do
	if [$DIR == './'];then
		continue
	fi
	LEN=${#SQLMAP_OUTPUT_PATH}
	let "LEN+=1"
	echo 'directory name: '$DIR
	cd $DIR
	if [ -f 'target.txt' ];then
		read -r firstline<'target.txt'
		DR=`expr "$firstline" : '\([a-z0-9.-?/:]*\)'`
	else
		DR=${DIR:$LEN}
	fi
	if [ -s log ];then
		if ! [ -d $RESULT_DIR_PATH'/'$INJECTABLE ]; then
			mkdir $RESULT_DIR_PATH'/'$INJECTABLE
		fi
		cd ..
		$ACTION $DIR $RESULT_DIR_PATH'/'$INJECTABLE'/'
		echo $DR >> $RESULT_DIR_PATH'/'$INJECTABLE'/'websiteslist.txt
	else
		if ! [ -d $RESULT_DIR_PATH'/'$NOTINJECTABLE ]; then
			mkdir $RESULT_DIR_PATH'/'$NOTINJECTABLE
		fi
		cd ..
		$ACTION $DIR $RESULT_DIR_PATH'/'$NOTINJECTABLE'/'
		echo $DR >> $RESULT_DIR_PATH'/'$NOTINJECTABLE'/'websiteslist.txt
	fi
done
echo 'Sorting finished. Have a nice day, Neo!'
