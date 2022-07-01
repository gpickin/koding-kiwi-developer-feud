component extends=api.handlers.BaseHandler {

    property name="questionService" inject="quickService:Question@core";
    property name="answerService" inject="quickService:Answer@core";

    function mergeWith( required parent, required children, required mergeKey, required parentField, childField="" ){
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



    function index( event, rc, prc ){
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

    

}