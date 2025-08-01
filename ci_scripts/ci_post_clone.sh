#!/bin/sh

#  ci_post_clone.sh
#  Cookle
#
#  Created by Hiromu Nakano on 2024/03/24.
#  Copyright © 2024 Hiromu Nakano. All rights reserved.

echo $SECRETS_BASE64 | base64 -d -o ../Cookle/Configurations/Secret.swift
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
