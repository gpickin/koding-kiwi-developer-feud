component {

	property name="serverService" inject="ServerService";

	/**
	 * Generate Swagger
	 */
	function run() {
		var serverDetails = serverService.resolveServerDetails( {} );
		var serverInfo = serverDetails.serverInfo;
		var runnerURL = ( serverInfo.SSLEnable ? 'http://' : 'http://' ) & '#serverInfo.host#:#serverInfo.port#/cbswagger?fwreinit=1';
		try{ 
			FileDelete( "swagger.json" );
		} catch ( any e ){

		}
		command( "!curl -v #runnerURL# | jq ." )
			.append( "swagger.json")
			.run();
	}

}
