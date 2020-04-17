# Quickly - a tool to build quick entities directly from your database

Quick is a popular CFML ORM.

## Installation
Install quickly using commandbox:

```json
install commandbox-quickly
```

## Usage

First, cd to your site root. dbase type and table list are optional.  If you leave the database type blank it defaults to mssql.  If you leave table list blank it will create entities for all of the tables it finds aside from sysdiagrams and cfmigrations.  

It will create these entities within a models/entities folder in your site.

```json
quickly create entities dbaseName userName passWord  [ ""/sqls/sqlserver/mysql ] [ commaDelimited,tableList }
```
If this gets any traction I may add relationships based on foreign keys.  Let me know if you think that would be useful.
