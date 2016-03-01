#!/bin/bash


rpm -q authconfig >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Package authconfig is not installed."
fi

authconfig --updateall
