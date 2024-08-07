#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Yuichi Mizutani (yumizu11) <iyumizu@hotmail.com>

DOCUMENTATION = '''
---
module: wsl

short_description: This module updates wsl and aksi shutdown wsl

version_added: "0.1"

description:
    - "This module controls wsl system. Currently you can update wsl system (not distribution), and also shutdown wsl (it causes all distributions will be terminated) with this module."

options:
    state:
        description:
            - Specifying one of 'updated' (wsl will be updated) or 'shutdown' (all distributions will be terminated, and wsl is shutdown."
        required: true

author:
    - Yuichi Mizutani (@yumizu11)
'''

EXAMPLES = '''
# Install store version of wsl if not installed
- name: Store version of wsl is installed
  yumizu11.wsl.wsl:

# Update WSL if store version of wsl is installed, or install store version of wsl if not installed
- name: Update WSL
  yumizu11.wsl.wsl:
    state: updated

# Uninstall store version of WSL (inbox version wsl is still there)
- name: WSL is uninstalled
  yumizu11.wsl.wsl:
    state: absent
    
# Shutdown WSL
- name: Shutdown WSL
  yumizu11.wsl.wsl:
    state: shutdown
'''

RETURN = '''
currenver:
    description: Current versio of wsl
    type: str
    returned: when state is update or present
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
'''
