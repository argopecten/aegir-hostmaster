---
name: aegir-module-enable-order
description: Canonical module enable order for Aegir hosting modules to avoid dependency failures during install or recovery.
---

# Aegir Module Enable Order

Use this skill when enabling modules manually or recovering broken dependencies.

## Order

`hosting -> hosting_task -> hosting_server -> hosting_web_server -> hosting_db_server -> hosting_platform -> hosting_client -> hosting_package -> hosting_site`

## Command

`drush pm:enable hosting hosting_task hosting_server hosting_web_server hosting_db_server hosting_platform hosting_client hosting_package hosting_site -y`

Source: `.github/SKILLS.md`
