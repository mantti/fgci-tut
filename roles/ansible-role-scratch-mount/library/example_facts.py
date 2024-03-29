#
# (c) 2018 Red Hat Inc.
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.
#
from __future__ import (absolute_import, division, print_function)
from ansible.errors import AnsibleError
__metaclass__ = type


### Documentation
ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = """
    Examples:
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/iosxr/iosxr_facts.py
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/junos/junos_facts.py
"""

EXAMPLES = """
    Examples:
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/iosxr/iosxr_facts.py
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/junos/junos_facts.py
"""


RETURN = """
    Examples:
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/iosxr/iosxr_facts.py
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/junos/junos_facts.py
"""

### Imports
try:
    from ansible.module_utils.basic import AnsibleModule
    """
    Examples:
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/iosxr/iosxr_facts.py
        https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/junos/junos_facts.py
    """
except ImportError:
    raise AnsibleError("[ ansible-role-scratch-mount_facts ]: Dependency not satisfied")

### Implementation
def main():
    """
        Examples:
            https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/iosxr/iosxr_facts.py
            https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/network/junos/junos_facts.py
    """
    raise AnsibleError(" [ ansible-role-scratch-mount_facts ]: Not Implemented")

### Entrypoint
if __name__ == '__main__':
    main()