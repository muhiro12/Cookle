#!/bin/sh

#  ci_post_clone.sh
#  Incomes
#
#  Created by Hiromu Nakano on 2024/03/24.
#  Copyright © 2024 Hiromu Nakano. All rights reserved.

echo $SECRET_BASE64 | base64 -d -o ../Cookle/Cookle/Secret.swift
