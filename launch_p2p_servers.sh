#!/bin/bash
coffee -bc $1.coffee
screen -c $1.screen
screen -list | head -2 | tail -1 | cut -f2 | xargs -I {} screen -S {} -X quit
