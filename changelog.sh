#!/bin/bash

git log $1 --pretty=format:'<li>%s</li>' --reverse | grep -v Merge >changelog.html