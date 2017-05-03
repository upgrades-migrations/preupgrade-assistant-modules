#!/bin/bash


rpm -q authconfig >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
    echo "The authconfig package is not installed."
fi

authconfig --updateall
