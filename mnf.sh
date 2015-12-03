#!/bin/bash


if [ $# -ne 1 ];
then
git checkout $2
fi
git merge --no-ff $1