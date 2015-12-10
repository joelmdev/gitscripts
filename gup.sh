#!/bin/bash


BEFORE=$(git stash list)
git stash save gup-temporary-stash
if [ $# -ne 1 ];
then
	git checkout $2
	git fetch --all --prune
	git rebase -p origin/$2 
	git checkout $1
	git rebase -p $2
else
	git checkout $1
	git fetch --all --prune
	git rebase -p origin/$1 
fi
if [ "$BEFORE" != "$(git stash list)" ]; 
then
	git stash pop
fi