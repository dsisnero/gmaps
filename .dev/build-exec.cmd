@echo off
cd /d %~dp0..
call shards build %1 && call bin\%*
