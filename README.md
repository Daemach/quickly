# Quickly

### A tool to build [Quick](https://github.com/elpete/quick) entities directly from your database

## Installation
Install Quickly using commandbox:

```json
install commandbox-quickly
```

## Caviat Emptor

This command assumes that you are adhering to these Quick conventions:

* You have database tables that named as a plural of the entities you wish to create. (User entities =  Users table.  Gallery entities = Galleries table.)
* Your primary key field is named "id" on each table.
* Quickly will add relationships if your tables have foreign keys named according to convention.  (Galleries table might have a userID, Images table might have a galleryID)
* Quickly will currently create basic relationships only - hasMany, hasManyThrough (1 level), belongsTo, belongsToThrough (1 level).  If you have one-to-one or many to many relationships, you can use these as a guide to add/modify them.  [More info here](https://quick.ortusbooks.com/v/3.0.0/relationships/relationship-types).


Quickly hasn't been tested on mysql because I don't use it.  If you run into problems let me know and I'll look into it.

## Usage

First, cd to your site root.

Commandbox does not run in the context of your site and therefore has no datasources.  Datasources are created on the fly by passing a database name and credentials.

dbaseName assumes localhost by default.  If your database is somewhere else, use hostname:port:dbaseName.  Port defaults are mssql: 1433, mysql: 3306

dbaseType and tableList are optional.  If you leave the database type blank it defaults to mssql (mysql is the alternative).  

If you leave tableList blank it will create entities for all of the dbo.tables it finds that have names that end in "ies" or "s", excluding sysdiagrams and cfmigrations.  If you want to limit this to specific tables, pass in a comma-delimited list (with,no,spaces).  Keep in mind that if you leave out a table, you may may have to add relationships manually

It will create these entities within a models/entities folder in your site and will prompt you to confirm overwriting if it finds an existing file.

```json
quickly create entities dbaseName userName passWord  dbaseType tableList
```