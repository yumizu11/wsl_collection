#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Yuichi Mizutani (yumizu11) <iyumizu@hotmail.com>

DOCUMENTATION = '''
---
module: distribution

short_description: Install and uninstall WSL distribution

version_added: "0.1"

description:
    - "This module installs and uninstalls a specified WSL distribution (like Ubuntu-24.04). This module also terminates or unregisters running distribution"
    - "Store version of WSL must be installed to use this module. The yumizu11.wsl.wsl module can install store version of wsl. Please see the document of yumizu11.wsl.wsl for more information."

options:
    name:
        description:
            - Name of distribution to install, uninstall, terminate or unregister.
        required: false
    state:
        description:
            - Specifying one of 'present' (disto package is installed), 'absent' (distro is unregistered and package is uninstalled), 'installed' (distro package is unsitannled and registered), 'terminated' (distro state is stopped), 'unregistered' (distro is unregistered, but package is not uninstalled), 'exported' (distro is exported to .tar or .vhdx file), 'imported' (distro is installed from .tar or .vhdx file), or 'query' (registered distros are enumerated).
        required: true
    is_default:
        description:
            - Specify is the distro is default distro or not. This parameter is applicable only when state is 'present' or 'installed'.
        required: false
    default_user:
        description:
            - Specify default user on the distro. This parameter is applicable only when state is 'installed'. The user will be created automatically after the distro is installed.
        required: false
    run_cmd:
        description:
            - List of command to run just after distro is installed.
    src:
        description:
            - Path to .tar or .vhdx file which distro install from. This parameter is applicable only when state is 'imported'
    install_path:
        description:
            - Path to install distro. This parameter is applicable only when state is 'imported'
    vhd:
        description:
            - True if the distro file is vhdx. This parameter is applicable only when state is 'imported' or 'exported'
    dest:
        description:
            - Path to export distro to. This parameter is applicable only when state is 'exported'

author:
    - Yuichi Mizutani (@yumizu11)
'''

EXAMPLES = '''
# Install Ubuntu-24.04
- name: Ensure store version of WSL is installed
  yumizu11.wsl.wsl:
    state: present

- name: Install Ubuntu-24.04
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04

# Install Ubuntu-24.04 with creating default user
- name: Install Ubuntu-24.04 with creating user john
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    default_user: john
    state: installed

# Install Ubuntu-24.04 with creating default user and install the latest version of Ansible
- name: Install Ubuntu-24.04 with creating user john and install ansible
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    default_user: john
    run_cmd:
        - add-apt-repository ppa:ansible/ansible -y
        - apt update
        - apt upgrade -y
        - apt install ansible -y
    state: installed

# Uninstall Ubuntu-24.04 if installed
- name: Uninstall Ubuntu-24.04
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    state: absent

# Terminate Kali-linux
- name: Terminate Kali-linux
  yumizu11.wsl.distribution:
    name: kali-linux
    state: terminated

# Unregister Kali-linux
- name: Terminate Kali-linux
  yumizu11.wsl.distribution:
    name: kali-linux
    state: unregistered

# Export a distro to a tar file
- name: Export a distro (tar)
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    dest: C:\\temp\\ubuntu2404.tar
    state: exported

# Export a distro to a vhdx file
- name: Export a distro (vhdx)
  yumizu11.wsl.distribution:
    name: kali-linux
    dest: C:\\temp\\kali.vhdx
    vhd: true
    state: exported

# Import a distro from tar file
- name: Import distro (tar)
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04-2
    src: C:\\temp\\ubuntu2404.tar
    install_path: C:\\wsl\\Ubuntu-24.04-Copy
    state: imported

# Import a distro from vhdx file
- name: Import distro (vhdx)
  yumizu11.wsl.distribution:
    name: kali-2
    src: C:\\temp\\kali.vhdx
    install_path: C:\\wsl\\kali-linux-2
    state: imported
    
# Query installed distro
- name: Query installed distro
  yumizu11.wsl.distribution:
    state: query
    register: query_result

- name: Debug - show query_result
    ansible.builtin.debug:
    var: query_result
'''

RETURN = '''
default_distro:
    description: The name of default distro.
    type: str
    returned: always
installed_distro:
    description: List of registered distro.
    type: list
    returned: always
stdout:
    description: Standard Output of wsl.exe
    type: str
    returned: when wsl command was executed in this module
stderr:
    description: Standard Error of wsl.exe
    type: str
    returned: when wsl command was executed in this module
rc:
    description: return code of wsl.exe
    type: number
    returned: when wsl command was executed in this module
couldinit_rc:
    description: Return code of cloud-init (debug purpose only)
    type: number
    returned: when cloud-init is used after installing distro
wsl_path:
    description: path to wsl.exe which the module used
    type: str
    returned: always
wsl_version:
    description: version number of wsl.exe
    type: str
    returned: always
'''
