component extends="quick.models.BaseEntity" table="answers" accessors="true" {

    property name="answerID" column="answerID";
    property name="answer";
    property name="questionID";

    variables._key = "answerID";

    this.constraints = {
        "answer": {
            required: true,
            size: "1..255"
        }
    }

    function votes(){
        return hasMany( "Vote@core", "answerID" );
    }
}