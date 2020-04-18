component {

    this.basePath = "";

    function run( 
        required database,
        required username,
        required password,
        dbType = "", 
        tableList = ""){
        this.basePath = resolvePath( "models/entities" );

        // Validate directory
		if ( !directoryExists( this.basePath ) ) {
			directoryCreate( this.basePath );
        }

        print.line();

        // Read in Templates
		var entityContent           = fileRead( "/commandbox-quickly/templates/entity.txt" );
        var propertyContent         = fileRead( "/commandbox-quickly/templates/property.txt" );
        var hasManyContent          = fileRead( "/commandbox-quickly/templates/hasMany.txt" );
        var hasManyThroughContent   = fileRead( "/commandbox-quickly/templates/hasManyThrough.txt" );
        var belongsToContent        = fileRead( "/commandbox-quickly/templates/belongsTo.txt" );
        var belongsToThroughContent = fileRead( "/commandbox-quickly/templates/belongsToThrough.txt" );

        if (arguments.database contains ":"){
            var dbase = listToArray(arguments.database);
        } else {
            var dbase = ["localhost","",arguments.database];
        }

        if (!arguments.dbType.len() || arguments.dbType == "sqls" || arguments.dbType == "sqlserver" || arguments.dbType == "mssql"){
            var ds = {
                class: 'net.sourceforge.jtds.jdbc.Driver'
                , bundleName: 'jtds'
                , bundleVersion: '1.3.1'
                , connectionString: 'jdbc:jtds:sqlserver://' & dbase[1] & ':' & ((dbase[2].len()) ? dbase[2] : 1433) & '/' & dbase[3]
                , username: arguments.username
                , password: arguments.password
            };
        } else if (arguments.dbType == "mysql"){
            var ds = {
                class: 'com.mysql.cj.jdbc.Driver'
                , bundleName: 'com.mysql.cj'
                , bundleVersion: '8.0.15'
                , connectionString: 'jdbc:mysql://' & dbase[1] & ':' & ((dbase[2].len()) ? dbase[2] : 3306) & '/' & dbase[3] & '?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Los_Angeles&useLegacyDatetimeCode=true'
                , username: arguments.username
                , password: arguments.password
            };
        } else {
            print.redLine( "No valid database type found (options are mssql or mysql). Exiting..." );
            return;
        }

        
        if (!arguments.tableList.len()){

            dbinfo name="arguments.tableList" type="tables" datasource=ds;

            arguments.tableList = arguments.tableList.filter(function(table){
                return ( table.table_schem == "dbo" && !listFind( "cfmigrations,sysdiagrams", table.table_name ) && reMatch("s$", table.table_name).len() );
            }).reduce(function(r,e){
                print.line(e);
                return listAppend(r,e.table_name);
            },"")
        }

        var dsMap = {};
        var bForeignKeys = false;
        
        try {
            for (table in arguments.tableList){
                dbinfo name="columns" type="columns" table=table datasource=ds;

                dsMap[table] = [:];

                for (column in columns){

                    bForeignKeys = booleanFormat(column.is_foreignKey);

                    dsMap[table][column.column_name] =  {
                        type: column.type_name,
                        inc: booleanFormat(column.IS_AUTOINCREMENT),
                        nulls: booleanFormat(column.IS_NULLABLE),
                        pk: booleanFormat(column.is_primaryKey),
                        fk: booleanFormat(column.is_foreignKey),
                        fkName: column.REFERENCED_PRIMARYKEY,
                        fkTable: column.REFERENCED_PRIMARYKEY_TABLE,
                        sortOrder: column.ORDINAL_POSITION
                    } ;
                }
            }
            print.line(dsmap)
            var tableMap = singularize(dsmap.keyList());
            print.line()
            print.line(tableMap)
            
            for (tbl in dsmap){
                for (col in dsmap[tbl]){
                    if ( tableMap.s.findKey( replaceNoCase(col,"ID","","ALL" ) ).len() ){
                        var tableName = tableMap.s.findKey( replaceNoCase(col,"ID","","ALL" ) )[1].path
                        dsmap[tbl][col].fk = "true";
                        dsmap[tbl][col].fkTable = replaceNoCase(col,"ID","","ALL");
                        dsmap[tbl]["belongsTo"] = right(tableName,tableName.len()-1);
                        dsmap[tableMap.s[replaceNoCase(col,"ID","","ALL")]]["hasMany"] = ["#tbl#","#tableMap.p[tbl]#"];
                    }
                }
            }

            // try for passthroughs... really should make this recursive...
            for (tbl in dsmap){
                if ( dsmap[tbl].findKey( "belongsTo" ).len() ){
                    if ( dsmap[tableMap.s[dsmap[tbl].belongsTo]].findKey( "belongsTo" ).len() ){
                        dsmap[tbl]["belongsToThrough"] = [ "#dsmap[tbl].belongsTo#", "#dsmap[tableMap.s[dsmap[tbl].belongsTo]].belongsTo#" ];
                    }
                }
                if ( dsmap[tbl].findKey( "hasMany" ).len() ){
                    if ( dsmap[dsmap[tbl].hasMany[1]].findKey( "hasMany" ).len() ){
                        dsmap[tbl]["hasManyThrough"] = [ "#dsmap[tbl].hasMany[1]#", "#dsmap[dsmap[tbl].hasMany[1]].hasMany[1]#" ];
                    }
                }
            }

            debug = 0
            if (!debug){
                for (tbl in dsMap){
                    var allProperties = "";
    
                    for (col in dsMap[tbl]){
                        if (!listFindNoCase("hasMany,hasManyThrough,belongsTo,belongsToThrough", col)){
                            allProperties = allProperties & replaceNoCase(
                                propertyContent,
                                "|property|",
                                'property name="#col#";',
                                "all" ) & cr;
                        }
                    }

                    if (dsMap[tbl].findKey("hasMany").len()){
                        allProperties = allProperties & cr & replaceNoCase(
                                            hasManyContent,
                                            "|name|",
                                            dsMap[tbl].hasMany[1],
                                            "all" ) & cr;
                        allProperties = replaceNoCase(
                                            allProperties,
                                            "|value|",
                                            dsMap[tbl].hasMany[2],
                                            "all" );
                    }

                    if (dsMap[tbl].findKey("hasManyThrough").len()){
                        allProperties = allProperties & cr & replaceNoCase(
                                            hasManyThroughContent,
                                            "|name|",
                                            dsMap[tbl].hasManyThrough[2],
                                            "all" ) & cr;
                        allProperties = replaceNoCase(
                                            allProperties,
                                            "|value|",
                                            SerializeJson(dsMap[tbl].hasManyThrough),
                                            "all" );
                    }

                    if (dsMap[tbl].findKey("belongsTo").len()){
                        allProperties = allProperties & cr & replaceNoCase(
                                            belongsToContent,
                                            "|name|",
                                            dsMap[tbl].belongsTo,
                                            "all" ) & cr;
                        allProperties = replaceNoCase(
                                            allProperties,
                                            "|value|",
                                            dsMap[tbl].belongsTo,
                                            "all" );
                    }

                    if (dsMap[tbl].findKey("belongsToThrough").len()){
                        allProperties = allProperties & cr & replaceNoCase(
                                            belongsToThroughContent,
                                            "|name|",
                                            dsMap[tbl].belongsToThrough[2],
                                            "all" ) & cr;
                        allProperties = replaceNoCase(
                                            allProperties,
                                            "|value|",
                                            SerializeJson(dsMap[tbl].belongsToThrough),
                                            "all" );
                    }

                    
    
                    var newEntityContent = replaceNoCase(
                        entityContent,
                        "|properties|",
                        allProperties,
                        "all"
                        );

                    print.greenLine(newEntityContent);
                    
                    var tableName = REreplaceNoCase(tbl, "ies$", "y");
                    tableName = REreplaceNoCase(tableName, "s$", "");
                    var entityPath = resolvePath( "#this.basePath#/#tableName#.cfc" );
    
                    // Create dir if it doesn't exist
                    directoryCreate(
                        getDirectoryFromPath( entityPath ),
                        true,
                        true
                    );
    
                    // Confirm it
                    if (
                        fileExists( entityPath ) && !confirm(
                            "The file '#getFileFromPath( entityPath )#' already exists, overwrite it (y/n)?"
                        )
                    ) {
                        print.yellowLine( "Skipping #entityPath#..." );
                        continue;
                    }
    
                    // Write out the files
                    file action="write" file="#entityPath#" mode="777" output="#newEntityContent#";
                    print.greenLine( "Created #entityPath#" );
                }
            }
            
                
            
        } catch ( any e ) {
            print.redLine("Mesg: #e.Message#");
            //print.redLine("#e#");
            print.redLine("Line: #e.tagcontext[1].line#");
        }
    }

    function singularize(string a){
        var r = {
            s = {},
            p = {}
        };
        listToArray(a).each(function(e){
            var t = REreplaceNoCase(e, "ies$", "y");
            r.s[REreplaceNoCase(t, "s$", "")] = e;
            r.p[e] = REreplaceNoCase(t, "s$", "");
        });
        return r;
    }

    function makeHasMany(col){
        return 
    }
}