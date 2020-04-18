component {

    this.basePath = "";

    function run( 
        required datasource,
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
		var entityContent          = fileRead( "/commandbox-quickly/templates/Entity.txt" );
        var propertyContent        = fileRead( "/commandbox-quickly/templates/Property.txt" );

        if (!arguments.dbType.len() || arguments.dbType == "sqls" || arguments.dbType == "sqlserver"){
            var ds = {
                class: 'net.sourceforge.jtds.jdbc.Driver'
                , bundleName: 'jtds'
                , bundleVersion: '1.3.1'
                , connectionString: 'jdbc:jtds:sqlserver://localhost:1433/' & arguments.datasource
                , username: arguments.username
                , password: arguments.password
            };
        } else if (arguments.dbType == "mysql"){
            var ds = {
                class: 'com.mysql.cj.jdbc.Driver'
                , bundleName: 'com.mysql.cj'
                , bundleVersion: '8.0.15'
                , connectionString: 'jdbc:mysql://localhost:3306/' & arguments.datasource & '?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Los_Angeles&useLegacyDatetimeCode=true'
                , username: arguments.username
                , password: arguments.password
            };
        }

        
        if (!arguments.tableList.len()){

            dbinfo name="arguments.tableList" type="tables" datasource=ds;

            arguments.tableList = arguments.tableList.filter(function(table){
                return ( table.table_schem == "dbo" && !listFind( "cfmigrations,sysdiagrams", table.table_name ) && reMatch("s$", table.table_name).len() );
            })
        }
		
		for (table in arguments.tableList){
            var allProperties = "";
			try {
                dbinfo name="columns" type="columns" table=table.table_name datasource=ds;
                for (column in columns){
                    
                    allProperties = allProperties & replaceNoCase(
                    propertyContent,
					"|property|",
					'property name="#columns.column_name#";',
					"all"
				    ) & cr;
                }
                print.greenLine(allProperties);

                var newEntityContent = replaceNoCase(
                entityContent,
				"|properties|",
				allProperties,
				"all"
                );
                
                var tableName = REreplaceNoCase(table.table_name, "ies$", "y");
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
                   // print.redLine( "Exiting..." );
                    continue;
                }

                // Write out the files
                file action="write" file="#entityPath#" mode="777" output="#newEntityContent#";
                print.greenLine( "Created #entityPath#" );

            } catch ( any e ) {
                print.redLine(e.Message);
            }
            
		}
    }
}