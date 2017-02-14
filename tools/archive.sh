#!/bin/bash
pushd ~
tar cJf fgci-ansible-`date +%Y%m%d`.tar.xz -X .fgci-ansible-excludes ./fgci-ansible
popd
