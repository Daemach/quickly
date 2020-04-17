# Quickly

### A tool to build [Quick](https://github.com/elpete/quick) entities directly from your database

## Installation
Install quickly using commandbox:

```json
install commandbox-quickly
```

## Usage

First, cd to your site root. 

dbaseType and tableList are optional.  If you leave the database type blank it defaults to sqls (mysql is the alternative).  

If you leave tableList blank it will create entities for all of the dbo.tables it finds aside from sysdiagrams and cfmigrations.  If you want to limit this to specific tables, pass in a comma-delimited list (with,no,spaces).

It will create these entities within a models/entities folder in your site.

```json
quickly create entities dbaseName userName passWord  dbaseType tableList
```

If this gets any traction I may add relationships based on foreign keys.  Let me know if you think that would be useful.
