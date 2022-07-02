component {


	/**
	 * Validate Swagger
	 */
	function run() {
		var pwd = ExpandPath( GetDirectoryFromPath( GetCurrentTemplatePath() ) & "../" );
		command( "!docker run -it -v #pwd#:/tmp stoplight/spectral:5 lint -s operation-operationId-unique -D -F error /tmp/swagger.json" )
			.run();
	}


}

