#!/bin/bash
tsocks git config --global user.name "JiYou"
tsocks git config --global user.email "jiyou09@gmail.com"
tsocks git remote rm origin
tsocks git remote add origin git@github.com:JiYou/easyinstall.git
tsocks git add .
tsocks git commit -asm "Update"
tsocks git push origin
