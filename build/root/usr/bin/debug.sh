#!/bin/bash

if [ "$CONTAINER_DEBUG" = "1" ]; then
    export PS4=' Line ${LINENO}: '
	set -x
fi