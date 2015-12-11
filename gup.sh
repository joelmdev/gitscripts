#!/bin/bash

#The MIT License (MIT)

#Copyright (c) 2015 Joel Marshall - Tusk Software - http:#tusksoft.com

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


HASERROR=false

if [ $# -le 3 ];
then
	BEFORE=$(git stash list)
	git stash save gup-temporary-stash

	if [ $# == 1 ];
	then
		echo "Gup is updating branch '$1' with latest changes from remote repo."
		echo ""
		git fetch --all --prune
		git checkout $1
		echo "Replaying any local commits to '$1' on top of latest changes from remote repo."
		git rebase -p origin/$1 
	fi

	if [ $# == 2 ];
	then
		echo "Gup is updating branch '$2' with latest changes from remote repo and rebasing local branch '$1' on top of '$2'."
		echo ""
		git fetch --all --prune
		git checkout $2
		echo "Replaying any local commits to '$2' on top of latest changes from remote repo."
		git rebase -p origin/$2 
		git checkout $1
		echo "Replaying '$1' onto updated '$2'."
		git rebase -p $2
	fi

	if [ $# == 3 ];
	then
		if  [ $1 == "--update-both" ];
		then
		echo "Gup is updating branches '$2' and '$3' with latest changes from remote repo and rebasing branch '$2' on top of '$3'. (You're the feature owner, right?)"
		echo ""
		git fetch --all --prune
		git checkout $3
		echo "Replaying any local commits to '$3' on top of latest changes from remote repo."
		git rebase -p origin/$3
		git checkout $2
		echo "Replaying any local commits to '$2' on top of latest changes from remote repo."
		git rebase -p origin/$2 
		echo "Replaying updated '$2' onto updated '$3'."
		git rebase -p $3
		else
			HASERROR=true
			echo "invalid flag '$3'"
		fi
	fi
	
	if [ "$BEFORE" != "$(git stash list)" ]; 
	then
		git stash pop
	fi
	
	if [ "$HASERROR" == "false" ];
	then
		echo ""
		echo "-------- Gup completed successfully! --------"
	fi
	
else
	echo "invalid syntax."
fi