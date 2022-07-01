component extends="coldbox.system.testing.BaseTestCase" {

    function run(){
        describe( "Database", function() {
			it( "can be queried", function() {
				var q = queryExecute(
                    "SELECT * FROM `test`",
                    [],
                    {datasource="developer_feud"}
                );
                expect( q ).toBeQuery();
			} );
		} );
    }

}