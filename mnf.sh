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

PROTECTED_BRANCHES=("dev" "test" "prod")

if [ $# -ne 1 ];
then
	BEFORE=$(git stash list)

	git stash save gup-temporary-stash
	
	if ! git checkout $2;
	then
		exit $?
	fi

	if ! git merge --no-ff --no-edit $1;
	then
		exit $?
	fi

	script_dir="$(dirname "$0")"
	"$script_dir/auto-tag.sh" || {
		echo "🔥  auto-tag failed – see message above."
		exit 1
	}

	if [ "$BEFORE" != "$(git stash list)" ]; 
	then
		git stash pop
	fi

	if [ "$BEFORE" == "$(git stash list)" ]; 
	then
		echo ""
		echo "-------- Merge completed successfully! --------"

		PROTECTED_BRANCH=false
		for branch in "${PROTECTED_BRANCHES[@]}"; do
			if [ "$1" == "$branch" ]; then
				PROTECTED_BRANCH=true
				break
			fi
		done

		if [ "$PROTECTED_BRANCH" == false ];
		then
			read -p "Do you want to delete the feature branch? (Y/n): " DELETE_BRANCH
			if [ "$DELETE_BRANCH" == "Y" ] || [ "$DELETE_BRANCH" == "y" ];
			then
				git branch -d $1
			fi
		fi
	else
		echo ""
		echo "-------- Merge completed successfully, but there was a problem when popping the stash. Please resolve the conflicts manually and run 'git stash drop', or reset your working directory and run 'git stash pop' on another branch. --------"
		exit 1
	fi
else
	git merge --no-ff $1
	exit $?
fi