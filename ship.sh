#!/bin/bash

#The MIT License (MIT)

#Copyright (c) 2015-2016 Joel Marshall - Tusk Software - https://tusksoft.com

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

ship_cleanup() {
	if git show-ref --verify --quiet refs/remotes/origin/$1;
	then
		git bdd $1
	else
		git bd $1
	fi
}

if [ $# == 2 ];
then
	MNF_SKIP_DELETE_PROMPT=1 git gmnf $1 $2 && git push && ship_cleanup $1
elif [ $# == 3 ];
then
	if [ "$1" != "--update-both" ];
	then
		echo "invalid flag '$1'"
		exit 1
	fi
	MNF_SKIP_DELETE_PROMPT=1 git gmnf $1 $2 $3 && git push && ship_cleanup $2
else
	echo "invalid syntax. usage: git ship <feature> <trunk>  OR  git ship --update-both <feature> <trunk>"
	exit 1
fi