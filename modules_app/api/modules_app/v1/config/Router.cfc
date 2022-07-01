component {

	function configure() {
		// API Echo
		get( "/", "Echo.index" );

		// API Authentication Routes
		post( "/login", "Auth.login" );
		post( "/logout", "Auth.logout" );
		post( "/register", "Auth.register" );

		// API Secured Routes
		get( "/whoami", "Echo.whoami" );



		route( "/questions" )
			.withHandler( "Questions" )
			.toAction( { GET: "index" } );


		route( "/:handler/:action" ).end();
	}

}
