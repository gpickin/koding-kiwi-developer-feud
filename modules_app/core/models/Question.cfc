component extends="core.models.BaseEntity"  table="questions" accessors="true" {

    property name="questionID" column="questionID" setter="false";
    property name="question";

    variables._key = "questionID";

    this.constraints = {
        "question": {
            required: true,
            size: "1..255",
        }
    }

    this.newQuestionconstraints = {
        "question": {
            required: true,
            size: "1..255"
        },
        "correctAnswer": {
            required: true
        }
    }

    /**
	 * Constructor
	 */
	function init() {
		super.init( entityName = "Question" );
		return this;
	}

    function getConstraints(){
        return this.constraints;
    }

    function answers(){
        return hasMany( "Answer@core", "questionID" );
    }
}