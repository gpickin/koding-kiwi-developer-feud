/**
 * Base JSON RESTFul handler
 * In each request the Response@api object will be dropped into the PRC scope as prc.response.
 * The current user requesting the call will be dropped into the PRC scope as prc.oCurrentUser
 *
 * <h2>Authentication and Authorizations</h2>
 * The Base Handler intercepts all calls to all actions. It will first assume all calls are public
 * unless the action has a 'secured' annotation, which denotes that it needs authentication.
 * If an action needs authentication and the user is not authenticated or their session timed out
 * the service will emit a 401 error exception with an appropirate status text.
 * <br>
 * You can also control the permissions needed for each user in order to execute an action by adding
 * a 'secured' annotation with a list of permissions to verify. If the user is not authorized a 403
 * will be emitted with the appropriate status text.
 */
component extends="coldbox.system.EventHandler" {

	// DI
	property name="cbsecurity" inject="@cbsecurity";

	// OPTIONAL HANDLER PROPERTIES
	this.prehandler_only = "";
	this.prehandler_except = "";
	this.posthandler_only = "";
	this.posthandler_except = "";
	this.aroundHandler_only = "";
	this.aroundHandler_except = "";

	// REST Allowed HTTP Methods Ex: this.allowedMethods = {delete='POST,DELETE',index='GET'}
	this.allowedMethods = {};

	// TODO: look in request context
	// Verb aliases - in case we are dealing with legacy browsers or servers
	METHODS = {
		"GET": "GET",
		"POST": "POST",
		"PATCH": "PATCH",
		"PUT": "PUT",
		"OPTIONS": "OPTIONS",
		"DELETE": "DELETE"
	};

	// TODO: look in request context
	// HTTP STATUS CODES
	STATUS = {
		"SUCCESS": 200,
		"CREATED": 201,
		"ACCEPTED": 202,
		"NO_CONTENT": 204,
		"BAD_REQUEST": 400,
		"NOT_AUTHORIZED": 401,
		"FORBIDDEN": 403,
		"NOT_FOUND": 404,
		"NOT_ALLOWED": 405,
		"NOT_ACCEPTABLE": 406,
		"LOCKED": 423,
		"TOO_MANY_REQUESTS": 429,
		"EXPECTATION_FAILED": 417,
		"INTERNAL_ERROR": 500,
		"NOT_IMPLEMENTED": 501
	};

	/**
	 * Around handler for all functions
	 */
	function aroundHandler(
		event,
		rc,
		prc,
		targetAction,
		eventArguments
	) {
		// Pagination variables
		event.paramValue( "page", "1" );
		event.paramValue( "maxRows", "25" );

		try {
			var stime = getTickCount();

			// prepare our response object
			prc.response = newResponse();
			// prepare argument execution
			var args = { event: arguments.event, rc: arguments.rc, prc: arguments.prc };
			structAppend( args, arguments.eventArguments );

			var simpleResults = arguments.targetAction( argumentCollection = args );

			auth().logout();
		} catch ( EntityNotFound e ) {
			log.warn( "#e.message# #e.detail#", e );

			prc.response.setErrorMessage( e.message, 404 );

			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
		} catch ( ValidationException e ) {
			log.warn( "#e.message# #e.detail#", e );

			var errors = deserializeJSON( e.extendedInfo );
			var allErrors = errors.reduce( function( allErrors, field, fieldErrors ) {
				arrayAppend(
					allErrors,
					fieldErrors.map( function( error ) {
						return error.message;
					} ),
					true
				);
				return allErrors;
			}, [] );
			prc.response
				.setData( errors )
				.setError( true )
				.setStatusCode( 412 )
				.setErrorMessage( allErrors, 412 );

			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
		} catch ( notAuthorized e ) {
			log.warn( "#e.message# #e.detail#", e );
			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
			onNotAuthorized( event, rc, prc );
		} catch ( onNotAuthorized e ) {
			log.warn( "#e.message# #e.detail#", e );
			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
			onNotAuthorized( event, rc, prc );
		} catch ( NotLoggedIn e ) {
			log.warn( "#e.message# #e.detail#", e );
			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
			onNotAuthenticated( event, rc, prc );
		} catch ( CloakingException e ) {
			log.warn( "#e.message# #e.detail#", e );

			prc.response.setErrorMessage( e.message, 403 );
			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
		} catch ( Any e ) {
			if ( listFindNoCase( "testing", getSetting( "environment" ) ) && structKeyExists( request, "textbox" ) ) {
				writeDump( var = e );
				request.testbox.debug( e );
				rethrow;
			}
			// Log Locally
			log.error( "Error calling #event.getCurrentEvent()#: #e.message# #e.detail#", e );

			// Setup General Error Response
			prc.response.setErrorMessage( "General application error: #e.message#", 500 );
			// Development additions
			if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
				prc.response.addMessage( "Detail: #e.detail#" ).addMessage( "StackTrace: #e.stacktrace#" );
			}
		}


		// Development/Staging additions
		if ( listFindNoCase( "development,staging", getSetting( "environment" ) ) ) {
			prc.response
				.addHeader( "x-current-route", event.getCurrentRoute() )
				.addHeader( "x-current-routed-url", event.getCurrentRoutedURL() )
				.addHeader( "x-current-routed-namespace", event.getCurrentRoutedNamespace() )
				.addHeader( "x-current-event", event.getCurrentEvent() );
		}

		// end timer
		prc.response.setResponseTime( getTickCount() - stime );

		// Did the user set a view to be rendered? If not use renderdata, else just delegate to view.
		if ( 1 == 1 || !len( event.getCurrentView() ) ) {
			// Simple HTML Handler Results?
			if ( !isNull( simpleResults ) ) {
				prc.response.setData( simpleResults ).setFormat( "html" );
			}
			// Magical Response renderings
			event.renderData(
				type = prc.response.getFormat(),
				data = prc.response.getDataPacket(),
				contentType = prc.response.getContentType(),
				statusCode = prc.response.getStatusCode(),
				statusText = prc.response.getStatusText(),
				location = prc.response.getLocation(),
				isBinary = prc.response.getBinary()
			);
		}

		// Global Response Headers
		prc.response
			.addHeader( "x-response-time", prc.response.getResponseTime() )
			.addHeader( "x-cached-response", prc.response.getCachedResponse() );

		// Custom Response Headers
		for ( var thisHeader in prc.response.getHeaders() ) {
			event.setHTTPHeader( name = thisHeader.name, value = thisHeader.value );
		}
	}

	/**
	 * Fires on invalid API Token calls
	 */
	function onInvalidAPIToken( event, rc, prc ) {
		prc.response
			.addMessage( "The API Token sent is invalid! Cannot continue request." )
			.setError( true )
			.setErrorCode( 403 )
			.setStatusCode( 403 )
			.setStatusText( "Invalid API Token" );
	}


	/**
	 * Prepare error response for an unathorized request
	 */
	function onNotAuthorized( event, rc, prc ) {
		prc.response.setErrorMessage(
			"Unauthorized Request! You do not have the right permissions to execute this request.",
			403
		);
	}

	/**
	 * Prepare error response for User not Found
	 */
	function UserNotFound( event, rc, prc ) {
		prc.response.setErrorMessage( "Requested User not Found", 404 );
	}

	/**
	 * Prepare error response for an un-authenticated request or session timeout
	 */
	function onNotAuthenticated( event, rc, prc ) {
		prc.response
			.addMessage( "Unauthorized Request! You do not have the right permissions to execute this request." )
			.setError( true )
			.setErrorCode( 401 )
			.setStatusCode( 401 )
			.setStatusText( "Not Authenticated" );
	}

	/**
	 * Fires on invalid routed events
	 */
	function onInvalidEvent( event, rc, prc ) {
		prc.response
			.addMessage( "The resource requested: '#event.getCurrentRoutedURL()#' does not exist" )
			.setError( true )
			.setErrorCode( 404 )
			.setStatusCode( 404 )
			.setStatusText( "Page Not Found" );
	}

	/**
	 * on localized errors
	 */
	function onError(
		event,
		rc,
		prc,
		faultAction,
		exception,
		eventArguments
	) {
		// Log Locally
		log.error(
			"Error in base handler (#arguments.faultAction#): #arguments.exception.message# #arguments.exception.detail#"
		);
		// Verify response exists, else create one
		if ( !structKeyExists( prc, "response" ) ) {
			prc.response = newResponse();
		}
		// Setup General Error Response
		prc.response.setErrorMessage( "Base Handler Application Error: #arguments.exception.message#", 500 );
		// Development additions
		if ( getSetting( "environment" ) eq "development" || getSetting( "environment" ) eq "staging" ) {
			prc.response
				.addMessage( "Detail: #arguments.exception.detail#" )
				.addMessage( "StackTrace: #arguments.exception.stacktrace#" );
		}
		// Render Error Out
		event.renderData(
			type = prc.response.getFormat(),
			data = prc.response.getDataPacket(),
			contentType = prc.response.getContentType(),
			statusCode = prc.response.getStatusCode(),
			statusText = prc.response.getStatusText(),
			location = prc.response.getLocation(),
			isBinary = prc.response.getBinary()
		);
	}

	/**
	 * on invalid http verbs
	 */
	function onInvalidHTTPMethod(
		event,
		rc,
		prc,
		faultAction,
		eventArguments
	) {
		// Log Locally
		log.warn(
			"InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#",
			getHTTPRequestData()
		);
		// Setup Response
		prc.response = newResponse().setErrorMessage(
			"InvalidHTTPMethod Execution of (#arguments.faultAction#): #event.getHTTPMethod()#",
			405
		);
		// Render Error Out
		event.renderData(
			type = prc.response.getFormat(),
			data = prc.response.getDataPacket(),
			contentType = prc.response.getContentType(),
			statusCode = prc.response.getStatusCode(),
			statusText = prc.response.getStatusText(),
			location = prc.response.getLocation(),
			isBinary = prc.response.getBinary()
		);
	}

	public any function newResponse() provider="Response@api" {
	}

	/**
	 * Ensures a value falls in a given range.
	 *
	 * @min The minimum value the target can be. If the actual value is less than the minimum value, the minimum value is returned.
	 * @actual The value to clamp.
	 * @max The maximum value the target can be. If the actual value is greater than the maximum value, the maximum value is returned.
	 *
	 * @returns numeric
	 */
	public numeric function clamp( required numeric min, required numeric actual, required numeric max ) {
		if ( arguments.actual < arguments.min ) {
			return arguments.min;
		}

		if ( arguments.actual > arguments.max ) {
			return arguments.max;
		}

		return arguments.actual;
	}

}
