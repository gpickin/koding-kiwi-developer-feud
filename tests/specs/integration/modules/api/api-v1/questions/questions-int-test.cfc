/**
 * Test Spec for the /api/v1/questions Handler
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll() {
		super.beforeAll();
		// do your own stuff here
	}

	function afterAll() {
		// do your own stuff here
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run() {
		describe( "API V1 Questions Handler", function() {
            beforeEach( function( currentSpec ) {
				// Setup as a new ColdBox request
                // VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			} );

            scenario( "GET /api/v1/questions", function() {
                given( "we provide no authentication", function() {
                    then( "we get a list of question structs", function() {
                        var event = get(
                            route = "/api/v1/questions"
                        );
                        
                        expect( event ).toHaveStatusCode( 200 );
                        expect( event.getRenderedContent() ).toBeJSON();
                        var response = deserializeJSON( event.getRenderedContent() );
                        debug( response );
                        expect( response ).toBeStruct();
                        expect( response ).toHaveKeyWithCase( "data" );
                        expect( response ).toHaveKeyWithCase( "error" );
                        expect( response ).toHaveKeyWithCase( "pagination" );
                        expect( response ).toHaveKeyWithCase( "messages" );
                        expect( response.error ).toBeFalse();

                        expect( response.data ).toBeArray();
                        expect( response.data ).toHaveLengthGTE( 1 );
                        expect( response.data[1] ).toBeStruct();
                        // expect( question.create( response.data[1] ).isValid() ).toBeTrue( "This object is not a question object" );
                        expect( response.data[1] ).toHaveKeyWithCase( "questionID" );
                        expect( response.data[1] ).toHaveKeyWithCase( "question" );
                        //expect( response.data[1] ).toHaveKeyWithCase( "categoryID" );

                    });
                })
            })
        } );
    }

}