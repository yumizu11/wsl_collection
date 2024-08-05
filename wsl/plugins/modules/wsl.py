#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Yuichi Mizutani (yumizu11) <iyumizu@hotmail.com>

DOCUMENTATION = '''
---
module: wsl

short_description: This module updates wsl and aksi shutdown wsl

version_added: "0.1"

description:
    - "This module controls wsl system. Currently you can update wsl system (not distribution), and also shutdown wsl (it causes all distributions will be terminated)."

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

# Update WSL
- name: Update WSL
  yumizu11.wsl.wsl:
    state: updated

# Uninstall WSL
- name: WSL is uninstalled
  yumizu11.wsl.wsl:
    state: absent
    
# Shutdown WSL
- name: Shutdown WSL
  yumizu11.wsl.wsl:
    state: shutdown
'''

RETURN = '''
'''
