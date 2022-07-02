component extends=api.handlers.BaseHandler {

    property name="questionService" inject="quickService:Question@core";
    property name="answerService" inject="quickService:Answer@core";

    private function mergeWith( required parent, required children, required mergeKey, required parentField, childField="" ){
        if( !len( arguments.childField ) ){
            arguments.childField = parentField;
        }
        return parent.map( (parentItem) => {
            parentItem[ mergeKey ] = children.filter( ( childItem ) => {
                return ( childItem[ childField ] == parentItem[ parentField ] );
            });
            return parentItem;
        });
    }

    /**
     * Display a paginated list of Questions
     *
     * @x-route (GET) /api/v1/questions
     * @tags Questions
     * @x-parameters api-v1/_apidocs/questions/index/parameters.json##parameters
     * @response-default api-v1/_apidocs/questions/index/responses.json##200
     * 
     */
    function index( event, rc, prc ) secured{
        param rc.page = "1";
        param rc.maxrows = "25";
        param rc.includeAnswers = false;

        prc.questions = questionService
            .retrieveQuery()
            .paginate( rc.page, rc.maxrows );

        if( rc.includeAnswers ){
            prc.answers = answerService
                .whereIn( "questionID", prc.questions.results.map( function( item ){ return item.questionID } ) )
                .withCount( "votes" )
                .retrieveQuery()
                .get();

            mergeWith( prc.questions.results, prc.answers, "answers", "questionID" );

        }

        prc.response
            .setDataWithPagination( 
                prc.questions
            );
    }

    /**
     * 
     * Creating a new Question
     * 
     * @x-route (POST) /api/v1/questions
     * @tags Questions
     * @requestBody api-v1/_apidocs/questions/create/requestBody.json
     * @response-200 api-v1/_apidocs/questions/create/responses.json##200 
     * @response-401 /resources/apidocs/api/v1/_responses/responses.401.json##401
     * @response-403 /resources/apidocs/api/v1/_responses/responses.403.json##403
     */
    function create( event, rc, prc ) {
        prc.oQuestion = questionService.create( { "question": rc.question } );
        prc.response
            .addMessage( "Question Created" )
            .setData( prc.oQuestion.getMemento() );
    }

}