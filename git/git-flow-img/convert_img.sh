#!/bin/sh

convert first-commit.png -type GrayScale eps2:first-commit.eps
convert feature-finish.png -type GrayScale eps2:feature-finish.eps
convert ff-merge.png -type GrayScale eps2:ff-merge.eps
convert release-finish.png -type GrayScale eps2:release-finish.eps
convert hotfix-finish.png -type GrayScale eps2:hotfix-finish.eps
