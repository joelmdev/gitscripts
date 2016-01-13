#!/bin/bash

#The MIT License (MIT)

#Copyright (c) 2015 Joel Marshall - Tusk Software - https://tusksoft.com

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


HASERROR=true

if [ $# -le 1 ];
then
	echo "Resync will reset branch '$1' to copy from remote repository. This will delete your local copy of '$1'. This can cause loss of work if you have progressed '$1' locally. Are you sure you want to continue? (Type YES to continue)"
	read ANSWER
	
	if [ "$ANSWER" == "YES" ];
	then
		BEFORE=$(git stash list)
		git stash save resync-temporary-stash
	
		git checkout master
		git branch -D $1
		git fetch --all --prune
		git checkout $1
		HASERROR=false
		
		if [ "$BEFORE" != "$(git stash list)" ]; 
		then
			git stash pop
		fi
		
		if [ "$HASERROR" == "false" ];
		then
			echo ""
			echo "-------- Resync completed successfully! --------"
		else
			echo ""
			echo "-------- Resync did not complete successfully. Please check the output above to identify the error. --------"
		fi
	else
		echo "Resync aborted."
	fi
	
else
	echo "invalid syntax."
fi