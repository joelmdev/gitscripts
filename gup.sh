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


HASERROR=true

if [ $# -le 3 ];
then
	BEFORE=$(git stash list)
	git stash save gup-temporary-stash

	if [ $# == 1 ];
	then
		HASREMOTE=$(git branch -l -a | grep /$1$)
		if [ "$HASREMOTE" == "" ];
		then
			echo "Can't update '$1' from the remote repo because no remote by the name of '$1' can be found."
		else
			echo "Gup is updating branch '$1' with latest changes from remote repo."
			echo ""
			git fetch --all --prune
			git checkout $1
			echo "Replaying any local commits to '$1' on top of latest changes from remote repo."
			REBASEPROGRESS=$(git rebase -p origin/$1|tee /dev/tty)
			HASERROR=false
		fi
	elif [ $# == 2 ];
	then
		HASREMOTE=$(git branch -l -a | grep /$1$)
		if [ "$HASREMOTE" == "" ];
		then
			echo "Gup is updating branch '$2' with latest changes from remote repo and rebasing local branch '$1' on top of '$2'."
			echo ""
			git fetch --all --prune
			git checkout $2
			echo "Replaying any local commits to '$2' on top of latest changes from remote repo."
			git rebase -p origin/$2 
			git checkout $1
			echo "Replaying '$1' onto updated '$2'."
			REBASEPROGRESS=$(git rebase -p $2|tee /dev/tty)
			HASERROR=false
		else
			echo "It appears that your branch '$1' has been pushed to the remote repository. Please use 'git gup --update-both $1 $2' instead."
		fi

	elif [ $# == 3 ];
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
			REBASEPROGRESS=$(git rebase -p $3|tee /dev/tty)
			HASERROR=false
		else
			echo "invalid flag '$3'"
		fi
	else
		echo "invalid number of arguments"	
	fi
	
	REBASESUCCEEDED=$(echo $REBASEPROGRESS | grep "Successfully rebased and updated")
	if [ "$REBASESUCCEEDED" == "" ];
	then
		HASERROR=true
	fi
	
	if [ "$HASERROR" == "false" ];
	then
		if [ "$BEFORE" != "$(git stash list)" ]; 
		then
			git stash pop
		fi
		echo ""
		echo "-------- Gup completed successfully! --------"
		if [ $# == 3 ];
		then
			echo ""
			echo "--update-both needs you to force an update of the remote feature branch '$2'. Would you like to do that now? (type YES to confirm, or any other key to do it later.)"
			read ANSWER
			if [ "$ANSWER" == "YES" ];
			then
				git push --force origin $2
			else
				echo "Forced update of '$2' aborted. Please be sure to run 'git push --force origin $2' before running 'git gup' again."
			fi
		fi
	else
		echo ""
		echo "-------- Gup did not complete successfully. Please check the output above to identify the error. --------"
		if [ "$BEFORE" != "$(git stash list)" ]; 
		then
			echo "Gup stashed your uncommitted changes, but did not pop them due to an error. Remember to run 'git stash pop' once you have resolved the error."
		fi
	fi
	
else
	echo "invalid syntax."
fi