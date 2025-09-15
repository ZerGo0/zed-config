#!/bin/bash

./update_auto_install_extensions.sh
git add . && git commit -m 'chore: sync'
git push
